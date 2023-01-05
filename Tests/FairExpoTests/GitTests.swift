/**
 Copyright (c) 2022 Marc Prud'hommeaux

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 The full text of the GNU Affero General Public License can be
 found in the COPYING.txt file or at https://www.gnu.org/licenses/

 Linking this library statically or dynamically with other modules is
 making a combined work based on this library.  Thus, the terms and
 conditions of the GNU Affero General Public License cover the whole
 combination.

 As a special exception, the copyright holders of this library give you
 permission to link this library with independent modules to produce an
 executable, regardless of the license terms of these independent
 modules, and to copy and distribute the resulting executable under
 terms of your choice, provided that you also meet, for each linked
 independent module, the terms and conditions of the license of that
 module.  An independent module is a module which is not derived from
 or based on this library.  If you modify this library, you may extend
 this exception to your version of the library, but you are not
 obligated to do so.  If you do not wish to do so, delete this
 exception statement from your version.
 */
#if DEBUG // TODO: enable testing in release builds
import Swift
import XCTest
@testable import FairCore
@testable import FairExpo

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension DataWrapper {
    /// Iterates through the entries of both the wrappers and executes the differentiator against the equivalent paths.
    /// - Parameters:
    ///   - against: the wrapper against which to diff
    ///   - differentiator: the diffing function
    /// - Returns: the list of differences between the two wrappers
    func diff<D: DataWrapper, Result>(_ pathKey: (Self.Path) -> String?, against: D, againstPathKey: (D.Path) -> String?, prioriry: TaskPriority? = nil, differentiator: @escaping (Self.Path?, D.Path?) async throws -> Result?) -> AsyncThrowingStream<Result?, Error> {
        let p1: [String? : Self.Path] = self.paths.dictionary(keyedBy: pathKey)
        let p2: [String? : D.Path] = against.paths.dictionary(keyedBy: againstPathKey)

        let paths = (Set(p1.keys.compacted()).union(p2.keys.compacted())).sorted()
        return paths.asyncMap(priority: prioriry) { path in
            let o1 = p1[path]
            let o2 = p2[path]
            return try await differentiator(o1, o2)
        }
    }
}

/// if the environment uses the "GH_TOKEN" or "GITHUB_TOKEN" (e.g., in an Action), then pass it along to the API requests
fileprivate let authToken: String? = ProcessInfo.processInfo.environment["GH_TOKEN"] ?? ProcessInfo.processInfo.environment["GITHUB_TOKEN"]

final class RemoteGitTests : XCTestCase {

    func testFair() async throws {
        let remote = try XCTUnwrap(URL(string: "https://github.com/fair-ground/Fair.git"))
        let fetch = try await Git.Rest().downloadPull(remote)
        let refs = fetch.refs
        XCTAssertLessThanOrEqual(462, refs.count)
        XCTAssertEqual("e9624bee3177db5443e23d65ba54fc28ca343afa", refs.first(where: { $0.name == "refs/tags/0.3.10" })?.branch)
    }


    func XXXtestCompareRepoContentsLocal() async throws {
        try await compareRepoContentsLocal(zipURL: URL(fileOrScheme: "~/Downloads/MemoZ-main.zip"), fsURL: URL(fileOrScheme: "~/Downloads/MemoZ-main/"))
    }

    func compareRepoContentsLocal(zipURL: URL, fsURL: URL) async throws {
        try await compareWrapperContents(zip: ZipArchiveDataWrapper(archive: ZipArchive(url: zipURL, accessMode: .read)), fs: FileSystemDataWrapper(root: fsURL))
    }

    func testCompareRepoContents() async throws {
        try await compareRepoContents(at: "marcprux/MemoZ")
//        try await compareRepoContents(at: "jectivex/JXKit") // seems to be wrong branch
//        try await compareRepoContents(at: "Alamofire/Alamofire") // missing file error
//        try await compareRepoContents(at: "fair-ground/Fair") // hangs and memory grows on checkout
//        try await compareRepoContents(at: "Huffle-Puff/App") // The file “b4df97b313d320feea3951333e04b08043c014” couldn’t be opened because there is no such file.
//        try await compareRepoContents(at: "Cloud-Cuckoo/App") // The file “3effe69ecaac9842fa4a932e65558a29de2d8d” couldn’t be opened because there is no such file.
    }

    func compareRepoContents(at orgName: String, branch: String = "main") async throws {
        let tmpdir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)
        dbg("tmpdir:", tmpdir.path)

        let gitURL = try XCTUnwrap(URL(string: "https://github.com/\(orgName).git"))
        let zipURL = try XCTUnwrap(URL(string: "https://github.com/\(orgName)/archive/refs/heads/\(branch).zip"))


        let gitout = tmpdir.appendingPathComponent("git", isDirectory: true)
        try FileManager.default.createDirectory(at: gitout, withIntermediateDirectories: true)
        dbg("cloning repository:", gitURL.absoluteString, "to:", gitout.path)
        dbg("downloading zip:", zipURL.absoluteString)

        async let fetch = try Git.Hub.clone(gitURL, local: gitout)
        async let (localZip, _) = try URLSession.shared.downloadFile(for: URLRequest(url: zipURL), useContentDispositionFileName: true, useLastModifiedDate: true)

        let zip = try await ZipArchiveDataWrapper(archive: ZipArchive(url: localZip, accessMode: .read))
        let (_, fs) = try await (fetch, FileSystemDataWrapper(root: gitout))

        dbg("downloaded zip:", zip.containerURL.path)

        try await compareWrapperContents(zip: zip, fs: fs)
    }

    func compareWrapperContents(zip: ZipArchiveDataWrapper, fs: FileSystemDataWrapper) async throws {
        struct DiffResult {
            var fsPath: FileSystemDataWrapper.Path? = nil
            var zipPath: ZipArchiveDataWrapper.Path? = nil
            var offset: Int? = nil
        }

        func compare(fsPath: FileSystemDataWrapper.Path?, zipPath: ZipArchiveDataWrapper.Path?) async throws -> DiffResult? {
//            return try await prf(msg: { result in result == nil ? nil : "compare: \(fsPath?.pathName ?? ""): \(result?.offset ?? 0)" }) {
                try await compareEntries(fsPath: fsPath, zipPath: zipPath)
//            }
        }

        func compareEntries(fsPath: FileSystemDataWrapper.Path?, zipPath: ZipArchiveDataWrapper.Path?) async throws -> DiffResult? {
            if fsPath?.pathName == ".git" || fsPath?.pathName.hasPrefix(".git/") == true {
                return nil // .git folders are not included in the zip, so do not compare
            }
            if fsPath?.pathName == ".github" || fsPath?.pathName.hasPrefix(".github/") == true {
                return nil // .github folders may not be in the zip
            }
            if zipPath?.pathName.hasSuffix(".github") == true {
                return nil // .github folders may not be in the zip
            }
            guard let fsPath = fsPath, let zipPath = zipPath, let zipEntry = zipPath.entry else {
                // one or the other path is missing
                return DiffResult(fsPath: fsPath, zipPath: zipPath)
            }

            if fsPath.pathIsDirectory && zipPath.pathIsDirectory {
                // skip over directories
                return nil
            }


            let zipEntryStream: AsyncThrowingStream<Data, Error> = zip.archive.extractAsync(from: zipEntry)
            //var zipEntryIterator = zipEntryStream.makeAsyncIterator()

            let fsEntryStream: FileHandle.FileAsyncBytes = try FileHandle(forReadingFrom: fsPath).bytesAsync
            var fsEntryIterator = fsEntryStream.makeAsyncIterator()

            var offset = 0

            for try await zipEntryDataChunk in zipEntryStream {
                //dbg("zipEntryDataChunk:", zipEntryDataChunk)
                for zb in zipEntryDataChunk {
                    guard let fb = try await fsEntryIterator.next() else { // out of bytes
                        return DiffResult(fsPath: fsPath, zipPath: zipPath, offset: offset)
                    }
                    if fb != zb { // the bytes are different at the given offset
                        return DiffResult(fsPath: fsPath, zipPath: zipPath, offset: offset)
                    }
                    offset += 1
                }
            }

            if try await fsEntryIterator.next() != nil { // there are more bytes in the file system: that's a difference
                return DiffResult(fsPath: fsPath, zipPath: zipPath, offset: offset)
            }

            return nil
        }

        for try await diff in fs.diff({ $0.pathName }, against: zip, againstPathKey: { $0.pathName.trimmingBasePath.isEmpty ? nil : $0.pathName.trimmingBasePath }, differentiator: compare) {
            if let diff = diff {
                dbg("diff:", diff)
                XCTFail("difference in paths: \(diff)")
                return
            }
        }

        // XCTAssertEqual([], diffs, "should have been no differences")
    }

    func XXXtestDemo() async throws {
        let remote = try XCTUnwrap(URL(string: "https://github.com/marcprux/DemoRepo.git"))
        guard let token = authToken else {
            throw XCTSkip("no auth token")
        }

        Git.Hub.session.password = token
        Git.Hub.session.user = "-unused-" // but seems to be needed to send credentials

        let rest = Git.Rest()
        let fetch = try await rest.downloadPull(remote)
        dbg("refs:", fetch.refs)
        guard let initialRef = fetch.refs.first else {
            return XCTFail("no initial ref")
        }

        let mainRef = "refs/heads/main"
        XCTAssertEqual(mainRef, initialRef.name)

        for (index, ref) in fetch.refs.enumerated() {
            dbg("pulling ref #\(index):", ref.branch)
            let pack = try await rest.pull(remote, want: ref.branch)

            if index == 0 {
                let commits = pack.commits.sorting(by: \.value.index, ascending: false)
                XCTAssertEqual(3, pack.commits.count)
                XCTAssertEqual(3, pack.trees.count)
                let messages = commits.map({ $0.value.commit }).map(\.message)
                XCTAssertEqual(["Initial commit", "Test commit 1\n", "Test commit 2\n"], messages)
            } else if index == 1 {
                XCTAssertEqual(1, pack.commits.count)
                XCTAssertEqual(1, pack.trees.count)
                XCTAssertEqual(20, pack.commits[ref.branch]?.1)
            } else if index == 2 {
                XCTAssertEqual(1, pack.commits.count)
                XCTAssertEqual(1, pack.trees.count)
            }
        }
    }
}

/// A test case whose `setUp` is expected to create a local URL that the test will use.
class LocalGitTest: XCTestCase {
    // TODO: @available(*, deprecated)
    fileprivate var url: URL! {
        get { localURL }
        set { localURL = newValue }
    }

    fileprivate var localURL: URL!

    override func tearDown() {
        if localURL != nil {
            XCTAssertNoThrow(try FileManager.default.removeItem(at: url))
        }
    }

    /// Returns the local testing URL for the given path.
    func localPath(_ path: String, isDirectory: Bool = false) -> URL {
        localURL.appendingPathComponent(path, isDirectory: isDirectory)
    }


    /// Returns a random temporary file URL
    func tmpfile(name: String = UUID().uuidString) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
    }

    /// Loads the test resource by name
    func resourcePath(_ name: String, ext: String? = nil) throws -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: ext) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return url
    }

    /// Loads the test fixture resource by name.
    func fixture(name: String, ext: String? = nil) async throws -> Data {
        try await Data(contentsOf: resourcePath(name, ext: ext))
    }

}

class TestGitAdd: LocalGitTest {
    private var repository: Git.Repository!

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try FileManager.default.createDirectory(at: localPath(".git/objects"), withIntermediateDirectories: true)
        repository = await Git.Repository(url)
    }

    func testFirstFile() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        var i = await Git.Index(url) ?? Git.Index()
        try await repository.stage.add(file, index: &i)
        try i.save(url)
        let data = try await Data(contentsOf: localPath(".git/index"))
        let index = await Git.Index(url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/index").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/95/d09f2b10159347eece71399a7e2e907ea3df4f").path))
        try await XXCTAssertEqual(27, (try await Data(contentsOf: localPath(".git/objects/95/d09f2b10159347eece71399a7e2e907ea3df4f"))).count)
        XCTAssertEqual(112, data.count)
        XCTAssertEqual(2, index?.version)
        XCTAssertEqual(40, index?.id.count)
        XCTAssertEqual(1, index?.entries.count)
        XCTAssertEqual("myfile.txt", index?.entries.first?.url.path.dropFirst(url.path.count + 1))
        XCTAssertEqual("95d09f2b10159347eece71399a7e2e907ea3df4f", index?.entries.first?.id)
        XCTAssertEqual(11, index?.entries.first?.size)
    }

    func testDoubleAdd() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        var index = await Git.Index(url) ?? Git.Index()
        try await repository.stage.add(file, index: &index)
        try await repository.stage.add(file, index: &index)
        XCTAssertEqual(1, index.entries.count)
    }

    func testCompressDecompress() async throws {
        try Data("hello world".utf8).write(to: localPath("myfile.txt"))
        for level in -1...9 {
            try await XXCTAssertEqual("hello world", String(decoding: Data.compressDeflate(
                try await Data(contentsOf: localPath("myfile.txt")), level: level).decompressInflate(), as: UTF8.self))
        }
    }

    func testNonExistingFile() async throws {
        let file = localPath("myfile.txt")
        var index = await Git.Index(url) ?? Git.Index()
        await XCTAssertThrowsError(try await repository.stage.add(file, index: &index))
    }

    func testOutsideProject() async throws {
        let file = tmpfile(name: "myfile.txt")
        try Data("hello world".utf8).write(to: file)
        var index = await Git.Index(url) ?? Git.Index()
        await XCTAssertThrowsError(try await repository.stage.add(file, index: &index))
    }
}

class TestGitCheckout: LocalGitTest {
    private var file: URL!
    private var rest: MockRest!

    override func setUp() async throws {
        rest = MockRest()
        Git.Hub.session = Git.Session()
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        Git.Hub.factory.rest = rest
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
    }

    func testTwoCommits() async throws {
        let repository = try await Git.Hub.create(url)

        try await repository.commit([self.file], message: "hello world")
        let first = try await Git.Hub.head.id(self.url)
        try Data("lorem ipsum\n".utf8).write(to: self.file)
        try await repository.commit([self.file], message: "lorem ipsum")
        let second = try await Git.Hub.head.id(self.url)
        XCTAssertNotEqual(first, second)
        try await XXCTAssertEqual("lorem ipsum\n", String(decoding: try await Data(contentsOf: self.file), as: UTF8.self))
        try await repository.check(first)
        try await XXCTAssertEqual("hello world\n", String(decoding: try await Data(contentsOf: self.file), as: UTF8.self))
        let firstID = try await Git.Hub.head.id(self.url)
        XCTAssertEqual(first, firstID)
    }

    func testThreeCommits() async throws {
        let secondfile = localPath("secondfile.txt")
        let thirdfile = localPath("thirdfile.txt")
        let repository = try await Git.Hub.create(url)
        try await repository.commit([self.file], message: "hello world")
        let first = try await Git.Hub.head.id(self.url)
        try Data("this is a second file\n".utf8).write(to: secondfile)
        try await repository.commit([secondfile], message: "lorem ipsum 2")
        try Data("this is a third file\n".utf8).write(to: thirdfile)
        try Data("a modified hello world\n".utf8).write(to: self.file)
        try await repository.commit([self.file, thirdfile], message: "lorem ipsum 3")
        try await repository.check(first)
        try await XXCTAssertEqual("hello world\n", String(decoding: try await Data(contentsOf: self.file), as: UTF8.self))
        XCTAssertFalse(FileManager.default.fileExists(atPath: secondfile.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: thirdfile.path))
    }
}

