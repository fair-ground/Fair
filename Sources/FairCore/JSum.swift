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

/// A JSum is a Joint Sum type, which is an enumeration that can represent one of:
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
///
/// They can also be used to instatiate a `Decodable` instance directly using the `Decodable.init(jsum:)` initializer.
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

public extension JSum {
    /// Returns the ``Bool`` value of type ``bol``.
    var bool: Bool? {
        switch self {
        case .bol(let b):
            return b
        default:
            return nil
        }
    }

    /// Returns the ``Int`` value of type ``num``.
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

    /// Returns the ``Double`` value of type ``num``.
    var double: Double? {
        switch self {
        case .num(let f):
            return f
        default:
            return nil
        }
    }

    /// Returns the ``String`` value of type ``str``.
    var string: String? {
        switch self {
        case .str(let s):
            return s
        default:
            return nil
        }
    }

    /// Returns the ``Array<JSum>`` value of type ``arr``.
    var array: [JSum]? {
        switch self {
        case .arr(let array):
            return array
        default:
            return nil
        }
    }

    /// Returns the ``dictionary<String, JSum>`` value of type ``obj``.
    var dictionary: [JObj.Key: JSum]? {
        switch self {
        case .obj(let dictionary):
            return dictionary
        default:
            return nil
        }
    }

    /// Returns the number of elements for an ``arr`` or key/values for an ``obj``
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
    /// Creates ``nul`` JSum
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

private enum JSumErrors : Error {
    case cannotEncode(nonEncodable: Any)
}

// MARK: Encoding / Decoding

private extension _JSumContainer {
    func addElement(_ element: _JSumContainer) throws {
        guard let arr = self.jsum.arr else {
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Element was not an array"))
        }
        self.jsum = .arr(arr + [element.jsum])
    }

    func insertElement(_ element: _JSumContainer, at index: Int) throws {
        guard var arr = self.jsum.arr else {
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Element was not an array"))
        }
        arr.insert(element.jsum, at: index)
        self.jsum = .arr(arr)
    }

    func setProperty(_ key: String, _ element: _JSumContainer) throws {
        guard var obj = self.jsum.obj else {
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Element was not an object"))
        }
        obj[key] = element.jsum
        self.jsum = .obj(obj)
    }
}

/// A set of options for decoding an entity from a `JSum` instance.
open class JSumDecodingOptions {
    /// The strategy to use in decoding dates. Defaults to `.deferredToDate`.
    open var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy

    /// The strategy to use in decoding binary data. Defaults to `.base64`.
    open var dataDecodingStrategy: JSONDecoder.DataDecodingStrategy

    /// The strategy to use in decoding non-conforming numbers. Defaults to `.throw`.
    open var nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy

    /// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
    open var keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy

    /// Contextual user-provided information for use during decoding.
    open var userInfo: [CodingUserInfoKey : Any]

    public init(dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate, dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64, nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy = .throw, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys, userInfo: [CodingUserInfoKey : Any] = [:]) {
        self.dateDecodingStrategy = dateDecodingStrategy
        self.dataDecodingStrategy = dataDecodingStrategy
        self.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
        self.keyDecodingStrategy = keyDecodingStrategy
        self.userInfo = userInfo
    }
}

/// A set of options for encoding an entity from a `JSum` instance.
open class JSumEncodingOptions {
    /// The output format to produce. Defaults to `[]`.
    open var outputFormatting: JSONEncoder.OutputFormatting

    /// The strategy to use in encoding dates. Defaults to `.deferredToDate`.
    open var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy

    /// The strategy to use in encoding binary data. Defaults to `.base64`.
    open var dataEncodingStrategy: JSONEncoder.DataEncodingStrategy

    /// The strategy to use in encoding non-conforming numbers. Defaults to `.throw`.
    open var nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy

    /// The strategy to use for encoding keys. Defaults to `.useDefaultKeys`.
    open var keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy

    /// Contextual user-provided information for use during encoding.
    open var userInfo: [CodingUserInfoKey : Any]

