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
import FairApp

#if canImport(SwiftUI)
#if DEBUG

public protocol SponsorshipService {

}

public extension SponsorshipService {
    static var github: SponsorshipService { GitHubSponsorshipService() }
}

private struct GitHubSponsorshipService : SponsorshipService {

}

public enum SponsorshipState {
    case planned
    case inProgress
    case available
}

public struct SponsoredFeature {
    public let name: LocalizedStringKey
    public let state: SponsorshipState
}

extension SponsoredFeature {
    public var sponsorStrings: (description: LocalizedStringKey, buttonText: LocalizedStringKey) {
        switch self.state {
        case .planned:
            return (LocalizedStringKey("This feature is being planned for a future release (subject to sponsorship goals)."), LocalizedStringKey("See Sponsorship Options"))
        case .inProgress:
            return (LocalizedStringKey("This feature is currently being developed, and is available as a preview to sponsors."), LocalizedStringKey("See Sponsorship Options"))
        case .available:
            return (LocalizedStringKey("This feature has been implemeted and can be made available once the project funding goals have been reached."), LocalizedStringKey("See Sponsorship Options"))
        }
    }
}

public struct SponsorButton {

}

/// A button that wraps an action with a check for whether the feature is available yet
public struct TeaserButton : View {
    public let feature: SponsoredFeature

    public var body: some View {
        Button {
            dbg("sponsor button")
        } label: {
            Text(feature.name)
        }
    }
}

#endif // DEBUG
#endif // canImport(SwiftUI)