class TestGitClone: LocalGitTest {
    private var rest: MockRest!

    override func setUp() async throws {
        rest = MockRest()
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = rest
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testFail() async throws {
        rest._error = Git.Failure.Request.invalid
        await XCTAssertThrowsError(try await Git.Hub.clone(invalidURL, local: url))
    }

    func testFailIfNoReference() async throws {
        rest._fetch = Git.Fetch()
        await XCTAssertThrowsError(try await Git.Hub.clone(invalidURL, local: url))
    }

    func testFailOnDownload() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._error = Git.Failure.Request.invalid
        rest._fetch = fetch
        await XCTAssertThrowsError(try await Git.Hub.clone(invalidURL, local: url))
    }

    func testFailIfRepository() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        _ = try await Git.Hub.create(url)
        await XCTAssertThrowsError(try await Git.Hub.clone(invalidURL, local: self.url))
    }

    func testSuccess() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        try await Git.Hub.clone(sampleURL, local: localPath("monami"))
    }

    func testCreatesFolder() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        try await Git.Hub.clone(sampleURL, local: localPath("monami"))
        var d: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath("monami").path, isDirectory: &d))
        XCTAssertTrue(d.boolValue)
    }

    func testCreatesRepository() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        try await Git.Hub.clone(sampleURL, local: localPath("monami"))
        let success = try await Git.Hub.repository(localPath("monami"))
        XCTAssertTrue(success)
    }

    func testHead() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        try await Git.Hub.clone(sampleURL, local: localPath("monami"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath("monami").appendingPathComponent(".git/index").path))
        try await XXCTAssertEqual("54cac1e1086e2709a52d7d1727526b14efec3a77", try await Git.Hub.head.id(localPath("monami")))
        try await XXCTAssertEqual("Initial commit", try await Git.Hub.head.commit(localPath("monami")).message)
        try await XXCTAssertEqual("54f3a4bf0a60f29d7c4798b590f92ffd56dd6d21", try await Git.Hub.head.tree(localPath("monami")).items.first?.id)
        try await XXCTAssertEqual("master", try await Git.Hub.head.branch(localPath("monami")))
    }

    func testWantHave() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest.onPull = { remote, want, have in
            XCTAssertEqual("54cac1e1086e2709a52d7d1727526b14efec3a77", want)
            XCTAssertEqual("", have)
        }
        do {
            try await Git.Hub.clone(sampleURL, local: localPath("monami"))
            XCTFail("expected error")
        } catch {
            // expected
        }
    }

    func testUnpacks() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        try await Git.Hub.clone(sampleURL, local: localPath("monami"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath("monami").appendingPathComponent("README.md").path))
        try await XXCTAssertEqual("""
# test
Test

""", String(decoding: (try await Data(contentsOf: localPath("monami").appendingPathComponent("README.md"))), as: UTF8.self))
    }

    func testRemotes() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        try await Git.Hub.clone(sampleURL, local: localPath("monami"))
        try await XXCTAssertEqual("54cac1e1086e2709a52d7d1727526b14efec3a77", String(decoding: (try await Data(contentsOf: localPath("monami").appendingPathComponent(".git/refs/remotes/origin/master"))), as: UTF8.self))
    }

    func testConfig() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        try await Git.Hub.clone(sampleURL, local: localPath("monami"))
        try await XXCTAssertEqual("""
[remote "origin"]
    url = https://host.com/monami.git
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
    remote = origin
    merge = refs/heads/master

""", String(decoding: (try await Data(contentsOf: localPath("monami").appendingPathComponent(".git/config"))), as: UTF8.self))
    }
}

class TestGitCommit: LocalGitTest {
    private var file: URL!

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
    }

    func testCreate() async throws {
        var commit = Git.Commit()
        commit.author.name = "Jonathan Waldman"
        commit.author.email = "jonathan.waldman@live.com"
        commit.author.date = Date(timeIntervalSince1970: 1494296655)
        commit.author.timezone = "-0500"
        commit.committer = commit.author
        commit.message = "Add project files.\n"
        commit.tree = "0d21e2f7f760f77ead2cb85cc128efb13f56401d"
        commit.parent.append("dc0d3343fa24e912f08bc18aaa6f664a4a020079")
        XCTAssertEqual("""
tree 0d21e2f7f760f77ead2cb85cc128efb13f56401d
parent dc0d3343fa24e912f08bc18aaa6f664a4a020079
author Jonathan Waldman <jonathan.waldman@live.com> 1494296655 -0500
committer Jonathan Waldman <jonathan.waldman@live.com> 1494296655 -0500

Add project files.

""", commit.serial)
    }

    func testSave() async throws {
        var commit = Git.Commit()
        commit.author.name = "Jonathan Waldman"
        commit.author.email = "jonathan.waldman@live.com"
        commit.author.date = Date(timeIntervalSince1970: 1494296655)
        commit.author.timezone = "-0500"
        commit.committer = commit.author
        commit.message = "Add project files.\n"
        commit.tree = "0d21e2f7f760f77ead2cb85cc128efb13f56401d"
        commit.parent.append("dc0d3343fa24e912f08bc18aaa6f664a4a020079")
        _ = try await Git.Hub.create(url)
        let id = try await Git.Hub.content.add(commit, url: self.url)
        try? await Git.Hub.head.update(self.url, id: id)
        XCTAssertEqual("5192391e9f907eeb47aa38d1c6a3a4ea78e33564", id)
        let object = try await Data(contentsOf: localPath(
            ".git/objects/51/92391e9f907eeb47aa38d1c6a3a4ea78e33564"))
        XCTAssertNotNil(object)
        XCTAssertEqual(173, object.count)
        try await XXCTAssertEqual("5192391e9f907eeb47aa38d1c6a3a4ea78e33564", String(
            decoding: try await Data(contentsOf: localPath(".git/refs/heads/master")), as: UTF8.self))
    }

    func testSaveBranch() async throws {
        var commit = Git.Commit()
        commit.author.name = "Jonathan Waldman"
        commit.author.email = "jonathan.waldman@live.com"
        commit.author.date = Date(timeIntervalSince1970: 1494296655)
        commit.author.timezone = "-0500"
        commit.committer = commit.author
        commit.message = "Add project files.\n"
        commit.tree = "0d21e2f7f760f77ead2cb85cc128efb13f56401d"
        commit.parent.append("dc0d3343fa24e912f08bc18aaa6f664a4a020079")
        _ = try await Git.Hub.create(url)
        try "ref: refs/heads/feature/test".write(to: localPath(".git/HEAD"),
                                                  atomically: true, encoding: .utf8)
        let id = try await Git.Hub.content.add(commit, url: self.url)
        try? await Git.Hub.head.update(self.url, id: id)
        XCTAssertEqual("5192391e9f907eeb47aa38d1c6a3a4ea78e33564", id)
        let object = try await Data(contentsOf: localPath(
            ".git/objects/51/92391e9f907eeb47aa38d1c6a3a4ea78e33564"))
        XCTAssertNotNil(object)
        XCTAssertEqual(173, object.count)
        try await XXCTAssertEqual("5192391e9f907eeb47aa38d1c6a3a4ea78e33564", String(
            decoding: try await Data(contentsOf:
                                        localPath(".git/refs/heads/feature/test")), as: UTF8.self))
    }

    func testBackAndForth() async throws {
        var commit = Git.Commit()
        commit.author.name = "Jonathan Waldman"
        commit.author.email = "jonathan.waldman@live.com"
        commit.author.date = Date(timeIntervalSince1970: 1494296655)
        commit.author.timezone = "-0500"
        commit.committer = commit.author
        commit.message = "Add project files.\n"
        commit.tree = "0d21e2f7f760f77ead2cb85cc128efb13f56401d"
        commit.parent.append("dc0d3343fa24e912f08bc18aaa6f664a4a020079")
        _ = try await Git.Hub.create(url)
        _ = try await Git.Hub.content.add(commit, url: self.url)
        let loaded = try Git.Commit(await Data(contentsOf: localPath(
            ".git/objects/51/92391e9f907eeb47aa38d1c6a3a4ea78e33564")).decompressInflate())
        XCTAssertEqual(commit.author.name, loaded.author.name)
        XCTAssertEqual(commit.author.email, loaded.author.email)
        XCTAssertEqual(commit.author.date, loaded.author.date)
        XCTAssertEqual(commit.author.timezone, loaded.author.timezone)
        XCTAssertEqual(commit.committer.name, loaded.committer.name)
        XCTAssertEqual(commit.committer.email, loaded.committer.email)
        XCTAssertEqual(commit.committer.date, loaded.committer.date)
        XCTAssertEqual(commit.committer.timezone, loaded.committer.timezone)
        XCTAssertEqual(commit.message, loaded.message)
        XCTAssertEqual(commit.tree, loaded.tree)
        XCTAssertEqual(commit.parent, loaded.parent)
    }

    func testMessageMultiline() async throws {
        var commit = Git.Commit()
        commit.tree = "0d21e2f7f760f77ead2cb85cc128efb13f56401d"
        commit.message = "Add project files.\n\n\n\n\n\ntest\ntest\ntest\n\n\ntest"
        _ = try await Git.Hub.create(url)
        let id = try await Git.Hub.content.add(commit, url: self.url)
        let loaded = try Git.Commit(try await Data(contentsOf: localPath(
            ".git/objects/\(id.prefix(2))/\(id.dropFirst(2))")).decompressInflate())
        XCTAssertEqual(commit.message, loaded.message)
    }

    func testLongAuthor() async throws {
        var commit = Git.Commit()
        commit.tree = "0d21e2f7f760f77ead2cb85cc128efb13f56401d"
        commit.author.name = "asdasdas asd sa das das dsa dsa das das das as dsa da"
        _ = try await Git.Hub.create(url)
        let id = try await Git.Hub.content.add(commit, url: self.url)
        let loaded = try Git.Commit(try await Data(contentsOf: localPath(
            ".git/objects/\(id.prefix(2))/\(id.dropFirst(2))")).decompressInflate())
        XCTAssertEqual(commit.author.name, loaded.author.name)
    }

    func testEmptyList() async throws {
        let repository = await Git.Repository(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        await XCTAssertThrowsError(try await repository.commit([], message: "hello world"))
    }

    func testEmptyMessage() async throws {
        let repository = await Git.Repository(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        await XCTAssertThrowsError(try await repository.commit([], message: "hello world"))
    }

    func testNoCredentials() async throws {
        let repository = await Git.Repository(url)
        await XCTAssertThrowsError(try await repository.commit([file], message: "hello world"))
    }

    func testInvalidUrl() async throws {
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        await XCTAssertThrowsError(try await repository.commit([localPath("none.txt")], message: "hello world\n"))
        
    }

    func testFirstCommit() async throws {
        let date = Date(timeIntervalSinceNow: -1)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        try await repository.commit([self.file], message: "hello world\n")
        let commit = try? await Git.Hub.head.commit(self.url)
        XCTAssertNotNil(commit)
        let _ = try await Git.Hub.head.id(self.url)
        XCTAssertEqual("hello", commit?.author.name)
        XCTAssertEqual("world", commit?.author.email)
        if let commit = commit {
            XCTAssertLessThan(date, commit.author.date)
            XCTAssertLessThan(date, commit.committer.date)
        }
        XCTAssertEqual("84b5f2f96994db6b67f8a0ee508b1ebb8b633c15", commit?.tree)
        XCTAssertEqual("hello world\n", commit?.message)
        XCTAssertNil(commit?.parent.first)
    }

    func testNotAllowedCommitEmpty() async throws {
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([self.file], message: "hello world")
        await XCTAssertThrowsError(try await repository.commit([self.file], message: "second commit"))
        
    }

    func testSecondCommitUpdate() async throws {
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([self.file], message: "hello world")
        try Data("lorem ipsum\n".utf8).write(to: self.file)
        try await repository.commit([self.file], message: "second commit")
        let idx = await Git.Index(self.url)
        XCTAssertEqual(1, idx?.entries.count)
        
    }

    func testInvalidFile() async throws {
        let repository = await Git.Repository(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        await XCTAssertThrowsError(try await repository.commit([URL(fileURLWithPath: "/")], message: "A failed commmit"))
    }

    func testSecondCommit() async throws {
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([self.file], message: "hello world")
        let id = try await Git.Hub.head.id(self.url)
        try Data("modified\n".utf8).write(to: self.file)
        try await repository.commit([self.file], message: "second commit")
        try await XXCTAssertEqual(id, (try await Git.Hub.head.commit(self.url)).parent.first)

    }

    func testFirstCommitSubtree() async throws {
        let abc = localPath("abc")
        try FileManager.default.createDirectory(at: abc, withIntermediateDirectories: true)
        let another = abc.appendingPathComponent("another.txt")
        try Data("lorem ipsum\n".utf8).write(to: another)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([self.file, another], message: "hello world")
        let tree = try? await Git.Hub.head.tree(self.url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(
            ".git/objects/01/a59b011a48660bb3828ec72b2b08990b8cf56b").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(
            ".git/objects/3b/18e512dba79e4c8300dd08aeb37f8e728b8dad").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(
            ".git/objects/12/b34e53d16df3d9f2dd6ad8a4c45af37e283dc1").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(
            ".git/objects/48/1fe7479499b1b5623dfef963b5802d87af8c94").path))
        try await XXCTAssertEqual("481fe7479499b1b5623dfef963b5802d87af8c94", (try await Git.Hub.head.commit(self.url)).tree)
        XCTAssertNotNil(tree)
        XCTAssertEqual(2, tree?.items.count)
        XCTAssertNotNil(tree?.items.first(where: { $0.category == .tree }))
    }

    func testIgnoredFile() async throws {
        try """
not.js

""".write(to: localPath(".gitignore"), atomically: true, encoding: .utf8)
        let ignored = localPath("not.js")
        try Data().write(to: ignored)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        await XCTAssertThrowsError(try await repository.commit([ignored], message: "hello world"))
        
    }

    func testTreeIgnoredIfNotInCommit() async throws {
        let abc = localPath("abc")
        try FileManager.default.createDirectory(at: abc, withIntermediateDirectories: true)
        let another = abc.appendingPathComponent("another.txt")
        try Data("lorem ipsum\n".utf8).write(to: another)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([self.file], message: "hello world")
        let tree = try? await Git.Hub.head.tree(self.url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(
            ".git/objects/84/b5f2f96994db6b67f8a0ee508b1ebb8b633c15").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(
            ".git/objects/3b/18e512dba79e4c8300dd08aeb37f8e728b8dad").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(
            ".git/objects/12/b34e53d16df3d9f2dd6ad8a4c45af37e283dc1").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(
            ".git/objects/48/1fe7479499b1b5623dfef963b5802d87af8c94").path))
        try await XXCTAssertEqual("84b5f2f96994db6b67f8a0ee508b1ebb8b633c15", (try await Git.Hub.head.commit(self.url)).tree)
        XCTAssertNotNil(tree)
        XCTAssertEqual(1, tree?.items.count)
        XCTAssertNotNil(tree?.items.first(where: { $0.category != .tree }))
    }
}

class TestGitConfig: LocalGitTest {

    override func setUp() async throws {
        url = tmpfile()
        try FileManager.default.createDirectory(at: localPath(".git/"), withIntermediateDirectories: true)
    }

    func testInvalid() async throws {
        await XCTAssertThrowsError(try await Git.Config(url))
    }