    public init(outputFormatting: JSONEncoder.OutputFormatting = .sortedKeys, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate, dataEncodingStrategy: JSONEncoder.DataEncodingStrategy = .base64, nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy = .throw, keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys, userInfo: [CodingUserInfoKey : Any] = [:]) {
        self.outputFormatting = outputFormatting
        self.dateEncodingStrategy = dateEncodingStrategy
        self.dataEncodingStrategy = dataEncodingStrategy
        self.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
        self.userInfo = userInfo
    }
}

#if canImport(Combine)
import Combine
protocol TopLevelJSumEncoder : TopLevelEncoder {
}
protocol TopLevelJSumDecoder : TopLevelDecoder {
}
#else
protocol TopLevelJSumDecoder {
}
#endif

extension Encodable {
    /// Creates an in-memory JSum representation of the instance's encoding.
    ///
    /// - Parameter options: the options for serializing the data
    /// - Returns: A JSum containing the structure of the encoded instance
    public func jsum(options: JSumEncodingOptions? = nil) throws -> JSum {
        try JSumEncoder(options: options).encode(self)
    }
}

extension Decodable {
    /// Creates an instance from an encoded intermediate representation.
    ///
    /// A `JSum` can be created from JSON, YAML, Plists, or other similar data formats.
    /// This intermediate representation can then be used to instantiate a compatible `Decodable` instance.
    ///
    /// - Parameters:
    ///   - jsum: the JSum to load the instance from
    ///   - options: the options for deserializing the data such as the decoding strategies for dates and data.
    @inlinable public init(jsum: JSum, options: JSumDecodingOptions? = nil) throws {
        try self = JSumDecoder(options: options).decode(Self.self, from: jsum)
    }
}

public class JSumEncoder : TopLevelJSumEncoder {
    @usableFromInline let options: JSumEncodingOptions

    /// Initializes `self` with default strategies.
    @inlinable public init(options: JSumEncodingOptions? = nil) {
        self.options = options ?? JSumEncodingOptions()
    }

    /// Encodes the given top-level value and returns its script object representation.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    /// - Returns: A new `Data` value containing the encoded script object data.
    /// - Throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - Throws: An error if any value throws an error during encoding.
    @inlinable public func encode<Value: Encodable>(_ value: Value) throws -> JSum {
        try encodeToTopLevelContainer(value)
    }

    /// Encodes the given top-level value and returns its script-type representation.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    /// - Returns: A new top-level array or dictionary representing the value.
    /// - Throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - Throws: An error if any value throws an error during encoding.
    @usableFromInline internal func encodeToTopLevelContainer<Value: Encodable>(_ value: Value) throws -> JSum {
        let encoder = JSumElementEncoder(options: options)
        guard let topLevel = try encoder.box_(value) else {
            throw EncodingError.invalidValue(value,
                                             EncodingError.Context(codingPath: [],
                                                                   debugDescription: "Top-level \(Value.self) did not encode any values."))
        }

        return topLevel.jsum
    }
}


/// `JSumDecoder` facilitates the decoding of `JSum` values into `Decodable` types.
public class JSumDecoder : TopLevelJSumDecoder {
    @usableFromInline let options: JSumDecodingOptions

    /// Initializes `self` with default strategies.
    public init(options: JSumDecodingOptions? = nil) {
        self.options = options ?? JSumDecodingOptions()
    }

    /// Decodes a top-level value of the given type from the given script representation.
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - data: The data to decode from.
    /// - Returns: A value of the requested type.
    /// - Throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not a valid script object.
    /// - Throws: An error if any value throws an error during decoding.
    public func decode<T: Decodable>(_ type: T.Type, from data: JSum) throws -> T {
        try decode(type, fromTopLevel: data)
    }

    /// Decodes a top-level value of the given type from the given script object container (top-level array or dictionary).
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - container: The top-level script container.
    /// - Returns: A value of the requested type.
    /// - Throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not a valid script object.
    /// - Throws: An error if any value throws an error during decoding.
    @usableFromInline internal func decode<T: Decodable>(_ type: T.Type, fromTopLevel container: JSum) throws -> T {
        let decoder = _JSumDecoder(options: options, referencing: container)
        guard let value = try decoder.unbox(container, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }

        return value
    }
}


fileprivate class JSumElementEncoder: Encoder {
    fileprivate let options: JSumEncodingOptions

    /// The encoder's storage.
    fileprivate var storage: _JSumEncodingStorage

    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any] {
        return self.options.userInfo
    }

