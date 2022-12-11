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
import Swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum Git {
    /// Zip compression level
    static let compressionLevel = 5

    actor Check {
        weak var repository: Repository?

        func setRepository(_ repository: Repository) {
            self.repository = repository
        }

        func reset() async throws {
            guard let url = repository?.url, let tree = try? await Hub.head.tree(url) else { return }
            try await check(tree)
        }

        func check(_ id: String) async throws {
            guard let url = repository?.url else { return }
            try await check(Tree(Commit(id, url: url).tree, url: url))
            try await Hub.head.update(url, id: id)
        }

        func merge(_ id: String) async throws {
            guard let url = repository?.url else { return }
            var tree = try await Hub.head.tree(url).items
            try await Tree(Commit(id, url: url).tree, url: url).items.forEach { item in
                if !tree.contains(where: { $0.id == item.id }) {
                    tree.append(item)
                }
            }
            var index = Index()
            try await extract(tree, index: &index)
            try index.save(url)
        }

        private func check(_ tree: Tree) async throws {
            guard let url = repository?.url else { return }
            try await remove(tree)
            var index = Index()
            try await extract(tree.items, index: &index)
            try index.save(url)
        }

        private func remove(_ tree: Tree) async throws {
            guard let url = repository?.url, let list = try await repository?.state.list(tree) else { return }
            try list.filter({ $0.1 != .deleted }).forEach {
                let path = $0.0.deletingLastPathComponent().path.dropFirst(url.path.count)
                if !path.isEmpty {
                    let dir = url.appendingPathComponent(String(path))
                    if FileManager.default.fileExists(atPath: dir.path) {
                        try FileManager.default.removeItem(at: dir)
                    }
                } else {
                    if FileManager.default.fileExists(atPath: $0.0.path) {
                        try FileManager.default.removeItem(at: $0.0)
                    }
                }
            }
        }

        private func extract(_ tree: [Tree.Item], index: inout Index) async throws {
            guard let url = repository?.url else { return }
            for item in tree {
                switch item.category {
                case .tree:
                    if !FileManager.default.fileExists(atPath: item.url.path) {
                        try FileManager.default.createDirectory(at: item.url, withIntermediateDirectories: true)
                    }
                    try await extract(Tree(item.id, url: url, trail: item.url).items, index: &index)
                default:
                    try await Hub.content.file(item.id, url: url).write(to: item.url, options: .atomic)
                    try await index.entry(item.id, url: item.url)
                }
            }
        }
    }

    public struct Commit {
        public internal(set) var author = User()
        public internal(set) var message = ""
        var committer = User()
        var parent = [String]()
        var tree = ""
        var gpg = ""

        init(_ id: String, url: URL) async throws {
            try await self.init(Hub.content.get(id, url: url))
        }

        init(_ data: Data) throws {
            let string = String(decoding: data, as: UTF8.self)
            let split = string.components(separatedBy: "\n\n")
            let signed = split.first!.components(separatedBy: "\ngpgsig")
            var lines = signed.first!.components(separatedBy: "\n")
            guard
                split.count > 1,
                lines.count >= 3,
                let tree = lines.removeFirst().components(separatedBy: "tree ").last,
                tree.count == 40,
                let committer = try? User(lines.removeLast()),
                let author = try? User(lines.removeLast())
            else { throw Failure.Commit.unreadable }
            while !lines.isEmpty {
                guard let parent = lines.removeFirst().components(separatedBy: "parent ").last, parent.count == 40
                else { throw Failure.Commit.unreadable }
                self.parent.append(parent)
            }
            if signed.count == 2 {
                gpg = "\ngpgsig" + signed[1]
            }
            self.tree = tree
            self.author = author
            self.committer = committer
            self.message = split.dropFirst().joined(separator: "\n\n")
        }

        init() { }

        var serial: String {
            var result = "tree \(tree)\n"
            parent.forEach {
                result += "parent \($0)\n"
            }
            result += "author \(author.serial)\ncommitter \(committer.serial)\(gpg)\n\n\(message)"
            return result
        }
    }

    public struct Config {
        struct Remote {
            fileprivate(set) var url = ""
            fileprivate(set) var fetch = ""
        }

        struct Branch {
            fileprivate(set) var remote = ""
            fileprivate(set) var merge = ""
        }

        private(set) var remote = [String: Remote]()
        private(set) var branch = [String: Branch]()

        init(_ url: String) {
            var remote = Remote()
            remote.url = "https://" + url
            remote.fetch = "+refs/heads/*:refs/remotes/origin/*"
            var branch = Branch()
            branch.remote = "origin"
            branch.merge = "refs/heads/master"
            self.remote["origin"] = remote
            self.branch["master"] = branch
        }

        init(_ url: URL) async throws {
            let lines = String(decoding: try await Data(contentsOf: url.appendingPathComponent(".git/config")), as: UTF8.self).components(separatedBy: "\n")
            var index = 0
            while index < lines.count {
                if lines[index].prefix(7) == "[remote" {
                    var remote = Remote()
                    remote.url = lines[index + 1].components(separatedBy: "= ")[1]
                    remote.fetch = lines[index + 2].components(separatedBy: "= ")[1]
                    self.remote[lines[index].components(separatedBy: "\"")[1]] = remote
                    index += 3
                } else if lines[index].prefix(7) == "[branch" {
                    var branch = Branch()
                    branch.remote = lines[index + 1].components(separatedBy: "= ")[1]
                    branch.merge = lines[index + 2].components(separatedBy: "= ")[1]
                    self.branch[lines[index].components(separatedBy: "\"")[1]] = branch
                    index += 3
                } else {
                    repeat {
                        index += 1
                    } while index < lines.count && !lines[index].isEmpty && lines[index].first != "["
                }
            }
        }

        func save(_ url: URL) throws {
            let dest = url.appendingPathComponent(".git/config")
            try Data(serial.utf8).write(to: dest, options: .atomic)
        }

        var serial: String {
            var result = ""
            remote.forEach {
                result += """
            [remote \"\($0.0)\"]
                url = \($0.1.url)
                fetch = \($0.1.fetch)

            """
            }
            branch.forEach {
                result += """
            [branch \"\($0.0)\"]
                remote = \($0.1.remote)
                merge = \($0.1.merge)

            """
            }
            return result
        }
    }

    struct Content {
        @discardableResult func add(_ commit: Commit, url: URL) async throws -> String {
            return try await {
                try await add($0.1, data: $0.0, url: url)
                return $0.1
            } (Hash.commit(commit.serial))
        }

        @discardableResult func add(_ tree: Tree, url: URL) async throws -> String {
            return try await {
                try await add($0.1, data: $0.0, url: url)
                return $0.1
            } (Hash.tree(tree.serial))
        }

        @discardableResult func add(_ file: URL, url: URL) async throws -> String {
            return try await {
                try await add($0.1, data: $0.0, url: url)
                return $0.1
            } (Hash.file(file))
        }

        @discardableResult func add(_ blob: Data, url: URL) async throws -> String {
            return try await {
                try await add($0.1, data: $0.0, url: url)
                return $0.1
            } (Hash.blob(blob))
        }

        func file(_ id: String, url: URL) async throws -> Data {
            let parse = Parse(try await Hub.content.get(id, url: url))
            _ = try parse.variable()
            return parse.data.subdata(in: parse.index ..< parse.data.count)
        }

        func get(_ id: String, url: URL) async throws -> Data {
            return try await Data(contentsOf: url.appendingPathComponent(".git/objects/\(id.prefix(2))/\(id.dropFirst(2))")).decompress()
        }

        func objects(_ url: URL) -> [String] {
            return FileManager.default.enumerator(at: url.appendingPathComponent(".git/objects/"), includingPropertiesForKeys: nil)!
                .filter({ !($0 as! URL).hasDirectoryPath }).map({ ($0 as! URL)
                    .resolvingSymlinksInPath().path.dropFirst(url.path.count + 13).replacingOccurrences(of: "/", with: "") })
        }

        private func add(_ id: String, data: Data, url: URL) async throws {
            let folder = url.appendingPathComponent(".git/objects/\(id.prefix(2))")
            let location = folder.appendingPathComponent(String(id.dropFirst(2)))
            if !FileManager.default.fileExists(atPath: location.path) {
                if !FileManager.default.fileExists(atPath: folder.path) {
                    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                }
                try Data.compress(data, level: compressionLevel).write(to: location)
            }
        }

    }

    actor Differ {
        weak var repository: Repository?

        func setRepository(_ repository: Repository) {
            self.repository = repository
        }

        func previous(_ url: URL) async throws -> (Date, Data)? {
            guard
                let repository = self.repository,
                let id = try await Hub.head.tree(repository.url).list(repository.url).first(where: { $0.url.path == url.path })?.id
            else { return nil }
            if let current = try? Hash.blob(await Data(contentsOf: url)).1 {
                if current == id {
                    throw Failure.Diff.unchanged
                }
            }
            return try await ((Hub.head.commit(repository.url)).author.date, Hub.content.file(id, url: repository.url))
        }

        func timeline(_ url: URL) async throws -> [(Date, Data)] {
            guard let repository = self.repository else { return [] }
            return try await History(repository.url).result.reduceAsync(into: { [Hash.blob($0).1: (Date(), $0)] } ((try? await Data(contentsOf: url)) ?? Data()), {
                guard
                    let id = try await Tree($1.tree, url: repository.url).list(repository.url).first(where: { $0.url.path == url.path })?.id,
                    $0[id] == nil
                else { return }
                $0[id] = try ($1.author.date, await Hub.content.file(id, url: repository.url))
            }).values.sorted(by: { $0.0 < $1.0 })
        }
    }

    final class Dispatch {
        //    private let queue = DispatchQueue(label: "", qos: .background, target: .global(qos: .background))

        func background(_ send: (() -> Void)) {
            //        queue.async {
            send()
            //        }
        }


        func background<R>(_ send: (() throws -> R), success: ((R) throws -> Void)) rethrows {
            //        queue.async {
            let result = try send()
            //            do {
            try success(result)
            //            }
            //        }
        }
//
//        func background<R>(_ send: (() throws -> R)) rethrows -> R {
//            //        queue.async {
//            let result = try send()
//            //            do {
//            return result
//            //            }
//            //        }
//        }

        func background<R>(_ send: (() throws -> R), error: ((Error) -> Void),
                           success: ((R) -> Void)) {
            //        queue.async {
            do {
                let result = try send()
                //                do {
                success(result)
                //                }
            } catch let exception {
                //                do {
                error(exception)
                //                }
            }
            //        }
        }
    }

    final class Factory {
        var rest = Rest()

        func open(_ url: URL) async throws -> Repository {
            if try await repository(url) {
                return await Repository(url)
            }
            throw Failure.Repository.invalid
        }

        func clone(_ remote: URL, local: URL) async throws {
            if try await repository(local) {
                throw Failure.Remote.already
            }
            let fetch = try await rest.downloadPull(remote)
            guard let reference = fetch.branch.first else { throw Failure.Fetch.empty }
            if !FileManager.default.fileExists(atPath: local.path) {
                try FileManager.default.createDirectory(at: local, withIntermediateDirectories: true)
            }

            let pack = try await self.rest.pull(remote, want: reference)
            let repository = try await self.create(local)
            try await pack.unpack(local)
            try await repository.check.check(reference)
            try await Hub.head.update(local, id: reference)
            try Hub.head.origin(local, id: reference)
            try Config(remote.withoutProtocol()).save(local)
        }

        func pull(_ repository: Repository) async throws -> Bool {
            let fetch = try await rest.downloadPull(Hub.head.remote(repository.url))
            guard let reference = fetch.branch.first else { throw Failure.Fetch.empty }
            if await reference == Hub.head.origin(repository.url) {
                return false // nothing to do
            } else {
                let have = Hub.content.objects(repository.url).reduce(into: "") { $0 += "0032have \($1)\n" }
                // dbg("pull having:", have)
                let pack = try await self.rest.pull(Hub.head.remote(repository.url), want: reference, have: have)
                try await pack.unpack(repository.url)
                if try await repository.merger.needs(reference) {
                    try await repository.check.merge(reference)
                    try await repository.stage.merge(reference)
                } else {
                    try await repository.check.check(reference)
                    try await Hub.head.update(repository.url, id: reference)
                }
                try Hub.head.origin(repository.url, id: reference)
                return true
            }
        }

        func push(_ repository: Repository) async throws {
            let fetch = try await rest.uploadPush(Hub.head.remote(repository.url))
            guard let current = try? await Hub.head.id(repository.url) else { throw Failure.Remote.empty }
            guard let reference = fetch.branch.first, reference != current else { return }
            try await repository.merger.known(reference)
            let pushed = try await self.rest.push(Hub.head.remote(repository.url), old: reference, new: current, pack: Pack.Maker(repository.url, from: current, to: reference).data)
            if pushed?.utf8String?.hasPrefix("000eunpack ok") == true {
                try Hub.head.origin(repository.url, id: current)
            } else {
                throw Failure.Remote.push
            }


        }

        func create(_ url: URL) async throws -> Repository {
            guard !(try await repository(url)) else {
                throw Failure.Repository.duplicating
            }
            let root = url.appendingPathComponent(".git")
            let objects = root.appendingPathComponent("objects")
            let refs = root.appendingPathComponent("refs")
            let head = root.appendingPathComponent("HEAD")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
            try FileManager.default.createDirectory(at: refs, withIntermediateDirectories: false)
            try FileManager.default.createDirectory(at: objects, withIntermediateDirectories: false)
            try Data("ref: refs/heads/master".utf8).write(to: head, options: .atomic)
            return try await open(url)
        }

        func delete(_ repository: Repository) throws {
            try FileManager.default.removeItem(at: repository.url.appendingPathComponent(".git"))
        }

        func repository(_ url: URL) async throws -> Bool {
            var d: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.appendingPathComponent(".git/refs").path, isDirectory: &d),
                  d.boolValue,
                  FileManager.default.fileExists(atPath: url.appendingPathComponent(".git/objects").path, isDirectory: &d),
                  d.boolValue else {
                return false
            }
            let reference = try await Hub.head.reference(url)

            if !reference.contains("refs") {
                return false
            }
            return true
        }
    }

    public struct Failure: LocalizedError {
        public struct Repository {
            public static let duplicating = Failure("This is already a repository.")
            public static let invalid = Failure("This is not a repository.")
        }

        public struct Index {
            public static let badHeader = Failure("Bad header in index file.")
        }

        public struct Parsing {
            public static let malformed = Failure("Unable to read file.")
        }

        public struct Press {
            public static let unreadable = Failure("Unable to read compressed file.")
        }

        public struct Tree {
            public static let unreadable = Failure("Unable to read tree.")
        }

        public struct Commit {
            public static let unreadable = Failure("Unable to read commit.")
            public static let empty = Failure("Nothing to commit.")
            public static let credentials = Failure("Username and Email need to be configured.")
            public static let message = Failure("Commit message can't be empty.")
            public static let ignored = Failure("Attemping to commit ignored file.")
            public static let none = Failure("Invalid url.")
        }

        public struct Add {
            public static let not = Failure("File does not exists.")
            public static let outside = Failure("File is not in project's directory.")
        }

        public struct User {
            public static let name = Failure("Invalid name.")
            public static let email = Failure("Invalid email.")
        }

        public struct Pack {
            public static let packNotFound = Failure("Pack file not found.")
            public static let invalidIndex = Failure("Index file for pack malformed.")
            public static let invalidPack = Failure("Pack file malformed.")
            public static let invalidDelta = Failure("Pack delta malformed.")
            public static let object = Failure("Unreadable pack object.")
            public static let size = Failure("Size not match.")
            public static let read = Failure("Can't read packed data.")
            public static let adler = Failure("Decompression checksum failed.")
        }

        public struct Fetch {
            public static let advertisement = Failure("Invalid advertisement.")
            public static let empty = Failure("No references in advertisement.")
        }

        public struct Request {
            public static let invalid = Failure("Invalid URL.")
            public static let empty = Failure("Empty response from server.")
            public static let auth = Failure("Couldn't authenticate to server, please review the url provided or your credentials.")
            public static let response = Failure("Invalid response from server.")
            public static let none = Failure("Couldn't find this resource or doesn't exists.")
        }

        public struct Remote {
            public static let none = Failure("No remote specified for this repository.")
            public static let changes = Failure("There are changes in the current repository. Commit or Revert them and try again.")
            public static let push = Failure("Failed sending changes to remote.")
            public static let empty = Failure("This repository is empty.")
            public static let already = Failure("There is already a repository in this directory.")
        }

        public struct Config {
            public static let none = Failure("Configuration file not found.")
        }

        public struct Merge {
            public static let common = Failure("These repositories are not compatible.")
            public static let unknown = Failure("Remote repository is different than local, try Pull before Push.")
        }

        public struct Diff {
            public static let unchanged = Failure("Couldn't find the requested file.")
        }

        public var errorDescription: String? { return string }
        private let string: String
        private init(_ string: String) { self.string = string }
    }

    public class Fetch {
        final class Pull: Fetch {
            init(_ data: Data) throws {
                super.init()
                var lines = String(decoding: data, as: UTF8.self).components(separatedBy: "\n")
                guard lines.count > 3, lines.removeFirst() == "001e# service=git-upload-pack", lines.removeLast() == "0000"
                else { throw Failure.Fetch.advertisement }
                lines.removeFirst()
                try lines.forEach {
                    guard $0.count > 44 else { throw Failure.Fetch.advertisement }
                    refs.append(Ref(branch: String($0.dropFirst(4).prefix(40)), name: String($0.dropFirst(4 + 40 + 1))))
                }
            }
        }

        final class Push: Fetch {
            init(_ data: Data) throws {
                super.init()
                var lines = String(decoding: data, as: UTF8.self).components(separatedBy: "\n")
                guard lines.count > 2 , lines.removeFirst() == "001f# service=git-receive-pack", lines.removeLast() == "0000"
                else { throw Failure.Fetch.advertisement }
                try lines.forEach {
                    guard $0.count > 48 else { throw Failure.Fetch.advertisement }
                    refs.append(Ref(branch: String($0.dropFirst(8).prefix(40)), name: String($0.dropFirst(8 + 40 + 1))))
                }
            }
        }

        final var refs = [Ref]()

        var branch: [String] {
            get {
                refs.map(\.branch)
            }
        }

        init() {

        }

        struct Ref {
            var branch: String
            var name: String = ""
        }
    }

    struct Head {
        func branch(_ url: URL) async throws -> String {
            return try await self.reference(url).replacingOccurrences(of: "refs/heads/", with: "")
        }

        func tree(_ url: URL) async throws -> Tree {
            return try await Tree(commit(url).tree, url: url)
        }

        func commit(_ url: URL) async throws -> Commit {
            return try await Commit(id(url), url: url)
        }

        func id(_ url: URL) async throws -> String {
            return String(decoding: try await Data(contentsOf: self.url(url)), as: UTF8.self).replacingOccurrences(of: "\n", with: "")
        }

        func update(_ url: URL, id: String) async throws {
            try await verify(url)
            try await Data(id.utf8).write(to: self.url(url), options: .atomic)
        }

        func verify(_ url: URL) async throws {
            let u = try await self.url(url).deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: u.path) {
                try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
            }
        }

        func url(_ url: URL) async throws -> URL {
            try await url.appendingPathComponent(".git/" + (reference(url)))
        }

        func reference(_ url: URL) async throws -> String {
            return try String(String(decoding: await Data(contentsOf: url.appendingPathComponent(".git/HEAD")), as:
                                        UTF8.self).dropFirst(5)).replacingOccurrences(of: "\n", with: "")
        }

        func origin(_ url: URL, id: String) throws {
            let remotes = url.appendingPathComponent(".git/refs/remotes/origin/")
            if !FileManager.default.fileExists(atPath: remotes.path) {
                try FileManager.default.createDirectory(at: remotes, withIntermediateDirectories: true)
            }
            try Data(id.utf8).write(to: remotes.appendingPathComponent("master"), options: .atomic)
        }

        func origin(_ url: URL) async -> String? {
            if let data = try? await Data(contentsOf: url.appendingPathComponent(".git/refs/remotes/origin/master")) {
                return String(decoding: data, as: UTF8.self)
            }
            return nil
        }

        func remote(_ url: URL) async throws -> String {
            guard let raw = try await Config(url).remote.first?.1.url else {
                throw Failure.Repository.invalid
            }

            return raw
        }

        func remote(_ url: URL) async throws -> URL {
            if let raw = try? await Config(url).remote.first?.1.url,
               let configURL = URL(string: raw) {
                return configURL
            } else {
                //dbg("error with url:", url.absoluteString)
                return url // FIXME: is this the right thing to return?
                //throw Failure.Repository.invalid
            }
        }
    }

    public struct History {
        private(set) var result = [Commit]()
        private(set) var map = [String: Commit]()
        private let url: URL

        init(_ url: URL) async throws {
            try await self.init(await Hub.head.id(url), url: url)
        }

        init(_ id: String, url: URL) async throws {
            self.url = url
            try await commits(id)
            result = map.values.sorted {
                if $0.author.date > $1.author.date {
                    return true
                } else if $0.author.date == $1.author.date {
                    return $0.parent.count > $1.parent.count
                }
                return false
            }
        }

        private mutating func commits(_ id: String) async throws {
            guard map[id] == nil else { return }
            let item = try await Commit(id, url: url)
            map[id] = item
            for parent in item.parent {
                try await commits(parent)
            }
        }
    }

    public struct Hub {
        public internal(set) static var session = Session()
        static let dispatch = Dispatch()
        static let content = Content()
        static let head = Head()
        static let factory = Factory()

        public static func repository(_ url: URL) async throws -> Bool {
            try await factory.repository(url)
        }

        public static func create(_ url: URL) async throws -> Repository {
            try await factory.create(url)
        }

        public static func open(_ url: URL) async throws -> Repository {
            try await factory.open(url)
        }

        public static func delete(_ repository: Repository) async throws {
            try factory.delete(repository)
        }

        public static func clone(_ remote: URL, local: URL) async throws {
            try await factory.clone(remote, local: local)
        }
    }

    public struct Ignore {
        private var contains = ["/.git/"]
        private var suffix = ["/.git"]

        init(_ url: URL) async {
            guard let data = try? await Data(contentsOf: url.appendingPathComponent(".gitignore")) else { return }
            String(decoding: data, as: UTF8.self).components(separatedBy: "\n").filter({ !$0.isEmpty }).forEach {
                switch $0.first {
                case "*":
                    suffix.append(String($0.dropFirst()))
                    contains.append({ $0.last == "/" ? $0 : $0 + "/" } (String($0.dropFirst())))
                case "/": suffix.append($0)
                default: suffix.append("/" + $0)
                }
                switch $0.last {
                case "*": contains.append({ $0.first == "/" ? $0 : "/" + $0 } (String($0.dropLast())))
                case "/": contains.append($0.first == "/" ? $0 : "/" + $0)
                default: contains.append(($0.first == "/" ? $0 : "/" + $0) + "/")
                }
            }
        }

        func url(_ url: URL) -> Bool {
            guard
                !url.hasDirectoryPath,
                !contains.contains(where: { url.path.contains($0) }),
                !suffix.contains(where: { url.path.hasSuffix($0) })
            else { return true }
            return false
        }
    }

    public struct Index {
        struct Entry {
            fileprivate(set) var created = Date()
            fileprivate(set) var modified = Date()
            fileprivate(set) var id = ""
            fileprivate(set) var url = URL(fileURLWithPath: "")
            fileprivate(set) var size = 0
            fileprivate(set) var device = 0
            fileprivate(set) var inode = 0
            fileprivate(set) var mode = 33188
            fileprivate(set) var user = 0
            fileprivate(set) var group = 0
            fileprivate(set) var conflicts = false
        }

        private(set) var id = ""
        private(set) var version = 2
        private(set) var entries = [Entry]()

        init() { }

        // TODO: @available(*, deprecated, message: "convert to throwing")
        init?(_ url: URL) async {
            guard
                let parse = try? await Parse(url: url.appendingPathComponent(".git/index")),
                "DIRC" == (try? parse.string()),
                let version = try? parse.number(),
                let count = try? parse.number(),
                let entries = try? (0 ..< count).map({ _ in try entry(parse, url: url) })
            else { return nil }
            parse.skipExtensions()
            id = (try? parse.hash()) ?? ""
            self.version = version
            self.entries = entries
        }

        init(url: URL) async throws {
            let parse = try await Parse(url: url.appendingPathComponent(".git/index"))
            guard try "DIRC" == parse.string() else {
                throw Failure.Index.badHeader
            }
            let version = try parse.number()
            let count = try parse.number()
            let entries = try (0 ..< count).map({ _ in try entry(parse, url: url) })

            parse.skipExtensions()
            id = try parse.hash()
            self.version = version
            self.entries = entries
        }

        mutating func entry(_ id: String, url: URL) async throws {
            var entry = Entry()
            entry.id = id
            entry.url = url
            entry.size = try await Data(contentsOf: url).count
            entries.removeAll(where: { $0.url.path == url.path })
            entries.append(entry)
        }

        func save(_ url: URL) throws {
            let serial = Serial()
            serial.string("DIRC")
            serial.number(UInt32(version))
            serial.number(UInt32(entries.count))
            entries.sorted(by: { $0.url.path.compare($1.url.path, options: .caseInsensitive) != .orderedDescending }).forEach {
                serial.date($0.created)
                serial.date($0.modified)
                serial.number(UInt32($0.device))
                serial.number(UInt32($0.inode))
                serial.number(UInt32($0.mode))
                serial.number(UInt32($0.user))
                serial.number(UInt32($0.group))
                serial.number(UInt32($0.size))
                serial.hex($0.id)
                serial.number(UInt8(0))

                let name = String($0.url.path.dropFirst(url.path.count + 1))
                var size = name.count
                serial.number(UInt8(size))
                serial.nulled(name)
                while (size + 7) % 8 != 0 {
                    serial.string("\u{0000}")
                    size += 1
                }
            }
            serial.hash()
            try serial.data.write(to: url.appendingPathComponent(".git/index"), options: .atomic)
        }

        private func entry(_ parse: Parse, url: URL) throws -> Entry {
            var entry = Entry()
            entry.created = try parse.date()
            entry.modified = try parse.date()
            entry.device = try parse.number()
            entry.inode = try parse.number()
            entry.mode = try parse.number()
            entry.user = try parse.number()
            entry.group = try parse.number()
            entry.size = try parse.number()
            entry.id = try parse.hash()
            entry.conflicts = try parse.conflict()
            entry.url = url.appendingPathComponent(try parse.name())
            return entry
        }
    }

    actor Merger {
        weak var repository: Repository?

        func setRepository(_ repository: Repository) {
            self.repository = repository
        }

        func needs(_ id: String) async throws -> Bool {
            guard let url = repository?.url, let local = try? await History(url), let remote = try? await History(id, url: url) else { return false }
            var same = false
            var index = 0
            let keys = Array(local.map.keys)
            while !same && index < keys.count {
                same = remote.map[keys[index]] != nil
                index += 1
            }
            if !same {
                throw Failure.Merge.common
            }
            return remote.map[try await Hub.head.id(url)] == nil && local.map[id] == nil
        }

        func known(_ id: String) async throws {
            guard let url = repository?.url, let history = try? await History(url) else { return }
            if history.map[id] == nil {
                throw Failure.Merge.unknown
            }
        }
    }

    public struct Pack {
        private enum Category: Int {
            case commit = 1
            case tree = 2
            case blob = 3
            case tag = 4
            case reserved = 5
            case deltaOfs = 6
            case deltaRef = 7
        }

        struct Maker {
            var data: Data { return serial.data }
            private var commits = [String: Commit]()
            private var trees = [String: Tree]()
            private var blobs = [String: Data]()
            private let url: URL
            private let to: String?
            private let serial = Serial()

            init(_ url: URL, from: String, to: String? = nil) async throws {
                self.url = url
                self.to = to
                try await commit(from)
                serial.string("PACK")
                serial.number(UInt32(2))
                serial.number(UInt32(commits.count + trees.count + blobs.count))
                try commits.values.forEach { try add(.commit, data: Data($0.serial.utf8)) }
                try trees.values.forEach { try add(.tree, data: $0.serial) }
                try blobs.values.forEach { try add(.blob, data: $0) }
                serial.hash()
            }

            private mutating func commit(_ id: String) async throws {
                let item = try await Commit(id, url: url)
                commits[id] = item
                for child in item.parent.filter({ $0 != to }) {
                    try await commit(child)
                }
                try await tree(item.tree)
            }

            private mutating func tree(_ id: String) async throws {
                let item = try await Tree(id, url: url)
                trees[id] = item
                for child in item.items {
                    try await child.category == .tree ? tree(child.id) : blob(child.id)
                }
            }

            private mutating func blob(_ id: String) async throws {
                try blobs[id] = await Hub.content.get(id, url: url).drop(while: { String(decoding: [$0], as: UTF8.self) != "\u{0000}" }).dropFirst()
            }

            private func add(_ category: Category, data: Data) throws {
                var count = data.count
                var byte = UInt8(0)
                var next = false
                if count > 15 {
                    byte = 1
                    next = true
                }
                byte <<= 3
                byte += UInt8(category.rawValue)
                byte <<= 4
                byte += UInt8(count & 15)
                count >>= 4
                serial.number(byte)
                while next {
                    if count >= 128 {
                        byte = 1
                    } else {
                        byte = 0
                        next = false
                    }
                    byte <<= 7
                    byte += UInt8(count & 127)
                    count >>= 7
                    serial.number(byte)
                }
                try serial.compress(data)
            }
        }

        static func pack(_ url: URL) async throws -> [String: Pack] {
            var result = [String: Pack]()
            if FileManager.default.fileExists(atPath: url.appendingPathComponent(".git/objects/pack").path) {
                for file in try FileManager.default.contentsOfDirectory(at: url.appendingPathComponent(".git/objects/pack"), includingPropertiesForKeys: nil) {
                    if file.lastPathComponent.hasSuffix(".pack") {
                        let id = String(file.lastPathComponent.dropFirst(5).dropLast(5))
                        result[id] = try await Pack(url, id: id)
                    }
                }
            }
            return result
        }

        private(set) var commits = [String: (commit: Commit, index: Int, data: Data)]()
        private(set) var trees = [String: (tree: Tree, index: Int, data: Data)]()
        private(set) var blobs = [String: (index: Int, data: Data)]()
        private(set) var tags = [String]()
        private var deltas = [(String, data: Data, Int)]()
        private var offsets = [(Int, data: Data, Int)]()

        init(_ url: URL, id: String) async throws {
            guard let data = try? await Data(contentsOf: url.appendingPathComponent(".git/objects/pack/pack-\(id).pack"))
            else { throw Failure.Pack.packNotFound }
            try self.init(data)
        }

        init(_ data: Data) throws {
            let parse = Parse(data)
            // https://git-scm.com/docs/pack-format
            try parse.discard("PACK")
            parse.discard(4) // 4-byte version number (network byte order)
            let count = try parse.number() // 4-byte number of objects contained in the pack (network byte order)

            for _ in 0..<count {
                let index = parse.index
                let byte = Int(try parse.byte())
                guard let category = Category(rawValue: (byte >> 4) & 7) else {
                    throw Failure.Pack.object
                }

                var expected = byte & 15
                if byte >= 128 {
                    expected = try parse.size(expected, shift: 4)
                }

                var ref = ""
                var ofs = 0

                switch category {
                case .deltaRef: ref = try parse.hash()
                case .deltaOfs: ofs = index - (try parse.offset())
                default: break
                }

                let content = try Data.unpack(expected, data: parse.data.subdata(in: parse.index ..< parse.data.count))
                parse.discard(content.index)

                switch category {
                case .commit: try commit(content.result, index: index)
                case .tree: try tree(content.result, index: index)
                case .blob: blob(content.result, index: index)
                case .tag: tag(content.result)
                case .deltaRef: deltas.append((ref, content.result, index))
                case .deltaOfs: offsets.append((ofs, content.result, index))
                case .reserved: throw Failure.Pack.invalidPack
                }
            }

            guard parse.data.count - parse.index == 20 else {
                throw Failure.Pack.invalidPack
            }
            for d in deltas {
                try delta(d.0, data: d.data, index: d.2)
            }
            for o in offsets {
                try delta(o.0, data: o.data, index: o.2)
            }
        }

        func unpack(_ url: URL) async throws {
            for commit in commits {
                try await Hub.content.add(commit.1.0, url: url)
            }
            for tree in trees {
                try await Hub.content.add(tree.1.0, url: url)
            }
            for blob in blobs {
                try await Hub.content.add(blob.1.1, url: url)
            }
        }

        func remove(_ url: URL, id: String) throws {
            try FileManager.default.removeItem(at: url.appendingPathComponent(".git/objects/pack/pack-\(id).idx"))
            try FileManager.default.removeItem(at: url.appendingPathComponent(".git/objects/pack/pack-\(id).pack"))
        }

        private mutating func commit(_ data: Data, index: Int) throws {
            let commit = try Commit(data)
            commits[Hash.commit(commit.serial).1] = (commit, index, data)
        }

        private mutating func tree(_ data: Data, index: Int) throws {
            trees[Hash.tree(data).1] = (try Tree(data), index, data)
        }

        private mutating func blob(_ data: Data, index: Int) {
            blobs[Hash.blob(data).1] = (index, data)
        }

        private mutating func tag(_ data: Data) {
            tags.append(String(decoding: data, as: UTF8.self))
        }

        private mutating func delta(_ ref: String, data: Data, index: Int) throws {
            if let commit = commits.first(where: { $0.0 == ref })?.1.2 {
                try delta(.commit, base: commit, data: data, index: index)
            } else if let tree = trees.first(where: { $0.0 == ref })?.1.2 {
                try delta(.tree, base: tree, data: data, index: index)
            } else if let blob = blobs.first(where: { $0.0 == ref })?.1.1 {
                try delta(.blob, base: blob, data: data, index: index)
            } else {
                throw Failure.Pack.invalidDelta
            }
        }

        private mutating func delta(_ ofs: Int, data: Data, index: Int) throws {
            if let commit = commits.first(where: { $0.1.1 == ofs })?.1.2 {
                try delta(.commit, base: commit, data: data, index: index)
            } else if let tree = trees.first(where: { $0.1.1 == ofs })?.1.2 {
                try delta(.tree, base: tree, data: data, index: index)
            } else if let blob = blobs.first(where: { $0.1.0 == ofs })?.1.1 {
                try delta(.blob, base: blob, data: data, index: index)
            } else {
                throw Failure.Pack.invalidDelta
            }
        }

        private mutating func delta(_ category: Category, base: Data, data: Data, index: Int) throws {
            let parse = Parse(data)
            var result = Data()
            guard try parse.size() == base.count else { throw Failure.Pack.invalidDelta }
            let expected = try parse.size()
            while parse.index < data.count {
                let byte = Int(try parse.byte())
                if byte >= 128 {
                    var offset = 0
                    var shift = 0
                    try (0 ..< 4).forEach {
                        offset += (byte >> $0) & 0x01 == 1 ? Int(try parse.byte()) << shift : 0
                        shift += 8
                    }
                    var size = 0
                    shift = 0
                    try (4 ..< 7).forEach {
                        size += (byte >> $0) & 0x01 == 1 ? Int(try parse.byte()) << shift : 0
                        shift += 8
                    }
                    if size == 0 { size = 65536 }
                    result += base.subdata(in: offset ..< offset + size)
                } else {
                    result += try parse.advance(byte)
                }
            }
            guard result.count == expected else { throw Failure.Pack.invalidDelta }
            switch category {
            case .commit: try commit(result, index: index)
            case .tree: try tree(result, index: index)
            case .blob: blob(result, index: index)
            default: throw Failure.Pack.invalidDelta
            }
        }
    }


    actor Packer {
        weak var repository: Repository?

        func setRepository(_ repository: Repository) {
            self.repository = repository
        }

        var packed: Bool {
            if let url = repository?.url {
                if (try? FileManager.default.contentsOfDirectory(at: url.appendingPathComponent(".git/objects/pack/"), includingPropertiesForKeys: nil))?.first( where: { $0.pathExtension == "pack" }) != nil {
                    return true
                }
                if FileManager.default.fileExists(atPath: url.appendingPathComponent(".git/packed-refs").path) {
                    return true
                }
            }
            return false
        }

        func unpack() async throws {
            guard let url = repository?.url else { return }
            for (name, pack) in try await Pack.pack(url) {
                try await pack.unpack(url)
                try pack.remove(url, id: name)
            }
            try await references()

            if let tree = try? await Hub.head.tree(url) {
                var index = Index()
                try await tree.map(&index, url: url)
                try index.save(url)
            }
        }

        private func references() async throws {
            guard let url = repository?.url, FileManager.default.fileExists(atPath: url.appendingPathComponent(".git/packed-refs").path) else { return }
            try String(decoding: await Data(contentsOf: url.appendingPathComponent(".git/packed-refs")), as: UTF8.self).components(separatedBy: "\n").forEach {
                if $0.first != "#" {
                    let reference = $0.components(separatedBy: " ")
                    guard reference.count >= 2 else { return }
                    let location = url.appendingPathComponent(".git/" + reference[1])
                    if !FileManager.default.fileExists(atPath: location.deletingLastPathComponent().path) {
                        try FileManager.default.createDirectory(at: location.deletingLastPathComponent(), withIntermediateDirectories: true)
                    }
                    try Data(reference[0].utf8).write(to: location, options: .atomic)
                }
            }
            try FileManager.default.removeItem(at: url.appendingPathComponent(".git/packed-refs"))
        }
    }

    private final class Parse {
        let data: Data
        private(set) var index = 0

        init(url: URL) async throws {
            self.data = try await Data(contentsOf: url)
        }

        init(_ data: Data) {
            self.data = data
        }

        func ascii(_ limiter: String) throws -> String {
            var result = ""
            var character = ""
            while character != limiter {
                result += character
                character = try self.character()
            }
            return result
        }

        func variable() throws -> String {
            var result = ""
            var byte = ""
            repeat {
                result += byte
                byte = try character()
            } while byte != "\u{0000}"
            return result
        }

        func name() throws -> String {
            return try {
                discard($0 ? 4 : 2)
                let result = String(decoding: try advance($1), as: UTF8.self)
                clean()
                return result
            } (try not2(), try length())
        }

        func discard(_ until: String) throws {
            while String(decoding: try advance(until.count), as: UTF8.self) != until {
                index -= until.count - 1
            }
        }

        func byte() throws -> UInt8 {
            if let b = try advance(1).first {
                return b
            }
            throw Failure.Parsing.malformed
        }

        func string() throws -> String {
            String(decoding: try advance(4), as: UTF8.self)
        }

        func character() throws -> String {
            String(decoding: try advance(1), as: UTF8.self)
        }

        func hash() throws -> String {
            (try advance(20)).map { String(format: "%02hhx", $0) }.joined()
        }

        func skipExtensions() {
            discard((data.count - 20) - index)
        }

        func decompress(_ amount: Int) throws -> Data {
            try advance(amount).decompress()
        }

        func discard(_ bytes: Int) {
            index += bytes
        }

        func number() throws -> Int {
            if let result = Int(try advance(4).map { String(format: "%02hhx", $0) }.joined(), radix: 16) {
                return result
            }
            throw Failure.Parsing.malformed
        }

        func date() throws -> Date {
            let result = Date(timeIntervalSince1970: TimeInterval(try number()))
            discard(4)
            return result
        }

        func conflict() throws -> Bool {
            var byte = data.subdata(in: index ..< index + 1).first!
            byte >>= 2
            if (byte & 0x01) == 1 {
                return true
            }
            byte >>= 1
            if (byte & 0x01) == 1 {
                return true
            }
            return false
        }

        func size(_ carry: Int = 0, shift: Int = 0) throws -> Int {
            var byte = 0
            var result = carry
            var shift = shift
            repeat {
                byte = Int(try self.byte())
                result += (byte & 127) << shift
                shift += 7
            } while byte >= 128
            return result
        }

        func offset() throws -> Int {
            var byte = 0
            var result = 0
            var times = 0
            repeat {
                byte = Int(try self.byte())
                if times > 0 {
                    result <<= 7
                }
                result += (byte & 127)
                times += 1
            } while byte >= 128
            if times > 1 {
                (1 ..< times).forEach {
                    result += Int(pow(2, (7 * Double($0))))
                }
            }
            return result
        }

        func advance(_ bytes: Int) throws -> Data {
            let index = self.index + bytes
            guard data.count >= index else { throw Failure.Parsing.malformed }
            let result = data.subdata(in: self.index ..< index)
            self.index = index
            return result
        }

        private func clean() {
            while (String(decoding: data.subdata(in: index ..< index + 1), as: UTF8.self) == "\u{0000}") { discard(1) }
        }

        private func not2() throws -> Bool {
            var byte = data.subdata(in:
                                        index ..< index + 1).withUnsafeBytes { $0.baseAddress!.bindMemory(to: UInt8.self, capacity: 1).pointee }
            byte >>= 1
            return (byte & 0x01) == 1
        }

        private func length() throws -> Int {
            guard let result = Int(data.subdata(in: index + 1 ..< index + 2).map { String(format: "%02hhx", $0) }.joined(),
                                   radix: 16) else { throw Failure.Parsing.malformed }
            return result
        }
    }

    public actor Repository {
        public typealias StatusCallback = (([(URL, Status)]) throws -> Void)
        public var status: StatusCallback?
        public let url: URL
        let state = State()
        let stage = Stage()
        let check = Check()
        let merger = Merger()
        let packer = Packer()
        let differ = Differ()

        init(_ url: URL) async {
            self.url = url
            await state.setRepository(self)
            await stage.setRepository(self)
            await check.setRepository(self)
            await merger.setRepository(self)
            await packer.setRepository(self)
            await differ.setRepository(self)
        }

        func setStatus(callback: @escaping StatusCallback) {
            self.status = callback
        }

        public func commit(_ files: [URL], message: String) async throws {
            try await refreshing { try await self.stage.commit(files, message: message) }
        }

        @discardableResult public func pull() async throws -> Bool {
            try await refreshing { try await Hub.factory.pull(self) }
        }

        public func push() async throws {
            try await refreshing { try await Hub.factory.push(self) }
        }

        public func log() async throws -> [Commit] {
            try await History(self.url).result
        }

        public func reset() async throws {
            try await refreshing { try await check.reset() }
        }

        public func check(_ id: String) async throws {
            try await refreshing { try await self.check.check(id) }
        }

        public func unpack() async throws {
            try await refreshing { try await self.packer.unpack() }
        }

        public func packed() async throws -> Bool {
            await self.packer.packed
        }

        public func branch() async throws -> String {
            try await Hub.head.branch(url)
        }

        public func remote() async throws -> String {
            try await Hub.head.remote(url)
        }

        public func remote(_ remote: String) throws {
            try Config(remote).save(url)
        }

        public func previous(_ url: URL) async throws -> (Date, Data)? {
            try await self.differ.previous(url)
        }

        public func timeline(_ url: URL) async throws -> [(Date, Data)] {
            try await self.differ.timeline(url)
        }

        /// Performs the given block and refresh afterwards
        func refreshing<T>(_ block: () async throws -> T) async throws -> T {
            let result = try await block()
            try await refresh()
            return result
        }

        internal func refresh() async throws {
            try await state.refresh()
        }
    }

    public class Rest: NSObject, URLSessionTaskDelegate {
        private var session: URLSession!

        override init() {
            super.init()
            session = URLSession(configuration: .ephemeral, delegate: self, delegateQueue: OperationQueue())
        }

        public func urlSession(_: URLSession, task: URLSessionTask, didReceive: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            completionHandler(.useCredential, didReceive.previousFailureCount == 0 ? Hub.session.credentials : nil)
        }

        func req(_ url: URL, timeout: TimeInterval = 90) -> URLRequest {
            URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeout)
        }

        private func gitreq(_ request: URLRequest) async throws -> Data {
            try await prf(msg: { data in "fetch \(request) \(request.allHTTPHeaderFields ?? [:]) size: \(data)" }) {
                do {
                    return try await session.fetch(request: request, validate: [200, 201]).data
                } catch {
                    dbg("error fetching:", request, request.allHTTPHeaderFields, error, (error as? LocalizedError)?.localizedDescription)
                    throw error
                }
            }
        }

        /// Requests the given endpoint with the default request parameters.
        func fetch(_ url: URL) async throws -> Data {
            try await validate(data: gitreq(req(url)))
        }

        /// Requests the given endpoint with the default request parameters.
        func fetch(_ urlRequest: URLRequest) async throws -> Data {
            try await gitreq(urlRequest)
        }

        func req(url: URL, upload: Bool, body: Data) -> URLRequest {
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 90)
            request.httpMethod = "POST"
            request.setValue(upload ? "application/x-git-upload-pack-request" : "application/x-git-receive-pack-request", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            return request
        }

        private func serviceURL(_ url: URL, path: String = "info/refs", service: String? = nil) -> URL {
            let url = url.appendingPathComponent(path)
            if let service = service {
                // https://git-scm.com/docs/gitprotocol-http#_smart_clients
                // “The request MUST contain exactly one query parameter, service=$servicename, where $servicename MUST be the service name the client wishes to contact to complete the operation. The request MUST NOT contain additional query parameters.”
                // return url.appending(queryItems: [URLQueryItem(name: "service", value: service)])
                return URL(string: url.absoluteString + "?service=" + service) ?? url
            } else {
                return url
            }
        }

        private func validate(data: Data?) throws -> Data {
            if let data = data, !data.isEmpty {
                return data
            } else {
                throw Failure.Request.empty
            }
        }

        func downloadPull(_ remote: URL) async throws -> Fetch {
            try await Fetch.Pull(fetch(serviceURL(remote, service: "git-upload-pack")))
        }

        func uploadPush(_ remote: URL) async throws -> Fetch {
            try await Fetch.Push(fetch(serviceURL(remote, service: "git-receive-pack")))
        }

        func pull(_ remote: URL, want: String, have: String = "") async throws -> Pack {
            try await Pack(fetch(req(url: serviceURL(remote, path: "git-upload-pack"), upload: true, body: """
                0032want \(want)
                0000\(have)0009done

                """.utf8Data)))
        }

        func push(_ remote: URL, old: String, new: String, pack: Data) async throws -> Data! {
            try await fetch(req(url: serviceURL(remote, path: "git-receive-pack"), upload: false, body: """
                0077\(old) \(new) refs/heads/master\0 report-status
                0000

                """.utf8Data + pack))
        }

        //@available(*, deprecated)
        func url(_ remote: String, suffix: String) throws -> URL {
            guard !remote.isEmpty, !remote.hasPrefix("http://"), !remote.hasPrefix("https://"), remote.hasSuffix(".git"),
                  let remote = remote.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
                  let url = URL(string: "https://" + remote + suffix)
            else { throw Failure.Request.invalid }
            return url
        }
    }

    final class Serial {
        private(set) var data = Data()
        private static let map = [
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, // 01234567
            0x08, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 89:;<=>?
            0x00, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x00, // @ABCDEFG
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00  // HIJKLMNO
        ] as [UInt8]

        func date(_ date: Date) {
            number(UInt32(date.timeIntervalSince1970))
            number(UInt32(0))
        }

        func hex(_ string: String) {
            data.append(contentsOf: string.utf8.reduce(into: ([UInt8](), [UInt8]())) {
                $0.0.append(Serial.map[Int($1 & 0x1F ^ 0x10)])
                if $0.0.count == 2 {
                    $0.1.append($0.0[0] << 4 | $0.0[1])
                    $0.0 = []
                }
            }.1)
        }

        func compress(_ data: Data) throws { try self.data.append(Data.compress(data, level: compressionLevel)) }
        func serial(_ serial: Serial) { data.append(serial.data) }
        func nulled(_ string: String) { self.string(string + "\u{0000}") }
        func string(_ string: String) { data.append(contentsOf: string.utf8) }
        func number<T: BinaryInteger>(_ number: T) { withUnsafeBytes(of: number) { data.append(contentsOf: $0.reversed()) } }
        func hash() { data.append(contentsOf: Hash.digest(data)) }
    }

    public final class Session: Codable {
        public internal(set) var url = URL(fileURLWithPath: "")
        public internal(set) var bookmark = Data()
        public internal(set) var name = ""
        public internal(set) var email = ""
        public internal(set) var user = ""
        public internal(set) var password: String = ""

#if canImport(Security)
        public internal(set) var passwordKeychain: String {
            get { return recover ?? "" }
            set {
                if recover == nil {
                    var query = self.query
                    query[kSecValueData as String] = Data(newValue.utf8)
                    SecItemAdd(query as CFDictionary, nil)
                } else {
                    SecItemUpdate(query as CFDictionary, [kSecValueData: Data(newValue.utf8)] as CFDictionary)
                }
            }
        }

        private var recover: String? {
            var result: CFTypeRef? = [String: Any]() as CFTypeRef
            var query = self.query
            query[kSecReturnData as String] = true
            query[kSecReturnAttributes as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            SecItemCopyMatching(query as CFDictionary, &result)
            if let data = (result as? [String: Any])?[String(kSecValueData)] as? Data {
                return String(decoding: data, as: UTF8.self)
            }
            return nil
        }

        private var query: [String: Any] {
            return [kSecClass: kSecClassGenericPassword, kSecAttrKeyType: 42, kSecAttrAccount: "user.key", kSecAttrService: "Git"] as [String: Any]
        }
#endif

        var credentials: URLCredential? {
            return URLCredential(user: user, password: password, persistence: .forSession)
        }

        public func load() async throws {
            guard let data = UserDefaults.standard.data(forKey: "session"),
                  let decoded = try? JSONDecoder().decode(Session.self, from: data)
                else {
                return dbg("no session to load")
            }
            self.name = decoded.name
            self.email = decoded.email
            self.url = decoded.url
            self.bookmark = decoded.bookmark
            self.user = decoded.user
        }

        public func update(_ name: String, email: String) async throws {
            guard !name.isEmpty else { throw Failure.User.name }

            try name.forEach {
                switch $0 {
                case "<", ">", "\n", "\t": throw Failure.User.name
                default: break
                }
            }

            try email.forEach {
                switch $0 {
                case " ", "*", "\\", "/", "$", "%", ";", ",", "!", "?", "~", "<", ">", "\n", "\t": throw Failure.User.email
                default: break
                }
            }

            let at = email.components(separatedBy: "@")
            let dot = at.last!.components(separatedBy: ".")
            guard at.count == 2, !at.first!.isEmpty, dot.count > 1, !dot.first!.isEmpty, !dot.last!.isEmpty
            else { throw Failure.User.email }

            self.name = name
            self.email = email
            try self.save()
        }

        public func update(_ user: String, password: String) async throws {
            self.user = user
            self.password = password
            try self.save()
        }

        public func update(_ url: URL, bookmark: Data) async throws {
            self.url = url
            self.bookmark = bookmark
            try self.save()
        }

        func save() throws {
            UserDefaults.standard.set(try JSONEncoder().encode(self), forKey: "session")
        }
    }

    actor Stage {
        weak var repository: Repository?

        func setRepository(_ repository: Repository) {
            self.repository = repository
        }

        func commit(_ files: [URL], message: String) async throws {
            guard let url = repository?.url, let list = try await repository?.state.list else { return }
            guard !files.isEmpty else { throw Failure.Commit.empty }
            guard !Hub.session.name.isEmpty else { throw Failure.Commit.credentials }
            guard !Hub.session.email.isEmpty else { throw Failure.Commit.credentials }
            guard !message.isEmpty else { throw Failure.Commit.message }
            try files.forEach { file in
                if !list.contains(where: { $0.0.path == file.path }) {
                    throw Failure.Commit.none
                }
            }
            var index = await Index(url) ?? Index()
            let ignore = await Ignore(url)
            let tree = try await Tree(url, ignore: ignore, update: files, entries: index.entries)
            let treeId = try await tree.save(url)
            for file in files {
                guard !ignore.url(file) else { throw Failure.Commit.ignored }
                try await add(file, index: &index)
            }
            var commit = Commit()
            commit.author.name = Hub.session.name
            commit.author.email = Hub.session.email
            commit.committer.name = Hub.session.name
            commit.committer.email = Hub.session.email
            commit.tree = treeId
            commit.message = message
            if let parent = try? await Hub.head.id(url) {
                commit.parent.append(parent)
            }
            try await Hub.head.update(url, id: Hub.content.add(commit, url: url))
            try index.save(url)
        }

        func merge(_ id: String) async throws {
            guard let url = repository?.url,
                    let files = try await repository?.state.list.map({ $0.0 }) else {
                return
            }
            guard !Hub.session.name.isEmpty else { throw Failure.Commit.credentials }
            guard !Hub.session.email.isEmpty else { throw Failure.Commit.credentials }
            var index = await Index(url) ?? Index()
            let ignore = await Ignore(url)
            let tree = try await Tree(url, ignore: ignore, update: files, entries: index.entries)
            let treeId = try await tree.save(url)
            for file in files {
                guard !ignore.url(file) else { throw Failure.Commit.ignored }
                try await add(file, index: &index)
            }
            var commit = Commit()
            commit.author.name = Hub.session.name
            commit.author.email = Hub.session.email
            commit.committer.name = Hub.session.name
            commit.committer.email = Hub.session.email
            commit.tree = treeId
            commit.message = "Merge.\n"
            commit.parent.append(try await Hub.head.id(url))
            commit.parent.append(id)
            try await Hub.head.update(url, id: Hub.content.add(commit, url: url))
            try index.save(url)
        }

        func add(_ file: URL, index: inout Index) async throws {
            guard let url = repository?.url else { return }
            guard file.path.contains(url.path) else { throw Failure.Add.outside }
            guard FileManager.default.fileExists(atPath: file.path) else { throw Failure.Add.not }
            let hash = try await Hub.content.add(file, url: url)
            try await index.entry(hash, url: file)
        }
    }

    public enum Status {
        case untracked
        case added
        case modified
        case deleted
    }

    actor State {
        weak var repository: Repository?
        var last = Date.distantPast

        init() {
        }

        func setRepository(_ repository: Repository) {
            self.repository = repository
        }

        func touch(date: Date = Date()) {
            self.last = date
        }

        func refresh() async throws {
            if self.needs == true {
                try await self.handle(changes: self.list)
            }
        }

        func handle(changes: [(URL, Git.Status)]) async throws {
            try await self.repository?.status?(changes)
        }

        var needs: Bool {
            guard let url = repository?.url else { return false }
            if let modified = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date,
               modified > last { return true }
            return modified([url])
        }

        // TODO: @available(*, deprecated, message: "convert to function")
        var list: [(URL, Status)] {
            get async throws {
                guard let url = repository?.url else { return [] }
                last = Date()
                return try await list((try? Hub.head.tree(url)))
            }
        }

        func list(_ tree: Tree?) async throws -> [(URL, Status)] {
            guard let url = repository?.url else { return [] }
            let contents = await self.contents
            let index = await Index(url)
            var tree = await tree?.list(url) ?? []
            return try await contents.reduceAsync(into: [(URL, Status)]()) { result, url in
                if let entries = index?.entries.filter({ $0.url == url }), !entries.isEmpty {
                    let hash = try await Hash.file(url).1
                    if entries.contains(where: { $0.id == hash }) {
                        if !tree.contains(where: { $0.id == hash }) {
                            result.append((url, .added))
                        }
                    } else {
                        result.append((url, .modified))
                    }
                    tree.removeAll { $0.url == url }
                } else {
                    result.append((url, .untracked))
                }
            } + tree.map({ ($0.url, .deleted) })
        }

        private var contents: [URL] {
            get async {
                guard let url = repository?.url else { return [] }
                let ignore = await Ignore(url)
                return FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil)?
                    .map({ ($0 as! URL).resolvingSymlinksInPath() })
                    .filter({ !ignore.url($0) })
                    .sorted(by: { $0.path.compare($1.path, options: .caseInsensitive) != .orderedDescending }) ?? []
            }
        }

        private func modified(_ urls: [URL]) -> Bool {
            var urls = urls
            guard
                !urls.isEmpty,
                let contents = try? FileManager.default.contentsOfDirectory(at: urls.first!, includingPropertiesForKeys:
                                                                                [.contentModificationDateKey])
            else { return false }
            for item in contents {
                if item.hasDirectoryPath {
                    if let modified = try? item.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                       modified > last {
                        return true
                    }
                }
                urls.append(item)
            }
            return modified(Array(urls.dropFirst()))
        }
    }

    public struct Tree {
        enum Category: String {
            case blob = "100644"
            case exec = "100755"
            case tree = "40000"
            case unknown
        }

        struct Item {
            var id = ""
            var url = URL(fileURLWithPath: "")
            var category = Category.unknown
        }

        private(set) var items = [Item]()
        private(set) var children = [String: Tree]()

        init(_ id: String, url: URL, trail: URL? = nil) async throws {
            try self.init(await Hub.content.get(id, url: url), url: trail ?? url)
        }

        init(_ data: Data, url: URL) throws {
            let parse = Parse(data)
            guard "tree" == (try? parse.ascii(" ")) else { throw Failure.Tree.unreadable }
            _ = try parse.variable()
            try self.init(parse, url: url)
        }

        init(_ data: Data) throws {
            try self.init(Parse(data), url: URL(fileURLWithPath: ""))
        }

        init(_ url: URL, ignore: Ignore, update: [URL], entries: [Index.Entry]) async throws {
            for file in try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                let content = file.resolvingSymlinksInPath()
                if content.hasDirectoryPath {
                    let child = try await Tree(content, ignore: ignore, update: update, entries: entries)
                    if !child.items.isEmpty {
                        var item = Item()
                        item.category = .tree
                        item.url = content
                        item.id = Hash.tree(child.serial).1
                        items.append(item)
                        children[item.id] = child
                    }
                } else if !ignore.url(content) {
                    if update.contains(where: { $0.path == content.path }) {
                        var item = Item()
                        item.category = .blob
                        item.url = content
                        item.id = try await Hash.file(content).1
                        items.append(item)
                    } else if let entry = entries.first(where: { $0.url.path == content.path }) {
                        var item = Item()
                        item.category = .blob
                        item.url = entry.url
                        item.id = entry.id
                        items.append(item)
                    }
                }
            }
        }

        init() { }

        private init(_ parse: Parse, url: URL) throws {
            while parse.index < parse.data.count {
                var item = Item()
                item.category = Category(rawValue: try parse.ascii(" ")) ?? .unknown
                item.url = url.appendingPathComponent(try parse.variable())
                item.id = try parse.hash()
                items.append(item)
            }
        }

        func list(_ url: URL) async -> [Item] {
            await items.flatMapAsync {
                await $0.category != .tree ? [$0] : (try? await Tree($0.id, url: url, trail: $0.url))?.list(url) ?? []
            }
        }

        func map(_ index: inout Index, url: URL) async throws {
            for item in items {
                if item.category == .tree {
                    try await Tree(item.id, url: url, trail: item.url).map(&index, url: url)
                } else {
                    try await index.entry(item.id, url: item.url)
                }
            }
        }

        @discardableResult func save(_ url: URL) async throws -> String {
            for child in children.values {
                try await child.save(url)
            }
            return try await Hub.content.add(self, url: url)
        }

        var serial: Data {
            let serial = Serial()
            items.sorted(by: {
                let left = $0.url.lastPathComponent + ($0.category == .tree ? "/" : "")
                let right = $1.url.lastPathComponent + ($1.category == .tree ? "/" : "")
                return left.compare(right) != .orderedDescending
            }).forEach {
                serial.string($0.category.rawValue + " ")
                serial.nulled($0.url.lastPathComponent)
                serial.hex($0.id)
            }
            return serial.data
        }
    }

    public struct User {
        public internal(set) var name = ""
        public internal(set) var email = ""
        public internal(set) var date = Date()
        var timezone = ""

        init() { }

        init(_ string: String) throws {
            let first = string.components(separatedBy: " <")
            let second = first.last?.components(separatedBy: "> ")
            let third = second?.last?.components(separatedBy: " ")
            guard
                first.count == 2,
                second?.count == 2,
                third?.count == 2,
                let names = first.first?.components(separatedBy: " "),
                names.count > 1,
                let seconds = TimeInterval(third![0])
            else { throw Failure.Commit.unreadable }
            name = names.dropFirst().joined(separator: " ")
            email = second![0]
            date = Date(timeIntervalSince1970: seconds)
            timezone = third![1]
        }

        var serial: String { return "\(name) <\(email)> \(Int(date.timeIntervalSince1970)) " + (timezone.isEmpty ? {
            $0.dateFormat = "xx"
            return $0.string(from: date)
        } (DateFormatter()) : timezone) }
    }

    public enum Hash {
        static func digest(_ data: Data) -> Data {
            data.sha1()
        }

        static func file(_ url: URL) async throws -> (Data, String) {
            return blob(try await Data(contentsOf: url))
        }

        static func blob(_ data: Data) -> (Data, String) {
            let packed = "blob \(data.count)\u{0000}".utf8 + data
            return (packed, hash(packed))
        }

        static func tree(_ data: Data) -> (Data, String) {
            let packed = "tree \(data.count)\u{0000}".utf8 + data
            return (packed, hash(packed))
        }

        static func commit(_ serial: String) -> (Data, String) {
            return {
                let packed = "commit \($0.count)\u{0000}".utf8 + $0
                return (packed, hash(packed))
            } (Data(serial.utf8))
        }

        private static func hash(_ data: Data) -> String {
            digest(data).map { String(format: "%02hhx", $0) }.joined()
        }
    }
}


fileprivate extension URL {
    // TODO: @available(*, deprecated, message: "porting shim")
    func withoutProtocol() -> String {
        return String(self.absoluteString.components(separatedBy: "://").last ?? .init(self.absoluteString))
    }
}
