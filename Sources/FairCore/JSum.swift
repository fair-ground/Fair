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

/// A JSum is a JavaScript Union Model, which is a sum type providing
/// an in-memory representation of a JSON-representible structure.
///
/// JSum can represent the following associated types:
///
/// - `JSum.bol`: `Bool`
/// - `JSum.str`: `String`
/// - `JSum.num`: `Double`
/// - `JSum.arr`: `Array`
/// - `JSum.obj`: `Dictionary`
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
/// The primary syntactic differences with JSON are that `null` is represented with the `nil` constant,
/// and object literals expressed in JSON with `{:}` are expressed in swift with `[:]`.
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
    /// The count of JSum is either the number of properties (for an object), number of elements (for an array), 0 for null, or 1 for string & number
    @inlinable public var count: Int {
        switch self {
        case .obj(let ob): return ob.count
        case .arr(let arr): return arr.count
        case .nul: return 0
        default: return 1
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
    /// Creates a dictonary of JSum
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
        }  else {
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

// MARK: CoreFoundation JSumConvertible extensions (needed for ObjC platforms)

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

extension NSNumber : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        isBool ? .bol(self.boolValue) : .num(self.doubleValue)
    }
}

// MARK: CoreFoundation JSumConvertible extensions (needed for Linux)

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
        .arr(try self.compactMap({ $0 as? JSumConvertible }).map({ try jsum(options: options) }))
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

extension NSData : JSumConvertible {
    func jsum(options: JSumOptions) throws -> JSum {
        .str(base64EncodedString())
    }
}

extension NSDate : JSumConvertible {
    private static let fmt: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func jsum(options: JSumOptions) throws -> JSum {
        .str(Self.fmt.string(from: self as Date))
    }
}

#endif
