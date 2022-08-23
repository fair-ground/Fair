/**
 Copyright (c) 2015-2022 Marc Prud'hommeaux

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import Swift

/// A JSum is a Join Sum type, which is an enumeration that can represent one of:
///
/// - `JSum.bol`: `Bool`
/// - `JSum.str`: `String`
/// - `JSum.num`: `Double`
/// - `JSum.arr`: `Array<JSum>`
/// - `JSum.obj`: `Dictionary<String, JSum>`
/// - `JSum.nul`: `nil`
///
/// The type can be fluently represented with literals that closely match JSON, such as:
///
/// ```
/// let ob: JSum = [
///    "string": "hello",
///    "number": 1.23,
///    "null": nil,
///    "array": [1, nil, "foo"],
///    "object": [
///        "x": "a",
///        "y": 5,
///        "z": [:]
///    ]
/// ]
/// ```
///
/// JSum can be created by parsing JSON, YAML, or Property List sources.
@frozen public enum JSum : Hashable, Sendable {
    case arr([JSum]) // Array
    case obj(JObj) // Dictionary
    case str(String) // String
    case num(Double) // Number
    case bol(Bool) // Boolean
    case nul // Null
}

/// A `JObj` is the associated dictionary type for a `JSum.obj`, which is equivalent to a JSON "object".
public typealias JObj = [String: JSum]

extension JSum {
    public subscript(index: Int) -> JSum {
        get {
            assert(index >= 0)
            switch self {
            case .arr(let array):
                if array.indices.contains(index) {
                    return array[index]
                } else {
                    return .nul
                }
            default:
                return .nul
            }
        }
        set {
            assert(index >= 0)
            switch self {
            case .arr(let array):
                let emptyCount = max(0, index + 1 - array.count)
                let empty = [JSum](repeating: .nul, count: emptyCount)
                var new = array
                new.append(contentsOf: empty)
                new[index] = newValue
                self = .arr(new)
            default:
                var array = [JSum](repeating: .nul, count: index + 1)
                array[index] = newValue
                self = .arr(array)
            }
        }
    }

    public subscript(key: JObj.Key) -> JSum {
        get {
            switch self {
            case .obj(let dictionary):
                return dictionary[key] ?? .nul
            default:
                return .nul
            }
        }
        set {
            switch self {
            case .obj(let dictionary):
                var new = dictionary
                new[key] = newValue
                self = .obj(new)
            default:
                var dictionary = [JObj.Key: JSum]()
                dictionary[key] = newValue
                self = .obj(dictionary)
            }
        }
    }
}

extension JSum {
    var bool: Bool? {
        switch self {
        case .bol(let b):
            return b
        default:
            return nil
        }
    }

    var int: Int? {
        switch self {
        case .num(let f):
            if Double(Int(f)) == f {
                return Int(f)
            } else {
                return nil
            }
        default:
            return nil
        }
    }

    var double: Double? {
        switch self {
        case .num(let f):
            return f
        default:
            return nil
        }
    }

    var string: String? {
        switch self {
        case .str(let s):
            return s
        default:
            return nil
        }
    }

    var array: [JSum]? {
        switch self {
        case .arr(let array):
            return array
        default:
            return nil
        }
    }

    var dictionary: [JObj.Key: JSum]? {
        switch self {
        case .obj(let dictionary):
            return dictionary
        default:
            return nil
        }
    }

    var count: Int? {
        switch self {
        case .arr(let array):
            return array.count
        case .obj(let dictionary):
            return dictionary.count
        default:
            return nil
        }
    }
}
extension JSum : ExpressibleByNilLiteral {
    /// Creates null JSum
    @inlinable public init(nilLiteral: ()) {
        self = .nul
    }
}

extension JSum : ExpressibleByBooleanLiteral {
    /// Creates boolean JSum
    @inlinable public init(booleanLiteral value: BooleanLiteralType) {
        self = .bol(value)
    }
}

extension JSum : ExpressibleByFloatLiteral {
    /// Creates numeric JSum
    @inlinable public init(floatLiteral value: FloatLiteralType) {
        self = .num(value)
    }
}

extension JSum : ExpressibleByIntegerLiteral {
    /// Creates numeric JSum
    @inlinable public init(integerLiteral value: IntegerLiteralType) {
        self = .num(Double(value))
    }
}

extension JSum : ExpressibleByArrayLiteral {
    /// Creates an array of JSum
    @inlinable public init(arrayLiteral elements: JSum...) {
        self = .arr(elements)
    }
}

extension JSum : ExpressibleByStringLiteral {
    /// Creates String JSum
    @inlinable public init(stringLiteral value: String) {
        self = .str(value)
    }
}

extension JSum : ExpressibleByDictionaryLiteral {
    /// Creates a dictionary of `String` to `JSum`
    @inlinable public init(dictionaryLiteral elements: (String, JSum)...) {
        var d: Dictionary<String, JSum> = [:]
        for (k, v) in elements { d[k] = v }
        self = .obj(d)
    }
}

/// Convenience accessors for the payloads of the various `JSum` types
public extension JSum {
    /// Returns the underlying String payload if this is a `JSum.str`, otherwise `.none`
    @inlinable var str: String? {
        guard case .str(let str) = self else { return .none }
        return str
    }

    /// Returns the underlying Boolean payload if this is a `JSum.bol`, otherwise `.none`
    @inlinable var bol: Bool? {
        guard case .bol(let bol) = self else { return .none }
        return bol
    }

    /// Returns the underlying Double payload if this is a `JSum.num`, otherwise `.none`
    @inlinable var num: Double? {
        guard case .num(let num) = self else { return .none }
        return num
    }

    /// Returns the underlying JObj payload if this is a `JSum.obj`, otherwise `.none`
    @inlinable var obj: JObj? {
        guard case .obj(let obj) = self else { return .none }
        return obj
    }

    /// Returns the underlying Array payload if this is a `JSum.arr`, otherwise `.none`
    @inlinable var arr: [JSum]? {
        guard case .arr(let arr) = self else { return .none }
        return arr
    }

    /// Returns the underlying `nil` payload if this is a `JSum.nul`, otherwise `.none`
    @inlinable var nul: Void? {
        guard case .nul = self else { return .none }
        return ()
    }

    /// JSum has a string subscript when it is an object type; setting a value on a non-obj type has no effect
    @inlinable subscript(key: String) -> JSum? {
        get {
            guard case .obj(let obj) = self else { return .none }
            return obj[key]
        }

        set {
            guard case .obj(var obj) = self else { return }
            obj[key] = newValue
            self = .obj(obj)
        }
    }

    /// JSum has a save indexed subscript when it is an array type; setting a value on a non-array type has no effect
    @inlinable subscript(index: Int) -> JSum? {
        get {
            guard case .arr(let arr) = self else { return .none }
            if index < 0 || index >= arr.count { return .none }
            return arr[index]
        }

        set {
            guard case .arr(var arr) = self else { return }
            if index < 0 || index >= arr.count { return }
            arr[index] = newValue ?? JSum.nul
            self = .arr(arr)
        }
    }
}

extension JSum : Encodable {
    @inlinable public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .nul: try container.encodeNil()
        case .bol(let x): try container.encode(x)
        case .num(let x): try container.encode(x)
        case .str(let x): try container.encode(x)
        case .obj(let x): try container.encode(x)
        case .arr(let x): try container.encode(x)
        }
    }
}

extension JSum : Decodable {
    @inlinable public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        func decode<T: Decodable>() throws -> T { try container.decode(T.self) }
        if container.decodeNil() {
            self = .nul
        } else {
            do {
                self = try .bol(container.decode(Bool.self))
            } catch DecodingError.typeMismatch {
                do {
                    self = try .num(container.decode(Double.self))
                } catch DecodingError.typeMismatch {
                    do {
                        self = try .str(container.decode(String.self))
                    } catch DecodingError.typeMismatch {
                        do {
                            self = try .arr(decode())
                        } catch DecodingError.typeMismatch {
                            do {
                                self = try .obj(decode())
                            } catch DecodingError.typeMismatch {
                                throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Encoded payload not of an expected type"))
                            }
                        }
                    }
                }
            }
        }
    }
}

#if canImport(Foundation)
import Foundation

public struct JSumOptions : OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let ignoreNonEncodable = Self(rawValue: 1 << 0)
    // public static let xxx = Self(rawValue: 1 << 1)
}

extension NSDictionary {
    /// Converts this instance to a JSum by serializing it to JSON and then de-serializing to a `JSum`.
    func jsum(options: JSumOptions = []) throws -> JSum {
        // this fails when there is a <data> elemement
        // try JSum(json: JSONSerialization.data(withJSONObject: self, options: []))

        var obj = JObj()
        obj.reserveCapacity(self.count)

        for (key, value) in self {
            if let key = key as? String, let value = value as? JSumConvertible {
                obj[key] = try value.jsum(options: options)
            } else {
                if !options.contains(.ignoreNonEncodable) {
                    throw JSumErrors.cannotEncode(nonEncodable: value)
                }
            }
        }

        return .obj(obj)
    }
}

/// A type that can export itself directly as a `JSum` instance without having to cross serialization boundries.
private protocol JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum
}

private enum JSumErrors : Error {
    case cannotEncode(nonEncodable: Any)
}

// MARK: Non-ObjC CoreFoundation JSumConvertible extensions

// these extensions are needed for NSDictionary->JSum conversions on non-ObjC platforms (Linux, Windows)

extension String : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .str(self as String)
    }
}

extension Bool : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .bol(self)
    }
}

extension Double : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .num(self)
    }
}

extension Int : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .num(.init(self))
    }
}

extension Array : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        var arr: [JSum] = []
        arr.reserveCapacity(self.count)
        for value in self {
            if let value = value as? JSumConvertible {
                arr.append(try value.jsum(options: options))
            } else if !options.contains(.ignoreNonEncodable) {
                throw JSumErrors.cannotEncode(nonEncodable: value)
            }
        }
        return .arr(arr)
    }
}

extension Dictionary : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        var obj = JObj()
        obj.reserveCapacity(self.count)
        for (key, value) in self {
            if let key = key as? String,
                let value = value as? JSumConvertible {
                obj[key] = try value.jsum(options: options)
            } else if !options.contains(.ignoreNonEncodable) {
                throw JSumErrors.cannotEncode(nonEncodable: value)
            }
        }
        return .obj(obj)
    }
}

extension Data : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .str(base64EncodedString())
    }
}

/// A shared date formatter for JSON serialization
private let iso8601: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

extension Date : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .str(iso8601.string(from: self as Date))
    }
}


// MARK: ObjC CoreFoundation JSumConvertible extensions

// these extensions are needed for NSDictionary->JSum conversions on ObjC platforms (iOS, macOS)

extension NSDictionary : JSumConvertible {

}

extension NSArray : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        JSum.arr(try self.compactMap { item in
            if let item = item as? JSumConvertible {
                return try item.jsum(options: options)
            } else {
                if options.contains(.ignoreNonEncodable) {
                    return nil
                } else {
                    throw JSumErrors.cannotEncode(nonEncodable: item)
                }
            }
        })
    }
}

extension NSString : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .str(self as String)
    }
}

extension NSNull : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .nul
    }
}

extension NSData : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .str(base64EncodedString())
    }
}

extension NSDate : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .str(iso8601.string(from: self as Date))
    }
}

extension NSNumber : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        isBool ? .bol(self.boolValue) : .num(self.doubleValue)
    }
}

private let trueNumber = NSNumber(value: true)
private let falseNumber = NSNumber(value: false)
private let trueObjCType = String(describing: trueNumber.objCType)
private let falseObjCType = String(describing: falseNumber.objCType)

#if canImport(Foundation)
import CoreFoundation
#endif

private extension NSNumber {
    /// Returns `true` if this number represents a boolean value.
    var isBool: Bool {
        get {
#if os(Linux)
            let type = CFNumberGetType(unsafeBitCast(self, to: CFNumber.self))
            if type == CFNumberType.sInt8Type && (self.compare(trueNumber) == ComparisonResult.orderedSame || self.compare(falseNumber) == ComparisonResult.orderedSame) {
                return true
            } else {
                return false
            }
#else
            let objCType = String(describing: self.objCType)
            if (self.compare(trueNumber) == ComparisonResult.orderedSame && objCType == trueObjCType) || (self.compare(falseNumber) == ComparisonResult.orderedSame && objCType == falseObjCType) {
                return true
            } else {
                return false
            }
#endif
        }
    }
}

#endif


// MARK: YAML Handling


// The YAML parsing code borrows heavily from the https://github.com/behrang/YamlSwift which is released under the following license:
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Behrang Noruzi Niya
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

extension JSum {
    public static func parse(yaml: String) throws -> JSum {
        let result = YAMLParser.tokenize(yaml) >>=- Context.parseDoc
        if let value = result.value { return value } else { throw ResultError.message(result.error) }
    }

    public static func parseMultiple(yaml: String) throws -> [JSum] {
        let result = YAMLParser.tokenize(yaml) >>=- Context.parseDocs
        if let value = result.value { return value } else { throw ResultError.message(result.error) }
    }
}

private extension JSum {
    static func int(_ number: Int) -> JSum {
        .num(Double(number))
    }
}

private extension JSum {
    enum ResultError: Error {
        case message(String?)
    }
}


private enum YAMLParser {

    struct Context {
        let tokens: [YAMLParser.TokenMatch]
        let aliases: [String.SubSequence: JSum]

        init(_ tokens: [YAMLParser.TokenMatch], _ aliases: [String.SubSequence: JSum] = [:]) {
            self.tokens = tokens
            self.aliases = aliases
        }

        static func parseDoc(_ tokens: [YAMLParser.TokenMatch]) -> YAMLResult<JSum> {
            let c = YAMLParser.lift(Context(tokens))
            let cv = c >>=- parseHeader >>=- parseValue
            let v = cv >>- getValue
            return cv
            >>- getContext
            >>- ignoreDocEnd
            >>=- expect(.end, message: "expected end")
            >>| v
        }

        static func parseDocs(_ tokens: [YAMLParser.TokenMatch]) -> YAMLResult<[JSum]> {
            return parseDocs([])(Context(tokens))
        }

        static func parseDocs(_ acc: [JSum]) -> (Context) -> YAMLResult<[JSum]> {
            return { context in
                if peekType(context) == .end {
                    return YAMLParser.lift(acc)
                }
                let cv = YAMLParser.lift(context)
                >>=- parseHeader
                >>=- parseValue
                let v = cv
                >>- getValue
                let c = cv
                >>- getContext
                >>- ignoreDocEnd
                let a = appendToArray(acc) <^> v
                return parseDocs <^> a <*> c |> YAMLParser.join
            }
        }

        static func error(_ message: String) -> (Context) -> String {
            return { context in
                let text = recreateText("", context: context) |> YAMLParser.escapeErrorContext
                return "\(message), \(text)"
            }
        }
    }
}

private typealias Context = YAMLParser.Context

private var error = YAMLParser.Context.error

private typealias ContextValue = (context: Context, value: JSum)
private typealias ContextKey = (context: Context, key: JObj.Key)

private func createContextValue(_ context: Context) -> (JSum) -> ContextValue { { value in (context, value) } }
private func getContext(_ cv: ContextValue) -> Context { cv.context }
private func getValue(_ cv: ContextValue) -> JSum { cv.value }
private func peekType(_ context: Context) -> JSum.TokenType { context.tokens[0].type }
private func peekMatch(_ context: Context) -> String { context.tokens[0].match }


private func advance(_ context: Context) -> Context {
    var tokens = context.tokens
    tokens.remove(at: 0)
    return Context(tokens, context.aliases)
}

private func ignoreSpace(_ context: Context) -> Context {
    if ![.comment, .space, .newLine].contains(peekType(context)) {
        return context
    }
    return ignoreSpace(advance(context))
}

private func ignoreDocEnd(_ context: Context) -> Context {
    if ![.comment, .space, .newLine, .docend].contains(peekType(context)) {
        return context
    }
    return ignoreDocEnd(advance(context))
}

private func expect(_ type: JSum.TokenType, message: String) -> (Context) -> YAMLResult<Context> {
    return { context in
        let check = peekType(context) == type
        return YAMLParser.`guard`(error(message)(context), check: check)
        >>| YAMLParser.lift(advance(context))
    }
}

private func expectVersion(_ context: Context) -> YAMLResult<Context> {
    let version = peekMatch(context)
    let check = ["1.1", "1.2"].contains(version)
    return YAMLParser.`guard`(error("invalid yaml version")(context), check: check)
    >>| YAMLParser.lift(advance(context))
}


private func recreateText(_ string: String, context: Context) -> String {
    if string.count >= 50 || peekType(context) == .end {
        return string
    }
    return recreateText(string + peekMatch(context), context: advance(context))
}

private func parseHeader(_ context: Context) -> YAMLResult<Context> {
    return parseHeader(true)(Context(context.tokens, [:]))
}

private func parseHeader(_ yamlAllowed: Bool) -> (Context) -> YAMLResult<Context> {
    return { context in
        switch peekType(context) {

        case .comment, .space, .newLine:
            return YAMLParser.lift(context)
            >>- advance
            >>=- parseHeader(yamlAllowed)

        case .yamlDirective:
            let err = "duplicate yaml directive"
            return YAMLParser.`guard`(error(err)(context), check: yamlAllowed)
            >>| YAMLParser.lift(context)
            >>- advance
            >>=- expect(.space, message: "expected space")
            >>=- expectVersion
            >>=- parseHeader(false)

        case .docStart:
            return YAMLParser.lift(advance(context))

        default:
            return YAMLParser.`guard`(error("expected ---")(context), check: yamlAllowed)
            >>| YAMLParser.lift(context)
        }
    }
}

private func parseValue(_ context: Context) -> YAMLResult<ContextValue> {
    switch peekType(context) {

    case .comment, .space, .newLine:
        return parseValue(ignoreSpace(context))

    case .null:
        return YAMLParser.lift((advance(context), nil))

    case ._true:
        return YAMLParser.lift((advance(context), true))

    case ._false:
        return YAMLParser.lift((advance(context), false))

    case .int:
        let m = peekMatch(context)
        // will throw runtime error if overflows
        let v = JSum.int(parseInt(m, radix: 10))
        return YAMLParser.lift((advance(context), v))

    case .intOct:
        let m = peekMatch(context) |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("0o"), template: "")
        // will throw runtime error if overflows
        let v = JSum.int(parseInt(m, radix: 8))
        return YAMLParser.lift((advance(context), v))

    case .intHex:
        let m = peekMatch(context) |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("0x"), template: "")
        // will throw runtime error if overflows
        let v = JSum.int(parseInt(m, radix: 16))
        return YAMLParser.lift((advance(context), v))

    case .intSex:
        let m = peekMatch(context)
        let v = JSum.int(parseInt(m, radix: 60))
        return YAMLParser.lift((advance(context), v))

    case .infinityP:
        return YAMLParser.lift((advance(context), .num(Double.infinity)))

    case .infinityN:
        return YAMLParser.lift((advance(context), .num(-Double.infinity)))

    case .nan:
        return YAMLParser.lift((advance(context), .num(Double.nan)))

    case .double:
        let m = NSString(string: peekMatch(context))
        return YAMLParser.lift((advance(context), .num(m.doubleValue)))

    case .dash:
        return parseBlockSeq(context)

    case .openSB:
        return parseFlowSeq(context)

    case .openCB:
        return parseFlowMap(context)

    case .questionMark:
        return parseBlockMap(context)

    case .stringDQ, .stringSQ, .string:
        return parseBlockMapOrString(context)

    case .literal:
        return parseliteral(context)

    case .folded:
        let cv = parseliteral(context)
        let c = cv >>- getContext
        let v = cv
        >>- getValue
        >>- { value in JSum.str(foldBlock(value.string ?? "")) }
        return createContextValue <^> c <*> v

    case .indent:
        let cv = parseValue(advance(context))
        let v = cv >>- getValue
        let c = cv
        >>- getContext
        >>- ignoreSpace
        >>=- expect(.dedent, message: "expected dedent")
        return createContextValue <^> c <*> v

    case .anchor:
        let m = peekMatch(context)
        let name = m[m.index(after: m.startIndex)...]
        let cv = parseValue(advance(context))
        let v = cv >>- getValue
        let c = addAlias(name) <^> v <*> (cv >>- getContext)
        return createContextValue <^> c <*> v

    case .alias:
        let m = peekMatch(context)
        let name = m[m.index(after: m.startIndex)...]
        let value = context.aliases[name]
        let err = "unknown alias \(name)"
        return YAMLParser.`guard`(error(err)(context), check: value != nil)
        >>| YAMLParser.lift((advance(context), value ?? nil))

    case .end, .dedent:
        return YAMLParser.lift((context, nil))

    default:
        return YAMLParser.fail(error("unexpected type \(peekType(context))")(context))

    }
}

private func addAlias(_ name: String.SubSequence) -> (JSum) -> (Context) -> Context {
    return { value in
        return { context in
            var aliases = context.aliases
            aliases[name] = value
            return Context(context.tokens, aliases)
        }
    }
}

private func appendToArray(_ array: [JSum]) -> (JSum) -> [JSum] {
    { array + [$0] }
}

private func putToMap(_ map: [JObj.Key: JSum]) -> (JSum) -> (JSum) -> [JObj.Key: JSum] {
    { key in
        { value in
            var map = map
            if let yamlKey = key.yamlKey {
                map[yamlKey] = value
            }
            return map
        }
    }
}

private func checkKeyValueUniqueness(_ acc: [JObj.Key: JSum]) ->(_ context: Context, _ key: JObj.Key) -> YAMLResult<ContextKey> {
    { (context, key) in
        let err = "duplicate key \(key)"
        return YAMLParser.`guard`(error(err)(context), check: !acc.keys.contains(key))
        >>| YAMLParser.lift((context, key))
    }
}

private extension JSum {
    /// This YAML as a key in a dictionary. Technically, YAML keys can be any type, but we corece them to a string to work with `JSum.obj`.
    var yamlKey: JObj.Key? {
        switch self {
        case .nul:
            return nil
        case .bol(let x):
            return x.description
        case .num(let x):
            return x.description
        case .str(let x):
            return x
        case .arr(_):
            return nil // cannot be used as a key
        case .obj(_):
            return nil // cannot be used as a key
        }
    }
}

private func checkKeyUniqueness(_ acc: [JObj.Key: JSum]) ->(_ context: Context, _ value: JSum) -> YAMLResult<ContextValue> {
    { (context, value) in
        let key = value.string ?? value.double?.description ?? value.bool?.description ?? ""
        let err = "duplicate key \(key)"
        return YAMLParser.`guard`(error(err)(context), check: !acc.keys.contains(key))
        >>| YAMLParser.lift((context, .str(key)))
    }
}

private func parseFlowSeq(_ context: Context) -> YAMLResult<ContextValue> {
    YAMLParser.lift(context)
    >>=- expect(.openSB, message: "expected [")
    >>=- parseFlowSeq([])
}

private func parseFlowSeq(_ acc: [JSum]) -> (Context) -> YAMLResult<ContextValue> {
    { context in
        if peekType(context) == .closeSB {
            return YAMLParser.lift((advance(context), .arr(acc)))
        }
        let cv = YAMLParser.lift(context)
        >>- ignoreSpace
        >>=- (acc.count == 0 ? YAMLParser.lift : expect(.comma, message: "expected comma"))
        >>- ignoreSpace
        >>=- parseValue
        let v = cv >>- getValue
        let c = cv
        >>- getContext
        >>- ignoreSpace
        let a = appendToArray(acc) <^> v
        return parseFlowSeq <^> a <*> c |> YAMLParser.join
    }
}

private func parseFlowMap(_ context: Context) -> YAMLResult<ContextValue> {
    YAMLParser.lift(context)
    >>=- expect(.openCB, message: "expected {")
    >>=- parseFlowMap([:])
}

private func parseFlowMap(_ acc: [JObj.Key: JSum]) -> (Context) -> YAMLResult<ContextValue> {
    { context in
        if peekType(context) == .closeCB {
            return YAMLParser.lift((advance(context), .obj(acc)))
        }
        let ck = YAMLParser.lift(context)
        >>- ignoreSpace
        >>=- (acc.count == 0 ? YAMLParser.lift : expect(.comma, message: "expected comma"))
        >>- ignoreSpace
        >>=- parseString
        >>=- checkKeyUniqueness(acc)
        let k = ck >>- getValue
        let cv = ck
        >>- getContext
        >>=- expect(.colon, message: "expected colon")
        >>=- parseValue
        let v = cv >>- getValue
        let c = cv
        >>- getContext
        >>- ignoreSpace
        let a = putToMap(acc) <^> k <*> v
        return parseFlowMap <^> a <*> c |> YAMLParser.join
    }
}

private func parseBlockSeq(_ context: Context) -> YAMLResult<ContextValue> {
    parseBlockSeq([])(context)
}

private func parseBlockSeq(_ acc: [JSum]) -> (Context) -> YAMLResult<ContextValue> {
    { context in
        if peekType(context) != .dash {
            return YAMLParser.lift((context, .arr(acc)))
        }
        let cv = YAMLParser.lift(context)
        >>- advance
        >>=- expect(.indent, message: "expected indent after dash")
        >>- ignoreSpace
        >>=- parseValue
        let v = cv >>- getValue
        let c = cv
        >>- getContext
        >>- ignoreSpace
        >>=- expect(.dedent, message: "expected dedent after dash indent")
        >>- ignoreSpace
        let a = appendToArray(acc) <^> v
        return parseBlockSeq <^> a <*> c |> YAMLParser.join
    }
}

private func parseBlockMap(_ context: Context) -> YAMLResult<ContextValue> {
    parseBlockMap([:])(context)
}

private func parseBlockMap(_ acc: [JObj.Key: JSum]) -> (Context) -> YAMLResult<ContextValue> {
    { context in
        switch peekType(context) {

        case .questionMark:
            return parseQuestionMarkkeyValue(acc)(context)

        case .string, .stringDQ, .stringSQ:
            return parseStringKeyValue(acc)(context)

        default:
            return YAMLParser.lift((context, .obj(acc)))
        }
    }
}

private func parseQuestionMarkkeyValue(_ acc: [JObj.Key: JSum]) -> (Context) -> YAMLResult<ContextValue> {
    { context in
        let ck = YAMLParser.lift(context)
        >>=- expect(.questionMark, message: "expected ?")
        >>=- parseValue
        >>=- checkKeyUniqueness(acc)
        let k = ck >>- getValue
        let cv = ck
        >>- getContext
        >>- ignoreSpace
        >>=- parseColonValueOrNil
        let v = cv >>- getValue
        let c = cv
        >>- getContext
        >>- ignoreSpace
        let a = putToMap(acc) <^> k <*> v
        return parseBlockMap <^> a <*> c |> YAMLParser.join
    }
}

private func parseColonValueOrNil(_ context: Context) -> YAMLResult<ContextValue> {
    if peekType(context) != .colon {
        return YAMLParser.lift((context, nil))
    }
    return parseColonValue(context)
}

private func parseColonValue(_ context: Context) -> YAMLResult<ContextValue> {
    YAMLParser.lift(context)
    >>=- expect(.colon, message: "expected colon")
    >>- ignoreSpace
    >>=- parseValue
}

private func parseStringKeyValue(_ acc: [JObj.Key: JSum]) -> (Context) -> YAMLResult<ContextValue> {
    { context in
        let ck = YAMLParser.lift(context)
        >>=- parseString
        >>=- checkKeyUniqueness(acc)
        let k = ck >>- getValue
        let cv = ck
        >>- getContext
        >>- ignoreSpace
        >>=- parseColonValue
        let v = cv >>- getValue
        let c = cv
        >>- getContext
        >>- ignoreSpace
        let a = putToMap(acc) <^> k <*> v
        return parseBlockMap <^> a <*> c |> YAMLParser.join
    }
}

private func parseString(_ context: Context) -> YAMLResult<ContextValue> {
    switch peekType(context) {

    case .string:
        let m = normalizeBreaks(peekMatch(context))
        let folded = m |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^[ \\t\\n]+|[ \\t\\n]+$"), template: "") |> foldFlow
        return YAMLParser.lift((advance(context), .str(folded)))

    case .stringDQ:
        let m = unwrapQuotedString(normalizeBreaks(peekMatch(context)))
        return YAMLParser.lift((advance(context), .str(unescapeDoubleQuotes(foldFlow(m)))))

    case .stringSQ:
        let m = unwrapQuotedString(normalizeBreaks(peekMatch(context)))
        return YAMLParser.lift((advance(context), .str(unescapeSingleQuotes(foldFlow(m)))))

    default:
        return YAMLParser.fail(error("expected string")(context))
    }
}

private func parseBlockMapOrString(_ context: Context) -> YAMLResult<ContextValue> {
    let match = peekMatch(context)
    // should spaces before colon be ignored?
    return context.tokens[1].type != .colon || YAMLParser.YAMLExp.matches(match, regex: YAMLParser.YAMLExp.regex("\n"))
    ? parseString(context)
    : parseBlockMap(context)
}

private func foldBlock(_ block: String) -> String {
    let (body, trail) = block |> YAMLParser.YAMLExp.splitTrail(YAMLParser.YAMLExp.regex("\\n*$"))
    return (body
            |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^([^ \\t\\n].*)\\n(?=[^ \\t\\n])", options: "m"), template: "$1 ")
            |> YAMLParser.YAMLExp.replace(
                YAMLParser.YAMLExp.regex("^([^ \\t\\n].*)\\n(\\n+)(?![ \\t])", options: "m"), template: "$1$2")
    ) + trail
}

private func foldFlow(_ flow: String) -> String {
    let (lead, rest) = flow |> YAMLParser.YAMLExp.splitLead(YAMLParser.YAMLExp.regex("^[ \\t]+"))
    let (body, trail) = rest |> YAMLParser.YAMLExp.splitTrail(YAMLParser.YAMLExp.regex("[ \\t]+$"))
    let folded = body
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^[ \\t]+|[ \\t]+$|\\\\\\n", options: "m"), template: "")
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("(^|.)\\n(?=.|$)"), template: "$1 ")
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("(.)\\n(\\n+)"), template: "$1$2")
    return lead + folded + trail
}

private func count(string: String) -> Int {
    string.count
}

private func parseliteral(_ context: Context) -> YAMLResult<ContextValue> {
    let literal = peekMatch(context)
    let blockContext = advance(context)
    let chomps = ["-": -1, "+": 1]
    let chomp = chomps[literal |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("[^-+]"), template: "")] ?? 0
    let indent = parseInt(literal |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("[^1-9]"), template: ""), radix: 10)
    let headerPattern = YAMLParser.YAMLExp.regex("^(\\||>)([1-9][-+]|[-+]?[1-9]?)( |$)")
    let error0 = "invalid chomp or indent header"
    let c = YAMLParser.`guard`(error(error0)(context),
                             check: YAMLParser.YAMLExp.matches(literal, regex: headerPattern!))
    >>| YAMLParser.lift(blockContext)
    >>=- expect(.string, message: "expected scalar block")
    let block = peekMatch(blockContext)
    |> normalizeBreaks
    let (lead, _) = block
    |> YAMLParser.YAMLExp.splitLead(YAMLParser.YAMLExp.regex("^( *\\n)* {1,}(?! |\\n|$)"))
    let foundindent = lead
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^( *\\n)*"), template: "")
    |> count
    let effectiveindent = indent > 0 ? indent : foundindent
    let invalidPattern =
    YAMLParser.YAMLExp.regex("^( {0,\(effectiveindent)}\\n)* {\(effectiveindent + 1),}\\n")
    let check1 = YAMLParser.YAMLExp.matches(block, regex: invalidPattern!)
    let check2 = indent > 0 && foundindent < indent
    let trimmed = block
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^ {0,\(effectiveindent)}"), template: "")
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\\n {0,\(effectiveindent)}"), template: "\n")
    |> (chomp == -1
        ? YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("(\\n *)*$"), template: "")
        : chomp == 0
        ? YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("(?=[^ ])(\\n *)*$"), template: "\n")
        : { s in s }
    )
    let error1 = "leading all-space line must not have too many spaces"
    let error2 = "less indented block scalar than the indicated level"
    return c
    >>| YAMLParser.`guard`(error(error1)(blockContext), check: !check1)
    >>| YAMLParser.`guard`(error(error2)(blockContext), check: !check2)
    >>| c
    >>- { context in (context, .str(trimmed))}
}


private func parseInt(_ string: String, radix: Int) -> Int {
    let (sign, str) = YAMLParser.YAMLExp.splitLead(YAMLParser.YAMLExp.regex("^[-+]"))(string)
    let multiplier = (sign == "-" ? -1 : 1)
    let ints = radix == 60
    ? toSexints(str)
    : toints(str)
    return multiplier * ints.reduce(0, { acc, i in acc * radix + i })
}

private func toSexints(_ string: String) -> [Int] {
    string.components(separatedBy: ":").map {
        c in Int(c) ?? 0
    }
}

private func toints(_ string: String) -> [Int] {
    string.unicodeScalars.map {
        c in
        switch c {
        case "0"..."9": return Int(c.value) - Int(("0" as UnicodeScalar).value)
        case "a"..."z": return Int(c.value) - Int(("a" as UnicodeScalar).value) + 10
        case "A"..."Z": return Int(c.value) - Int(("A" as UnicodeScalar).value) + 10
        default: fatalError("invalid digit \(c)")
        }
    }
}

private func normalizeBreaks(_ s: String) -> String {
    YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\\r\\n|\\r"), template: "\n")(s)
}

private func unwrapQuotedString(_ s: String) -> String {
    String(s[s.index(after: s.startIndex)..<s.index(before: s.endIndex)])
}

private func unescapeSingleQuotes(_ s: String) -> String {
    YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("''"), template: "'")(s)
}

private func unescapeDoubleQuotes(_ input: String) -> String {
    input
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\\\\([0abtnvfre \"\\/N_LP])"))
    { escapeCharacters[$0[1]] ?? "" }
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\\\\x([0-9A-Fa-f]{2})"))
    { String(describing: UnicodeScalar(parseInt($0[1], radix: 16))) }
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\\\\u([0-9A-Fa-f]{4})"))
    { String(describing: UnicodeScalar(parseInt($0[1], radix: 16))) }
    |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\\\\U([0-9A-Fa-f]{8})"))
    { String(describing: UnicodeScalar(parseInt($0[1], radix: 16))) }
}

private let escapeCharacters = [
    "0": "\0",
    "a": "\u{7}",
    "b": "\u{8}",
    "t": "\t",
    "n": "\n",
    "v": "\u{B}",
    "f": "\u{C}",
    "r": "\r",
    "e": "\u{1B}",
    " ": " ",
    "\"": "\"",
    "\\": "\\",
    "/": "/",
    "N": "\u{85}",
    "_": "\u{A0}",
    "L": "\u{2028}",
    "P": "\u{2029}"
]


private let invalidOptionsPattern = try! NSRegularExpression(pattern: "[^ixsm]", options: [])

private let regexOptions: [Character: NSRegularExpression.Options] = [
    "i": .caseInsensitive,
    "x": .allowCommentsAndWhitespace,
    "s": .dotMatchesLineSeparators,
    "m": .anchorsMatchLines
]

private extension YAMLParser {
    struct YAMLExp {
        static func matchRange(_ string: String, regex: NSRegularExpression) -> NSRange {
            let sr = NSMakeRange(0, string.utf16.count)
            return regex.rangeOfFirstMatch(in: string, options: [], range: sr)
        }

        static func matches(_ string: String, regex: NSRegularExpression) -> Bool {
            return matchRange(string, regex: regex).location != NSNotFound
        }

        static func regex(_ pattern: String, options: String = "") -> NSRegularExpression! {
            if matches(options, regex: invalidOptionsPattern) {
                return nil
            }

            let opts = options.reduce(NSRegularExpression.Options()) { (acc, opt) -> NSRegularExpression.Options in
                return NSRegularExpression.Options(rawValue:acc.rawValue | (regexOptions[opt] ?? NSRegularExpression.Options()).rawValue)
            }
            return try? NSRegularExpression(pattern: pattern, options: opts)
        }

        static func replace(_ regex: NSRegularExpression, template: String) -> (String) -> String {
            { string in
                let s = NSMutableString(string: string)
                let range = NSMakeRange(0, string.utf16.count)
                _ = regex.replaceMatches(in: s, options: [], range: range,
                                         withTemplate: template)
#if os(Linux)
                return s._bridgeToSwift()
#else
                return s as String
#endif
            }
        }

        static func replace(_ regex: NSRegularExpression, block: @escaping ([String]) -> String) -> (String) -> String {
            { string in
                let s = NSMutableString(string: string)
                let range = NSMakeRange(0, string.utf16.count)
                var offset = 0
                regex.enumerateMatches(in: string, options: [], range: range) {
                    result, _, _ in
                    if let result = result {
                        var captures = [String](repeating: "", count: result.numberOfRanges)
                        for i in 0..<result.numberOfRanges {
                            let rangeAt = result.range(at: i)
                            if let r = Range(rangeAt) {
                                captures[i] = NSString(string: string).substring(with: NSRange(r))
                            }
                        }
                        let replacement = block(captures)
                        let offR = NSMakeRange(result.range.location + offset, result.range.length)
                        offset += replacement.count - result.range.length
                        s.replaceCharacters(in: offR, with: replacement)
                    }
                }
#if os(Linux)
                return s._bridgeToSwift()
#else
                return s as String
#endif
            }
        }

        static func splitLead(_ regex: NSRegularExpression) -> (String) -> (String, String) {
            return { string in
                let r = matchRange(string, regex: regex)
                if r.location == NSNotFound {
                    return ("", string)
                } else {
                    let s = NSString(string: string)
                    let i = r.location + r.length
                    return (s.substring(to: i), s.substring(from: i))
                }
            }
        }

        static func splitTrail(_ regex: NSRegularExpression) -> (String) -> (String, String) {
            return { string in
                let r = matchRange(string, regex: regex)
                if r.location == NSNotFound {
                    return (string, "")
                } else {
                    let s = NSString(string: string)
                    let i = r.location
                    return (s.substring(to: i), s.substring(from: i))
                }
            }
        }

        static func substring(_ range: NSRange, _ string : String ) -> String {
            return NSString(string: string).substring(with: range)
        }

        static func substring(_ index: Int, _ string: String ) -> String {
            return NSString(string: string).substring(from: index)
        }
    }

}

private enum YAMLResult<T> {
    case error(String)
    case value(T)

    var error: String? {
        switch self {
        case .error(let e): return e
        case .value: return nil
        }
    }

    var value: T? {
        switch self {
        case .error: return nil
        case .value(let v): return v
        }
    }

    func map <U> (f: (T) -> U) -> YAMLResult<U> {
        switch self {
        case .error(let e): return .error(e)
        case .value(let v): return .value(f(v))
        }
    }

    func flatMap <U> (f: (T) -> YAMLResult<U>) -> YAMLResult<U> {
        switch self {
        case .error(let e): return .error(e)
        case .value(let v): return f(v)
        }
    }
}

private extension YAMLParser  {
    static func lift <V>(_ v: V) -> YAMLResult<V> { .value(v) }
    static func fail <T>(_ e: String) -> YAMLResult<T> { .error(e) }
    static func join <T>(_ x: YAMLResult<YAMLResult<T>>) -> YAMLResult<T> { x >>=- { i in i } }
    static func `guard`(_ error: @autoclosure() -> String, check: Bool) -> YAMLResult<()> { check ? lift(()) : .error(error()) }
}

private extension JSum {
    enum TokenType: String {
        case yamlDirective = "%YAML"
        case docStart = "doc-start"
        case docend = "doc-end"
        case comment = "comment"
        case space = "space"
        case newLine = "newline"
        case indent = "indent"
        case dedent = "dedent"
        case null = "null"
        case _true = "true"
        case _false = "false"
        case infinityP = "+infinity"
        case infinityN = "-infinity"
        case nan = "nan"
        case double = "double"
        case int = "int"
        case intOct = "int-oct"
        case intHex = "int-hex"
        case intSex = "int-sex"
        case anchor = "&"
        case alias = "*"
        case comma = ","
        case openSB = "["
        case closeSB = "]"
        case dash = "-"
        case openCB = "{"
        case closeCB = "}"
        case key = "key"
        case keyDQ = "key-dq"
        case keySQ = "key-sq"
        case questionMark = "?"
        case colonFO = ":-flow-out"
        case colonFI = ":-flow-in"
        case colon = ":"
        case literal = "|"
        case folded = ">"
        case reserved = "reserved"
        case stringDQ = "string-dq"
        case stringSQ = "string-sq"
        case stringFI = "string-flow-in"
        case stringFO = "string-flow-out"
        case string = "string"
        case end = "end"
    }
}

private typealias TokenPattern = (type: JSum.TokenType, pattern: NSRegularExpression)

private let bBreak = "(?:\\r\\n|\\r|\\n)"

// printable non-space chars,
// except `:`(3a), `#`(23), `,`(2c), `[`(5b), `]`(5d), `{`(7b), `}`(7d)
private let safeIn = "\\x21\\x22\\x24-\\x2b\\x2d-\\x39\\x3b-\\x5a\\x5c\\x5e-\\x7a" +
"\\x7c\\x7e\\x85\\xa0-\\ud7ff\\ue000-\\ufefe\\uff00\\ufffd" +
"\\U00010000-\\U0010ffff"
// with flow indicators: `,`, `[`, `]`, `{`, `}`
private let safeOut = "\\x2c\\x5b\\x5d\\x7b\\x7d" + safeIn
private let plainOutPattern =
"([\(safeOut)]#|:(?![ \\t]|\(bBreak))|[\(safeOut)]|[ \\t])+"
private let plainInPattern =
"([\(safeIn)]#|:(?![ \\t]|\(bBreak))|[\(safeIn)]|[ \\t]|\(bBreak))+"
private let dashPattern = YAMLParser.YAMLExp.regex("^-([ \\t]+(?!#|\(bBreak))|(?=[ \\t\\n]))")
private let finish = "(?= *(,|\\]|\\}|( #.*)?(\(bBreak)|$)))"


private let tokenPatterns: [TokenPattern] = [
    (.yamlDirective, YAMLParser.YAMLExp.regex("^%YAML(?= )")),
    (.docStart, YAMLParser.YAMLExp.regex("^---")),
    (.docend, YAMLParser.YAMLExp.regex("^\\.\\.\\.")),
    (.comment, YAMLParser.YAMLExp.regex("^#.*|^\(bBreak) *(#.*)?(?=\(bBreak)|$)")),
    (.space, YAMLParser.YAMLExp.regex("^ +")),
    (.newLine, YAMLParser.YAMLExp.regex("^\(bBreak) *")),
    (.dash, dashPattern!),
    (.null, YAMLParser.YAMLExp.regex("^(null|Null|NULL|~)\(finish)")),
    (._true, YAMLParser.YAMLExp.regex("^(true|True|TRUE)\(finish)")),
    (._false, YAMLParser.YAMLExp.regex("^(false|False|FALSE)\(finish)")),
    (.infinityP, YAMLParser.YAMLExp.regex("^\\+?\\.(inf|Inf|INF)\(finish)")),
    (.infinityN, YAMLParser.YAMLExp.regex("^-\\.(inf|Inf|INF)\(finish)")),
    (.nan, YAMLParser.YAMLExp.regex("^\\.(nan|NaN|NAN)\(finish)")),
    (.int, YAMLParser.YAMLExp.regex("^[-+]?[0-9]+\(finish)")),
    (.intOct, YAMLParser.YAMLExp.regex("^0o[0-7]+\(finish)")),
    (.intHex, YAMLParser.YAMLExp.regex("^0x[0-9a-fA-F]+\(finish)")),
    (.intSex, YAMLParser.YAMLExp.regex("^[0-9]{2}(:[0-9]{2})+\(finish)")),
    (.double, YAMLParser.YAMLExp.regex("^[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?\(finish)")),
    (.anchor, YAMLParser.YAMLExp.regex("^&\\w+")),
    (.alias, YAMLParser.YAMLExp.regex("^\\*\\w+")),
    (.comma, YAMLParser.YAMLExp.regex("^,")),
    (.openSB, YAMLParser.YAMLExp.regex("^\\[")),
    (.closeSB, YAMLParser.YAMLExp.regex("^\\]")),
    (.openCB, YAMLParser.YAMLExp.regex("^\\{")),
    (.closeCB, YAMLParser.YAMLExp.regex("^\\}")),
    (.questionMark, YAMLParser.YAMLExp.regex("^\\?( +|(?=\(bBreak)))")),
    (.colonFO, YAMLParser.YAMLExp.regex("^:(?!:)")),
    (.colonFI, YAMLParser.YAMLExp.regex("^:(?!:)")),
    (.literal, YAMLParser.YAMLExp.regex("^\\|.*")),
    (.folded, YAMLParser.YAMLExp.regex("^>.*")),
    (.reserved, YAMLParser.YAMLExp.regex("^[@`]")),
    (.stringDQ, YAMLParser.YAMLExp.regex("^\"([^\\\\\"]|\\\\(.|\(bBreak)))*\"")),
    (.stringSQ, YAMLParser.YAMLExp.regex("^'([^']|'')*'")),
    (.stringFO, YAMLParser.YAMLExp.regex("^\(plainOutPattern)(?=:([ \\t]|\(bBreak))|\(bBreak)|$)")),
    (.stringFI, YAMLParser.YAMLExp.regex("^\(plainInPattern)")),
]

private extension YAMLParser {
    typealias TokenMatch = (type: JSum.TokenType, match: String)

    static func escapeErrorContext(_ text: String) -> String {
        let endIndex = text.index(text.startIndex, offsetBy: 50, limitedBy: text.endIndex) ?? text.endIndex
        let escaped = String(text[..<endIndex])
        |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\\r"), template: "\\\\r")
        |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\\n"), template: "\\\\n")
        |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\""), template: "\\\\\"")
        return "near \"\(escaped)\""
    }

    static func tokenize(_ text: String) -> YAMLResult<[TokenMatch]> {
        var text = text
        var matchList: [TokenMatch] = []
        var indents = [0]
        var insideFlow = 0
    next:
        while text.endIndex > text.startIndex {
            for tokenPattern in tokenPatterns {
                let range = YAMLParser.YAMLExp.matchRange(text, regex: tokenPattern.pattern)
                if range.location != NSNotFound {
                    let rangeEnd = range.location + range.length
                    switch tokenPattern.type {

                    case .newLine:
                        let match = (range, text) |> YAMLParser.YAMLExp.substring
                        let lastindent = indents.last ?? 0
                        let rest = match[match.index(after: match.startIndex)...]
                        let spaces = rest.count
                        let nestedBlockSequence =
                        YAMLParser.YAMLExp.matches((rangeEnd, text) |> YAMLParser.YAMLExp.substring, regex: dashPattern!)
                        if spaces == lastindent {
                            matchList.append(TokenMatch(.newLine, match))
                        } else if spaces > lastindent {
                            if insideFlow == 0 {
                                if matchList.last != nil &&
                                    matchList[matchList.endIndex - 1].type == .indent {
                                    indents[indents.endIndex - 1] = spaces
                                    matchList[matchList.endIndex - 1] = TokenMatch(.indent, match)
                                } else {
                                    indents.append(spaces)
                                    matchList.append(TokenMatch(.indent, match))
                                }
                            }
                        } else if nestedBlockSequence && spaces == lastindent - 1 {
                            matchList.append(TokenMatch(.newLine, match))
                        } else {
                            while nestedBlockSequence && spaces < (indents.last ?? 0) - 1
                                    || !nestedBlockSequence && spaces < indents.last ?? 0 {
                                indents.removeLast()
                                matchList.append(TokenMatch(.dedent, ""))
                            }
                            matchList.append(TokenMatch(.newLine, match))
                        }

                    case .dash, .questionMark:
                        let match = (range, text) |> YAMLParser.YAMLExp.substring
                        let index = match.index(after: match.startIndex)
                        let indent = match.count
                        indents.append((indents.last ?? 0) + indent)
                        matchList.append(
                            TokenMatch(tokenPattern.type, String(match[..<index])))
                        matchList.append(TokenMatch(.indent, String(match[index...])))

                    case .colonFO:
                        if insideFlow > 0 {
                            continue
                        }
                        fallthrough

                    case .colonFI:
                        let match = (range, text) |> YAMLParser.YAMLExp.substring
                        matchList.append(TokenMatch(.colon, match))
                        if insideFlow == 0 {
                            indents.append((indents.last ?? 0) + 1)
                            matchList.append(TokenMatch(.indent, ""))
                        }

                    case .openSB, .openCB:
                        insideFlow += 1
                        matchList.append(TokenMatch(tokenPattern.type, (range, text) |> YAMLParser.YAMLExp.substring))

                    case .closeSB, .closeCB:
                        insideFlow -= 1
                        matchList.append(TokenMatch(tokenPattern.type, (range, text) |> YAMLParser.YAMLExp.substring))

                    case .literal, .folded:
                        matchList.append(TokenMatch(tokenPattern.type, (range, text) |> YAMLParser.YAMLExp.substring))
                        text = (rangeEnd, text) |> YAMLParser.YAMLExp.substring
                        let lastindent = indents.last ?? 0
                        let minindent = 1 + lastindent
                        let blockPattern = YAMLParser.YAMLExp.regex(("^(\(bBreak) *)*(\(bBreak)" +
                                                             "( {\(minindent),})[^ ].*(\(bBreak)( *|\\3.*))*)(?=\(bBreak)|$)"))
                        let (lead, rest) = text |> YAMLParser.YAMLExp.splitLead(blockPattern!)
                        text = rest
                        let block = (lead
                                     |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^\(bBreak)"), template: "")
                                     |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^ {0,\(lastindent)}"), template: "")
                                     |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("\(bBreak) {0,\(lastindent)}"), template: "\n")
                        ) + (YAMLParser.YAMLExp.matches(text, regex: YAMLParser.YAMLExp.regex("^\(bBreak)")) && lead.endIndex > lead.startIndex
                             ? "\n" : "")
                        matchList.append(TokenMatch(.string, block))
                        continue next

                    case .stringFO:
                        if insideFlow > 0 {
                            continue
                        }
                        let indent = (indents.last ?? 0)
                        let blockPattern = YAMLParser.YAMLExp.regex(("^\(bBreak)( *| {\(indent),}" +
                                                             "\(plainOutPattern))(?=\(bBreak)|$)"))
                        var block = (range, text)
                        |> YAMLParser.YAMLExp.substring
                        |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^[ \\t]+|[ \\t]+$"), template: "")
                        text = (rangeEnd, text) |> YAMLParser.YAMLExp.substring
                        while true {
                            let range = YAMLParser.YAMLExp.matchRange(text, regex: blockPattern!)
                            if range.location == NSNotFound {
                                break
                            }
                            let s = (range, text) |> YAMLParser.YAMLExp.substring
                            block += "\n" +
                            YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^\(bBreak)[ \\t]*|[ \\t]+$"), template: "")(s)
                            text = (range.location + range.length, text) |> YAMLParser.YAMLExp.substring
                        }
                        matchList.append(TokenMatch(.string, block))
                        continue next

                    case .stringFI:
                        let match = (range, text)
                        |> YAMLParser.YAMLExp.substring
                        |> YAMLParser.YAMLExp.replace(YAMLParser.YAMLExp.regex("^[ \\t]|[ \\t]$"), template: "")
                        matchList.append(TokenMatch(.string, match))

                    case .reserved:
                        return fail(escapeErrorContext(text))

                    default:
                        matchList.append(TokenMatch(tokenPattern.type, (range, text) |> YAMLParser.YAMLExp.substring))
                    }
                    text = (rangeEnd, text) |> YAMLParser.YAMLExp.substring
                    continue next
                }
            }
            return fail(escapeErrorContext(text))
        }
        while indents.count > 1 {
            indents.removeLast()
            matchList.append((.dedent, ""))
        }
        matchList.append((.end, ""))
        return lift(matchList)
    }
}


// MARK: Parser Operators

precedencegroup Functional {
    associativity: left
    higherThan: DefaultPrecedence
}

infix operator <*>: Functional
private func <*> <T, U> (f: YAMLResult<(T) -> U>, x: YAMLResult<T>) -> YAMLResult<U> {
    switch (x, f) {
    case (.error(let e), _): return .error(e)
    case (.value, .error(let e)): return .error(e)
    case (.value(let x), .value(let f)): return . value(f(x))
    }
}

infix operator <^>: Functional
private func <^> <T, U> (f: (T) -> U, x: YAMLResult<T>) -> YAMLResult<U> { x.map(f: f) }

infix operator >>-: Functional
private func >>- <T, U> (x: YAMLResult<T>, f: (T) -> U) -> YAMLResult<U> { x.map(f: f) }

infix operator >>=-: Functional
private func >>=- <T, U> (x: YAMLResult<T>, f: (T) -> YAMLResult<U>) -> YAMLResult<U> { x.flatMap(f: f) }

infix operator >>|: Functional
private func >>| <T, U> (x: YAMLResult<T>, y: YAMLResult<U>) -> YAMLResult<U> { x.flatMap { _ in y } }

infix operator |>: Functional
private func |> <T, U> (x: T, f: (T) -> U) -> U { f(x) }
