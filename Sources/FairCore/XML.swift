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

 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
import Swift
import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif // canImport(FoundationXML)

/// An XML Element Document, which is an in-memory tree representation
/// of the contents of an XML source.
public struct XMLNode : Hashable {
    public enum Errors : Error {
        case unknownParseError
        case tidyHTMLUnavailable
        case badElementCount(Int)
    }

    public struct Entity : OptionSet {
        /// The format's default value.
        public let rawValue: UInt

        /// Creates an Entity value with the given raw value.
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static var lt: Entity { return Entity(rawValue: 1 << 0) }
        public static var amp: Entity { return Entity(rawValue: 1 << 1) }
        public static var gt: Entity { return Entity(rawValue: 1 << 2) }
        public static var quot: Entity { return Entity(rawValue: 1 << 3) }
        public static var apos: Entity { return Entity(rawValue: 1 << 4) }
    }

    public var elementName: String
    public var attributes: [String : String]
    public var children: [Child]
    public var namespaceURI: String?
    public var qualifiedName: String?
    public var namespaces: [String: String]?

    /// This is the document root, which is the only one that permits an empty element name
    @inlinable public var isDocument: Bool { return elementName == "" }

    /// Returns all the children of this tree that are element nodes
    @inlinable public var elementChildren: [XMLNode] {
        return children.compactMap { child in
            if case .element(let element) = child {
                return element
            } else {
                return nil
            }
        }
    }

    /// The attributes for this element
    @inlinable public subscript(attribute name: String) -> String? {
        get { return attributes[name] }
        set { attributes[name] = newValue }
    }

    /// A `Child` consists of all the data strucutres that may be contained within an XML element.
    public enum Child : Hashable {
        case element(XMLNode)
        case content(String)
        case comment(String)
        case cdata(Data)
        case whitespace(String)
        case processingInstruction(target: String, data: String?)
    }

    public init(elementName: String, attributes: [String : String] = [:], children: [Child] = [], namespaceURI: String? = nil, qualifiedName: String? = nil, namespaces: [String: String]? = nil) {
        self.elementName = elementName
        self.attributes = attributes
        self.children = children
        self.namespaceURI = namespaceURI
        self.qualifiedName = qualifiedName
        self.namespaces = namespaces
    }

    /// Appends the given tree as an element child
    @inlinable public mutating func append(_ element: XMLNode) {
        self.children.append(.element(element))
    }

    /// Adds the given element to the node.
    /// - Parameters:
    ///   - elementName: the name of the element
    ///   - attributes: any attributes for the element
    ///   - content: the textual content of the element
    ///   - CDATA: whether the text content should be in a CDATA tag (default: false)
    /// - Returns: the appended XMLNode
    @discardableResult @inlinable public mutating func addElement(_ elementName: String, attributes: [String: String] = [:] , content: String? = nil, CDATA: Bool = false) -> XMLNode {
        var node = XMLNode(elementName: elementName, attributes: attributes)
        if let content = content {
            if CDATA {
                node.children.append(.cdata(content.utf8Data))
            } else {
                node.children.append(.content(content))
            }
        }
        self.children.append(.element(node))
        return self
    }

    /// Returns an array of child elements with the given name and optional namespace.
    /// - Parameters:
    ///   - elementName: the element name of the child
    ///   - namespace: the list of namespaces
    /// - Returns: the filtered list of child elements matching the name and namespace URI.
    @inlinable public func childElements(named elementName: String, namespaceURI: String? = nil) -> [XMLNode] {
        if let namespaceURI = namespaceURI {
            // there may be more than a single alias to a given namespace
            guard let prefixes = self.namespaces?.filter({ $0.value == namespaceURI }).keys,
                    !prefixes.isEmpty else {
                return []
            }
            let elementNames = prefixes.map({ $0 + ":" + elementName }).set()
            return self.elementChildren.filter { element in
                elementNames.contains(element.elementName)
            }
        } else {
            return self.elementChildren
        }
    }

    /// Returns the value of the given attribute, optionally mapped with the given URL
    /// - Parameters:
    ///   - key: the attribute key
    ///   - namespace: the namespace of the key
    /// - Returns: the value of the attribute
    @inlinable public func attributeValue(key: String, namespaceURI: String? = nil) -> String? {
        if let namespaceURI = namespaceURI {
            // there may be more than a single alias to a given namespace
            guard let prefixes = self.namespaces?.filter({ $0.value == namespaceURI }).keys,
                    !prefixes.isEmpty else {
                return nil
            }
            for pfx in prefixes {
                if let value = self.attributes[pfx + ":" + key] {
                    return value
                }
            }
            return nil
        } else {
            return self.attributes[key]
        }
    }

