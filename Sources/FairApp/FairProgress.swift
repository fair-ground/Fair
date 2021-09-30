/**
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
#if canImport(SwiftUI)
import SwiftUI
import Combine

@available(iOS 14.0, macOS 11.0, *)
public struct FairProgressView: View {
    @StateObject private var progress: ProgressObserver

    public init(_ progress: Progress) {
        _progress = StateObject(wrappedValue: ProgressObserver(progress: progress))
    }

    /// An observable pass-through for a progress bar
    private final class ProgressObserver: ObservableObject {
        var progress: Progress
        var cancellable: AnyCancellable!

        init(progress: Progress) {
            self.progress = progress
            self.cancellable = progress.publisher(for: \.fractionCompleted)
                .combineLatest(progress.publisher(for: \.localizedAdditionalDescription))
                .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
                .sink { [weak self] _ in self?.objectWillChange.send() }
        }
    }

    public var body: some View {
        ProgressView(progress.progress)
    }
}

@available(iOS 14.0, macOS 11.0, *)
struct FairProgressView_Previews: PreviewProvider {
    static var previews: some View {
        let progress: Progress = {
            let progress = Progress()
            progress.kind = .file
            progress.fileOperationKind = .downloading
            progress.estimatedTimeRemaining = 123
            progress.totalUnitCount = 114848484
            progress.completedUnitCount = 8484420
            progress.throughput = 921161
            return progress
        }()

        return Group {
            FairProgressView(progress)
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
