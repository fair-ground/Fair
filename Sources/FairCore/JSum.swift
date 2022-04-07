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

/// A JSum is a sum type that can represent the following associated types:
///
/// - `Bool` (`JSum.bol`)
/// - `String` (`JSum.str`)
/// - `Double` (`JSum.num`)
/// - `Array` (`JSum.arr`)
/// - `Dictionary` (`JSum.obj`)
/// - `nil` (`JSum.nul`)
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
@frozen public enum JSum : Hashable {
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