    @inlinable public func xmlString(declaration: String = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>", quote: String = "\"", compactCloseTags: Bool = false, escape entities: Entity = [.lt, .amp, .gt], commentScriptCDATA: Bool = false, attributeSorter: ([String: String]) -> [(String, String)] = { Array($0).sorted(by: { $0.0 < $1.0 }) }) -> String {
        var str = ""

        // when we use single quotes for entites, we escape them; same for double-quotes
        var entities = entities
        entities.insert(quote == "\"" ? .quot : .apos)

        if isDocument {
            str += declaration // the document header is the XML declaration
        } else {
            str += "<" + elementName
            for (key, value) in attributeSorter(attributes) {
                str += " " + key + "=" + quote + value.escapedXMLEntities(entities) + quote
            }
            if children.isEmpty && compactCloseTags {
                str += "/"
            }
            str += ">"
        }

        for child in children {
            switch child {
            case .element(let element):
                str += element.xmlString(quote: quote, compactCloseTags: compactCloseTags, escape: entities, commentScriptCDATA: commentScriptCDATA, attributeSorter: attributeSorter)
            case .content(let content):
                str.append(content.escapedXMLEntities(entities))
            case .comment(let comment):
                str += "<!--" + comment + "-->"
            case .cdata(let data):
                // note that we manually replace "]]>" with "]] >" in order to prevent it from breaking the CDATA
                // this is potentially dangerous, because the code might contains "]]>" that runs in a meaningful way.
                let code = (String(data: data, encoding: .utf8)?.replacingOccurrences(of: "]]>", with: "]] >") ?? "")
                //dbg("CDATA", data.localizedByteCount, elementName)
                if commentScriptCDATA && elementName == "script" {
                    // https://www.w3.org/TR/html-polyglot/#dfn-safe-text-content
                    str += "//<![CDATA[\n" + code + "\n//]]>"
                } else {
                    str += "<![CDATA[" + code + "]]>"
                }
            case .whitespace(let whitespace):
                str += whitespace
            case .processingInstruction(let target, let data):
                str += "<?" + target
                if let data = data {
                    str += " " + data
                }
                str += "?>"
            }
        }

        if !isDocument && !(children.isEmpty && compactCloseTags) {
            str += "</" + elementName + ">"
        }

        return str
    }

    /// Options for configuring the `XMLParser`
    public struct Options: OptionSet, Hashable {
        public let rawValue: Int

        public static let resolveExternalEntities = Self(rawValue: 1 << 0)
        public static let reportNamespacePrefixes = Self(rawValue: 1 << 1)
        public static let processNamespaces = Self(rawValue: 1 << 2)
        public static let tidyHTML = Self(rawValue: 1 << 3)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    /// Parses the given `Data` and returns an `XMLNode`
    @inlinable public static func parse(data: Data, options: Options = [.resolveExternalEntities, .reportNamespacePrefixes, .processNamespaces], entityResolver: ((_ name: String, _ systemID: String?) -> (Data?))? = nil) throws -> XMLNode {

        var xmlData = data
        if options.contains(.tidyHTML) {
            #if os(iOS) // XMLDocument unavailable on iOS; perhaps try CFXMLInterface?
            throw Errors.tidyHTMLUnavailable
            #else
            // round-trip the tidied document and then re-parse
            xmlData = try XMLDocument(data: data, options: .documentTidyHTML).xmlData
            #endif
        }

        let parser = XMLParser(data: xmlData)
        parser.shouldProcessNamespaces = options.contains(.processNamespaces)
        parser.shouldReportNamespacePrefixes = options.contains(.reportNamespacePrefixes)
        parser.shouldResolveExternalEntities = options.contains(.resolveExternalEntities)

        let delegate = Delegate()
        if let entityResolver = entityResolver {
            delegate.entityResolver = entityResolver
        }

        parser.delegate = delegate
        if parser.parse() == false {
            if let error = parser.parserError {
                throw error
            } else if let parseError = delegate.parseErrors.first {
                throw parseError
            } else if let validationError = delegate.validationErrors.first {
                throw validationError
            } else {
                throw Errors.unknownParseError
            }
        }

        if delegate.elements.count != 1 {
            throw Errors.badElementCount(delegate.elements.count)
        }

        return delegate.currentElement
    }

    @usableFromInline internal final class Delegate : NSObject, XMLParserDelegate {
        @usableFromInline var elements = Array<XMLNode>()
        @usableFromInline var namespaces: [String: [String]] = [:]
        @usableFromInline var parseErrors: [Error] = []
        @usableFromInline var validationErrors: [Error] = []
        @usableFromInline var entityResolver: (_ name: String, _ systemID: String?) -> (Data?) = { _, _ in nil}

        @usableFromInline override init() {
            super.init()
        }

