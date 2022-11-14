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
import FairApp

public struct JSONCommand : AsyncParsableCommand {
    public static let experimental = true
    public static var configuration = CommandConfiguration(commandName: "json",
                                                           abstract: "JSON manipulation tools.",
                                                           shouldDisplay: !experimental,
                                                           subcommands: [
                                                            SignCommand.self,
                                                            VerifyCommand.self,
                                                           ])

    public init() {
    }

    enum Errors : Error {
        case invalidBase64Key
        case missingSignatureProperty
    }

    public struct SignCommand: FairStructuredCommand {
        public static let experimental = false

        public typealias Output = JSum

        public static var configuration = CommandConfiguration(commandName: "sign",
                                                               abstract: "Adds a message authentication code to the given JSON.",
                                                               shouldDisplay: !experimental)

        @OptionGroup public var msgOptions: MsgOptions

        @Option(name: [.long], help: ArgumentHelp("The property in which the signature will be stored", valueName: "prop"))
        public var property: String = "signature"

        @Option(name: [.long], help: ArgumentHelp("The base64 encoding of the key", valueName: "key"))
        public var keyBase64: String

        //@Argument(help: ArgumentHelp("A string version of the key", valueName: "keystr", visibility: .default))
        //public var keyString: String?

        /// The JSON files (or standard input) to encode
        @Argument(help: ArgumentHelp("The input JSON to sign", valueName: "body", visibility: .default))
        public var inputs: [String]

        public init() { }

        private func keyData() throws -> Data {
            if let data = Data(base64Encoded: keyBase64) {
                //dbg(wip("####"), "KEY:", data.utf8String)
                return data
            }

            throw Errors.invalidBase64Key
        }

        public func executeCommand() async throws -> AsyncThrowingStream<JSum, Error> {
            warnExperimental(Self.experimental)

            return executeSeries(inputs, initialValue: nil) { input, prev in
                msg(.info, "signing input:", input)
                var json = try JSum(json: Data(contentsOf: URL(fileOrScheme: input)))
                json[property] = nil // clear the signature if it exists
                let sig = try json.sign(key: try keyData())
                json[property] = .str(sig.base64EncodedString()) // embed the signature into the JSON
                return json
            }
        }
    }

    public struct VerifyCommand: FairStructuredCommand {
        public static let experimental = false

        public typealias Output = [JSum]

        public static var configuration = CommandConfiguration(commandName: "verify",
                                                               abstract: "Verifies a message authentication code for the given JSON.",
                                                               shouldDisplay: !experimental)

        @OptionGroup public var msgOptions: MsgOptions

        @Option(name: [.long], help: ArgumentHelp("The property in which the signature will be stored", valueName: "prop"))
        public var property: String = "signature"

        @Option(name: [.long], help: ArgumentHelp("The base64 encoding of the key", valueName: "key"))
        public var keyBase64: String

        //@Argument(help: ArgumentHelp("A string version of the key", valueName: "keystr", visibility: .default))
        //public var keyString: String?

        /// The JSON files (or standard input) to encode
        @Argument(help: ArgumentHelp("The JSON file to verify", valueName: "file", visibility: .default))
        public var inputs: [String]

        public init() { }

        private func keyData() throws -> Data {
            if let data = Data(base64Encoded: keyBase64) {
                return data
            }

            throw Errors.invalidBase64Key
        }

        public func executeCommand() async throws -> AsyncThrowingStream<[JSum], Error> {
            warnExperimental(Self.experimental)

            return executeSeries(inputs, initialValue: nil) { input, prev in
                msg(.info, "verifying input:", input)
                let contents = try JSum(json: Data(contentsOf: URL(fileOrScheme: input)))
                // the payload can either be an object or an array of objects
                let jsons = contents.arr?.compactMap(\.obj) ?? contents.obj.map({ [$0 ]}) ?? []
                return try jsons.map {
                    var json = $0
                    guard let sig = json[property]?.str,
                          let sigData = Data(base64Encoded: sig) else {
                        throw Errors.missingSignatureProperty
                    }

                    json[property] = nil
                    let jobj = JSum.obj(json)
                    let resigned = try jobj.sign(key: keyData())
                    if resigned != sigData {
                        throw SignableError.signatureMismatch//(resigned, sigData)
                    }
                    return jobj // returns the validated JSON without the signature
                }
            }
        }
    }

}