    /// Initializes `self` with the given top-level encoder options.
    fileprivate init(options: JSumEncodingOptions, codingPath: [CodingKey] = []) {
        self.options = options
        self.storage = _JSumEncodingStorage()
        self.codingPath = codingPath
    }

    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    fileprivate var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        return self.storage.count == self.codingPath.count
    }

    public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        // If an existing keyed container was already requested, return that one.
        let topContainer: _JSumContainer
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushKeyedContainer(options)
        } else {
            guard let container = self.storage.containers.last else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }

        let container = _JSumKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
        return KeyedEncodingContainer(container)
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        // If an existing unkeyed container was already requested, return that one.
        let topContainer: _JSumContainer
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            do {
                topContainer = try storage.pushUnkeyedContainer(options)
            } catch {
                fatalError("Failed to pushUnkeyedContainer: \(error)")
            }
        } else {
            guard let container = self.storage.containers.last else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }

        return _JSumUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

fileprivate final class _JSumContainer {
    var jsum: JSum
    init(jsum: JSum) {
        self.jsum = jsum
    }
}

// MARK: - Encoding Storage and Containers
fileprivate struct _JSumEncodingStorage {
    /// The container stack.
    /// Elements may be any one of the script types
    private(set) fileprivate var containers: [_JSumContainer] = []

    /// Initializes `self` with no containers.
    fileprivate init() {}

    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate mutating func pushKeyedContainer(_ options: JSumEncodingOptions) -> _JSumContainer {
        let dictionary = _JSumContainer(jsum: JSum.obj([:]))
        self.containers.append(dictionary)
        return dictionary
    }

    fileprivate mutating func pushUnkeyedContainer(_ options: JSumEncodingOptions) throws -> _JSumContainer {
        let array = _JSumContainer(jsum: JSum.arr([]))
        self.containers.append(array)
        return array
    }

    fileprivate mutating func push(container: __owned _JSumContainer) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() -> _JSumContainer {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.popLast()!
    }
}

fileprivate struct _JSumUnkeyedEncodingContainer: UnkeyedEncodingContainer {
    /// A reference to the encoder we're writing to.
    private let encoder: JSumElementEncoder

    /// A reference to the container we're writing to.
    private var container: _JSumContainer

    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]

    /// The number of elements encoded into the container.
    public var count: Int {
        container.jsum.count ?? 0
    }

    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: JSumElementEncoder, codingPath: [CodingKey], wrapping container: _JSumContainer) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    public mutating func encodeNil() throws { try container.addElement(.init(jsum: JSum.nul)) }
    public mutating func encode(_ value: Bool) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: Int) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: Int8) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: Int16) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: Int32) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: Int64) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: UInt) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: UInt8) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: UInt16) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: UInt32) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: UInt64) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: Float) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: Double) throws { try container.addElement(encoder.box(value)) }
    public mutating func encode(_ value: String) throws { try container.addElement(encoder.box(value)) }

    public mutating func encode<T: Encodable>(_ value: T) throws {
        self.encoder.codingPath.append(_JSumKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        try self.container.addElement(self.encoder.box(value))
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        self.codingPath.append(_JSumKey(index: self.count))
        defer { self.codingPath.removeLast() }

        let dictionary = _JSumContainer(jsum: JSum.obj([:]))
        try? self.container.addElement(dictionary)

        let container = _JSumKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self.codingPath.append(_JSumKey(index: self.count))
        defer { self.codingPath.removeLast() }

        do {
            let array = _JSumContainer(jsum: JSum.arr([]))
            try self.container.addElement(array)
            return _JSumUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
        } catch {
            fatalError("Failed to pushUnkeyedContainer: \(error)")
        }
    }

    public mutating func superEncoder() -> Encoder {
        return _JSumReferencingEncoder(referencing: self.encoder, at: self.container.jsum.count ?? 0, wrapping: self.container)
    }
}

extension JSumElementEncoder: SingleValueEncodingContainer {
    private func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
    }

    public func encodeNil() throws {
        assertCanEncodeNewValue()
        self.storage.push(container: _JSumContainer(jsum: JSum.nul))
    }

    public func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: self.box(value))
    }

    public func encode<T: Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }
}

extension JSumElementEncoder {

    /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
    fileprivate func box(_ value: Bool) -> _JSumContainer {
        .init(jsum: .bol(value))
    }