    func testParse() async throws {
        try await fixture(name: "config0").write(to: localPath(".git/config"))
        let config = try await Git.Config(url)
        XCTAssertEqual(1, config.remote.count)
        XCTAssertEqual(1, config.branch.count)
        XCTAssertEqual("origin", config.remote.first?.0)
        XCTAssertEqual("https://github.com/vauxhall/merge.git", config.remote.first?.1.url)
        XCTAssertEqual("+refs/heads/*:refs/remotes/origin/*", config.remote.first?.1.fetch)
        XCTAssertEqual("master", config.branch.first?.0)
        XCTAssertEqual("origin", config.branch.first?.1.remote)
        XCTAssertEqual("refs/heads/master", config.branch.first?.1.merge)
        XCTAssertEqual("""
[remote "origin"]
    url = https://github.com/vauxhall/merge.git
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
    remote = origin
    merge = refs/heads/master

""", config.serial)
    }

    func testSave() async throws {
        try Git.Config("lorem ipsum").save(url)
        try await XXCTAssertEqual("""
[remote "origin"]
    url = https://lorem ipsum
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
    remote = origin
    merge = refs/heads/master

""", String(decoding: (try await Data(contentsOf: localPath(".git/config"))), as: UTF8.self))
    }
}

class TestGitContents: LocalGitTest {
    private var repository: Git.Repository!

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testInitial() async throws {
        let repository = try await Git.Hub.create(url)
        self.repository = repository
        await XXCTAssertEqual(true, await repository.state.needs)
    }

    func testAfterStatus() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let repository = try await Git.Hub.create(url)
        _ = try await repository.state.list
        await XXCTAssertEqual(false, await repository.state.needs)
    }

    func testAfterEdition() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let repository = try await Git.Hub.create(url)
        _ = try await repository.state.list
        try "hello\n".write(to: localPath("file.txt"), atomically: true, encoding: .utf8)
        await XXCTAssertEqual(true, await repository.state.needs)
    }

    func testAfterContentEdition() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let file = localPath("file.txt")
        try "hello\n".write(to: file, atomically: true, encoding: .utf8)
        let repository = try await Git.Hub.create(url)
        _ = try await repository.state.list
        try "world\n".write(to: file, atomically: true, encoding: .utf8)
        _ = try await repository.state.list
        try "lorem ipsum\n".write(to: file, atomically: true, encoding: .utf8)
        await XXCTAssertEqual(true, await repository.state.needs)
    }

    func testAfterSubtreeEdition() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let dir = localPath("adir")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("file.txt")
        try "hello\n".write(to: file, atomically: true, encoding: .utf8)
        let repository = try await Git.Hub.create(url)
        _ = try await repository.state.list
        try "world\n".write(to: file, atomically: true, encoding: .utf8)
        _ = try await repository.state.list
        try "lorem ipsum\n".write(to: file, atomically: true, encoding: .utf8)
        await XXCTAssertEqual(true, await repository.state.needs)
    }

    func testAfterSubSubtreeEdition() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let dir = localPath("adir/inside/another")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("file.txt")
        try "hello\n".write(to: file, atomically: true, encoding: .utf8)
        let repository = try await Git.Hub.create(url)
        _ = try await repository.state.list
        try "world\n".write(to: file, atomically: true, encoding: .utf8)
        _ = try await repository.state.list
        try "lorem ipsum\n".write(to: file, atomically: true, encoding: .utf8)
        await XXCTAssertEqual(true, await repository.state.needs)
    }
}

class TestGitDiff: LocalGitTest {
    private var repository: Git.Repository!

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testOneChange() async throws {
        let repository = try await Git.Hub.create(url)
        self.repository = repository
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await self.repository.commit([file], message: "My first commit\n")
        try Data("Lorem ipsum\n".utf8).write(to: file)
        let diff = try await self.repository.previous(file)
        XCTAssertNotNil(diff)
        XCTAssertEqual("hello world\n", String(decoding: diff!.1, as: UTF8.self))
        XCTAssertGreaterThanOrEqual(Date(), diff!.0)
    }

    func testInSubdirectory() async throws {
        let repository = try await Git.Hub.create(url)
        self.repository = repository
        let dir = localPath("dir")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)
        let file = dir.appendingPathComponent("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await self.repository.commit([file], message: "My first commit\n")
        try Data("Lorem ipsum\n".utf8).write(to: file)
        let diff = try await self.repository.previous(file)
        if let data = diff?.1 {
            XCTAssertEqual("hello world\n", String(decoding: data, as: UTF8.self))
        } else {
            XCTFail()
        }
    }

    func testNewFile() async throws {
        self.repository = try await Git.Hub.create(url)
        let file1 = localPath("myfile1.txt")
        let file2 = localPath("myfile2.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try await self.repository.commit([file1], message: "My first commit\n")
        try Data("Lorem ipsum\n".utf8).write(to: file2)
        let diffs = try await self.repository.previous(file2)
        XCTAssertNil(diffs)
    }

    func testNoChange() async throws {
        self.repository = try await Git.Hub.create(url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await self.repository.commit([file], message: "My first commit\n")
        try await XCTAssertThrowsError(await self.repository.previous(file))
    }

    func testTimeline() async throws {
        self.repository = try await Git.Hub.create(url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await self.repository.commit([file], message: "My first commit\n")
        try Data("Lorem ipsum\n".utf8).write(to: file)
        try await self.repository.commit([file], message: "My second commit\n")
        try Data("Lorem ipsum\nWith some updates".utf8).write(to: file)
        let timeline = try await self.repository.timeline(file)
        XCTAssertEqual(3, timeline.count)
        XCTAssertEqual("Lorem ipsum\nWith some updates", String(decoding: timeline[2].1, as: UTF8.self))
    }

    func testTimelineSubdirectory() async throws {
        self.repository = try await Git.Hub.create(url)
        let dir = localPath("dir")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)
        let file = dir.appendingPathComponent("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await self.repository.commit([file], message: "My first commit\n")
        try Data("Lorem ipsum\n".utf8).write(to: file)
        try await self.repository.commit([file], message: "My second commit\n")
        try Data("Lorem ipsum\nWith some updates".utf8).write(to: file)
        let timeline = try await self.repository.timeline(file)
        XCTAssertEqual(3, timeline.count)
        XCTAssertEqual("Lorem ipsum\nWith some updates", String(decoding: timeline[2].1, as: UTF8.self))
    }

    func testTimelineDeletedFile() async throws {
        self.repository = try await Git.Hub.create(url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await self.repository.commit([file], message: "My first commit\n")
        try FileManager.default.removeItem(at: file)
        let timeline = try await self.repository.timeline(file)
        XCTAssertEqual(2, timeline.count)
    }
}

class TestGitFetch: LocalGitTest {
    func testPull() async throws {
        let fetch = try Git.Fetch.Pull(await fixture(name: "fetchPull0"))
        XCTAssertNotNil(fetch)
        XCTAssertEqual(1, fetch.branch.count)
        XCTAssertEqual("54cac1e1086e2709a52d7d1727526b14efec3a77", fetch.branch.first)
    }

    func testPush() async throws {
        let fetch = try Git.Fetch.Push(await fixture(name: "fetchPush0"))
        XCTAssertNotNil(fetch)
        XCTAssertEqual(1, fetch.branch.count)
        XCTAssertEqual("21641afd04cd878a8e5d0275d25524499805569d", fetch.branch.first)
    }
}

class TestGitHash: LocalGitTest {
    private var file: URL!

    override func setUp() async throws {
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        file = localPath("file.json")
        try "hello world\n".write(to: file, atomically: true, encoding: .utf8)
    }

    func testFile() async throws {
        try await XXCTAssertEqual("3b18e512dba79e4c8300dd08aeb37f8e728b8dad", try await Git.Hash.file(file).1)
    }

    func testTree() async throws {
        XCTAssertEqual("4b825dc642cb6eb9a060e54bf8d69288fbee4904", Git.Hash.tree(Data()).1)
    }

    func testCommit() async throws {
        XCTAssertEqual("dcf5b16e76cce7425d0beaef62d79a7d10fce1f5", Git.Hash.commit("").1)
    }
}

class TestGitHead: LocalGitTest {

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testHEAD() async throws {
        _ = try await Git.Hub.create(url)
        try await XXCTAssertEqual("refs/heads/master", try await Git.Hub.head.reference(self.url))
    }

    func testHeadNone() async throws {
        _ = try await Git.Hub.create(url)
        let head = try? await Git.Hub.head.commit(self.url)
        XCTAssertNil(head)
    }

    func testTreeNone() async throws {
        _ = try await Git.Hub.create(url)
        let tree = try? await Git.Hub.head.tree(self.url)
        XCTAssertNil(tree)
    }

    func testLastCommit() async throws {
        let date = Date(timeIntervalSinceNow: -1)
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "ab"
        Git.Hub.session.email = "cd"
        try await repository.commit([file], message: "hello world\n")
        let commit = try await Git.Hub.head.commit(self.url)
        XCTAssertEqual("ab", commit.author.name)
        XCTAssertEqual("ab", commit.committer.name)
        XCTAssertEqual("cd", commit.author.email)
        XCTAssertEqual("cd", commit.committer.email)
        XCTAssertLessThan(date, commit.author.date)
        XCTAssertLessThan(date, commit.committer.date)
        XCTAssertEqual("hello world\n", commit.message)
        XCTAssertEqual("007a8ffce38213667b95957dc505ef30dac0248d", commit.tree)
    }

    func testTreeAfterCommit() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "ab"
        Git.Hub.session.email = "cd"
        try await repository.commit([file], message: "hello world")
        let tree = try? await Git.Hub.head.tree(self.url)
        XCTAssertEqual(1, tree?.items.count)
        XCTAssertEqual(.blob, tree?.items.first?.category)
        XCTAssertEqual(file, tree?.items.first?.url)
        XCTAssertEqual("95d09f2b10159347eece71399a7e2e907ea3df4f", tree?.items.first?.id)
    }
}

class TestGitHub: LocalGitTest {

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testRepositoryFails() async throws {
        let success = try await Git.Hub.repository(self.url)
        XCTAssertEqual(false, success)
    }

    func testRepository() async throws {
        _ = try await Git.Hub.create(url)
        let success = try await Git.Hub.repository(self.url)
        XCTAssertEqual(true, success)
    }

    func testCreate() async throws {
        let root = localPath(".git")
        let refs = root.appendingPathComponent("refs")
        let objects = root.appendingPathComponent("objects")
        let head = root.appendingPathComponent("HEAD")
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))

        _ = try await Git.Hub.create(self.url)

        var directory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.path, isDirectory: &directory))
        XCTAssertTrue(directory.boolValue)
        XCTAssertTrue(FileManager.default.fileExists(atPath: refs.path, isDirectory: &directory))
        XCTAssertTrue(directory.boolValue)
        XCTAssertTrue(FileManager.default.fileExists(atPath: objects.path, isDirectory: &directory))
        XCTAssertTrue(directory.boolValue)
        XCTAssertTrue(FileManager.default.fileExists(atPath: head.path, isDirectory: &directory))
        XCTAssertFalse(directory.boolValue)

        let data = try await Data(contentsOf: head)
        let content = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(content.contains("ref: refs/"))
    }

    func testDelete() async throws {
        let repository = try await Git.Hub.create(url)
        try await Git.Hub.delete(repository)
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(".git").path))
    }

    func testCreateFailsIfAlreadyExists() async throws {
        _ = try await Git.Hub.create(url)
        do {
            _ = try await Git.Hub.create(self.url)
        } catch {
            XCTAssertNotNil(error as? Git.Failure)
        }
    }

    func testOpenFails() async throws {
        do {
            let _ = try await Git.Hub.open(self.url)
            XCTFail("expected open to fail")
        } catch {

        }
    }

    func testOpen() async throws {
        _ = try await Git.Hub.create(url)
        let _ = try await Git.Hub.open(self.url)
    }

    func testObjects() async throws {
        _ = try await Git.Hub.create(url)
        try FileManager.default.createDirectory(at: localPath(".git/objects/ab"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: localPath(".git/objects/cd"), withIntermediateDirectories: true)
        try Data("h".utf8).write(to: localPath(".git/objects/ab/hello"))
        try Data("h".utf8).write(to: localPath(".git/objects/ab/world"))
        try Data("h".utf8).write(to: localPath(".git/objects/cd/lorem"))
        try Data("h".utf8).write(to: localPath(".git/objects/cd/ipsum"))
        let objects = Git.Hub.content.objects(self.url)
        XCTAssertEqual(4, objects.count)
        XCTAssertNotNil(objects.first(where: { $0 == "abhello" }))
        XCTAssertNotNil(objects.first(where: { $0 == "abworld" }))
        XCTAssertNotNil(objects.first(where: { $0 == "cdlorem" }))
        XCTAssertNotNil(objects.first(where: { $0 == "cdipsum" }))
    }
}

class TestGitIgnore: LocalGitTest {
    private var ignore: Git.Ignore!

    override func setUp() async throws {
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try """
.DS_Store
*.xcuserstate
.dSYM*
/something
Pods/
/More/
weird

""".write(to: localPath(".gitignore"), atomically: true, encoding: .utf8)
        ignore = await Git.Ignore(url)
    }

    func testAccept() async throws {
        XCTAssertFalse(ignore.url(url))
        XCTAssertFalse(ignore.url(localPath("afile.txt")))
    }

    func testGit() async throws {
        XCTAssertFalse(ignore.url(localPath("test.git")))
        XCTAssertFalse(ignore.url(localPath("git")))
        XCTAssertFalse(ignore.url(localPath(".gito")))
        XCTAssertFalse(ignore.url(localPath(".gitignore")))
        XCTAssertTrue(ignore.url(localPath(".git")))
        XCTAssertTrue(ignore.url(localPath(".git/HEAD")))
        XCTAssertTrue(ignore.url(localPath(".git/some/other/thing")))
    }

    func testExplicit() async throws {
        XCTAssertFalse(ignore.url(localPath(".DS_Storea")))
        XCTAssertFalse(ignore.url(localPath("DS_Store")))
        XCTAssertFalse(ignore.url(localPath("world.DS_Store")))
        XCTAssertTrue(ignore.url(localPath(".DS_Store")))
        XCTAssertTrue(ignore.url(localPath("hello/.DS_Store")))
        XCTAssertTrue(ignore.url(localPath("something")))
    }

    func testFolders() async throws {
        XCTAssertFalse(ignore.url(localPath("Any/other")))
        XCTAssertTrue(ignore.url(localPath("Any", isDirectory: true)))
        XCTAssertTrue(ignore.url(localPath("Other", isDirectory: true)))
        XCTAssertTrue(ignore.url(localPath("Any/Other", isDirectory: true)))
    }

    func testFolderContents() async throws {
        XCTAssertFalse(ignore.url(localPath("aPods/thing")))
        XCTAssertTrue(ignore.url(localPath("Pods/thing")))
        XCTAssertTrue(ignore.url(localPath("More/thing")))
        XCTAssertTrue(ignore.url(localPath("a/weird/thing")))
    }

    func testPrefixStar() async throws {
        XCTAssertFalse(ignore.url(localPath(".xcuserstatea")))
        XCTAssertTrue(ignore.url(localPath("hallo.xcuserstate")))
        XCTAssertTrue(ignore.url(localPath(".xcuserstate")))
        XCTAssertTrue(ignore.url(localPath(".xcuserstate/a")))
        XCTAssertTrue(ignore.url(localPath("hello/world/.xcuserstate")))
    }

    func testSuffixStar() async throws {
        XCTAssertFalse(ignore.url(localPath("a.dSYM")))
        XCTAssertTrue(ignore.url(localPath(".dSYM.zip")))
        XCTAssertTrue(ignore.url(localPath(".dSYM")))
        XCTAssertTrue(ignore.url(localPath(".dSYM/addas")))
        XCTAssertTrue(ignore.url(localPath(".dSYM/x/y/z")))
        XCTAssertTrue(ignore.url(localPath("asdsa/.dSYM")))
    }
}