        /// Convenience getter/setter for the button of the elements stack
        @usableFromInline var currentElement: XMLNode {
            get {
                return elements.last!
            }

            set {
                if elements.isEmpty {
                    elements.append(newValue)
                } else {
                    elements[elements.count-1] = newValue
                }
            }
        }

        @usableFromInline func parserDidStartDocument(_ parser: XMLParser) {
            // the root document is simply an empty element name
            elements.append(XMLNode(elementName: ""))
        }

        @usableFromInline func parserDidEndDocument(_ parser: XMLParser) {
            // we do nothing here because we hold on to the root document
        }

        @usableFromInline func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) {
            self.namespaces[prefix, default: []].append(namespaceURI)
        }

        @usableFromInline func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String) {
            let _ = self.namespaces[prefix]?.popLast()
        }

        @usableFromInline func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
            elements.append(XMLNode(elementName: elementName, attributes: attributeDict, children: [], namespaceURI: namespaceURI, qualifiedName: qName, namespaces: self.namespaces.compactMapValues(\.last)))
        }

        @usableFromInline func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            if let element = elements.popLast() { // remove the last element…
                currentElement.children.append(.element(element)) // … and add it as a child to the parent
            }
        }

        @inlinable func parser(_ parser: XMLParser, foundCharacters string: String) {
            currentElement.children.append(.content(string))
        }

        @inlinable func parser(_ parser: XMLParser, foundIgnorableWhitespace whitespaceString: String) {
            currentElement.children.append(.whitespace(whitespaceString))
        }

        @inlinable func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?) {
            currentElement.children.append(.processingInstruction(target: target, data: data))
        }

        @inlinable func parser(_ parser: XMLParser, foundComment comment: String) {
            currentElement.children.append(.comment(comment))
        }

        @inlinable func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            currentElement.children.append(.cdata(CDATABlock))
        }

        @inlinable func parser(_ parser: XMLParser, resolveExternalEntityName name: String, systemID: String?) -> Data? {
            entityResolver(name, systemID)
        }

        @inlinable func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
            parseErrors.append(parseError)
        }

        @inlinable func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
            validationErrors.append(validationError)
        }
    }

//    public struct ParseError : Error, Hashable {
//        /// The line number in the original document at which the error occured
//        public var lineNumber: Int
//        /// The column number in the original document at which the error occured
//        public var columnNumber: Int
//        /// The underlying error code for the error
//        public var code: XMLParser.ErrorCode
//        /// Whether this is a validation error or a parser error
//        public var validation: Bool
//    }
}


/// Utilities for XMLNode
public extension XMLNode {
    /// All the raw string content of all children (which may contain blank whitespace elements)
    @inlinable var childContent: [String] {
        self.children.map {
            if case .content(let str) = $0 { return str }
            if case .cdata(let data) = $0 { return String(data: data, encoding: .utf8) }
            return nil
        }.compactMap({ $0 })
    }

    /// Join together all the child contents that are strings or CDATA blocks
    @inlinable var stringContent: String {
        childContent.joined()
    }

    /// Join together all the child content and trim and whitespace
    @inlinable var childContentTrimmed: String {
        stringContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Converts the current node into a dictionary of element children names and the trimmed content of their joined string children.
    /// Note that any non-content children are ignored, so this is not a complete view of the element node.
    ///
    /// E.g. the XML:
    ///
    /// ```<ob><str>X</string><num>1.2</num></ob>```
    ///
    /// will return the dictionary:
    ///
    /// ```["str": "X", "num": "1.2"]```
    @inlinable func elementDictionary(attributes: Bool, childNodes: Bool) -> [String: String] {
        var dict: [String: String] = [:]
        if attributes {
            for attr in self.attributes {
                dict[attr.key] = attr.value
            }
        }
        if childNodes {
            for child in elementChildren {
                dict[child.elementName] = child.childContentTrimmed
            }
        }
        return dict
    }
}

internal extension String {

    /// Returns the string with the given XML entites escaped; the default does not include single apostrophes
    @inlinable func escapedXMLEntities(_ entities: XMLNode.Entity) -> String {
        var str = ""
        str.reserveCapacity(self.count)
        let lt = entities.contains(.lt)
        let amp = entities.contains(.amp)
        let gt = entities.contains(.gt)
        let quot = entities.contains(.quot)
        let apos = entities.contains(.apos)
        for char in self {
            switch char {
            case "<" where lt: str.append("&lt;")
            case "&" where amp: str.append("&amp;")
            case ">" where gt: str.append("&gt;")
            case "\"" where quot: str.append("&quot;")
            case "'" where apos: str.append("&apos;") // messes up CSS, and isn't necessary
            default: str.append(char)
            }
        }
        return str
    }
}