    fileprivate func box(_ value: Int) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: Int8) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: Int16) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: Int32) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: Int64) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: UInt) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: UInt8) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: UInt16) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: UInt32) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: UInt64) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: Float) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: Double) -> _JSumContainer {
        .init(jsum: .num(.init(value)))
    }
    fileprivate func box(_ value: String) -> _JSumContainer {
        .init(jsum: .str(value))
    }
    fileprivate func box(_ date: Date) throws -> _JSumContainer {
        switch self.options.dateEncodingStrategy {
        case .deferredToDate:
            // Must be called with a surrounding with(pushedKey:) call.
            // Dates encode as single-value objects; this can't both throw and push a container, so no need to catch the error.
            try date.encode(to: self)
            return .init(jsum: self.storage.popContainer().jsum)

        case .secondsSince1970:
            return .init(jsum: .num(date.timeIntervalSince1970))

        case .millisecondsSince1970:
            return .init(jsum: .num(1000.0 * date.timeIntervalSince1970))

        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return .init(jsum: .str(_iso8601Formatter.string(from: date)))
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }

        case .formatted(let formatter):
            return .init(jsum: .str(formatter.string(from: date)))

        case .custom(let closure):
            let depth = self.storage.count
            do {
                try closure(date, self)
            } catch {
                // If the value pushed a container before throwing, pop it back off to restore state.
                if self.storage.count > depth {
                    let _ = self.storage.popContainer()
                }

                throw error
            }

            guard self.storage.count > depth else {
                // The closure didn't encode anything. Return the default keyed container.
                return .init(jsum: .obj([:]))
            }

            // We can pop because the closure encoded something.
            return self.storage.popContainer()

        @unknown default:
            return .init(jsum: .str(_iso8601Formatter.string(from: date)))
        }
    }

    func box(_ data: Data) throws -> _JSumContainer {
        switch self.options.dataEncodingStrategy {
        case .deferredToData:
            // Must be called with a surrounding with(pushedKey:) call.
            let depth = self.storage.count
            do {
                try data.encode(to: self)
            } catch {
                // If the value pushed a container before throwing, pop it back off to restore state.
                // This shouldn't be possible for Data (which encodes as an array of bytes), but it can't hurt to catch a failure.
                if self.storage.count > depth {
                    let _ = self.storage.popContainer()
                }

                throw error
            }

            return self.storage.popContainer()

        case .base64:
            return .init(jsum: .str(data.base64EncodedString()))

        case .custom(let closure):
            let depth = self.storage.count
            do {
                try closure(data, self)
            } catch {
                // If the value pushed a container before throwing, pop it back off to restore state.
                if self.storage.count > depth {
                    let _ = self.storage.popContainer()
                }

                throw error
            }

            guard self.storage.count > depth else {
                // The closure didn't encode anything. Return the default keyed container.
                return .init(jsum: .obj([:]))
            }

            // We can pop because the closure encoded something.
            return self.storage.popContainer()
        @unknown default:
            return .init(jsum: .str(data.base64EncodedString()))
        }
    }

    fileprivate func box<T: Encodable>(_ value: T) throws -> _JSumContainer {
        return try self.box_(value) ?? .init(jsum: JSum.obj([:]))
    }

    fileprivate func box_<T: Encodable>(_ value: T) throws -> _JSumContainer? {
        let type = Swift.type(of: value)
        if type == Date.self || type == NSDate.self {
            return try self.box((value as! Date))
        } else if type == Data.self || type == NSData.self {
            return try self.box((value as! Data))
        } else if type == URL.self || type == NSURL.self {
            return .init(jsum: .str((value as! URL).absoluteString))
        } else if type == Decimal.self || type == NSDecimalNumber.self {
            return .init(jsum: .num((value as! NSDecimalNumber).doubleValue))
        }

        // The value should request a container from the JSumElementEncoder.
        let depth = self.storage.count
        do {
            try value.encode(to: self)
        } catch let error {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                let _ = self.storage.popContainer()
            }

            throw error
        }

        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer()
    }
}

