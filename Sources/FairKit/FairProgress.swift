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
import Swift
#if canImport(SwiftUI)
import SwiftUI
import Combine

/// A progress style that shows a circle being filled in.
/// The `Label` and `CurrentValueLabel` are not rendered as part of the view.
public struct PieProgressViewStyle : ProgressViewStyle {
    let lineWidth: CGFloat

    public init(lineWidth: CGFloat) {
        self.lineWidth = lineWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        PieProgressView(fractionCompleted: configuration.fractionCompleted ?? 1.0, label: configuration.label, currentValueLabel: configuration.currentValueLabel, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .bevel, miterLimit: 0, dash: [], dashPhase: 0))
    }
}

private struct PieProgressView<L1: View, L2: View> : View {
    let fractionCompleted: Double
    let label: L1
    let currentValueLabel: L2
    let style: StrokeStyle

    var body: some View {
        // draw a faint outline
        Circle()
            .stroke(style: self.style)
            .opacity(0.4)
        Circle()
            .trim(from: 0, to: fractionCompleted)
            .stroke(style: self.style)
            .rotationEffect(Angle(degrees: -90))
            .opacity(0.8)
    }
}



public struct CapsuleProgressViewStyle : ProgressViewStyle {
    public init() {
    }

    public func makeBody(configuration: Configuration) -> some View {
        CapsuleProgressView(fractionCompleted: configuration.fractionCompleted ?? 1.0, label: configuration.label, currentValueLabel: configuration.currentValueLabel)
    }
}

private struct CapsuleProgressView<L1: View, L2: View> : View {
    let fractionCompleted: Double
    let label: L1
    let currentValueLabel: L2

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.secondary)
            Capsule()
                .fill(.linearGradient(stops: [
                    Gradient.Stop(color: Color.accentColor, location: 0.0),
                    Gradient.Stop(color: Color.accentColor, location: fractionCompleted),
                    Gradient.Stop(color: Color.clear, location: fractionCompleted),
                    Gradient.Stop(color: Color.clear, location: 1.0)
                ], startPoint: UnitPoint(x: 0.0, y: 0.5), endPoint: UnitPoint(x: 1.0, y: 0.5)))
                .animation(Animation.easeIn, value: fractionCompleted) // this animates the progress bar smoothly
            Capsule()
                .stroke(Color.accentColor, lineWidth: 2)

            label
                .font(Font.headline.smallCaps())
            VStack {
                Spacer()
                // if the progress has a current value, put in in the bottom
                currentValueLabel
                    .font(Font.caption)
            }
        }
    }
}


/// Observable progress
public final class ObservableProgress: ObservableObject {
    public var progress: Progress {
        didSet {
            self.cancellable = progress.publisher(for: \.fractionCompleted)
                .combineLatest(progress.publisher(for: \.localizedAdditionalDescription))
                .throttle(for: 0.005, scheduler: DispatchQueue.main, latest: true)
                .sink { [weak self] _ in
                    // dbg("progress:", self?.progress.fractionCompleted)
                    // assert((self?.progress.fractionCompleted ?? 0.0) <= wip(1.0))
                    self?.objectWillChange.send()
                }
        }
    }
    private var cancellable: AnyCancellable!

    public init(progress: Progress = Progress()) {
        self.progress = progress
    }
}

/// A progress view that observes the underlying `ObservableProgress`.
@available(iOS 14.0, macOS 11.0, *)
public struct FairProgressView: View {
    @StateObject private var progress: ObservableProgress

    public init(_ progress: Progress) {
        _progress = StateObject(wrappedValue: ObservableProgress(progress: progress))
    }

    public var body: some View {
        ProgressView(progress.progress)
        //    .progressViewStyle(CapsuleProgressViewStyle())
        // ProgressView(value: progress.progress.fractionCompleted, total: 1.0)
        // .labelsHidden()
        // .progressViewStyle(.circular)

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
                //.progressViewStyle(PieProgressViewStyle(lineWidth: 40))
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