class TestGitIndex: LocalGitTest {
    private var ignore: Git.Ignore!

    override func setUp() async throws {
        url = tmpfile()
        try FileManager.default.createDirectory(at: localPath(".git"), withIntermediateDirectories: true)
        ignore = await Git.Ignore(url)
    }

    func testIndexFails() async throws {
        try Data().write(to: localPath(".git/index"))
        let idx = await Git.Index(url)
        XCTAssertNil(idx)
    }

    func testIndexNoExists() async throws {
        let idx = await Git.Index(url)
        XCTAssertNil(idx)
    }

    func testIndex0() async throws {
        try await fixture(name: "index0").write(to: localPath(".git/index"))
        let index = await Git.Index(url)
        XCTAssertNotNil(index)
        XCTAssertEqual(2, index?.version)
        XCTAssertEqual(1, index?.entries.count)
        XCTAssertNotNil(index?.entries.first)
        XCTAssertEqual("483a3bef65960a1651d83168f2d1501397617472", index?.id)
        XCTAssertTrue(index?.entries.first?.conflicts == false)
        XCTAssertEqual("afile.json", index?.entries.first?.url.path.dropFirst(url.path.count + 1))
        XCTAssertEqual("3b18e512dba79e4c8300dd08aeb37f8e728b8dad", index?.entries.first?.id)
        XCTAssertEqual(12, index?.entries.first?.size)
        XCTAssertEqual(Date(timeIntervalSince1970: 1554190306), index?.entries.first?.created)
        XCTAssertEqual(Date(timeIntervalSince1970: 1554190306), index?.entries.first?.modified)
        XCTAssertEqual(16777220, index?.entries.first?.device)
        XCTAssertEqual(10051196, index?.entries.first?.inode)
        XCTAssertEqual(502, index?.entries.first?.user)
        XCTAssertEqual(20, index?.entries.first?.group)
    }

    func testIndex0BackAndForth() async throws {
        try await fixture(name: "index0").write(to: localPath(".git/index"))
        var index = await Git.Index(url)
        try FileManager.default.removeItem(at: localPath(".git/index"))
        try index?.save(url)
        index = await Git.Index(url)
        XCTAssertNotNil(index)
        XCTAssertEqual(2, index?.version)
        XCTAssertEqual(1, index?.entries.count)
        XCTAssertNotNil(index?.entries.first)
        XCTAssertTrue(index?.entries.first?.conflicts == false)
        XCTAssertEqual("afile.json", index?.entries.first?.url.path.dropFirst(url.path.count + 1))
        XCTAssertEqual("3b18e512dba79e4c8300dd08aeb37f8e728b8dad", index?.entries.first?.id)
        XCTAssertEqual(12, index?.entries.first?.size)
        XCTAssertEqual(Date(timeIntervalSince1970: 1554190306), index?.entries.first?.created)
        XCTAssertEqual(Date(timeIntervalSince1970: 1554190306), index?.entries.first?.modified)
        XCTAssertEqual(16777220, index?.entries.first?.device)
        XCTAssertEqual(10051196, index?.entries.first?.inode)
        XCTAssertEqual(502, index?.entries.first?.user)
        XCTAssertEqual(20, index?.entries.first?.group)
    }

    func testIndex1() async throws {
        try await fixture(name: "index1").write(to: localPath(".git/index"))
        let index = await Git.Index(url)
        XCTAssertNotNil(index)
        XCTAssertEqual(2, index?.version)
        XCTAssertEqual(22, index?.entries.count)
        XCTAssertEqual("be8343716dab3cb0a2f40813b3f0077bb0cb1a80", index?.id)
    }

    func testIndex1BackAndForth() async throws {
        try await fixture(name: "index1").write(to: localPath(".git/index"))
        var index = await Git.Index(url)
        try FileManager.default.removeItem(at: localPath(".git/index"))
        try index?.save(url)
        index = await Git.Index(url)
        XCTAssertNotNil(index)
        XCTAssertEqual(2, index?.version)
        XCTAssertEqual(22, index?.entries.count)
    }

    func testIndex2() async throws {
        try await fixture(name: "index2").write(to: localPath(".git/index"))
        let index = await Git.Index(url)
        XCTAssertNotNil(index)
        XCTAssertEqual(2, index?.version)
        XCTAssertEqual(22, index?.entries.count)
        XCTAssertEqual("5b7d07ddf4a539c8344a734364ddc4b17099c5d7", index?.id)
    }

    func testIndex2BackAndForth() async throws {
        try await fixture(name: "index2").write(to: localPath(".git/index"))
        var index = await Git.Index(url)
        try FileManager.default.removeItem(at: localPath(".git/index"))
        try index?.save(url)
        index = await Git.Index(url)
        XCTAssertNotNil(index)
        XCTAssertEqual(2, index?.version)
        XCTAssertEqual(22, index?.entries.count)
    }

    func testIndex3() async throws {
        try await fixture(name: "index3").write(to: localPath(".git/index"))
        let index = await Git.Index(url)
        XCTAssertNotNil(index)
        XCTAssertEqual(2, index?.version)
        XCTAssertEqual(22, index?.entries.count)
        XCTAssertEqual("22540a368e9c10d2ead5c097626cc2b2ea0cc0ac", index?.id)
    }

    func testIndex3BackAndForth() async throws {
        try await fixture(name: "index3").write(to: localPath(".git/index"))
        var index = await Git.Index(url)
        try FileManager.default.removeItem(at: localPath(".git/index"))
        try index?.save(url)
        index = await Git.Index(url)
        XCTAssertNotNil(index)
        XCTAssertEqual(2, index?.version)
        XCTAssertEqual(22, index?.entries.count)
    }

    func testIndex4() async throws {
        try await fixture(name: "index4").write(to: localPath(".git/index"))
        let index = await Git.Index(url)
        XCTAssertNotNil(index?.entries.first(where: { $0.id == "4545025894f8bd0408a845a9072198a887245b29" }))
        XCTAssertNotNil(index?.entries.first(where: { $0.url.path.contains("ARPresenter.swift") }))
        XCTAssertEqual(334, index?.entries.count)
    }

    func testAddEntry() async throws {
        let file = localPath("file.txt")
        try "hello world".write(to: file, atomically: true, encoding: .utf8)
        var index = Git.Index()
        try await index.entry("asd", url: file)
        XCTAssertEqual(1, index.entries.count)
        XCTAssertEqual(file, index.entries.first?.url)
        XCTAssertEqual("asd", index.entries.first?.id)
        XCTAssertEqual(11, index.entries.first?.size)
    }
}

class TestGitList: LocalGitTest {
    private var repository: Git.Repository!

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testEmpty() async throws {
        let repository = try await Git.Hub.create(url)
        try await XXCTAssertEqual(true, try await repository.state.list.isEmpty)
    }

    func testOneFile() async throws {
        let file = localPath("myfile.txt")
        try Data().write(to: file)
        let repository = try await Git.Hub.create(url)
        let status = try await repository.state.list
        XCTAssertEqual(1, status.count)
        XCTAssertEqual(file, status[0].0)
    }

    func testTwoFiles() async throws {
        let file1 = localPath("myfile1.txt")
        let file2 = localPath("myfile2.txt")
        try Data().write(to: file1)
        try Data().write(to: file2)
        let repository = try await Git.Hub.create(url)
        let status = try await repository.state.list
        XCTAssertEqual(2, status.count)
        XCTAssertEqual(file1, status[0].0)
        XCTAssertEqual(file2, status[1].0)
    }

    func testOneDirectory() async throws {
        let directory = localPath("folder")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let repository = try await Git.Hub.create(url)
        try await XXCTAssertEqual(true, try await repository.state.list.isEmpty)
    }

    func testOneFileInDirectory() async throws {
        let directory = localPath("folder")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("myfile.txt")
        try Data().write(to: file)
        let repository = try await Git.Hub.create(url)
        let status = try await repository.state.list
        XCTAssertEqual(1, status.count)
        XCTAssertEqual(file, status[0].0)
    }

    func testOneFileInSubDirectory() async throws {
        let directory = localPath("folder")
        let sub = directory.appendingPathComponent("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let file = sub.appendingPathComponent("myfile.txt")
        try Data().write(to: file)
        let repository = try await Git.Hub.create(url)
        let status = try await repository.state.list
        XCTAssertEqual(1, status.count)
        XCTAssertEqual(file, status[0].0)
    }

    func testOneFileAndFileInDirectory() async throws {
        let directory = localPath("folder")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file1 = directory.appendingPathComponent("myfile1.txt")
        let file2 = localPath("myfile2.txt")
        try Data().write(to: file1)
        try Data().write(to: file2)
        let repository = try await Git.Hub.create(url)
        let status = try await repository.state.list
        XCTAssertEqual(2, status.count)
        XCTAssertEqual(file1, status[0].0)
        XCTAssertEqual(file2, status[1].0)
    }

    func testSortFiles() async throws {
        let file1 = localPath("a")
        let file2 = localPath("B")
        let file3 = localPath("c")
        let file4 = localPath("D")
        let file5 = localPath("e1")
        let file6 = localPath("E2")
        let file7 = localPath("e3")
        let file8 = localPath("e4e")
        try Data().write(to: file1)
        try Data().write(to: file2)
        try Data().write(to: file3)
        try Data().write(to: file4)
        try Data().write(to: file5)
        try Data().write(to: file6)
        try Data().write(to: file7)
        try Data().write(to: file8)
        let repository = try await Git.Hub.create(url)
        let status = try await repository.state.list
        XCTAssertEqual(file1, status[0].0)
        XCTAssertEqual(file2, status[1].0)
        XCTAssertEqual(file3, status[2].0)
        XCTAssertEqual(file4, status[3].0)
        XCTAssertEqual(file5, status[4].0)
        XCTAssertEqual(file6, status[5].0)
        XCTAssertEqual(file7, status[6].0)
        XCTAssertEqual(file8, status[7].0)
    }

    func testSortedInDirectories() async throws {
        let directory1 = localPath("a")
        let directory2 = localPath("a/d")
        let directory3 = localPath("b")
        try FileManager.default.createDirectory(at: directory1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: directory2, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: directory3, withIntermediateDirectories: true)

        let file1 = directory1.appendingPathComponent("a")
        let file2 = directory1.appendingPathComponent("b")
        let file3 = directory1.appendingPathComponent("c")
        let file4 = directory2.appendingPathComponent("a")
        let file5 = directory2.appendingPathComponent("b")
        let file6 = directory2.appendingPathComponent("c")
        let file7 = directory3.appendingPathComponent("a")
        let file8 = directory3.appendingPathComponent("b")
        let file9 = directory3.appendingPathComponent("c")
        try Data().write(to: file1)
        try Data().write(to: file2)
        try Data().write(to: file3)
        try Data().write(to: file4)
        try Data().write(to: file5)
        try Data().write(to: file6)
        try Data().write(to: file7)
        try Data().write(to: file8)
        try Data().write(to: file9)
        let repository = try await Git.Hub.create(url)
        let status = try await repository.state.list
        XCTAssertEqual(file1, status[0].0)
        XCTAssertEqual(file2, status[1].0)
        XCTAssertEqual(file3, status[2].0)
        XCTAssertEqual(file4, status[3].0)
        XCTAssertEqual(file5, status[4].0)
        XCTAssertEqual(file6, status[5].0)
        XCTAssertEqual(file7, status[6].0)
        XCTAssertEqual(file8, status[7].0)
        XCTAssertEqual(file9, status[8].0)
    }
}

class TestGitLog: LocalGitTest {
    private var file: URL!
    private var repository: Git.Repository!

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "my@email.com"
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
    }

    func testOneCommit() async throws {
        self.repository = try await Git.Hub.create(url)
        try await self.repository.commit([self.file], message: "Lorem ipsum\n")
        let commits = try await self.repository.log()
        XCTAssertEqual(1, commits.count)
        XCTAssertEqual("hello", commits.first?.author.name)
        XCTAssertEqual("hello", commits.first?.committer.name)
        XCTAssertEqual("my@email.com", commits.first?.author.email)
        XCTAssertEqual("my@email.com", commits.first?.committer.email)
        XCTAssertEqual("Lorem ipsum\n", commits.first?.message)
        XCTAssertEqual("84b5f2f96994db6b67f8a0ee508b1ebb8b633c15", commits.first?.tree)
        XCTAssertNil(commits.first?.parent.first)
    }

    func testTwoCommits() async throws {
        self.repository = try await Git.Hub.create(url)
        try await self.repository.commit([self.file], message: "Lorem ipsum\n")
        try Data("lorem ipsum\n".utf8).write(to: self.file)
        try await self.repository.commit([self.file], message: "The rebels, the misfits\n")
        let commits = try await self.repository.log()
        XCTAssertEqual(2, commits.count)
        XCTAssertEqual("The rebels, the misfits\n", commits.first?.message)
        XCTAssertEqual("a9b8f695fe7d66da97114df1c3a14df9070d2eae", commits.first?.tree)
        XCTAssertNotNil(commits.first?.parent)
        XCTAssertEqual("Lorem ipsum\n", commits.last?.message)
        XCTAssertEqual("84b5f2f96994db6b67f8a0ee508b1ebb8b633c15", commits.last?.tree)
        XCTAssertNil(commits.last?.parent.first)
    }
}

class TestGitMerge: LocalGitTest {
    private var rest: MockRest!

    override func setUp() async throws {
        rest = MockRest()
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        Git.Hub.factory.rest = rest
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
    }

    func testMerging() async throws {
        let repository = try await Git.Hub.create(url)
        let file1 = localPath("file1.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try await repository.commit([file1], message: "First commit.\n")
        let first = try await Git.Hub.head.id(self.url)
        let file2 = localPath("file2.txt")
        try Data("lorem ipsum\n".utf8).write(to: file2)
        try await repository.commit([file2], message: "Second commit.\n")
        let second = try await Git.Hub.head.id(self.url)
        try await repository.stage.merge(first)
        let merged = try await Git.Hub.head.commit(self.url)
        XCTAssertEqual(second, merged.parent.first)
        XCTAssertEqual(first, merged.parent.last)
        XCTAssertEqual("Merge.\n", merged.message)
        try await XXCTAssertEqual(3, try await Git.History(self.url).result.count)
    }

    func testSynch() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "335a33ae387dc24f057852fdb92e5abc71bf6b85"))
        rest._fetch = fetch
        rest._pull = try? Git.Pack(await fixture(name: "fetch2"))
        let repository = try await Git.Hub.create(url)
        try Git.Config("lorem ipsum").save(self.url)
        try await repository.pull()
        let file = localPath("control.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await repository.commit([file], message: "First commit")
        try await repository.pull()
        try await repository.push()
        try await XXCTAssertEqual(await Git.Hub.head.origin(self.url)!, try await Git.Hub.head.id(self.url))
    }
}

class TestGitPack: LocalGitTest {

    override func setUp() async throws {
        url = tmpfile()
        try FileManager.default.createDirectory(at: localPath(".git/objects/pack"), withIntermediateDirectories: true)
    }

    func testPackNotFound() async throws {
        await XCTAssertThrowsError(try await Git.Pack(url, id: "hello"))
    }

    func testLoadAllPacks() async throws {
        try await copy("0")
        try await copy("1")
        try await copy("2")
        let packed = try await Git.Pack.pack(url)
        XCTAssertEqual(3, packed.count)
    }