fileprivate struct _JSumKeyedEncodingContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K

    /// A reference to the encoder we're writing to.
    private let encoder: JSumElementEncoder

    /// A reference to the container we're writing to.
    private var container: _JSumContainer

    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]

    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: JSumElementEncoder, codingPath: [CodingKey], wrapping container: _JSumContainer) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    public mutating func encodeNil(forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .nul))
    }

    public mutating func encode(_ value: Bool, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .bol(value)))
    }

    public mutating func encode(_ value: Int, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: Int8, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: Int16, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: Int32, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: Int64, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: UInt, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: UInt8, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: UInt16, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: UInt32, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: UInt64, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: String, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .str(value)))
    }

    public mutating func encode(_ value: Float, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(.init(value))))
    }

    public mutating func encode(_ value: Double, forKey key: Key) throws {
        try container.setProperty(key.stringValue, .init(jsum: .num(value)))
    }

    public mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        try container.setProperty(key.stringValue, self.encoder.box(value))
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let dictionary = _JSumContainer(jsum: JSum.obj([:]))
        _ = try? self.container.setProperty(key.stringValue, dictionary)

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        let container = _JSumKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: dictionary)
        return KeyedEncodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        do {
            let array = _JSumContainer(jsum: JSum.arr([]))
            try container.setProperty(key.stringValue, array)

            self.codingPath.append(key)
            defer { self.codingPath.removeLast() }
            return _JSumUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: array)
        } catch {
            fatalError("Failed to nestedUnkeyedContainer: \(error)")
        }
    }

    public mutating func superEncoder() -> Encoder {
        return _JSumReferencingEncoder(referencing: self.encoder, at: _JSumKey.super, wrapping: self.container)
    }

    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return _JSumReferencingEncoder(referencing: self.encoder, at: key, wrapping: self.container)
    }
}


/// `_JSumReferencingEncoder` is a special subclass of JSumElementEncoder which has its own storage, but references the contents of a different encoder.
/// It's used in `superEncoder()`, which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
fileprivate class _JSumReferencingEncoder: JSumElementEncoder {
    /// The type of container we're referencing.
    private enum Reference {
        /// Referencing a specific index in an array container.
        case array(_JSumContainer, Int)

        /// Referencing a specific key in a dictionary container.
        case dictionary(_JSumContainer, String)
    }

    /// The encoder we're referencing.
    private let encoder: JSumElementEncoder

    /// The container reference itself.
    private let reference: Reference

    /// Initializes `self` by referencing the given array container in the given encoder.
    fileprivate init(referencing encoder: JSumElementEncoder, at index: Int, wrapping array: _JSumContainer) {
        self.encoder = encoder
        self.reference = .array(array, index)
        super.init(options: encoder.options, codingPath: encoder.codingPath)

        self.codingPath.append(_JSumKey(index: index))
    }

    /// Initializes `self` by referencing the given dictionary container in the given encoder.
    fileprivate init(referencing encoder: JSumElementEncoder, at key: CodingKey, wrapping dictionary: _JSumContainer) {
        self.encoder = encoder
        self.reference = .dictionary(dictionary, key.stringValue)
        super.init(options: encoder.options, codingPath: encoder.codingPath)

        self.codingPath.append(key)
    }

    fileprivate override var canEncodeNewValue: Bool {
        // With a regular encoder, the storage and coding path grow together.
        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
        // We have to take this into account.
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }

    // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
    deinit {
        let value: _JSumContainer
        switch self.storage.count {
        case 0: value = _JSumContainer(jsum: JSum.obj([:]))
        case 1: value = self.storage.popContainer()
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }

        switch self.reference {
        case .array(let array, let index):
            try? array.insertElement(value, at: index)

        case .dictionary(let dictionary, let key):
            try? dictionary.setProperty(key, value)
        }
    }
}


fileprivate class _JSumDecoder: Decoder {
    let options: JSumDecodingOptions

    /// The decoder's storage.
    fileprivate var storage: _JSumDecodingStorage

    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey: Any] {
        return self.options.userInfo
    }

    /// Initializes `self` with the given top-level container and options.
    fileprivate init(options: JSumDecodingOptions, referencing container: JSum, at codingPath: [CodingKey] = []) {
        self.options = options
        self.storage = _JSumDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
    }

    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard !(self.storage.topContainer == .nul) else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard case .obj(let obj) = self.storage.topContainer else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String: Any].self, reality: self.storage.topContainer)
        }

        let container = _JSumKeyedDecodingContainer<Key>(referencing: self, wrapping: obj)
        return KeyedDecodingContainer(container)
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !(self.storage.topContainer == .nul) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get unkeyed decoding container -- found null value instead."))
        }

        guard case .arr(let arr) = self.storage.topContainer else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: self.storage.topContainer)
        }

        return _JSumUnkeyedDecodingContainer(referencing: self, wrapping: arr)
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

