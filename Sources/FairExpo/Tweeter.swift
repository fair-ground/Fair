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
import FairApp

/// A very simple Twitter client for posting messages (and nothing else).
public enum Tweeter {
    /// Posts the given message, returning a response like:
    /// `{"data":{"id":"1543033216067567616","text":"New Release: Cloud Cuckoo 0.9.75 - https://t.co/pris66nrlj"}}`
    public static func post(text: String, reply_settings: String? = nil, quote_tweet_id: TweetID? = nil, in_reply_to_tweet_id: TweetID? = nil, direct_message_deep_link: String? = nil, auth: OAuth1.Info) async throws -> PostResponse {
        // https://developer.twitter.com/en/docs/twitter-api/tweets/manage-tweets/api-reference/post-tweets
        let url = URL(string: "https://api.twitter.com/2/tweets")!

        let method = "POST"
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(OAuth1.authHeader(for: method, url: url, info: auth), forHTTPHeaderField: "Authorization")

        struct Post : Encodable {
            var text: String
            var reply_settings: String?
            var quote_tweet_id: TweetID?
            var direct_message_deep_link: String?

            // TODO:
            // let for_super_followers_only: Bool
            // let geo.place_id: String
            // let media.media_ids: [String]
            // let media.tagged_user_ids: [String]
            // let poll.duration_minutes: [String]
            // let poll.options: [String]

            var reply: Reply?

            struct Reply : Encodable {
                var in_reply_to_tweet_id: TweetID

                /// Please note that `in_reply_to_tweet_id` needs to be in the request if `exclude_reply_user_ids` is present.
                var exclude_reply_user_ids: [String]?
            }
        }

        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var post = Post(text: text, reply_settings: reply_settings, quote_tweet_id: quote_tweet_id, direct_message_deep_link: direct_message_deep_link, reply: nil)
        if let in_reply_to_tweet_id = in_reply_to_tweet_id {
            post.reply = .init(in_reply_to_tweet_id: in_reply_to_tweet_id, exclude_reply_user_ids: nil)
        }
        req.httpBody = try post.json()

        let (data, response) = try await URLSession.shared.fetch(request: req, validate: nil) // [201]) // 201 Created is the only valid response code
        dbg("received posting response:", response)
        dbg("received posting data:", data.utf8String ?? "")
        let responseItem = try PostResponse(json: data)
        return responseItem
    }

    /// A Twitter ID is a numeric string like "1542958914332934147"
    public struct TweetID : RawCodable {
        public typealias RawValue = String // XOr<String>.Or<UInt64>
        public let rawValue: RawValue

        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }

    /// The response to a tweet can be either success or an error
    public struct PostResponse : RawCodable {
        public typealias RawValue = XOr<TweetPostedResponse>.Or<TweetPostedError>
        public let rawValue: RawValue

        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }

        /// The error if it was unsuccessful
        public var error: TweetPostedError? { rawValue.infer() }

        /// The tweet response, if it is not an error
        public var response: TweetPostedResponse? { rawValue.infer() }
    }

    public struct TweetPostedResponse : Codable {
        public let data: Payload
        public struct Payload : Codable {
            public let id: TweetID
            public let text: String
        }
    }

    /// {"detail":"You are not allowed to create a Tweet with duplicate content.","type":"about:blank","title":"Forbidden","status":403}
    public struct TweetPostedError : Codable {
        public let type: String
        public let title: String
        public let detail: String
        public let status: Int
    }

}
