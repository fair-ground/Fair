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

import struct Foundation.Data

/// An RSS web feed document outline with a generic `WebFeedAdditions` parameters allowing extension points for the various elements.
public struct WebFeed<Additions: WebFeedAdditions> {
    public var channels: [Channel]

    /// Additional properties as defined in the item additions
    public var additions: Additions.FeedAdditions?

    public init(channels: [Channel] = [], additions: Additions.FeedAdditions? = nil) throws {
        self.channels = channels
        self.additions = additions
    }

    /// Attempts to initialze the WebFeed with the given RSS data, which must be valid XML.
    public init(xmlData data: Data) throws {
        try self.init(node: XMLNode.parse(data: data, options: [.reportNamespacePrefixes]))
    }

    private init(node: FairCore.XMLNode) throws {
        guard let root = node.elementChildren.first,
              root.elementName == "rss" else {
            throw Errors.noRSSRoot
        }
        let channels = root.elementChildren
        if channels.contains(where: { $0.elementName != "channel" }) {
            throw Errors.rootChannelsInvalid
        }
        self.channels = try channels.map(Channel.init)

        self.additions = try Additions.FeedAdditions(node: node)
    }

    public struct Channel {
        public var title: String?
        public var link: String?
        public var language: String?
        public var description: String?
        public var items: [Item]

        /// Additional properties as defined in the item additions
        public var additions: Additions.ChannelAdditions?

        public init(title: String? = nil, link: String? = nil, language: String? = nil, description: String? = nil, items: [Item] = [], additions: Additions.ChannelAdditions? = nil) {
            self.title = title
            self.link = link
            self.language = language
            self.description = description
            self.items = []
            self.additions = additions
        }

        public init(node: FairCore.XMLNode) throws {
            let elements = node.elementChildren.dictionary(keyedBy: \.elementName)

            self.title = elements["title"]?.childContentTrimmed
            self.link = elements["link"]?.childContentTrimmed
            self.description = elements["description"]?.stringContent // note we don't trim
            self.language = elements["language"]?.childContentTrimmed

            self.items = try node.elementChildren.filter({ $0.elementName == "item" }).map(Item.init)
            self.additions = try Additions.ChannelAdditions(node: node)
        }

        public struct Item {
            public var title: String?
            public var link: String?
            public var pubDate: String?
            public var description: String?
            public var enclosures: [Enclosure]

            /// Additional properties as defined in the item additions
            public var additions: Additions.ItemAdditions?

            public init(title: String? = nil, link: String? = nil, pubDate: String? = nil, description: String? = nil, enclosures: [Enclosure] = [], additions: Additions.ItemAdditions? = nil) {
                self.title = title
                self.link = link
                self.pubDate = pubDate
                self.description = description
                self.enclosures = enclosures
                self.additions = additions
            }

            public init(node: FairCore.XMLNode) throws {
                let elements = node.elementChildren.dictionary(keyedBy: \.elementName)

                self.title = elements["title"]?.childContentTrimmed
                self.link = elements["link"]?.childContentTrimmed
                self.pubDate = elements["pubDate"]?.childContentTrimmed
                self.description = elements["description"]?.stringContent // note we don't trim

                self.enclosures = try node.elementChildren.filter({ $0.elementName == "enclosure" }).map(Enclosure.init)
                self.additions = try Additions.ItemAdditions(node: node)
            }
        }

        // <enclosure url="https://sparkle-project.org/files/Sparkle%20Test%20App.zip" length="107758" type="application/octet-stream" sparkle:edSignature="7cLALFUHSwvEJWSkV8aMreoBe4fhRa4FncC5NoThKxwThL6FDR7hTiPJh1fo2uagnPogisnQsgFgq6mGkt2RBw==" />

        public struct Enclosure {
            public var url: String?
            public var length: String?
            public var type: String?

            public var additions: Additions.EnclosureAdditions?

            public init(url: String? = nil, length: String? = nil, type: String? = nil, additions: Additions.EnclosureAdditions? = nil) {
                self.url = url
                self.length = length
                self.type = type
                self.additions = additions
            }

            public init(node: FairCore.XMLNode) throws {
                let dict = node.elementDictionary(attributes: true, childNodes: false)
                self.url = dict["url"]
                self.length = dict["length"]
                self.type = dict["type"]

                self.additions = try Additions.EnclosureAdditions(node: node)
            }
        }
    }

    public enum Errors : Error {
        case noRSSRoot
        case rootChannelsInvalid
        case noChannelTitle
        case noChannelLink
    }
}

/// An instance that can be created from an XML node
public protocol XMLNodeExpressible {
    init?(node: FairCore.XMLNode) throws
}

extension Never : XMLNodeExpressible {
    public init?(node: FairCore.XMLNode) throws {
        nil
    }
}

/// Contains optional structures that can hold additional data in the outline of a `WebFeed`
public protocol WebFeedAdditions {
    associatedtype FeedAdditions: XMLNodeExpressible
    associatedtype ChannelAdditions: XMLNodeExpressible
    associatedtype ItemAdditions: XMLNodeExpressible
    associatedtype EnclosureAdditions: XMLNodeExpressible
}

/// An empty default additions protocol implementation for `WebFeedAdditions`
public enum EmptyFeedAdditions : WebFeedAdditions {
    public typealias FeedAdditions = Never
    public typealias ChannelAdditions = Never
    public typealias ItemAdditions = Never
    public typealias EnclosureAdditions = Never
}

extension WebFeed : Equatable where Additions.FeedAdditions : Equatable, Additions.ChannelAdditions : Equatable, Additions.EnclosureAdditions : Equatable, Additions.ItemAdditions : Equatable { }
extension WebFeed.Channel : Equatable where Additions.ChannelAdditions : Equatable, Additions.EnclosureAdditions : Equatable, Additions.ItemAdditions : Equatable { }
extension WebFeed.Channel.Item : Equatable where Additions.EnclosureAdditions : Equatable, Additions.ItemAdditions : Equatable { }
extension WebFeed.Channel.Enclosure : Equatable where Additions.EnclosureAdditions : Equatable { }

extension WebFeed : Hashable where Additions.FeedAdditions : Hashable, Additions.ChannelAdditions : Hashable, Additions.EnclosureAdditions : Hashable, Additions.ItemAdditions : Hashable { }
extension WebFeed.Channel : Hashable where Additions.ChannelAdditions : Hashable, Additions.EnclosureAdditions : Hashable, Additions.ItemAdditions : Hashable { }
extension WebFeed.Channel.Item : Hashable where Additions.EnclosureAdditions : Hashable, Additions.ItemAdditions : Hashable { }
extension WebFeed.Channel.Enclosure : Hashable where Additions.EnclosureAdditions : Hashable { }

extension WebFeed : Sendable where Additions.FeedAdditions : Sendable, Additions.ChannelAdditions : Sendable, Additions.EnclosureAdditions : Sendable, Additions.ItemAdditions : Sendable { }
extension WebFeed.Channel : Sendable where Additions.ChannelAdditions : Sendable, Additions.EnclosureAdditions : Sendable, Additions.ItemAdditions : Sendable { }
extension WebFeed.Channel.Item : Sendable where Additions.EnclosureAdditions : Sendable, Additions.ItemAdditions : Sendable { }
extension WebFeed.Channel.Enclosure : Sendable where Additions.EnclosureAdditions : Sendable { }