fileprivate struct _JSumDecodingStorage {
    /// The container stack.
    /// Elements may be any one of the script types
    private(set) fileprivate var containers: [JSum] = []

    /// Initializes `self` with no containers.
    fileprivate init() {}

    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate var topContainer: JSum {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        return self.containers.last!
    }

    fileprivate mutating func push(container: __owned JSum) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() {
        precondition(!self.containers.isEmpty, "Empty container stack.")
        self.containers.removeLast()
    }
}

fileprivate struct _JSumKeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K

    /// A reference to the decoder we're reading from.
    private let decoder: _JSumDecoder

    /// A reference to the container we're reading from.
    private let container: [String: JSum]

    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]

    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: _JSumDecoder, wrapping container: [String: JSum]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
    }

    public var allKeys: [Key] {
        return self.container.keys.compactMap { Key(stringValue: $0) }
    }

    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }

    public func decodeNil(forKey key: Key) throws -> Bool {
        (self.container[key.stringValue] == .nul) != false
    }

    public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }
        guard let value = try self.decoder.unbox(entry, as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let entry = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(key) (\"\(key.stringValue)\")."))
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
        }

        return value
    }

    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- no value found for key \"\(key.stringValue)\""))
        }

        guard let obj = value.dictionary else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String: Any].self, reality: value)
        }

        let container = _JSumKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: obj)
        return KeyedDecodingContainer(container)
    }

    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested unkeyed container -- no value found for key \"\(key.stringValue)\""))
        }

        guard let array = value.array else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }

        return _JSumUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    private func _superDecoder(forKey key: __owned CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        let value: JSum = self.container[key.stringValue] ?? .nul
        return _JSumDecoder(options: self.decoder.options, referencing: value, at: self.decoder.codingPath)
    }

    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: _JSumKey.super)
    }

    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

fileprivate struct _JSumUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    /// A reference to the decoder we're reading from.
    private let decoder: _JSumDecoder

    /// A reference to the container we're reading from.
    private let container: [JSum]

    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]

    /// The index of the element we're about to decode.
    private(set) public var currentIndex: Int

    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: _JSumDecoder, wrapping container: [JSum]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }

    public var count: Int? {
        return self.container.count
    }

    public var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }

    public mutating func decodeNil() throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        if self.container[self.currentIndex] == .nul {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }

    public mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int.Type) throws -> Int {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int8.Type) throws -> Int8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int16.Type) throws -> Int16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Float.Type) throws -> Float {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Double.Type) throws -> Double {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: String.Type) throws -> String {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [_JSumKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        guard value != .nul else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard let obj = value.dictionary else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String: JSum].self, reality: value)
        }

        self.currentIndex += 1
        let container = _JSumKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: obj)
        return KeyedDecodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested unkeyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        guard !(value == .nul) else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard case .arr(let arr) = value else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [Any].self, reality: value)
        }

        self.currentIndex += 1
        return _JSumUnkeyedDecodingContainer(referencing: self.decoder, wrapping: arr)
    }

    public mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(_JSumKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self, DecodingError.Context(codingPath: self.codingPath,
                                                                                  debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        self.currentIndex += 1
        return _JSumDecoder(options: self.decoder.options, referencing: value, at: self.decoder.codingPath)
    }
}