    func testUnpackWithPack() async throws {
        try await copy("1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.pack").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.idx").path))
        let pack = try await Git.Pack(url, id: "1")
        try await pack.unpack(url)

        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/33/5a33ae387dc24f057852fdb92e5abc71bf6b85").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/de/bc85c20f099d7d379d0bbcf3f49643057130ba").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/d4/ad833626ea79708a91e61c461b1c4ed8c5a9a7").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/d2/7de8c22fb0cfdc7d12f8eaf30bcc5343e7f70a").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/8d/c0abf0a0b0d70a0a8680daa69a7df74acfce95").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/7e/6a00e39a6bf673236a1a9dfe10fb84c8cde5e4").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/3e/df2d51b40d48afd71e415bb3df7429d0043909").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/fd/3a92df1d71c4cc25f1d0781977031d3908722d").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/53/93c4bf55b2adf4db6ff8c59b6172b015df2f75").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/50/d65cf62b3d1d7a06d4766693d293ada11f3e8a").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/ce/013625030ba8dba906f756967f9e9ca394464a").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/d3/42d27d93c4e0baac81f2d10f40c10b37ec553b").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/91/77be007bb25b1f12ecc3fd14eb191cd07d69f4").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/6e/d198640569dee5fc505808548729ef230d6a33").path))
    }

    func testUnpackSize() async throws {
        try await copy("1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.pack").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.idx").path))
        let pack = try await Git.Pack(url, id: "1")
        try await pack.unpack(url)

        try await XXCTAssertEqual(33, (try await Data(contentsOf: localPath(".git/objects/7e/6a00e39a6bf673236a1a9dfe10fb84c8cde5e4")).count))
        try await XXCTAssertEqual(222, (try await Data(contentsOf: localPath(".git/objects/33/5a33ae387dc24f057852fdb92e5abc71bf6b85")).count))
        try await XXCTAssertEqual(122, (try await Data(contentsOf: localPath(".git/objects/53/93c4bf55b2adf4db6ff8c59b6172b015df2f75")).count))
    }

    func testRemove() async throws {
        try await copy("1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.pack").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.idx").path))
        let pack = try await Git.Pack(url, id: "1")
        try pack.remove(url, id: "1")
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.pack").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.idx").path))
    }

    func testLoadPack0() async throws {
        try await copy("0")
        let pack = try await Git.Pack(url, id: "0")
        XCTAssertEqual(3, pack.commits.count)
        XCTAssertEqual(10, pack.trees.count)
        XCTAssertEqual(4, pack.blobs.count)
        pack.trees.forEach {
            XCTAssertEqual($0.key, Git.Hash.tree($0.value.0.serial).1)
        }
    }

    func testLoadPack1() async throws {
        try await copy("1")
        let pack = try await Git.Pack(url, id: "1")
        XCTAssertEqual(5, pack.commits.count)
        XCTAssertEqual(5, pack.trees.count)
        XCTAssertEqual(4, pack.blobs.count)
    }

    func testLoadPack2() async throws {
        try await copy("2")
        let pack = try await Git.Pack(url, id: "2")
        XCTAssertEqual(19, pack.commits.count)
        XCTAssertEqual(70, pack.trees.count)
        XCTAssertEqual(66, pack.blobs.count)
        XCTAssertNotNil(pack.trees.first(where: { $0.0 == "d14d41ee118d52df4b9811b2eacc943f06cd942a" }))
        XCTAssertNotNil(pack.commits.first(where: { $0.0 == "0807a029cb42acd13ad194248436f093b8e63a4f" }))
        XCTAssertNotNil(pack.blobs.first(where: { $0.0 == "0ec0ff154d5c479f0af27d7a5064bb570c62500d" }))
        if let data = pack.trees.first(where: { $0.0 == "d14d41ee118d52df4b9811b2eacc943f06cd942a" })?.1.0.serial {
            XCTAssertEqual("d14d41ee118d52df4b9811b2eacc943f06cd942a", Git.Hash.tree(data).1)
        }
    }

    func testHashTreePack1() async throws {
        try await copy("1")
        let pack = try await Git.Pack(url, id: "1")
        let tree = pack.trees.first(where: { $0.key == "50d65cf62b3d1d7a06d4766693d293ada11f3e8a" })!.value.0
        XCTAssertEqual("50d65cf62b3d1d7a06d4766693d293ada11f3e8a", Git.Hash.tree(tree.serial).1)
    }

    func testLoadFetch0() async throws {
        let pack = try Git.Pack(await fixture(name: "fetch0"))
        XCTAssertEqual(1, pack.commits.count)
        XCTAssertEqual(1, pack.trees.count)
        XCTAssertEqual(1, pack.blobs.count)
        XCTAssertEqual("""
tree 9b8166fc80d0f0fe9192d4bf1dbaa87f194e012f\nauthor vauxhall <zero.griffin@gmail.com> 1557649511 +0200\ncommitter GitHub <noreply@github.com> 1557649511 +0200\ngpgsig -----BEGIN PGP SIGNATURE-----\n \n wsBcBAABCAAQBQJc19hnCRBK7hj4Ov3rIwAAdHIIAAPh6Gw1sQOwGSQsX94V8slE\n /5LdUSOjyqb6kkSKFYNJO7HKiBhS5DnLCtytbbbhMCI+VkvD91fwwu75cTzidl/7\n ky4aH+l4O7/rYol3sMXlslrz3uxbMNano8oCXPCmkRd6SDITNPtcLVn1m/1msgo6\n w9/3GrILm7jJBoqsq1Yw9HgPqbk7rEvUmexf7Fn9lb/YYhuisp86XCtDGfqMMRow\n GeXUxGUGlAluDFDDwneTb0PPowHhQioTKOqooaM9ocEDENtzv4EZY4o4lccTegHm\n a69zNgV4ALzMxVpwN03216fS9kw7gRriy9hNGMJIGnVGKIgQD/4B9hZ8Xv9bM84=\n =HKXb\n -----END PGP SIGNATURE-----\n \n\nInitial commit
""", pack.commits.first?.value.0.serial)
        try await XXCTAssertEqual("9b8166fc80d0f0fe9192d4bf1dbaa87f194e012f", try await pack.trees.first?.1.0.save(url))
        XCTAssertEqual("README.md", pack.trees.first?.1.0.items.first?.url.lastPathComponent)
        XCTAssertEqual("""
# test
Test

""", String(decoding: pack.blobs.first!.value.1, as: UTF8.self))
    }

    func testLoadFetch1() async throws {
        let pack = try Git.Pack(await fixture(name: "fetch1"))
        XCTAssertEqual(23, pack.commits.count)
        XCTAssertEqual(43, pack.trees.count)
        XCTAssertEqual(23, pack.blobs.count)
    }

    func testPack0Hash() async throws {
        let data = try await fixture(name: "pack-0.pack")
        XCTAssertEqual(data.suffix(20), Git.Hash.digest(data.subdata(in: 0 ..< data.count - 20)))
    }

    func testPack1Hash() async throws {
        let data = try await fixture(name: "pack-1.pack")
        XCTAssertEqual(data.suffix(20), Git.Hash.digest(data.subdata(in: 0 ..< data.count - 20)))
    }

    func testPack2Hash() async throws {
        let data = try await fixture(name: "pack-2.pack")
        XCTAssertEqual(data.suffix(20), Git.Hash.digest(data.subdata(in: 0 ..< data.count - 20)))
    }

    private func copy(_ id: String) async throws {
        try await fixture(name: "pack-\(id)", ext: "idx").write(to: localPath(".git/objects/pack/pack-\(id).idx"))
        try await fixture(name: "pack-\(id)", ext: "pack").write(to: localPath(".git/objects/pack/pack-\(id).pack"))
    }
}

class TestGitPress: LocalGitTest {
    private var repository: Git.Repository!

    override func setUp() async throws {
        url = tmpfile()
        try FileManager.default.createDirectory(at: localPath(".git/objects/ab"), withIntermediateDirectories: true)
        repository = await Git.Repository(url)
    }

    func testCompressed0() async throws {
        try await XXCTAssertEqual("""
        hello world
        """, await String(decoding: fixture(name: "compressed0").decompressInflate(), as: UTF8.self))
    }

    func testBlob0() async throws {
        try await XXCTAssertEqual("""
        blob 12\u{0000}hello rorld

        """, await String(decoding: fixture(name: "blob0").decompressInflate(), as: UTF8.self))
    }

    func testTree0() async throws {
        try await XXCTAssertEqual(839, await fixture(name: "tree0").decompressInflate().count)
    }

    func testTree1() async throws {
        try await fixture(name: "tree1").write(to: localPath(".git/objects/ab/helloworld"))
        let tree = try await Git.Tree("abhelloworld", url: url)
        XCTAssertEqual(1, tree.items.count)
        XCTAssertEqual(.blob, tree.items.first?.category)
        XCTAssertEqual("hello.json", tree.items.first?.url.lastPathComponent)
        XCTAssertEqual("e0f1ee1826f922f041e557a16173f2a93835825e", tree.items.first?.id)
    }

    func testTree2() async throws {
        try await fixture(name: "tree2").write(to: localPath(".git/objects/ab/helloworld"))
        let tree = try await Git.Tree("abhelloworld", url: url)
        XCTAssertEqual(2, tree.items.count)
        XCTAssertEqual(.blob, tree.items.first?.category)
        XCTAssertEqual(.tree, tree.items.last?.category)
        XCTAssertEqual("hello.json", tree.items.first?.url.lastPathComponent)
        XCTAssertEqual("e0f1ee1826f922f041e557a16173f2a93835825e", tree.items.first?.id)
        XCTAssertEqual("mydir", tree.items.last?.url.lastPathComponent)
        XCTAssertEqual("213190a0fbccf0c01ebf2776edb8011fd935dbba", tree.items.last?.id)
    }

    func testTree3() async throws {
        try await fixture(name: "tree3").write(to: localPath(".git/objects/ab/helloworld"))
        let tree = try await Git.Tree("abhelloworld", url: url)
        XCTAssertEqual(11, tree.items.count)
        XCTAssertEqual(11, tree.items.filter({ $0.category != .tree }).count)
    }

    func testTree4() async throws {
        try await fixture(name: "tree4").write(to: localPath(".git/objects/ab/helloworld"))
        let tree = try await Git.Tree("abhelloworld", url: url)
        XCTAssertNotNil(tree.items.first(where: { $0.id == "71637250a143a4c2eed7103f08b3610cd4f1f1f9" }))
    }

    func testCommit0() async throws {
        try await XXCTAssertEqual("""
        commit 191\u{0000}tree 99ff9f93b7f0f7d300dc3c42d16cdfcdf5c2a82f
        author vauxhall <zero.griffin@gmail.com> 1554638195 +0200
        committer vauxhall <zero.griffin@gmail.com> 1554638195 +0200

        This is my first commit.

        """, String(decoding: await fixture(name: "commit0").decompressInflate(), as: UTF8.self))
    }

    func testCommit1() async throws {
        try await XXCTAssertEqual("""
        commit 232\u{0000}tree 250202b9788cc1edd675dabec0081004179475f8
        parent 0cbd117f7fe2ec884168863af047e8c89e71aaf1
        author vauxhall <zero.griffin@gmail.com> 1554641683 +0200
        committer vauxhall <zero.griffin@gmail.com> 1554641683 +0200

        My second commit.

        """, String(decoding: await fixture(name: "commit1").decompressInflate(), as: UTF8.self))
    }

    func testParseCommit0() async throws {
        let commit = try await Git.Commit(fixture(name: "commit0").decompressInflate())
        XCTAssertNil(commit.parent.first)
        XCTAssertEqual("99ff9f93b7f0f7d300dc3c42d16cdfcdf5c2a82f", commit.tree)
        XCTAssertEqual("vauxhall", commit.author.name)
        XCTAssertEqual("zero.griffin@gmail.com", commit.author.email)
        XCTAssertEqual("vauxhall", commit.committer.name)
        XCTAssertEqual("zero.griffin@gmail.com", commit.committer.email)
        XCTAssertEqual(Date(timeIntervalSince1970: 1554638195), commit.author.date)
        XCTAssertEqual(Date(timeIntervalSince1970: 1554638195), commit.committer.date)
        XCTAssertEqual("This is my first commit.\n", commit.message)
        XCTAssertEqual("", commit.gpg)
    }

    func testParseCommit1() async throws {
        let commit = try await Git.Commit(fixture(name: "commit1").decompressInflate())
        XCTAssertEqual("0cbd117f7fe2ec884168863af047e8c89e71aaf1", commit.parent.first)
        XCTAssertEqual("", commit.gpg)
    }

    func testParseCommit2() async throws {
        let commit = try await Git.Commit(fixture(name: "commit2").decompressInflate())
        XCTAssertEqual("890be9af6d5a18a1eb999f0ad44c15a83f227af4", commit.parent.first)
        XCTAssertEqual("d27de8c22fb0cfdc7d12f8eaf30bcc5343e7f70a", commit.parent.last)
        XCTAssertEqual("a50257e1731e34b6be3db840155ff86c3b5a26e2", commit.tree)
        XCTAssertEqual("vauxhall", commit.author.name)
        XCTAssertEqual("zero.griffin@gmail.com", commit.author.email)
        XCTAssertEqual("+0200", commit.author.timezone)
        XCTAssertEqual("vauxhall", commit.committer.name)
        XCTAssertEqual("zero.griffin@gmail.com", commit.committer.email)
        XCTAssertEqual("+0200", commit.committer.timezone)
        XCTAssertEqual(Date(timeIntervalSince1970: 1557728927), commit.author.date)
        XCTAssertEqual(Date(timeIntervalSince1970: 1557728927), commit.committer.date)
        XCTAssertEqual("Merge branch \'master\' of https://github.com/vauxhall/merge\n", commit.message)
        XCTAssertEqual("", commit.gpg)
    }

    func testParseCommit2BackAndForth() async throws {
        let commit = try await Git.Commit(fixture(name: "commit2").decompressInflate())
        XCTAssertEqual("79be52211d61ef2e59134ae6e8aaa0fe121de71f", Git.Hash.commit(commit.serial).1)
    }

    func testParseCommit3() async throws {
        let commit = try await Git.Commit(fixture(name: "commit3").decompressInflate())
        XCTAssertEqual("8dc0abf0a0b0d70a0a8680daa69a7df74acfce95", commit.parent.first)
        XCTAssertEqual("9177be007bb25b1f12ecc3fd14eb191cd07d69f4", commit.tree)
        XCTAssertEqual("vauxhall", commit.author.name)
        XCTAssertEqual("zero.griffin@gmail.com", commit.author.email)
        XCTAssertEqual("GitHub", commit.committer.name)
        XCTAssertEqual("noreply@github.com", commit.committer.email)
        XCTAssertEqual(Date(timeIntervalSince1970: 1557728914), commit.author.date)
        XCTAssertEqual(Date(timeIntervalSince1970: 1557728914), commit.committer.date)
        XCTAssertEqual("Create another.txt", commit.message)
        XCTAssertEqual("""
\ngpgsig -----BEGIN PGP SIGNATURE-----\n \n wsBcBAABCAAQBQJc2Q6SCRBK7hj4Ov3rIwAAdHIIAG87iBwa22KVe14mZRay8eNm\n zIBtaLODH51ETcpmjFouPM59Zp1jrVtyuqa3RCj2Ijsrj0VVNfIET9XTd/LfHnvM\n oel2lT69YtWUvu6Dnm7NhyaMvgqhfTytF4W3uXd5FB1aTwyv2cUNq5y+fNzqjYlY\n kxDiyVX2Efg54yyDsO1GbWR20ij3m9lR7GrysX2oS135WatX62w0zmQHoslrbjPT\n zAJaherlmbXG07A6yoRajdp/o+Tujf/irjMVWBwuYy3WI96U+Mj5CuFHgQvVq3om\n sb+wQXR0sq9g1x5v/rC780IsuNzj8hl3eVj6PQMzlTdqUBYwJxCzMMQXPeYQ5z8=\n =GDUq\n -----END PGP SIGNATURE-----\n \

""", commit.gpg)
    }

    func testParseCommit3BackAndForth() async throws {
        let commit = try await Git.Commit(fixture(name: "commit3").decompressInflate())
        XCTAssertEqual("d27de8c22fb0cfdc7d12f8eaf30bcc5343e7f70a", Git.Hash.commit(commit.serial).1)
    }
}

class TestGitPull: LocalGitTest {
    private var rest: MockRest!

    override func setUp() async throws {
        rest = MockRest()
        Git.Hub.session = Git.Session()
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        Git.Hub.factory.rest = rest
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testSuccessUpToDate() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        try Git.Config("lorem ipsum").save(self.url)
        try await repository.commit([file], message: "hello world\n")
        try await Git.Hub.head.origin(self.url, id: try Git.Hub.head.id(self.url))
        let fetch = Git.Fetch()
        await fetch.refs.append(.init(branch: (try? Git.Hub.head.id(self.url)) ?? ""))
        self.rest._fetch = fetch
        try await repository.pull()
    }

    func testCallFetch() async throws {
        var callbacks = 0
        rest.onDownload = { url in
            // XCTAssertEqual(wip("host.com/monami.git"), url) // TODO: restore
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try Git.Config("host.com/monami.git").save(self.url)
        await XCTAssertThrowsError(try await repository.pull())
        
        XCTAssertEqual(1, callbacks)
    }

    func testCallPull() async throws {
        var callbacks = 0
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "hello world"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        rest.onPull = { remote, want, have in
            // XCTAssertEqual("https://host.com/monami.git", remote) // TODO: remote URL should be the saved host name
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try Git.Config("host.com/monami.git").save(self.url)
        await XCTAssertThrowsError(try await repository.pull())
        
        XCTAssertEqual(1, callbacks)
    }

    func testWant() async throws {
        var callbacks = 0
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "hello world"))
        rest._fetch = fetch
        rest.onPull = { remote, want, have in
            XCTAssertEqual("hello world", want)
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try Git.Config("lorem ipsum").save(self.url)
        await XCTAssertThrowsError(try await repository.pull())

        XCTAssertEqual(1, callbacks)
    }

    /* FIXME Linux
     XCTAssertEqual failed: ("0032have 11world
     0032have 11hello
     0032have 99lorem
     ") is not equal to ("0032have 99lorem
     0032have 11hello
     0032have 11world
     ") -
     */
    func testHave() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        var callbacks = 0
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "hello world"))
        rest._fetch = fetch

        rest.onPull = { remote, want, have in
            XCTAssertEqual("0032have 11world\n0032have 11hello\n0032have 99lorem\n", have)
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try FileManager.default.createDirectory(at: localPath(".git/objects/99"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: localPath(".git/objects/11"), withIntermediateDirectories: true)
        try Data("h".utf8).write(to: localPath(".git/objects/11/hello"))
        try Data("h".utf8).write(to: localPath(".git/objects/11/world"))
        try Data("h".utf8).write(to: localPath(".git/objects/99/lorem"))
        try Git.Config("lorem ipsum").save(self.url)
        let _ = try? await repository.pull() // fail expected, but callback should be invoked
        
        XCTAssertEqual(1, callbacks)
    }

    func testCheckout() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        let repository = try await Git.Hub.create(url)
        try Git.Config("lorem ipsum").save(self.url)
        try await repository.pull()
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/index").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath("README.md").path))
        try await XXCTAssertEqual("54cac1e1086e2709a52d7d1727526b14efec3a77", try await Git.Hub.head.id(self.url))
        try await XXCTAssertEqual("Initial commit", try await Git.Hub.head.commit(self.url).message)
        try await XXCTAssertEqual("54f3a4bf0a60f29d7c4798b590f92ffd56dd6d21", try await Git.Hub.head.tree(self.url).items.first?.id)
        try await XXCTAssertEqual("54cac1e1086e2709a52d7d1727526b14efec3a77", String(decoding: (try await Data(contentsOf: localPath(".git/refs/remotes/origin/master"))), as: UTF8.self))
        try await XXCTAssertEqual("""
# test
Test

""", String(decoding: (try await Data(contentsOf: localPath("README.md"))), as: UTF8.self))
    }

    func testUpdateConfig() async throws {
        let repository = try await Git.Hub.create(url)
        try await repository.remote("host.com/monami.git")
        try await XXCTAssertEqual("""
[remote "origin"]
    url = https://host.com/monami.git
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
    remote = origin
    merge = refs/heads/master

""", String(decoding: (try await Data(contentsOf: localPath(".git/config"))), as: UTF8.self))
    }

    func testMergeFailNoCommonAncestor() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "54cac1e1086e2709a52d7d1727526b14efec3a77"))
        rest._fetch = fetch
        rest._pull = try Git.Pack(await fixture(name: "fetch0"))
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        try Git.Config("lorem ipsum").save(self.url)
        try await repository.commit([file], message: "This is a commit that should not be in the history.\n")
        await XCTAssertThrowsError(try await repository.pull())
    }

    func testMerge() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "335a33ae387dc24f057852fdb92e5abc71bf6b85"))
        rest._fetch = fetch
        rest._pull = try? Git.Pack(await fixture(name: "fetch2"))
        let repository = try await Git.Hub.create(url)
        try Git.Config("lorem ipsum").save(self.url)
        try await repository.pull()
        XCTAssertEqual(4, try FileManager.default.contentsOfDirectory(atPath: self.url.path).count)
        self.rest._fetch!.refs = [.init(branch: "4ec6903ca199e0e92c6cd3abb5b95f3b7f3d7e4d")]
        self.rest._pull = try Git.Pack(await fixture(name: "fetch3"))
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await repository.commit([file], message: "Add file not tracked in the list.")
        let external = try await Git.Hub.head.id(self.url)
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: self.url.path).contains("myfile.txt"))
        try await repository.pull()
        let commit = try await Git.Hub.head.commit(self.url)
        let contents = try FileManager.default.contentsOfDirectory(atPath: self.url.path)
        XCTAssertTrue(contents.contains("myfile.txt"))
        XCTAssertTrue(contents.contains("asd.txt"))
        XCTAssertEqual(7, contents.count)
        XCTAssertEqual(2, commit.parent.count)
        XCTAssertEqual("4ec6903ca199e0e92c6cd3abb5b95f3b7f3d7e4d", commit.parent.last)
        XCTAssertEqual(external, commit.parent.first)
        try await XXCTAssertEqual(true, try await repository.state.list.isEmpty)
        try await XXCTAssertEqual("4ec6903ca199e0e92c6cd3abb5b95f3b7f3d7e4d", String(decoding: (try await Data(contentsOf: localPath(".git/refs/remotes/origin/master"))), as: UTF8.self))
    }

    func testFailsIfChanges() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "hello world"))
        rest._fetch = fetch
        let repository = try await Git.Hub.create(url)
        try Git.Config("host.com/monami.git").save(self.url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        await XCTAssertThrowsError(try await repository.pull())
    }
}

class TestGitPush: LocalGitTest {
    private var rest: MockRest!

    override func setUp() async throws {
        rest = MockRest()
        Git.Hub.session = Git.Session()
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        Git.Hub.factory.rest = rest
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testSuccessUpToDate() async throws {
        let file = localPath("file.txt")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        try Git.Config("lorem ipsum").save(self.url)
        try await repository.commit([file], message: "hello world\n")
        try? await Git.Hub.head.origin(self.url, id: try Git.Hub.head.id(self.url))
        let fetch = Git.Fetch()
        await fetch.refs.append(.init(branch: (try? Git.Hub.head.id(self.url)) ?? ""))
        self.rest._fetch = fetch
        do {
            try await repository.push()
        }
    }

    func testCallFetch() async throws {
        var callbacks = 0
        rest.onUpload = { url in
            // XCTAssertEqual("host.com/monami.git", url)
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try Git.Config("host.com/monami.git").save(self.url)
        await XCTAssertThrowsError(try await repository.push())

        XCTAssertEqual(1, callbacks)
    }

    func testCallPush() async throws {
        var callbacks = 0
        let file = localPath("file.txt")
        try Data("hello world\n".utf8).write(to: file)
        rest.onPush = { remote, old, new, pack in
            //XCTAssertEqual("host.com/monami.git", remote)
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try Git.Config("host.com/monami.git").save(self.url)
        try await repository.commit([file], message: "My first commit\n")
        let fetch = Git.Fetch()
        await fetch.refs.append(.init(branch: try Git.Hub.head.id(self.url)))
        self.rest._fetch = fetch
        try Data("hello world updated\n".utf8).write(to: file)
        try await repository.commit([file], message: "My second commit\n")
        try await repository.push()

        XCTAssertEqual(1, callbacks)
    }

    func testOldAndNew() async throws {
        var callbacks = 0
        let file = localPath("file.txt")
        try Data("hello world\n".utf8).write(to: file)
        var id = ""
        rest.onPush = { remote, old, new, pack in
            XCTAssertEqual(id, old)
            //XCTAssertEqual("host.com/monami.git", remote)
            try await self.XXCTAssertEqual(try await Git.Hub.head.id(self.url), new)
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try Git.Config("host.com/monami.git").save(self.url)
        try await repository.commit([file], message: "My first commit\n")
        let fetch = Git.Fetch()
        id = try await Git.Hub.head.id(self.url)
        fetch.refs.append(.init(branch: id))
        self.rest._fetch = fetch
        try Data("hello world updated\n".utf8).write(to: file)
        try await repository.commit([file], message: "My second commit\n")
        try await repository.push()

        XCTAssertEqual(1, callbacks)
    }

    func testPack() async throws {
        var callbacks = 0
        let file = localPath("file.txt")
        try Data("hello world\n".utf8).write(to: file)
        rest.onPush = { remote, old, new, pack in
            let pack = try Git.Pack(pack)
            XCTAssertNotNil(pack.commits[new])
            XCTAssertEqual(1, pack.commits.count)
            XCTAssertEqual(1, pack.trees.count)
            XCTAssertEqual(1, pack.blobs.count)
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try Git.Config("host.com/monami.git").save(self.url)
        try await repository.commit([file], message: "My first commit\n")
        let fetch = Git.Fetch()
        await fetch.refs.append(.init(branch: try Git.Hub.head.id(self.url)))
        self.rest._fetch = fetch
        try Data("hello world updated\n".utf8).write(to: file)
        try await repository.commit([file], message: "My second commit\n")
        try await repository.push()

        XCTAssertEqual(1, callbacks)
    }

    func testNoCommits() async throws {
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "hello world"))
        rest._fetch = fetch
        let repository = try await Git.Hub.create(url)
        try Git.Config("host.com/monami.git").save(self.url)
        await XCTAssertThrowsError(try await repository.push())
    }

    func test3Commits() async throws {
        var callbacks = 0
        let file = localPath("file.txt")
        try Data("hello world\n".utf8).write(to: file)
        rest.onPush = { remote, old, new, pack in
            let pack = try Git.Pack(pack)
            XCTAssertEqual(2, pack.commits.count)
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try await repository.commit([file], message: "First commit\n")
        let fetch = Git.Fetch()
        await fetch.refs.append(.init(branch: try Git.Hub.head.id(self.url)))
        self.rest._fetch = fetch
        try Data("Updated\n".utf8).write(to: file)
        try await repository.commit([file], message: "Second commit\n")
        try Data("Updated again\n".utf8).write(to: file)
        try await repository.commit([file], message: "Third commit\n")
        try await repository.push()
        XCTAssertEqual(1, callbacks)
    }

    func test2CommitsEmptyResponse() async throws {
        let file = localPath("file.txt")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        try await repository.commit([file], message: "First commit\n")
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "another id"))
        self.rest._fetch = fetch
        self.rest._push = ""
        try Data("Updated\n".utf8).write(to: file)
        try await repository.commit([file], message: "Second commit\n")
        await XCTAssertThrowsError(try await repository.push())
    }

    func test2Commits1Uploaded() async throws {
        var callbacks = 0
        let file = localPath("file.txt")
        try Data("hello world\n".utf8).write(to: file)
        rest.onPush = { remote, old, new, pack in
            let pack = try Git.Pack(pack)
            XCTAssertNotNil(pack.commits[new])
            XCTAssertEqual(1, pack.commits.count)
            callbacks += 1
        }
        let repository = try await Git.Hub.create(url)
        try await repository.commit([file], message: "First commit\n")
        let fetch = Git.Fetch()
        await fetch.refs.append(.init(branch: try Git.Hub.head.id(self.url)))
        self.rest._fetch = fetch
        try Data("Updated\n".utf8).write(to: file)
        try await repository.commit([file], message: "Second commit\n")
        try await repository.push()
        XCTAssertEqual(1, callbacks)
    }

    func testUnknownReference() async throws {
        let file = localPath("file.txt")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        try await repository.commit([file], message: "First commit\n")
        let fetch = Git.Fetch()
        fetch.refs.append(.init(branch: "unknown reference"))
        self.rest._fetch = fetch
        try Data("Updated\n".utf8).write(to: file)
        await XCTAssertThrowsError(try await repository.push())
    }
}

class TestGitRefresh: LocalGitTest {

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testAfterCommit() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let expect = expectation(description: "")
        let repository = try await Git.Hub.create(url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        await repository.setStatus { _ in
            expect.fulfill()
        }
        try await repository.commit([file], message: "hello world\n")
        
        await waitForExpectations(timeout: 1)
    }

    func testAfterReset() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let expect = expectation(description: "")
        let repository = try await Git.Hub.create(url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await repository.commit([file], message: "My first commit\n")
        await repository.setStatus { _ in
            expect.fulfill()
        }
        try await repository.reset()
        await waitForExpectations(timeout: 1)
    }

    func testAfterUnpack() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let expect = expectation(description: "")
        let repository = try await Git.Hub.create(url)
        await repository.setStatus { _ in
            expect.fulfill()
        }
        try await repository.unpack()
        
        await waitForExpectations(timeout: 1)
    }
}

class TestGitRepack: LocalGitTest {
    private var rest: MockRest!