extension _JSumDecoder: SingleValueDecodingContainer {
    private func expectNonNull<T>(_ type: T.Type) throws {
        if storage.topContainer == .nul {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) but found null value instead."))
        }
    }

    public func decodeNil() -> Bool {
        storage.topContainer == .nul
    }

    public func decode(_ type: Bool.Type) throws -> Bool {
        try expectNonNull(Bool.self)
        return try self.unbox(self.storage.topContainer, as: Bool.self)!
    }

    public func decode(_ type: Int.Type) throws -> Int {
        try expectNonNull(Int.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Int8.Type) throws -> Int8 {
        try expectNonNull(Int8.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Int16.Type) throws -> Int16 {
        try expectNonNull(Int16.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Int32.Type) throws -> Int32 {
        try expectNonNull(Int32.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Int64.Type) throws -> Int64 {
        try expectNonNull(Int64.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt.Type) throws -> UInt {
        try expectNonNull(UInt.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        try expectNonNull(UInt8.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        try expectNonNull(UInt16.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        try expectNonNull(UInt32.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        try expectNonNull(UInt64.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Float.Type) throws -> Float {
        try expectNonNull(Float.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: Double.Type) throws -> Double {
        try expectNonNull(Double.self)
        return .init(try self.unboxNumber(self.storage.topContainer))
    }

    public func decode(_ type: String.Type) throws -> String {
        try expectNonNull(String.self)
        return try self.unbox(self.storage.topContainer, as: String.self)!
    }

    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        try expectNonNull(type)
        return try self.unbox(self.storage.topContainer, as: type)!
    }
}

@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
internal var _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()


extension _JSumDecoder {
    /// Returns the given value unboxed from a container.
    fileprivate func unbox(_ value: JSum, as type: Bool.Type) throws -> Bool? {
        guard case .bol(let bol) = value else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return bol
    }

    fileprivate func unboxNumber(_ value: JSum) throws -> Double {
        guard case .num(let num) = value else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: Double.self, reality: value)
        }
        return num
    }

    fileprivate func unbox(_ value: JSum, as type: Double.Type) throws -> Double? {
        try unboxNumber(value)
    }

    fileprivate func unbox(_ value: JSum, as type: String.Type) throws -> String? {
        guard case .str(let str) = value else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }

        return str
    }

    fileprivate func unbox(_ value: JSum, as type: Date.Type) throws -> Date? {
        switch options.dateDecodingStrategy {
        case .deferredToDate:
            return try Date(from: self)

        case .secondsSince1970:
            guard let number = value.num else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date secondsSince1970."))
            }

            return Date(timeIntervalSince1970: number)

        case .millisecondsSince1970:
            guard let number = value.num else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date millisecondsSince1970."))
            }

            return Date(timeIntervalSince1970: number / 1000.0)

        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                guard let string = value.string,
                      let date = _iso8601Formatter.date(from: string) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
                }

                return date
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }

        case .formatted(let formatter):
            guard let string = value.string else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
            }
            guard let date = formatter.date(from: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Date string does not match format expected by formatter."))
            }
            return date

        case .custom(let closure):
            return try closure(self)

        @unknown default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unhandled date decoding strategy."))
        }
    }

    fileprivate func unbox(_ value: JSum, as type: Data.Type) throws -> Data? {
        switch options.dataDecodingStrategy {
        case .deferredToData:
            return try Data(from: self)

        case .base64:
            guard let string = value.string else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected data to be Base64."))
            }

            guard let data = Data(base64Encoded: string) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Encountered Data is not valid Base64."))
            }

            return data

        case .custom(let closure):
            return try closure(self)

        @unknown default:
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unhandled data decoding strategy."))
        }
    }

    fileprivate func unbox(_ value: JSum, as type: URL.Type) throws -> URL? {
        guard let string = value.string else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected URL string."))
        }

        return URL(string: string)
    }

    fileprivate func unbox<T: Decodable>(_ value: JSum, as type: T.Type) throws -> T? {
        if type == Date.self || type == NSDate.self {
            return try self.unbox(value, as: Date.self) as? T
        } else if type == Data.self || type == NSData.self {
            return try self.unbox(value, as: Data.self) as? T
        } else if type == URL.self || type == NSURL.self {
            return try self.unbox(value, as: URL.self) as? T
        } else {
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try type.init(from: self)
        }
    }
}

extension DecodingError {
    /// Returns a `.typeMismatch` error describing the expected type.
    ///
    /// - Parameters:
    ///   - path: The path of `CodingKey`s taken to decode a value of this type.
    ///   - expectation: The type expected to be encountered.
    ///   - reality: The value that was encountered instead of the expected type.
    /// - Returns: A `DecodingError` with the appropriate path and debug description.
    internal static func _typeMismatch(at path: [CodingKey], expectation: Any.Type, reality: Any) -> DecodingError {
        let description = "Expected to decode \(expectation) but found \(type(of: reality)) instead."
        return .typeMismatch(expectation, Context(codingPath: path, debugDescription: description))
    }
}

fileprivate struct _JSumKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    fileprivate init(index: Int) {
        self.stringValue = "Index \(index)"
        self.intValue = index
    }

    fileprivate static let `super` = _JSumKey(stringValue: "super")!
}


#endif