    override func setUp() async throws {
        rest = MockRest()
        Git.Hub.session = Git.Session()
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        Git.Hub.factory.rest = rest
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testFailIfInvalidId() async throws {
        await XCTAssertThrowsError(try await Git.Pack.Maker(url, from: "", to: ""))
        await XCTAssertThrowsError(try await Git.Pack.Maker(url, from: ""))
    }

    func test1Commit() async throws {
        let file = localPath("file.txt")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        try await repository.commit([file], message: "First commit\n")
        let packed = try await Git.Pack.Maker(self.url, from: Git.Hub.head.id(self.url)).data
        let pack = try Git.Pack(packed)
        XCTAssertEqual(1, pack.commits.count)
        XCTAssertEqual(1, pack.trees.count)
        XCTAssertEqual(1, pack.blobs.count)
        try await XXCTAssertEqual(try await Git.Hub.head.id(self.url), pack.commits.keys.first)
        XCTAssertEqual("92b8b694ffb1675e5975148e1121810081dbdffe", pack.trees.keys.first)
        XCTAssertEqual("3b18e512dba79e4c8300dd08aeb37f8e728b8dad", pack.blobs.keys.first)
    }

    func test2Commits() async throws {
        let file1 = localPath("file1.txt")
        let file2 = localPath("file2.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try Data("lorem ipsum\n".utf8).write(to: file2)
        let repository = try await Git.Hub.create(url)
        try await repository.commit([file1], message: "First commit\n")
        let first = try await Git.Hub.head.id(self.url)
        try await repository.commit([file2], message: "Second commit\n")
        let second = try await Git.Hub.head.id(self.url)
        let packed = try await Git.Pack.Maker(self.url, from: second).data
        let pack = try Git.Pack(packed)
        XCTAssertEqual(2, pack.commits.count)
        XCTAssertEqual(2, pack.trees.count)
        XCTAssertEqual(2, pack.blobs.count)
        XCTAssertNotNil(pack.commits[first])
        XCTAssertNotNil(pack.commits[second])
        XCTAssertNotNil(pack.trees["9ba091b521c5e794814b5a5ca78a29727c9cf31f"])
        XCTAssertNotNil(pack.trees["82424451ac502bd69712561a524e2d97fd932c69"])
        XCTAssertNotNil(pack.blobs["3b18e512dba79e4c8300dd08aeb37f8e728b8dad"])
        XCTAssertNotNil(pack.blobs["01a59b011a48660bb3828ec72b2b08990b8cf56b"])
    }

    func test2CommitsRestricted() async throws {
        let file1 = localPath("file1.txt")
        let file2 = localPath("file2.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try Data("lorem ipsum\n".utf8).write(to: file2)
        let repository = try await Git.Hub.create(url)
        try await repository.commit([file1], message: "First commit\n")
        let first = try await Git.Hub.head.id(self.url)
        try await repository.commit([file2], message: "Second commit\n")
        let second = try await Git.Hub.head.id(self.url)
        let packed = try await Git.Pack.Maker(self.url, from: second, to: first).data
        let pack = try Git.Pack(packed)
        XCTAssertEqual(1, pack.commits.count)
        XCTAssertEqual(1, pack.trees.count)
        XCTAssertEqual(2, pack.blobs.count)
        XCTAssertNotNil(pack.commits[second])
        XCTAssertNil(pack.commits[first])
        XCTAssertNotNil(pack.trees["9ba091b521c5e794814b5a5ca78a29727c9cf31f"])
        XCTAssertNil(pack.trees["82424451ac502bd69712561a524e2d97fd932c69"])
        XCTAssertNotNil(pack.blobs["3b18e512dba79e4c8300dd08aeb37f8e728b8dad"])
        XCTAssertNotNil(pack.blobs["01a59b011a48660bb3828ec72b2b08990b8cf56b"])
    }

    func test2CommitsToEmpty() async throws {
        let file1 = localPath("file1.txt")
        let file2 = localPath("file2.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try Data("lorem ipsum\n".utf8).write(to: file2)
        let repository = try await Git.Hub.create(url)
        try await repository.commit([file1], message: "First commit\n")
        try await repository.commit([file2], message: "Second commit\n")
        let second = try await Git.Hub.head.id(self.url)
        let packed = try await Git.Pack.Maker(self.url, from: second, to: "").data
        let pack = try Git.Pack(packed)
        XCTAssertEqual(2, pack.commits.count)
        XCTAssertEqual(2, pack.trees.count)
        XCTAssertEqual(2, pack.blobs.count)
    }

    func testHash() async throws {
        let file1 = localPath("file1.txt")
        let file2 = localPath("file2.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try Data("lorem ipsum\n".utf8).write(to: file2)
        let repository = try await Git.Hub.create(url)
        try await repository.commit([file1], message: "First commit\n")
        try await repository.commit([file2], message: "Second commit\n")
        let packed = try await Git.Pack.Maker(self.url, from: Git.Hub.head.id(self.url)).data
        XCTAssertEqual(packed.suffix(20), Git.Hash.digest(packed.subdata(in: 0 ..< packed.count - 20)))
    }
}

class TestGitRepository: LocalGitTest {

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testRefresh() async throws {
        let repository = await Git.Repository(URL(fileURLWithPath: ""))
        await repository.state.touch()
        try await repository.refresh()
        //XCTAssertEqual(Date.distantPast, repository.state.last)
    }

    func testBranch() async throws {
        var callbacks = 0
        let repository = try await Git.Hub.create(url)
        do {
            let branch = try await repository.branch()
            XCTAssertEqual("master", branch)
            callbacks += 1

        }
        
        XCTAssertEqual(1, callbacks)
    }

    func XXXtestRemoteNone() async throws {
        var callbacks = 0
        let repository = try await Git.Hub.create(url)
        do {
            let remote = try await repository.remote()
            XCTAssertEqual("", remote)
            callbacks += 1

        }
        
        XCTAssertEqual(1, callbacks)
    }

    func testRemote() async throws {
        let repository = try await Git.Hub.create(url)
        try Git.Config("hello world").save(self.url)
        let remote = try await repository.remote()
        try await XXCTAssertEqual("""
[remote "origin"]
    url = https://hello world
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
    remote = origin
    merge = refs/heads/master

""", String(decoding: try await Data(contentsOf: localPath(".git/config")), as: UTF8.self))
        //XCTAssertEqual("hello world", remote)
        XCTAssertNotNil(remote)
    }
}

class TestGitReset: LocalGitTest {
    private var repository: Git.Repository!

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testOneFile() async throws {
        var callbacks = 0
        self.repository = try await Git.Hub.create(url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        try await self.repository.commit([file], message: "My first commit\n")
        try FileManager.default.removeItem(at: file)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        do {
            try await self.repository.reset()
            XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
            try await XXCTAssertEqual("hello world\n", String(decoding: (try await Data(contentsOf: file)), as: UTF8.self))
            callbacks += 1

        }
        XCTAssertEqual(1, callbacks)
    }

    func testSubdirectories() async throws {
        self.repository = try await Git.Hub.create(url)
        let dir = localPath("dir1")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)
        let file1 = localPath("myfile1.txt")
        let file2 = dir.appendingPathComponent("myfile2.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try Data("lorem ipsum\n".utf8).write(to: file2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file1.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file2.path))
        try await self.repository.commit([file1, file2], message: "My first commit\n")
        try FileManager.default.removeItem(at: file1)
        try FileManager.default.removeItem(at: dir)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file1.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file2.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.path))
        try await self.repository.reset()
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file1.path))
        try await XXCTAssertEqual("hello world\n", String(decoding: (try await Data(contentsOf: file1)), as: UTF8.self))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file2.path))
        try await XXCTAssertEqual("lorem ipsum\n", String(decoding: (try await Data(contentsOf: file2)), as: UTF8.self))
    }

    func testRemoveOneFile() async throws {
        self.repository = try await Git.Hub.create(url)
        let file1 = localPath("myfile1.txt")
        let file2 = localPath("myfile2.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try await self.repository.commit([file1], message: "My first commit\n")
        try Data("lorem ipsum\n".utf8).write(to: file2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file2.path))
        try await self.repository.reset()
        XCTAssertFalse(FileManager.default.fileExists(atPath: file2.path))
    }

    func testRemoveDirectories() async throws {
        self.repository = try await Git.Hub.create(url)
        let file1 = localPath("myfile1.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try await self.repository.commit([file1], message: "My first commit\n")
        let dir = localPath("dir1")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)
        let file2 = dir.appendingPathComponent("myfile2.txt")
        try Data("lorem ipsum\n".utf8).write(to: file2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: file2.path))
        try await self.repository.reset()
        XCTAssertFalse(FileManager.default.fileExists(atPath: dir.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file2.path))
    }

    func testIndex() async throws {
        self.repository = try await Git.Hub.create(url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await self.repository.commit([file], message: "My first commit\n")
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/index").path))
        try FileManager.default.removeItem(at: localPath(".git/index"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(".git/index").path))
        try await self.repository.reset()
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/index").path))
    }
}

class TestGitRest: XCTestCase {
    func testEmpty() async throws {
        await XCTAssertThrowsError(try Git.Rest().url("", suffix: ""))
    }

    func testSuccess() async throws {
        XCTAssertNoThrow(try Git.Rest().url("github.com/some/repository.git", suffix: ""))
    }

    func testProtocol() async throws {
        await XCTAssertThrowsError(try Git.Rest().url("https://github.com/some/repository.git", suffix: ""))
        await XCTAssertThrowsError(try Git.Rest().url("http://github.com/some/repository.git", suffix: ""))
    }

    func testEnding() async throws {
        await XCTAssertThrowsError(try Git.Rest().url("github.com/some/repository.git/", suffix: ""))
        await XCTAssertThrowsError(try Git.Rest().url("github.com/some/repository", suffix: ""))
    }

    func testValidity() async throws {
        let url = (try? Git.Rest().url("github.com/some/repository.git", suffix: "")) ?? URL(fileURLWithPath: "")
        XCTAssertEqual("https://github.com/some/repository.git", url.absoluteString)
    }
}

class TestGitRestoreIndex: LocalGitTest {

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        Git.Hub.session.name = "hello"
        Git.Hub.session.email = "world"
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testAfterReset() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let repository = try await Git.Hub.create(url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await repository.commit([file], message: "hello world\n")
        var index = await Git.Index(self.url)
        let id = index?.id
        XCTAssertEqual(40, id?.count)
        XCTAssertEqual(1, index?.entries.count)
        XCTAssertEqual("3b18e512dba79e4c8300dd08aeb37f8e728b8dad", index?.entries.first?.id)
        try FileManager.default.removeItem(at: localPath(".git/index"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(".git/index").path))
        try await repository.reset()
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/index").path))
        index = await Git.Index(self.url)
        XCTAssertEqual(id, index?.id)
        XCTAssertEqual(1, index?.entries.count)
        XCTAssertEqual("3b18e512dba79e4c8300dd08aeb37f8e728b8dad", index?.entries.first?.id)
    }

    func testAfterUnpack() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let repository = try await Git.Hub.create(url)
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await repository.commit([file], message: "hello world\n")
        var index = await Git.Index(self.url)
        let id = index?.id
        XCTAssertEqual(40, id?.count)
        XCTAssertEqual(1, index?.entries.count)
        XCTAssertEqual("3b18e512dba79e4c8300dd08aeb37f8e728b8dad", index?.entries.first?.id)
        try FileManager.default.removeItem(at: localPath(".git/index"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(".git/index").path))
        try await repository.unpack()
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/index").path))
        index = await Git.Index(self.url)
        XCTAssertEqual(id, index?.id)
        XCTAssertEqual(1, index?.entries.count)
        XCTAssertEqual("3b18e512dba79e4c8300dd08aeb37f8e728b8dad", index?.entries.first?.id)
    }
}

class TestGitSession: XCTestCase {
    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        UserDefaults.standard.removeObject(forKey: "session")
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: "session")
    }

    func testLoadFromGit() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        XCTAssertTrue(Git.Hub.session.email.isEmpty)
        XCTAssertTrue(Git.Hub.session.name.isEmpty)
        let data = "hasher\n".data(using: .utf8)!
        let url = URL(fileURLWithPath: "hello/world")
        let session = Git.Session()
        session.name = "lorem ipsum"
        session.email = "lorem@world.com"
        session.user = "pablo@mousaka.com"
        session.bookmark = data
        session.url = url
        try session.save()
        try await Git.Hub.session.load()
        XCTAssertEqual("lorem ipsum", Git.Hub.session.name)
        XCTAssertEqual("lorem@world.com", Git.Hub.session.email)
        XCTAssertEqual("pablo@mousaka.com", Git.Hub.session.user)
        XCTAssertEqual(data, Git.Hub.session.bookmark)
        XCTAssertEqual(url.path, Git.Hub.session.url.path)
    }

    func testUpdateName() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        XCTAssertTrue(Git.Hub.session.email.isEmpty)
        XCTAssertTrue(Git.Hub.session.name.isEmpty)
        try await Git.Hub.session.update("pablo", email: "mousaka@mail.com")
        Git.Hub.session.name = ""
        Git.Hub.session.email = ""
        try await Git.Hub.session.load()
        XCTAssertEqual("pablo", Git.Hub.session.name)
        XCTAssertEqual("mousaka@mail.com", Git.Hub.session.email)
    }

    func testUpdateUrl() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        XCTAssertTrue(Git.Hub.session.email.isEmpty)
        XCTAssertTrue(Git.Hub.session.name.isEmpty)
        let data = "hasher\n".data(using: .utf8)!
        let url = URL(fileURLWithPath: "hello/world")
        try await Git.Hub.session.update(url, bookmark: data)
        Git.Hub.session.url = URL(fileURLWithPath: "")
        Git.Hub.session.bookmark = Data()
        try await Git.Hub.session.load()
        XCTAssertEqual(data, Git.Hub.session.bookmark)
        XCTAssertEqual(url.path, Git.Hub.session.url.path)
    }
}

class TestGitStaging: LocalGitTest {

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testIndexSizeNameOneChar() async throws {
        let file = localPath("a")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([file], message: "hello")
        try await XXCTAssertEqual(96, try await Data(contentsOf: localPath(".git/index")).count)
    }

    func testIndexSizeNameTwoChar() async throws {
        let file = localPath("ab")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([file], message: "hello")
        try await XXCTAssertEqual(104, try await Data(contentsOf: localPath(".git/index")).count)
    }

    func testIndexSizeNameThreeChar() async throws {
        let file = localPath("abc")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([file], message: "hello")
        try await XXCTAssertEqual(104, try await Data(contentsOf: localPath(".git/index")).count)
    }

    func testIndexSizeNameTenChar() async throws {
        let file = localPath("abcdefghij")
        try Data("hello world\n".utf8).write(to: file)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([file], message: "hello")
        try await XXCTAssertEqual(112, try await Data(contentsOf: localPath(".git/index")).count)
    }

    func testIndexSubtree() async throws {
        let a = localPath("a")
        let b = a.appendingPathComponent("b")
        let c = a.appendingPathComponent("c")
        try FileManager.default.createDirectory(at: b, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: c, withIntermediateDirectories: true)
        let file1 = b.appendingPathComponent("myfile1.txt")
        let file2 = c.appendingPathComponent("myfile2.txt")
        try Data("hello world\n".utf8).write(to: file1)
        try Data("lorem ipsum\n".utf8).write(to: file2)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([file1, file2], message: "hello")
        let index = await Git.Index(self.url)
        XCTAssertEqual(2, index?.entries.count)
        XCTAssertEqual("3b18e512dba79e4c8300dd08aeb37f8e728b8dad", index?.entries.first?.id)
        XCTAssertEqual(file1.path, index?.entries.first?.url.path)
        XCTAssertEqual(12, index?.entries.first?.size)
        XCTAssertEqual("01a59b011a48660bb3828ec72b2b08990b8cf56b", index?.entries.last?.id)
        XCTAssertEqual(file2.path, index?.entries.last?.url.path)
        XCTAssertEqual(12, index?.entries.last?.size)
    }

    func testTreeAfterPartialUpdate() async throws {
        let file1 = localPath("file1")
        let file2 = localPath("file2")
        try Data("hello world\n".utf8).write(to: file1)
        try Data("lorem ipsum\n".utf8).write(to: file2)
        let repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await repository.commit([file1, file2], message: "hello")
        try Data("hello world updated\n".utf8).write(to: file1)
        try await repository.commit([file1], message: "hello")
        try await XXCTAssertEqual(2, (try await Git.Hub.head.tree(self.url)).items.count)
    }
}

class TestGitStatus: LocalGitTest {
    private var repository: Git.Repository!

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testNoChanges() async throws {
        #if true || os(Linux)
        throw XCTSkip("TODO: fix intermittent failure when running in parallel") // mostly on Linux, but sometimes on macOS
        #endif
        let expect = expectation(description: "")
        self.repository = try await Git.Hub.create(url)
        await repository.setStatus {
            XCTAssertTrue($0.isEmpty)
            expect.fulfill()
        }
        try await self.repository.refresh()
        await waitForExpectations(timeout: 1)
    }

    func testEmpty() async throws {
        let repository = try await Git.Hub.create(url)
        try await XXCTAssertEqual(true, try await repository.state.list.isEmpty)
    }

    func testUntracked() async throws {
        try Data("hello world".utf8).write(to: localPath("myfile.txt"))
        let repository = try await Git.Hub.create(url)
        let status = try await repository.state.list
        XCTAssertEqual(1, status.count)
        XCTAssertEqual(.untracked, status.first?.1)
    }

    func testAddedWithIndex() async throws {
        let file1 = localPath("myfile.txt")
        let file2 = localPath("myfile2.txt")
        try Data("hello world".utf8).write(to: file1)
        try Data("hello world 2".utf8).write(to: file2)
        var index = await Git.Index(url) ?? Git.Index()
        let repository = try await Git.Hub.create(url)
        try await repository.stage.add(file1, index: &index)
        try index.save(self.url)
        let status = try await repository.state.list
        XCTAssertEqual(2, status.count)
        XCTAssertEqual(.untracked, status[1].1)
        XCTAssertEqual(.added, status[0].1)
    }

    func testAdded() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        var index = await Git.Index(url) ?? Git.Index()
        let repository = try await Git.Hub.create(url)
        try await repository.stage.add(file, index: &index)
        try index.save(self.url)
        let status = try await repository.state.list
        XCTAssertEqual(1, status.count)
        XCTAssertEqual(.added, status.first?.1)
    }

    func testModified() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        self.repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await self.repository.commit([file], message: "First commit")
        try Data("modified".utf8).write(to: file)
        let status = try await self.repository.state.list
        XCTAssertEqual(1, status.count)
        XCTAssertEqual(.modified, status.first?.1)
    }

    func testNotEdited() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        self.repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await self.repository.commit([file], message: "First commit")
        let status = try await self.repository.state.list
        XCTAssertEqual(true, status.isEmpty)
    }

    func testDeleted() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        self.repository = try await Git.Hub.create(url)
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await self.repository.commit([file], message: "First commit")
        try FileManager.default.removeItem(at: file)
        let status = try await self.repository.state.list
        XCTAssertEqual(1, status.count)
        XCTAssertEqual(.deleted, status.first?.1)
        XCTAssertEqual(file, status.first?.0)
    }

    func testNotEditedInSubtree() async throws {
        let sub = localPath("sub")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let file = sub.appendingPathComponent("myfile.txt")
        let outside = localPath("outside.txt")
        try Data("hello world\n".utf8).write(to: file)
        try Data("lorem ipsum\n".utf8).write(to: outside)
        let repository = try await Git.Hub.create(url)
        self.repository = repository
        Git.Hub.session.name = "asd"
        Git.Hub.session.email = "my@email.com"
        try await self.repository.commit([outside, file], message: "First commit")
        try await XXCTAssertEqual(true, try await self.repository.state.list.isEmpty)
    }
}

class TestGitTree: LocalGitTest {
    private var ignore: Git.Ignore!

    override func setUp() async throws {
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        ignore = await Git.Ignore(url)
    }

    func testEmpty() async throws {
        let tree = try await Git.Tree(url, ignore: ignore, update: [], entries: [])
        XCTAssertTrue(tree.items.isEmpty)
    }

    func testAvoidGit() async throws {
        try FileManager.default.createDirectory(at: localPath(".git"), withIntermediateDirectories: true)
        let file = localPath(".git/myfile.txt")
        try Data("hello world".utf8).write(to: file)
        let tree = try await Git.Tree(url, ignore: ignore, update: [], entries: [])
        XCTAssertTrue(tree.items.isEmpty)
    }

    func testOneFileNotValid() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        let tree = try await Git.Tree(url, ignore: ignore, update: [], entries: [])
        XCTAssertTrue(tree.items.isEmpty)
    }

    func testOneFile() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world".utf8).write(to: file)
        let tree = try await Git.Tree(url, ignore: ignore, update: [file], entries: [])
        XCTAssertEqual(1, tree.items.count)
        XCTAssertEqual(file, tree.items.first?.url)
        XCTAssertEqual("95d09f2b10159347eece71399a7e2e907ea3df4f", tree.items.first?.id)
        XCTAssertEqual(.blob, tree.items.first?.category)
    }

    func testSave() async throws {
        let file = localPath("myfile.txt")
        try Data("hello world\n".utf8).write(to: file)
        try await XXCTAssertEqual("84b5f2f96994db6b67f8a0ee508b1ebb8b633c15", try await Git.Tree(url, ignore: ignore, update: [file], entries: []).save(url))
        let object = try? await Data(contentsOf: localPath(
            ".git/objects/84/b5f2f96994db6b67f8a0ee508b1ebb8b633c15"))
        XCTAssertNotNil(object)
        XCTAssertEqual(55, object?.count)
    }

    func testOneFileInSub() async throws {
        let sub = localPath("abc", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let file = sub.appendingPathComponent("another.txt")
        try Data("lorem ipsum\n".utf8).write(to: file)
        let tree = try await Git.Tree(url, ignore: ignore, update: [file], entries: [])
        XCTAssertEqual(1, tree.items.count)
        XCTAssertEqual(.tree, tree.items.first?.category)
        XCTAssertEqual(sub, tree.items.first?.url)
        XCTAssertEqual("12b34e53d16df3d9f2dd6ad8a4c45af37e283dc1", tree.items.first?.id)
        XCTAssertEqual(sub, tree.items.first?.url)
        XCTAssertEqual(1, tree.children.count)
        XCTAssertEqual(.blob, tree.children.values.first?.items.first?.category)
        XCTAssertEqual("01a59b011a48660bb3828ec72b2b08990b8cf56b", tree.children.values.first?.items.first?.id)
        XCTAssertEqual(file, tree.children.values.first?.items.first?.url)
    }

    func testSaveSub() async throws {
        let sub = localPath("abc")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let file = sub.appendingPathComponent("another.txt")
        try Data("lorem ipsum".utf8).write(to: file)
        try await XXCTAssertEqual("869b9c7ef21df1511a4a1cded69b0b011fe0e8c3", try await Git.Tree(url, ignore: ignore, update: [file], entries: []).save(url))
        let object = try await Data(contentsOf: localPath(
            ".git/objects/86/9b9c7ef21df1511a4a1cded69b0b011fe0e8c3"))
        XCTAssertNotNil(object)
        XCTAssertEqual(45, object.count)
    }

    func testEmptySub() async throws {
        let sub = localPath("abc")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let tree = try await Git.Tree(url, ignore: ignore, update: [], entries: [])
        XCTAssertTrue(tree.items.isEmpty)
    }

    func testEmptySubInSub() async throws {
        let sub = localPath("abc")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let another = sub.appendingPathComponent("def")
        try FileManager.default.createDirectory(at: another, withIntermediateDirectories: true)
        let tree = try await Git.Tree(url, ignore: ignore, update: [], entries: [])
        XCTAssertTrue(tree.items.isEmpty)
    }

    func testLoadWithOneFileInSub() async throws {
        let sub = localPath("abc", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let file = sub.appendingPathComponent("another.txt")
        try Data("lorem ipsum\n".utf8).write(to: file)
        var tree = try await Git.Tree(url, ignore: ignore, update: [file], entries: [])
        let id = try await tree.save(url)
        tree = try await Git.Tree(id, url: url)
        let found = await tree.list(url).first(where: { $0.url == file })
        XCTAssertNotNil(found)
    }

    func testMakeIndex() async throws {
        let sub = localPath("abc", isDirectory: true)
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        let file = sub.appendingPathComponent("another.txt")
        try Data("lorem ipsum\n".utf8).write(to: file)
        var index = Git.Index()
        let tree = try await Git.Tree(url, ignore: ignore, update: [file], entries: [])
        _ = try await tree.save(url)
        try await tree.map(&index, url: url)
        XCTAssertEqual(1, index.entries.count)
        XCTAssertEqual(file, index.entries.first?.url)
        XCTAssertEqual("01a59b011a48660bb3828ec72b2b08990b8cf56b", index.entries.first?.id)
    }
}

class TestGitUnpack: LocalGitTest {

    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
        url = tmpfile()
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func testNotPacked() async throws {
        var callbacks = 0
        let repository = try await Git.Hub.create(url)
        do {
            let packed = try await repository.packed()
            XCTAssertFalse(packed)
            callbacks += 1

        }
        
        XCTAssertEqual(1, callbacks)
    }

    func testPacked() async throws {
        let repository = try await Git.Hub.create(url)
        try await self.addPack("1")
        let packed = try await repository.packed()
        XCTAssertTrue(packed)
    }

    func testPackedReference() async throws {
        let repository = try await Git.Hub.create(url)
        try await self.addReference()
        let packed = try await repository.packed()
        XCTAssertTrue(packed)
    }

    func testUnpack1() async throws {
        var callbacks = 0
        let repository = try await Git.Hub.create(url)
        try await self.addPack("1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.pack").path))
        do {
            try await repository.unpack()
            XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/33/5a33ae387dc24f057852fdb92e5abc71bf6b85").path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(".git/objects/pack/pack-1.pack").path))

            callbacks += 1

        }
        
        XCTAssertEqual(1, callbacks)
    }

    func testUnpack2() async throws {
        let repository = try await Git.Hub.create(url)
        try await self.addPack("2")
        try await repository.unpack()
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/d1/4d41ee118d52df4b9811b2eacc943f06cd942a").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/08/07a029cb42acd13ad194248436f093b8e63a4f").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/objects/0e/c0ff154d5c479f0af27d7a5064bb570c62500d").path))
    }

    func testReferences() async throws {
        let repository = try await Git.Hub.create(url)
        try await self.addReference()
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/packed-refs").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(".git/refs/heads/master").path))
        try await repository.unpack()
        XCTAssertTrue(FileManager.default.fileExists(atPath: localPath(".git/refs/heads/master").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: localPath(".git/packed-refs").path))
        try await XXCTAssertEqual("335a33ae387dc24f057852fdb92e5abc71bf6b85", try await Git.Hub.head.id(self.url))
    }

    private func addPack(_ id: String) async throws {
        try FileManager.default.createDirectory(at: localPath(".git/objects/pack"), withIntermediateDirectories: true)
        try await fixture(name: "pack-\(id)", ext: "idx").write(to: localPath(".git/objects/pack/pack-\(id).idx"))
        try await fixture(name: "pack-\(id)", ext: "pack").write(to: localPath(".git/objects/pack/pack-\(id).pack"))
    }

    private func addReference() async throws {
        try await fixture(name: "packed-refs0", ext: nil).write(to: localPath(".git/packed-refs"))
    }
}

class TestGitUser: XCTestCase {
    override func setUp() async throws {
        Git.Hub.session = Git.Session()
        Git.Hub.factory.rest = MockRest()
    }

    func testNonEmpty() async throws {
        await update("", email: "")
        await update("", email: "test@mail.com")
        await update("test", email: "")
    }

    func testCommitCharacters() async throws {
        await update("hello", email: "test<@mail.com")
        await update("hello", email: "test>@mail.com")
        await update("h<ello", email: "test@mail.com")
        await update("h>ello", email: "test@mail.com")
        await update("hello", email: "test@mail.com\n")
        await update("hello\n", email: "test@mail.com")
        await update("hello", email: "test@mail.com\t")
        await update("hello\t", email: "test@mail.com")
    }

    func testAt() async throws {
        await update("test", email: "testmail.com")
        await update("test", email: "test@@mail.com")
        await update("test", email: "@mail.com")
    }

    func testDot() async throws {
        await update("test", email: "test@mailcom")
        await update("test", email: "test@mailcom.")
        await update("test", email: "test@.mailcom")
    }

    func testWeird() async throws {
        await update("test", email: "test@ mail.com")
        await update("test", email: "test @mail.com")
        await update("test", email: "te st@mail.com")
        await update("test", email: " test@mail.com")
        await update("test", email: "test@mail.com ")
    }

    private func update(_ user: String, email: String) async {
        do {
            try await Git.Hub.session.update(user, email: email)
            XCTFail("expected error from update")
        } catch {
            // expected
        }
    }
}

private class MockRest: Git.Rest {
    var _error: Error?
    var _fetch: Git.Fetch?
    var _pull: Git.Pack?
    var _push = "000eunpack ok"
    var onDownload: ((String) async throws -> Void)?
    var onUpload: ((String) async throws -> Void)?
    var onPull: ((String, String, String) async throws -> Void)?
    var onPush: ((String, String, String, Data) async throws -> Void)?

    private func mocked<T>(_ value: T?, error: @escaping ((Error) -> Void), result: @escaping ((T) throws -> Void), handler: () -> () = { } ) {
        if let _fetch = value {
            do {
                defer { handler() }
                try result(_fetch)
            } catch let exception {
                error(exception)
            }
        } else if let _error = self._error {
            error(_error)
        }
    }

    override func downloadPull(_ url: URL) async throws -> Git.Fetch {
        try await onDownload?(url.absoluteString)

        if let fetch = _fetch {
            return fetch
        } else {
            throw _error ?? CocoaError(.featureUnsupported)
        }
    }

    override func uploadPush(_ remote: URL) async throws -> Git.Fetch {
        try await onUpload?(remote.absoluteString)

        if let fetch = _fetch {
            return fetch
        } else {
            throw _error ?? CocoaError(.featureUnsupported)
        }
    }

    override func pull(_ remote: URL, want: String, have: String = "") async throws -> Git.Pack {
        try await onPull?(remote.absoluteString, want, have)

        if let pull = _pull {
            return pull
        } else {
            throw _error ?? CocoaError(.featureUnsupported)
        }
    }

    override func push(_ remote: URL, old: String, new: String, pack: Data) async throws -> Data {
        try await onPush?(remote.absoluteString, old, new, pack)

        if let error = _error {
            throw error
        } else {
            return _push.utf8Data
        }
    }

}


@available(*, deprecated, message: "work in progress")
fileprivate func wip<T>(_ value: T) -> T { value }

fileprivate let sampleURL = URL(string: "https://host.com/monami.git")!
fileprivate let invalidURL = URL(string: "about:blank")!

extension XCTestCase {
    //@available(*, deprecated, message: "convert to async")
    func waitForExpectations(timeout: TimeInterval) async {
        await self.waitForExpectations(timeout: timeout) { error in
            dbg("error:", error)
        }
    }

    /// Async variant of the standard `XCTAssertEqual`.
    func XXCTAssertEqual<T: Equatable>(_ t1: @autoclosure () async throws -> T, _ t2: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async rethrows {
        let v1 = try await t1()
        let v2 = try await t2()
        XCTAssertEqual(v1, v2, message(), file: file, line: line)
    }

    /// Async variant of the standard `XCTAssertThrowsError`.
    @discardableResult fileprivate func XCTAssertThrowsError<T>(_ block: @autoclosure () async throws -> T, file: StaticString = #file, line: UInt = #line) async -> T? {
        do {
            let result = try await block()
            XCTFail("expected block to throw error, but was successful", file: file, line: line)
            return result
        } catch {
            return nil
        }
    }
}
#endif // DEBUG
