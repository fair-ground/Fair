import Swift

/// A parsed SVG path as per: https://www.w3.org/TR/SVG11/paths.html#PathDataBNF
///
/// Paths can be used to derive a `CGPath`, which in turn can be rendered in a `SwiftUI.Shape`.
///
/// For example, creating a half circle with a radius of 26:
///
/// ```
/// let pathView = try SVGPath("M 0 0 A 25 25 0 1 0 0 50Z").fill(Color.red)
/// ```
@available(macOS 11.0, iOS 14.0, *)
public struct SVGPath : Hashable, Sendable {
    /// The parsed tokens of the path
    private let tokens: [PathToken]
    /// The amount to inset the drawn path by
    private var inset: CGFloat = 0.0

    /// Initialize this view with the given SVG path.
    /// An error will be thrown if the path cannot be parsed.
    public init(_ svgPath: String) throws {
        var parser = PathParser()
        self.tokens = try parser.parse(pathString: svgPath)
    }
}


#if canImport(CoreGraphics)
import CoreGraphics

extension SVGPath {
    /// The underlying `CGPath` for the SVG string
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var builder = CGMutablePath.CGPathBuilder(path: path, tokens: tokens)
        builder.build()
        return path
    }
}

public struct SVGPathOptions : OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// Use absolute paths instead of relative paths
    public static let absolute = SVGPathOptions(rawValue: 1 << 0)

    /// Use spaces instead of commas
    public static let spaces = SVGPathOptions(rawValue: 1 << 1)
}

extension CGPath {

    /// The path data describing of the outline of a shape per the SVG section on [Path data](https://www.w3.org/TR/SVG11/paths.html#PathData)
    ///
    /// - Parameter options: whether to use absolute (vs. relative) coordinates and spaces (vs. commas) when generating the path data.
    /// - Returns: the SVG path data
    func svgPath(_ options: SVGPathOptions = []) -> String {
        enum PathCmd {
            case moveTo(CGPoint)
            case lineTo(CGPoint)
            case curveTo(CGPoint, CGPoint, CGPoint)
            case quadCurveTo(CGPoint, CGPoint)
            case closePath

            func svgString(relative: Bool, sep: String, lastPoint: inout CGPoint) -> String {
                let xoff = relative ? lastPoint.x : 0
                let yoff = relative ? lastPoint.y : 0

                func pointString(_ points: [CGPoint]) -> String {
                    return points.map({ String(format: "%g%@%g", $0.x-xoff, sep, $0.y-yoff) }).joined(separator: sep)
                }

                func cmd(_ char: Character) -> String {
                    return relative ? String(char).lowercased() : String(char).uppercased()
                }

                switch self {
                case .moveTo(let p1):
                    lastPoint = p1
                    return cmd("M") + pointString([p1])
                case .lineTo(let p1):
                    lastPoint = p1
                    if p1.x - xoff == 0 { // shorthand V(ertical)
                        return cmd("V") + String(format: "%g", p1.y - yoff)
                    } else if p1.y - yoff == 0 { // shorthand H(orizontal)
                        return cmd("H") + String(format: "%g", p1.x - xoff)
                    } else {
                        return cmd("L") + pointString([p1])
                    }
                case .curveTo(let p1, let p2, let p3):
                    lastPoint = p3
                    return cmd("C") + pointString([p1, p2, p3])
                case .quadCurveTo(let p1, let p2):
                    lastPoint = p2
                    return cmd("Q") + pointString([p1, p2])
                case .closePath:
                    return cmd("Z")
                }
            }
        }

        var cmds: [PathCmd] = []
        self.applyWithBlock { element in
            let points = element.pointee.points
            switch element.pointee.type {
            case .moveToPoint: cmds.append(.moveTo(points[0]))
            case .addLineToPoint: cmds.append(.lineTo(points[0]))
            case .addCurveToPoint: cmds.append(.curveTo(points[0], points[1], points[2]))
            case .addQuadCurveToPoint: cmds.append(.quadCurveTo(points[0], points[1]))
            case .closeSubpath: cmds.append(.closePath)
            @unknown default: cmds.append(.closePath)
            }
        }

        if cmds.isEmpty { // no path means no SVG
            return "m0,0z"
        }

        // trim out trailing moveTo commands; they unnecessarily make the controlPointBounds of the path larger
        // while case .some(.moveTo) = cmds.last { cmds = cmds.dropLast() }
        let sep = options.contains(.spaces) ? " " : ","
        let relative = !options.contains(.absolute)

        var svg = ""
        var current = CGPoint.zero
        for cmd in cmds {
            svg += cmd.svgString(relative: relative, sep: sep, lastPoint: &current)
        }
        return svg
    }
}


extension CGPath {

}

#if canImport(SwiftUI)
import SwiftUI

/// Renders the underlying path as a `SwiftUI.InsettableShape`.
@available(macOS 11.0, iOS 14.0, *)
extension SVGPath : View, InsettableShape {
    public func path(in rect: CGRect) -> Path {
        Path(cgPath.fitting(rect: rect, inset: inset))
    }

    /// Returns `self` inset by `amount`.
    public func inset(by amount: CGFloat) -> Self {
        var shape = self
        shape.inset += amount
        return shape
    }
}

public extension Path {
    /// create a SwiftUI Path element from a svg formatted string
    /// https://www.w3.org/TR/SVG11/paths.html
    /// For example, creating a half circle with a radius of 26:
    /// private let cgPath = CGPath.path(fromSVGPath: "M 0 0 A 25 25 0 1 0 0 50Z")!
    init(svgPath: String) throws {
        let cgPath = try CGPath.path(fromSVGPath: svgPath)
        self.init(cgPath)
    }
}

#endif

// Path parsing is mostly based on https://github.com/GenerallyHelpfulSoftware/Scalar2D which uses the following license:
//
// MIT License
//
// Copyright (c) 2016-2019 Generally Helpful Software
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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension CGPath
{
    /// Transform this CGPath to fit int the given rectangle
    func fitting(rect sourceRect: CGRect, inset sourceInset: CGFloat = 0.0, stretch: Bool = false) -> CGPath
    {
        let (containerWidth, containerHeight) = (sourceRect.width, sourceRect.height)

        let bbox = self.boundingBoxOfPath
        let (pathWidth, pathHeight) = (bbox.width, bbox.height)
        guard containerWidth >= 0 && containerHeight >= 0 && !bbox.isEmpty && !bbox.isInfinite && !bbox.isNull && pathWidth > 0 && pathHeight > 0 else
        {
            return self
        }


        let inset = sourceInset
        let rect = sourceRect.insetBy(dx: inset, dy: inset)
        let scaleX = rect.width / pathWidth
        let scaleY = rect.height / pathHeight
        let scale = min(scaleX, scaleY)

        //dbg("fitting sourceRect:", sourceRect, "inset rect:", rect, "bbox:", bbox, "scaleX:", scaleX, "scaleY:", scaleY)

        let scaledPathWidth = pathWidth * scale
        let scaledPathHeight = pathHeight * scale

        if scale < 0 {
            return CGMutablePath()
        }
        
        if scaledPathWidth - (inset * scale) <= 0 {
            return CGMutablePath()
        }

        if scaledPathHeight - (inset * scale) <= 0 {
            return CGMutablePath()
        }

        var requiredTransform = CGAffineTransform.identity
//            .translatedBy(x: rect.minX, y: rect.minY)
//            .translatedBy(x: centerX, y: centerY)
//            .translatedBy(x: pathWidth/2.0, y: pathHeight/2.0)
//            .translatedBy(x: (containerWidth / 2.0), y: 0.0)
            .translatedBy(x: (inset / 2) - (rect.minX / 2), y: (inset / 2) - (rect.minY / 2))
            .translatedBy(x: (containerWidth/2.0) - (scaledPathWidth/2.0), y: (containerHeight/2.0) - (scaledPathHeight/2.0))
            .scaledBy(x: stretch ? scaleX : scale, y: stretch ? scaleY : scale)
            .translatedBy(x: -bbox.minX, y: -bbox.minY)
//            .translatedBy(x: scale != scaleX ? (containerWidth / 2.0) : 0.0, y: 0.0)
//            .translatedBy(x: inset, y: inset)
//            .translatedBy(x: (containerWidth/2.0) - (containerWidth - pathWidth)/2.0, y: (containerHeight/2.0) - (containerHeight - pathHeight)/2.0)

        return self.copy(using: &requiredTransform) ?? self
    }
}

private struct Vector2D
{
    let deltaX: CGFloat
    let deltaY: CGFloat

    init(deltaX: CGFloat, deltaY: CGFloat)
    {
        self.deltaX = deltaX
        self.deltaY = deltaY
    }

    private var vectorMagnitude: CGFloat
    {
        let    result = sqrt(self.deltaX*self.deltaX+self.deltaY*self.deltaY)
        return result
    }

    func vectorRatio(vector2: Vector2D) -> CGFloat
    {
        var result = self.deltaX*vector2.deltaX + self.deltaY*vector2.deltaY
        result /= self.vectorMagnitude*vector2.vectorMagnitude
        return result
    }

    func vectorAngle(vector2: Vector2D) -> CGFloat
    {
        let vectorRatio = self.vectorRatio(vector2: vector2)
        var  result = acos(vectorRatio)
        if(self.deltaX*vector2.deltaY) < (self.deltaY*vector2.deltaX)
        {
            result *= -1.0
        }
        return result
    }
}

private extension CGMutablePath
{
    struct CGPathBuilder
    {
        private let tokens: [PathToken]
        var x: CGFloat = 0.0
        var y: CGFloat = 0.0

        var lastCubicX₂: CGFloat?
        var lastCubicY₂: CGFloat?

        var lastQuadX₁: CGFloat?
        var lastQuadY₁: CGFloat?

        let mutablePath : CGMutablePath

        fileprivate init(path: CGMutablePath, tokens: [PathToken])
        {
            self.mutablePath = path
            self.tokens = tokens

            if !path.isEmpty
            {
                let startCoordinate = path.currentPoint
                self.x = startCoordinate.x
                self.y = startCoordinate.y
            }
        }


        /**
         The smooth/shortcut operators T & S work with the control points of the immediately previous curve operators. This method just cleans the control points out if the previous operand was not a curve operatior.
         **/
        mutating func clearControlPoints()
        {
            lastCubicX₂ = nil
            lastQuadX₁ = nil
        }

        /**
         A routine to take the parameters provided by an SVG arc operator and add it to a CGMutablePath
         - parameters:
         - xRadius: the radius of the arc along the X axis
         - yRadius: the radious of the arc along the Y axis
         - tiltAngle: the rotation (in degrees) of the arc off the X Axis
         - largeArcFlag: whether the long path will be selected
         - sweepFlag: whether the path will travel clockwise or counterclockwise
         - endX: the absolute X coordinate of the end point.
         - endY: the absolute Y coordinate of the end point.

         - warning; An end point that equals the start point will result in nothing being drawn.
         **/
        mutating private func addArc(xRadius radX: CGFloat, yRadius radY: CGFloat, tiltAngle: Double, largeArcFlag: PathToken.ArcChoice, sweepFlag: PathToken.ArcSweep, endX: CGFloat, endY: CGFloat)
        {
            //implementation notes http://www.w3.org/TR/SVG/implnote.html#ArcConversionEndpointToCenter
            // general algorithm from MIT licensed http://code.google.com/p/svg-edit/source/browse/trunk/editor/canvg/canvg.js
            // Gabe Lerner (gabelerner@gmail.com)
            // first do first aid to the parameters to keep them in line

            let kDegreesToRadiansConstant: Double = Double.pi/180.0

            defer
            {
                self.x = endX
                self.y = endY
            }

            if(self.x == endX && endY == self.y)
            { // do nothing
            }
            else if(radX == 0.0 || radY == 0.0) // not an actual arc, draw a line segment
            {
                self.mutablePath.addLine(to: CGPoint(x: endX, y: endY))
            }
            else // actually try to draw an arc
            {
                var xRadius = abs(radX) // make sure radius are positive
                var yRadius = abs(radY)
                let xAxisRotationDegrees = fmod(tiltAngle, 360.0)

                let xAxisRotationRadians = xAxisRotationDegrees*kDegreesToRadiansConstant


                let cosineAxisRotation = CGFloat(cos(xAxisRotationRadians))
                let sineAxisRotation = CGFloat(sin(xAxisRotationRadians))

                let deltaX = self.x-endX
                let deltaY = self.y-endY

                let ½DeltaX = deltaX / 2.0
                let ½DeltaY = deltaY / 2.0

                var xRadius² = xRadius*xRadius
                var yRadius² = yRadius*yRadius


                // steps are from the implementation notes
                // F.6.5  Step 1: Compute (x1′, y1′)
                let    translatedCurPoint = CGPoint(x: cosineAxisRotation*½DeltaX+sineAxisRotation*½DeltaY,
                                                    y: -1.0*sineAxisRotation*½DeltaX+cosineAxisRotation*½DeltaY)


                let translatedCurPointX² = translatedCurPoint.x*translatedCurPoint.x
                let translatedCurPointY² = translatedCurPoint.y*translatedCurPoint.y

                // (skipping to different section) F.6.6 Step 3: Ensure radii are large enough
                var    shouldBeNoMoreThanOne = translatedCurPointX²/(xRadius²)
                + translatedCurPointY²/(yRadius²)

                if(shouldBeNoMoreThanOne > 1.0)
                {
                    xRadius *= sqrt(shouldBeNoMoreThanOne)
                    yRadius *= sqrt(shouldBeNoMoreThanOne)

                    xRadius² = xRadius*xRadius
                    yRadius² = yRadius*yRadius

                    shouldBeNoMoreThanOne = translatedCurPointX²/(xRadius²)
                    + translatedCurPointY²/(yRadius²)
                    if(shouldBeNoMoreThanOne > 1.0) // sometimes just a bit north of 1.0000000 after first pass
                    {
                        shouldBeNoMoreThanOne += 0.000001 // making sure
                        xRadius *= sqrt(shouldBeNoMoreThanOne)
                        yRadius *= sqrt(shouldBeNoMoreThanOne)

                        xRadius² = xRadius*xRadius
                        yRadius² = yRadius*yRadius
                    }
                }

                var    transform = CGAffineTransform.identity
                // back to  F.6.5   Step 2: Compute (cx′, cy′)
                let  centerScalingDivisor = xRadius²*translatedCurPointY²
                + yRadius²*translatedCurPointX²

                var    centerScaling = CGFloat(0.0)

                if(centerScalingDivisor != 0.0)
                {
                    let centerScaling² = (xRadius²*yRadius²
                                          - xRadius²*translatedCurPointY²
                                          - yRadius²*translatedCurPointX²)
                    / centerScalingDivisor

                    centerScaling = sqrt(centerScaling²)


                    if(centerScaling.isNaN)
                    {
                        centerScaling = 0.0
                    }

                    if(sweepFlag.rawValue == largeArcFlag.rawValue)
                    {

                        centerScaling *= -1.0
                    }
                }

                let translatedCenterPoint = CGPoint(x: centerScaling*xRadius*translatedCurPoint.y/yRadius,
                                                    y: -1.0*centerScaling*yRadius*translatedCurPoint.x/xRadius)

                // F.6.5  Step 3: Compute (cx, cy) from (cx′, cy′)


                let averageX = (self.x+endX)/2.0
                let averageY = (self.y+endY)/2.0
                let centerPoint = CGPoint(x:averageX+cosineAxisRotation*translatedCenterPoint.x-sineAxisRotation*translatedCenterPoint.y,
                                          y: averageY+sineAxisRotation*translatedCenterPoint.x+cosineAxisRotation*translatedCenterPoint.y)
                // F.6.5   Step 4: Compute θ1 and Δθ

                // misusing CGPoint as a vector
                let vectorX = Vector2D(deltaX: 1.0, deltaY: 0.0)
                let vectorU = Vector2D(deltaX: (translatedCurPoint.x-translatedCenterPoint.x)/xRadius,
                                       deltaY: (translatedCurPoint.y-translatedCenterPoint.y)/yRadius)
                let vectorV = Vector2D(deltaX: (-1.0*translatedCurPoint.x-translatedCenterPoint.x)/xRadius,
                                       deltaY: (-1.0*translatedCurPoint.y-translatedCenterPoint.y)/yRadius)

                let    startAngle = vectorX.vectorAngle(vector2: vectorU)

                var    angleDelta = vectorU.vectorAngle(vector2: vectorV)

                let vectorRatio = vectorU.vectorRatio(vector2: vectorV)

                if(vectorRatio <= -1)
                {
                    angleDelta = CGFloat.pi
                }
                else if(vectorRatio >= 1.0)
                {
                    angleDelta = 0.0
                }

                switch sweepFlag
                {
                case .clockwise where angleDelta > 0.0:
                    angleDelta = angleDelta - 2.0 * CGFloat.pi
                case .counterclockwise where angleDelta < 0.0:
                    angleDelta = angleDelta - 2.0 * CGFloat.pi
                default:
                    break
                }

                transform = transform.translatedBy(x: centerPoint.x, y: centerPoint.y)

                transform = transform.rotated(by: CGFloat(xAxisRotationRadians))

                let radius = (xRadius > yRadius) ? xRadius : yRadius
                let scaleX = (xRadius > yRadius) ? 1.0 : xRadius / yRadius
                let scaleY = (xRadius > yRadius) ? yRadius / xRadius : 1.0

                transform = transform.scaledBy(x: scaleX, y: scaleY)

                self.mutablePath.addArc(center: CGPoint.zero, radius: radius, startAngle: startAngle, endAngle: startAngle+angleDelta, clockwise: 0 == sweepFlag.rawValue, transform: transform)
            }
            clearControlPoints()
        }
        /**
         Loop over the tokens and add the equivalent CGPath operation to the mutablePath.
         */
        mutating func build()
        {
            for aToken in tokens
            {
                switch aToken
                {
                case .close:
                    mutablePath.closeSubpath()
                    if !mutablePath.isEmpty // move the start point to the
                    {
                        let startPoint = mutablePath.currentPoint
                        x = startPoint.x
                        y = startPoint.y
                    }
                case let .moveTo(deltaX, deltaY):
                    x = x + deltaX
                    y = y + deltaY

                    mutablePath.move(to: CGPoint(x: x, y: y))
                    clearControlPoints()

                case let .moveToAbsolute(newX, newY):
                    x = newX
                    y = newY
                    mutablePath.move(to: CGPoint(x: x, y: y))
                    clearControlPoints()

                case let .lineTo(deltaX, deltaY):
                    x = x + deltaX
                    y = y + deltaY
                    mutablePath.addLine(to: CGPoint(x: x, y: y))
                    clearControlPoints()

                case let .lineToAbsolute(newX, newY):
                    x = newX
                    y = newY
                    mutablePath.addLine(to: CGPoint(x: x, y: y))
                    clearControlPoints()

                case .horizontalLineTo(let deltaX):
                    x = x + deltaX
                    mutablePath.addLine(to: CGPoint(x: x, y: y))
                    clearControlPoints()

                case .horizontalLineToAbsolute(let newX):
                    x = newX
                    mutablePath.addLine(to: CGPoint(x: x, y: y))
                    clearControlPoints()

                case .verticalLineTo(let deltaY):
                    y = y + deltaY
                    mutablePath.addLine(to: CGPoint(x: x, y: y))
                    clearControlPoints()

                case .verticalLineToAbsolute(let newY):
                    y = newY
                    mutablePath.addLine(to: CGPoint(x: x, y: y))
                    clearControlPoints()

                case let .quadraticBezierTo(deltaX₁, deltaY₁, deltaX, deltaY):
                    let x₁ = deltaX₁ + x
                    let y₁ = deltaY₁ + y
                    x = x + deltaX
                    y = y + deltaY

                    mutablePath.addQuadCurve(to: CGPoint(x: x, y: y) , control: CGPoint(x: x₁, y: y₁))
                    lastCubicX₂ = nil // clean out the last cubic as this is a quad

                    lastQuadX₁ = x₁
                    lastQuadY₁ = y₁

                case let .quadraticBezierToAbsolute(x₁, y₁, newX, newY):
                    x = newX
                    y = newY
                    mutablePath.addQuadCurve(to: CGPoint(x: x, y: y) , control: CGPoint(x: x₁, y: y₁))
                    lastCubicX₂ = nil // clean out the last cubic as this is a quad
                    lastQuadX₁ = x₁
                    lastQuadY₁ = y₁

                case let .smoothQuadraticBezierTo(deltaX, deltaY):
                    var x₁ = x
                    var y₁ = y

                    if let previousQuadX₁  = self.lastQuadX₁,
                       let previousQuadY₁ = self.lastQuadY₁
                    {
                        x₁ -= (previousQuadX₁-x₁)
                        y₁ -= (previousQuadY₁-y₁)
                    }

                    x = x + deltaX
                    y = y + deltaY

                    mutablePath.addQuadCurve(to: CGPoint(x: x, y: y) , control: CGPoint(x: x₁, y: y₁))
                    lastCubicX₂ = nil // clean out the last cubic as this is a quad
                    lastQuadX₁ = x₁
                    lastQuadY₁ = y₁

                case let .smoothQuadraticBezierToAbsolute(newX, newY):
                    var x₁ = x
                    var y₁ = y

                    if let previousQuadX₁ = self.lastQuadX₁,
                       let previousQuadY₁ = self.lastQuadY₁
                    {
                        x₁ -= (previousQuadX₁-x₁)
                        y₁ -= (previousQuadY₁-y₁)
                    }

                    x = newX
                    y = newY

                    mutablePath.addQuadCurve(to: CGPoint(x: x, y: y) , control: CGPoint(x: x₁, y: y₁))
                    lastCubicX₂ = nil // clean out the last cubic as this is a quad
                    lastQuadX₁ = x₁
                    lastQuadY₁ = y₁

                case let .cubicBezierTo(deltaX₁, deltaY₁, deltaX₂, deltaY₂, deltaX, deltaY):

                    let x₁ = x + deltaX₁
                    let y₁ = y + deltaY₁
                    let x₂ = x + deltaX₂
                    let y₂ = y + deltaY₂

                    x = x + deltaX
                    y = y + deltaY

                    mutablePath.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x₁, y: y₁), control2: CGPoint(x: x₂, y: y₂))
                    lastCubicX₂ = x₂
                    lastCubicY₂ = y₂
                    lastQuadX₁ = nil // clean out the last quad as this is a cubic

                case let .cubicBezierToAbsolute(x₁, y₁, x₂, y₂, newX, newY):

                    x = newX
                    y = newY
                    lastCubicX₂ = x₂
                    lastCubicY₂ = y₂

                    mutablePath.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x₁, y: y₁), control2: CGPoint(x: x₂, y: y₂))

                    lastQuadX₁ = nil // clean out the last quad as this is a cubic

                case let .smoothCubicBezierTo(deltaX₂, deltaY₂, deltaX, deltaY):

                    var x₁ = x
                    var y₁ = y


                    if let previousCubicX₂ = self.lastCubicX₂,
                       let previousCubicY₂ = self.lastCubicY₂
                    {
                        x₁ -= (previousCubicX₂-x₁)
                        y₁ -= (previousCubicY₂-y₁)
                    }

                    lastCubicX₂ = x + deltaX₂
                    lastCubicY₂ = y + deltaY₂

                    x = x + deltaX
                    y = y + deltaY

                    mutablePath.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x₁, y: y₁), control2: CGPoint(x: lastCubicX₂!, y: lastCubicY₂!))

                    lastQuadX₁ = nil // clean out the last quad as this is a cubic

                case let .smoothCubicBezierToAbsolute(x₂, y₂, newX, newY):

                    var x₁ = x
                    var y₁ = y
                    if let previousCubicX₂ = self.lastCubicX₂,
                       let previousCubicY₂ = self.lastCubicY₂
                    {
                        x₁ -= (previousCubicX₂-x₁)
                        y₁ -= (previousCubicY₂-y₁)
                    }

                    x = newX
                    y = newY
                    lastCubicX₂ = CGFloat(x₂)
                    lastCubicY₂ = CGFloat(y₂)

                    mutablePath.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: x₁, y: y₁), control2: CGPoint(x: lastCubicX₂!, y: lastCubicY₂!))

                    lastQuadX₁ = nil // clean out the last quad as this is a cubic

                case let .arcTo(xRadius, yRadius, tiltAngle, largeArcFlag, sweepFlag, deltaX, deltaY):

                    self.addArc(xRadius: xRadius, yRadius: yRadius, tiltAngle: tiltAngle, largeArcFlag: largeArcFlag, sweepFlag: sweepFlag, endX: x + deltaX, endY: y + deltaY)

                case let .arcToAbsolute(xRadius, yRadius, tiltAngle, largeArcFlag, sweepFlag, newX, newY):

                    self.addArc(xRadius: xRadius, yRadius: yRadius, tiltAngle: tiltAngle, largeArcFlag: largeArcFlag, sweepFlag: sweepFlag, endX: newX, endY: newY)

                case .bad(_, _):
                    break
                }
            }
        }

    }
    /**
     There might be a case where you would want to add an SVG path to a pre-existing CGMutablePath.
     - parameters:
     - svgPath: a (hopefully) well formatted SVG path.
     - returns: true if the SVG path was valid, false otherwise.
     **/
    func add(svgPath: String) throws
    {
        let tokens = try svgPath.asPathTokens()
        var builder = CGPathBuilder(path: self, tokens: tokens)
        builder.build()
    }

    // following convenience init is not allowed by the current compiler
    //    public convenience init?(svgPath: String)
    //    {
    //        self.init()
    //        if !self.addSVGPath(svgPath: svgPath)
    //        {
    //            return nil
    //        }
    //    }
}

private extension CGPath
{
    /**
     A factory method to create an immutable CGPath from an SVG path string.

     - parameters:
     - svgPath: A (hopefully) valid path complying to the SVG path specification.
     - returns: an optional CGPath which will be .Some if the SVG path string was valid.
     **/
    static func path(fromSVGPath svgPath: String) throws -> CGPath
    {
        let mutableResult = CGMutablePath()
        try mutableResult.add(svgPath: svgPath)
        return mutableResult.copy() ?? mutableResult
    }
}

#endif


private struct PathParser
{
    private enum ParseState
    {
        case lookingForFirstOperand
        case lookingForOperand
        case buildingToken
    }

    var resultTokens = [PathToken]()
    private var parseState = ParseState.lookingForFirstOperand
    private var tokenBuilder: TokenBuilder!
    private var buffer : String.UnicodeScalarView!

    fileprivate init()
    {

    }

    fileprivate mutating func parse(pathString: String) throws -> [PathToken]
    {
        self.parseState = ParseState.lookingForFirstOperand
        self.resultTokens = [PathToken]()

        self.buffer = pathString.unicodeScalars
        var cursor = buffer.startIndex
        let range = cursor..<buffer.endIndex
        self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: "M")

        while range.contains(cursor)
        {
            let aCharacter = buffer[cursor]

            try self.handleCharacter(character: aCharacter, atCursor: cursor)

            cursor = buffer.index(after: cursor)
        }

        return try self.complete()
    }

    fileprivate mutating func handleCharacter(character: UnicodeScalar, atCursor cursor: String.UnicodeScalarView.Index) throws
    {
        switch parseState
        {
        case .lookingForFirstOperand:
            switch character
            {
            case " ", "\t", "\n", "\r": // possible leading whitespace
                break
            case "m", "M":
                self.parseState = .buildingToken
            case "l", "L", "H", "h", "Q", "q", "V", "v", "C", "c", "T", "t", "S", "s", "A", "a":
                throw PathToken.FailureReason.missingMoveAtStart(offset: cursor)
            default:
                throw PathToken.FailureReason.unexpectedCharacter(badCharacter: character, offset: cursor)
            }

        case .lookingForOperand:
            switch character
            {
            case " ", "\t", "\n", "\r", ",": // possible operand separators
                break
            case "z", "Z":
                resultTokens.append(PathToken.close)
            case "l", "L", "H", "h", "Q", "q", "V", "v", "C", "c", "T", "t", "S", "s", "A", "a", "m", "M":
                self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: character)
                parseState = .buildingToken
            case "-", "+", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".": // an implied
                guard  let mostRecentToken = self.resultTokens.last else
                {
                    throw PathToken.FailureReason.missingMoveAtStart(offset: cursor)
                }

                guard mostRecentToken.impliesSubsequentOperand else
                {
                    throw PathToken.FailureReason.missingMoveAtStart(offset: cursor)
                }

                self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: mostRecentToken.impliedSubsequentOperand, firstCharacter: character)
                parseState = .buildingToken
                let _ = try self.tokenBuilder.testCompletionCharacter(character: character, atIndex: cursor) // I know it's not completed

            default:
                throw PathToken.FailureReason.unexpectedCharacter(badCharacter: character, offset: cursor)
            }

        case .buildingToken:

            let isTokenEnder = self.tokenBuilder.isCompletionCharacter(testCharacter: character)
            if(isTokenEnder) // a character appeared that forces a new operand token.
            {
                let newToken = try self.tokenBuilder.buildToken()
                resultTokens.append(newToken)

                switch character
                {
                case "Z", "z":
                    resultTokens.append(PathToken.close)
                    parseState = .lookingForOperand
                case "l", "L", "H", "h", "Q", "q", "V", "v", "C", "c", "T", "t", "S", "s", "A", "a", "m", "M":
                    self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: character)
                    parseState = .buildingToken
                case " ", "\t", "\n", "\r", ",":
                    parseState = .lookingForOperand
                default:

                    guard newToken.impliesSubsequentOperand else
                    {
                        throw PathToken.FailureReason.missingMoveAtStart(offset: cursor)
                    }
                    self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: newToken.impliedSubsequentOperand, firstCharacter : character) // already found the parameter
                    parseState = .buildingToken
                }
            }
            else
            {
                if case .complete =  try self.tokenBuilder.testCompletionCharacter(character: character, atIndex: cursor)
                {
                    resultTokens.append(try self.tokenBuilder.buildToken())
                    self.parseState = .lookingForOperand
                }
            }
        }
    }

    mutating fileprivate func complete() throws -> [PathToken]
    {
        switch parseState
        {
        case .lookingForOperand:
            break
        case .lookingForFirstOperand:
            throw PathToken.FailureReason.noOperands(offset: self.buffer.startIndex)
        case .buildingToken:
            let lastToken = try self.tokenBuilder.buildToken()
            self.resultTokens.append(lastToken)
        }
        return self.resultTokens
    }
}


/**
 SVG path strings (the "d" parameter of a <path> element) are faily complicated because they use various tricks for compactness. Thus parameters and operands can be separated by nothing(operand immediately followed by the start of its first parameter), commas, +, -, white space, and even a period if the preceding parameter already has a period. Also, operands can be implied to be the same as the previous operand, unless it was a move, in which case the implied operand is a line, or a close path in which case the use of an implied operand is an error.

 The token builder builds up an individual token (an operand + its parameters)
 **/

private struct TokenBuilder
{
    enum TokenBuildState
    {
        case lookingForParameter
        case insideParameter
        case complete
    }

    let operand: UnicodeScalar
    let numberOfParameters: Int
    var lookingForParameter: Bool
    var activeParameterStartIndex: String.UnicodeScalarView.Index
    let buffer: String.UnicodeScalarView
    var activeParameterEndIndex: String.UnicodeScalarView.Index?
    var seenPeriod: Bool
    var seenExponent: Bool
    var seenDigit: Bool
    var completedParameters: [Double]

    init(buffer: String.UnicodeScalarView, startIndex: String.UnicodeScalarView.Index, operand: UnicodeScalar, firstCharacter : UnicodeScalar? = nil)
    {
        self.buffer = buffer
        self.operand = operand
        self.numberOfParameters = PathToken.parametersPerOperand(operand: operand)
        self.activeParameterStartIndex = startIndex
        self.activeParameterEndIndex = nil
        self.seenPeriod = false
        self.seenDigit = false
        self.lookingForParameter = true


        self.seenExponent = false
        self.completedParameters = Array<Double>()
        self.completedParameters.reserveCapacity(self.numberOfParameters)

        if let startCharacter = firstCharacter
        {
            switch startCharacter
            {
            case ".":
                self.seenPeriod = true
            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                self.seenDigit = true
            default:
                break
            }
            self.beginParameterAtIndex(index: startIndex)
        }

    }

    private var activeParameterIndex: Int
    {
        return self.completedParameters.count
    }

    private var completed: Bool
    {
        return self.completedParameters.count == self.numberOfParameters
    }

    private var activeParameterString: String?
    {
        guard let endIndex = self.activeParameterEndIndex else
        {
            return nil
        }
        let range = self.activeParameterStartIndex...endIndex
        return String(self.buffer[range])
    }

    mutating private func completeActiveParameter() throws
    {
        guard let completedParameterString = self.activeParameterString, let endIndex = self.activeParameterEndIndex else
        {
            throw PathToken.FailureReason.tooFewParameters(operand: self.operand, expectedParameterCount: self.numberOfParameters, actualParameterCount: self.completedParameters.count, offset: self.activeParameterStartIndex)
        }

        if !self.seenDigit
        {
            throw PathToken.FailureReason.badParameter(operand: self.operand, parameterIndex: self.activeParameterIndex, unexpectedValue: completedParameterString, offset: endIndex)
        }
        else if completedParameterString.hasSuffix("e") // exponent without value
        {
            throw PathToken.FailureReason.badParameter(operand: self.operand, parameterIndex: self.activeParameterIndex, unexpectedValue: completedParameterString, offset: endIndex)
        }
        else if !self.seenExponent && !self.seenPeriod
        {
            if let intValue = Int(completedParameterString)
            {
                self.completedParameters.append(Double(intValue))
            }
            else
            {
                throw PathToken.FailureReason.badParameter(operand: self.operand, parameterIndex: self.activeParameterIndex, unexpectedValue: completedParameterString, offset: endIndex)
            }
        }
        else
        {
            if let doubleValue = Double(completedParameterString)
            {
                self.completedParameters.append(Double(doubleValue))
            }
            else
            {
                throw PathToken.FailureReason.badParameter(operand: self.operand, parameterIndex: self.activeParameterIndex, unexpectedValue: completedParameterString, offset: endIndex)
            }
        }
        self.activeParameterEndIndex = nil
        if !self.completed
        {
            self.seenPeriod = false
            self.seenExponent = false
            self.seenDigit = false
        }
    }

    private mutating func beginParameterAtIndex(index: String.UnicodeScalarView.Index)
    {
        self.activeParameterStartIndex = index
        self.activeParameterEndIndex = index
        self.lookingForParameter = false
    }

    mutating func testCompletionCharacter(character: UnicodeScalar, atIndex index: String.UnicodeScalarView.Index) throws -> TokenBuildState
    {
        if self.completed
        {
            fatalError("Program Error should not be continuing to parse a completed token")
        }
        else if self.lookingForParameter
        {
            var foundNumber = false
            switch character
            {
            case " ", "\t", "\n", "\r", ",":
                break

            case ".":
                foundNumber = true
                self.seenPeriod = true

            case "-", "+":
                foundNumber = true

            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                foundNumber = true
                self.seenDigit = true

            default:
                throw PathToken.FailureReason.unexpectedCharacter(badCharacter: character, offset: index)
            }

            if foundNumber
            {
                self.beginParameterAtIndex(index: index)
            }
        }
        else // inside a parameter
        {
            switch character
            {
            case " ", "\t", "\n", "\r", ",":
                try self.completeActiveParameter()
                self.lookingForParameter = true

            case ".":
                if(self.seenExponent)
                {
                    throw PathToken.FailureReason.unexpectedCharacter(badCharacter: character, offset: index)
                }
                else if (self.seenPeriod)
                {
                    if self.seenDigit
                    {
                        try self.completeActiveParameter()

                        self.beginParameterAtIndex(index: index)
                        self.seenPeriod = true
                    }
                    else
                    {
                        self.activeParameterEndIndex = index
                    }
                }
                else
                {
                    self.seenPeriod = true
                    self.activeParameterEndIndex = index
                }

            case "e" where !self.seenExponent:
                fallthrough
            case "E" where !self.seenExponent:
                self.seenExponent = true
                self.activeParameterEndIndex = index

            case "-", "+":
                let lastCharacter = self.previousCharacter
                if lastCharacter == "e" || lastCharacter == "E"
                {
                    self.activeParameterEndIndex = index
                }
                else if self.seenDigit
                {
                    try self.completeActiveParameter()

                    self.beginParameterAtIndex(index: index)
                }
                else
                {
                    throw PathToken.FailureReason.unexpectedCharacter(badCharacter: character, offset: index)
                }

            case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                self.seenDigit = true
                self.activeParameterEndIndex = index
            default:
                throw PathToken.FailureReason.unexpectedCharacter(badCharacter: character, offset: index)
            }
        }

        if self.completed
        {
            self.lookingForParameter = false
            return .complete
        }
        else if self.lookingForParameter
        {
            return .lookingForParameter
        }
        else
        {
            return .insideParameter
        }
    }

    private var previousCharacter : UnicodeScalar
    {
        guard let endIndex = self.activeParameterEndIndex else
        {
            return buffer[self.activeParameterStartIndex]
        }

        let result = buffer[endIndex]
        return result
    }

    fileprivate func isCompletionCharacter(testCharacter: UnicodeScalar) -> Bool
    {
        let onLastParameter = self.numberOfParameters == (self.activeParameterIndex+1)
        && self.activeParameterEndIndex != nil
        && !self.lookingForParameter

        switch testCharacter
        {
        case "l", "L", "H", "h", "Q", "q", "V", "v", "C", "c", "T", "t", "S", "s", "A", "a", "m", "M",  "z", "Z":
            return true
        case "+", "-":

            if onLastParameter
                && self.previousCharacter != "e"
                && self.previousCharacter != "E" // might be of the form 1e-3
            {
                return true
            }
            else
            {
                return false
            }
        case " ", "\t", "\n", "\r", ",":
            if onLastParameter
            {
                return true
            }
            else
            {
                return false
            }
        case ".":
            if onLastParameter && (self.seenPeriod || self.seenExponent)
            {
                return true
            }
            else
            {
                return false
            }

        default:
            return false
        }
    }

    mutating fileprivate func buildToken() throws -> PathToken
    {
        if self.self.activeParameterEndIndex != nil
        {
            try self.completeActiveParameter()
        }

        if self.completed
        {
            return try PathToken(operand: self.operand, parameters: self.completedParameters, atOffset: self.activeParameterStartIndex)
        }
        else
        {
            throw PathToken.FailureReason.tooFewParameters(operand: self.operand, expectedParameterCount: self.numberOfParameters, actualParameterCount: self.completedParameters.count, offset: self.activeParameterStartIndex)
        }
    }
}

private extension String
{
    /**
     A function that converts a properly formatted string using the [SVG path specification](http://www.w3.org/TR/SVG/paths.html) to an array of PathTokens.
     - returns: An array of PathToken
     - throws: a PathToken.FailureReason
     **/

    func asPathTokens() throws -> [PathToken]
    {
        var parser = PathParser()
        return try parser.parse(pathString: self)

    }


    struct PathParser
    {
        private enum ParseState
        {
            case lookingForFirstOperand
            case lookingForOperand
            case buildingToken
        }

        var resultTokens = [PathToken]()
        private var parseState = ParseState.lookingForFirstOperand
        private var tokenBuilder: TokenBuilder!
        private var buffer : String.UnicodeScalarView!

        fileprivate init()
        {

        }

        fileprivate mutating func parse(pathString: String) throws -> [PathToken]
        {
            self.parseState = ParseState.lookingForFirstOperand
            self.resultTokens = [PathToken]()

            self.buffer = pathString.unicodeScalars
            var cursor = buffer.startIndex
            let range = cursor..<buffer.endIndex
            self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: "M")

            while range.contains(cursor)
            {
                let aCharacter = buffer[cursor]

                try self.handleCharacter(character: aCharacter, atCursor: cursor)

                cursor = buffer.index(after: cursor)
            }

            return try self.complete()
        }

        fileprivate mutating func handleCharacter(character: UnicodeScalar, atCursor cursor: String.UnicodeScalarView.Index) throws
        {
            switch parseState
            {
            case .lookingForFirstOperand:
                switch character
                {
                case " ", "\t", "\n", "\r": // possible leading whitespace
                    break
                case "m", "M":
                    self.parseState = .buildingToken
                case "l", "L", "H", "h", "Q", "q", "V", "v", "C", "c", "T", "t", "S", "s", "A", "a":
                    throw PathToken.FailureReason.missingMoveAtStart(offset: cursor)
                default:
                    throw PathToken.FailureReason.unexpectedCharacter(badCharacter: character, offset: cursor)
                }

            case .lookingForOperand:
                switch character
                {
                case " ", "\t", "\n", "\r", ",": // possible operand separators
                    break
                case "z", "Z":
                    resultTokens.append(PathToken.close)
                case "l", "L", "H", "h", "Q", "q", "V", "v", "C", "c", "T", "t", "S", "s", "A", "a", "m", "M":
                    self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: character)
                    parseState = .buildingToken
                case "-", "+", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".": // an implied
                    guard  let mostRecentToken = self.resultTokens.last else
                    {
                        throw PathToken.FailureReason.missingMoveAtStart(offset: cursor)
                    }

                    guard mostRecentToken.impliesSubsequentOperand else
                    {
                        throw PathToken.FailureReason.missingMoveAtStart(offset: cursor)
                    }

                    self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: mostRecentToken.impliedSubsequentOperand, firstCharacter: character)
                    parseState = .buildingToken
                    let _ = try self.tokenBuilder.testCompletionCharacter(character: character, atIndex: cursor) // I know it's not completed

                default:
                    throw PathToken.FailureReason.unexpectedCharacter(badCharacter: character, offset: cursor)
                }

            case .buildingToken:

                let isTokenEnder = self.tokenBuilder.isCompletionCharacter(testCharacter: character)
                if(isTokenEnder) // a character appeared that forces a new operand token.
                {
                    let newToken = try self.tokenBuilder.buildToken()
                    resultTokens.append(newToken)

                    switch character
                    {
                    case "Z", "z":
                        resultTokens.append(PathToken.close)
                        parseState = .lookingForOperand
                    case "l", "L", "H", "h", "Q", "q", "V", "v", "C", "c", "T", "t", "S", "s", "A", "a", "m", "M":
                        self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: character)
                        parseState = .buildingToken
                    case " ", "\t", "\n", "\r", ",":
                        parseState = .lookingForOperand
                    default:

                        guard newToken.impliesSubsequentOperand else
                        {
                            throw PathToken.FailureReason.missingMoveAtStart(offset: cursor)
                        }
                        self.tokenBuilder = TokenBuilder(buffer: self.buffer, startIndex: cursor, operand: newToken.impliedSubsequentOperand, firstCharacter : character) // already found the parameter
                        parseState = .buildingToken
                    }
                }
                else
                {
                    if case .complete =  try self.tokenBuilder.testCompletionCharacter(character: character, atIndex: cursor)
                    {
                        resultTokens.append(try self.tokenBuilder.buildToken())
                        self.parseState = .lookingForOperand
                    }
                }
            }
        }

        mutating fileprivate func complete() throws -> [PathToken]
        {
            switch parseState
            {
            case .lookingForOperand:
                break
            case .lookingForFirstOperand:
                throw PathToken.FailureReason.noOperands(offset: self.buffer.startIndex)
            case .buildingToken:
                let lastToken = try self.tokenBuilder.buildToken()
                self.resultTokens.append(lastToken)
            }
            return self.resultTokens
        }
    }
}


private protocol ParseBufferError : Error
{
    var failurePoint : String.UnicodeScalarView.Index?{get}
}

private extension ParseBufferError
{
    func description(forBuffer buffer: String.UnicodeScalarView) -> String
    {
        guard let failurePoint = self.failurePoint else
        {
            return self.localizedDescription
        }

        let lineCount = buffer.lineCount(before: failurePoint)

        let lineCountString = "Failure at line: \(lineCount+1)"

        var beginCursor = failurePoint
        var endCursor = failurePoint
        let validRange = buffer.startIndex..<buffer.endIndex

        var rangeCount = 10 // arbitrary
        while rangeCount >= 0
        {
            let newBegin = buffer.index(before: beginCursor)
            if validRange.contains(newBegin)
            {
                beginCursor = newBegin
            }

            let newEnd = buffer.index(after: endCursor)
            if validRange.contains(newEnd)
            {
                endCursor = newEnd
            }
            rangeCount -= 1
        }

        let rangeString = String(buffer[beginCursor...endCursor])

        return lineCountString + "\n" + ">>> \(rangeString) <<<<\n" + self.localizedDescription
    }
}

private extension String.UnicodeScalarView
{
    func lineCount(before: String.UnicodeScalarView.Index) -> Int
    {
        var result = 0
        var cursor = self.startIndex
        let range = cursor..<before

        while range.contains(cursor) {
            let character = self[cursor]
            if character == "\n"
            {
                result += 1
            }
            cursor = self.index(after: cursor)
        }

        return result
    }
}


/**
 An enum encapsulating an individual path definition operation such as a line to, or a close path
 **/
private enum PathToken : CustomStringConvertible, Hashable
{
    /**
     In the SVG definition of an Arc, there are almost always 2 ways to get from the starting point to the specified ending point. One way is likely longer than the other, thus the choice.
     **/
    enum ArcChoice : Int, Hashable
    {
        case large = 1
        case short = 0
    }

    /**
     In the SVG definition of an Arc, there is always the choice to reach from the start point to the end point by going clockwise or counterclockwise. Thus the need for this flag.
     **/
    enum ArcSweep : Int, Hashable
    {
        case clockwise = 0
        case counterclockwise = 1
    }
    /**
     If the parsing of a string fails, and it turns out to not be a valid SVG path string. These errors will be thrown.
     **/
    enum FailureReason : CustomStringConvertible, ParseBufferError, Hashable
    {

        case noReason
        case missingMoveAtStart(offset: String.UnicodeScalarView.Index)
        case unexpectedCharacter(badCharacter: UnicodeScalar, offset: String.UnicodeScalarView.Index)
        case tooFewParameters(operand: UnicodeScalar, expectedParameterCount: Int, actualParameterCount: Int, offset: String.UnicodeScalarView.Index)
        case badParameter(operand: UnicodeScalar, parameterIndex: Int, unexpectedValue: String, offset: String.UnicodeScalarView.Index)
        case noOperands(offset: String.UnicodeScalarView.Index)

        var failurePoint: String.UnicodeScalarView.Index?
        {
            switch self {
            case .noReason:
                return nil
            case .missingMoveAtStart(let result):
                return result
            case .unexpectedCharacter(_, let result):
                return result
            case .tooFewParameters(_, _, _, let result):
                return result
            case .badParameter(_, _, _,let result):
                return result
            case .noOperands(let result):
                return result
            }
        }

        var description: String
        {
            switch self
            {
            case .noReason:
                return "No Failure"
            case let .unexpectedCharacter(badCharacter, offset):
                return "Unexpected character: \(badCharacter) at offset: \(offset)"
            case let .tooFewParameters(operand, expectedParameterCount, actualParameterCount, offset):
                return "Operand '\(operand)' (\(PathToken.name(forOperand: operand))) expects \(expectedParameterCount), but had \(actualParameterCount) at offset: \(offset)"
            case let .badParameter(operand, parameterIndex, unexpectedValue, offset):
                return "Operand '\(operand)' (\(PathToken.name(forOperand: operand))) had a unexpected parameter '\(unexpectedValue)' for parameter \(parameterIndex) at offset: \(offset)"
            case .noOperands:
                return "Just white space."
            case .missingMoveAtStart:
                return "Missing move to at start."
            }
        }
    }

    case bad(UnicodeScalar, FailureReason)
    case close
    case moveTo(Double, Double)
    case moveToAbsolute(Double, Double)
    case lineTo(Double, Double)
    case lineToAbsolute(Double, Double)
    case horizontalLineTo(Double)
    case horizontalLineToAbsolute(Double)
    case verticalLineTo(Double)
    case verticalLineToAbsolute(Double)
    case cubicBezierTo(Double, Double, Double, Double, Double, Double)
    case cubicBezierToAbsolute(Double, Double, Double, Double, Double, Double)
    case smoothCubicBezierTo(Double, Double, Double, Double)
    case smoothCubicBezierToAbsolute(Double, Double, Double, Double)
    case quadraticBezierTo(Double, Double, Double, Double)
    case quadraticBezierToAbsolute(Double, Double, Double, Double)
    case smoothQuadraticBezierTo(Double, Double)
    case smoothQuadraticBezierToAbsolute(Double, Double)
    case arcTo(Double, Double, Double, ArcChoice, ArcSweep, Double, Double)
    case arcToAbsolute(Double, Double, Double, ArcChoice, ArcSweep, Double, Double)


    init(operand: UnicodeScalar, parameters: [Double], atOffset offset: String.UnicodeScalarView.Index) throws
    {
        switch operand
        {
        case "z", "Z":
            assert(parameters.count == 0, "close needs no parameters")
            self = .close
        case "m":
            assert(parameters.count == 2, "moveTo needs 2 parameters")
            self = .moveTo(parameters[0], parameters[1])
        case "M":
            assert(parameters.count == 2, "moveToAbsolute needs 2 parameters")
            self = .moveToAbsolute(parameters[0], parameters[1])
        case "l":
            assert(parameters.count == 2, "lineTo needs 2 parameters")
            self = .lineTo(parameters[0], parameters[1])
        case "L":
            assert(parameters.count == 2, "lineToAbsolute needs 2 parameters")
            self = .lineToAbsolute(parameters[0], parameters[1])
        case "h":
            assert(parameters.count == 1, "horizontalLineTo needs 1 parameter")
            self = .horizontalLineTo(parameters[0])
        case "H":
            assert(parameters.count == 1, "horizontalLineToAbsolute needs 1 parameter")
            self = .horizontalLineToAbsolute(parameters[0])
        case "v":
            assert(parameters.count == 1, "verticalLineTo needs 1 parameter")
            self = .verticalLineTo(parameters[0])
        case "V":
            assert(parameters.count == 1, "verticalLineToAbsolute needs 1 parameter")
            self = .verticalLineToAbsolute(parameters[0])
        case "q":
            assert(parameters.count == 4, "quadraticBezierTo needs 4 parameters")
            self = .quadraticBezierTo(parameters[0], parameters[1], parameters[2], parameters[3])
        case "Q":
            assert(parameters.count == 4, "quadraticBezierToAbsolute needs 4 parameters")
            self = .quadraticBezierToAbsolute(parameters[0], parameters[1], parameters[2], parameters[3])
        case "c":
            assert(parameters.count == 6, "cubicBezierTo needs 6 parameters")
            self = .cubicBezierTo(parameters[0], parameters[1], parameters[2], parameters[3], parameters[4], parameters[5])
        case "C":
            assert(parameters.count == 6, "cubicBezierToAbsolute needs 6 parameters")
            self = .cubicBezierToAbsolute(parameters[0], parameters[1], parameters[2], parameters[3], parameters[4], parameters[5])
        case "t":
            assert(parameters.count == 2, "smoothQuadraticBezierTo needs 2 parameters")
            self = .smoothQuadraticBezierTo(parameters[0], parameters[1])
        case "T":
            assert(parameters.count == 2, "smoothQuadraticBezierToAbsolute needs 2 parameters")
            self = .smoothQuadraticBezierToAbsolute(parameters[0], parameters[1])
        case "s":
            assert(parameters.count == 4, "smoothCubicBezierTo needs 4 parameters")
            self = .smoothCubicBezierTo(parameters[0], parameters[1], parameters[2], parameters[3])
        case "S":
            assert(parameters.count == 4, "smoothCubicBezierToAbsolute needs 4 parameters")
            self = .smoothCubicBezierToAbsolute(parameters[0], parameters[1], parameters[2], parameters[3])
        case "a", "A":
            assert(parameters.count == 7, "arcTo needs 7 parameters")
            let arcChoiceRaw = parameters[3]
            let arcSweepRaw = parameters[4]

            guard arcChoiceRaw == 1 || arcChoiceRaw == 0 else
            {
                throw PathToken.FailureReason.badParameter(operand: operand, parameterIndex: 3, unexpectedValue: String(describing: arcChoiceRaw), offset: offset)
            }

            guard arcSweepRaw == 1 || arcSweepRaw == 0 else
            {
                throw PathToken.FailureReason.badParameter(operand: operand, parameterIndex: 4, unexpectedValue: String(describing: arcSweepRaw), offset: offset)
            }

            let archChoice = ArcChoice(rawValue: Int(arcChoiceRaw))
            let arcSweep = ArcSweep(rawValue: Int(arcSweepRaw))
            if operand == "a"
            {
                self = .arcTo(parameters[0], parameters[1], Double(parameters[2]), archChoice!, arcSweep!, parameters[5], parameters[6])
            }
            else
            {
                self = .arcToAbsolute(parameters[0], parameters[1], Double(parameters[2]), archChoice!, arcSweep!, parameters[5], parameters[6])
            }
        default:
            throw PathToken.FailureReason.unexpectedCharacter(badCharacter: operand, offset: offset)
        }
    }

    var operand: UnicodeScalar
    {
        get
        {
            switch self
            {
            case .bad(let badOperand, _ ):
                return badOperand
            case .close:
                return "z"
            case .moveTo(_, _):
                return "m"
            case .moveToAbsolute(_, _):
                return "M"
            case .lineTo(_, _):
                return "l"
            case .lineToAbsolute(_, _):
                return "L"
            case .horizontalLineTo(_):
                return "h"
            case .horizontalLineToAbsolute(_):
                return "H"
            case .verticalLineTo(_):
                return "v"
            case .verticalLineToAbsolute(_):
                return "V"
            case .cubicBezierTo(_, _, _, _, _, _):
                return "c"
            case .cubicBezierToAbsolute(_, _, _, _, _, _):
                return "C"
            case .quadraticBezierTo(_, _, _, _):
                return "q"
            case .quadraticBezierToAbsolute(_, _, _, _):
                return "Q"
            case .smoothCubicBezierTo(_, _, _, _):
                return "s"
            case .smoothCubicBezierToAbsolute(_, _, _, _):
                return "S"
            case .smoothQuadraticBezierTo(_, _):
                return "t"
            case .smoothQuadraticBezierToAbsolute(_, _):
                return "T"
            case .arcTo(_, _, _, _, _, _, _):
                return "a"
            case .arcToAbsolute(_, _, _, _, _, _, _):
                return "A"
            }
        }
    }

    fileprivate var impliesSubsequentOperand: Bool
    {
        switch self
        {
        case .close:
            return false //I don't believe that a z implies a subsequent M
        default:
            return true // M implies L, m implies l, otherwise operand implies the same operand
        }
    }

    fileprivate var impliedSubsequentOperand: UnicodeScalar
    {
        switch self
        {
        case .moveTo(_, _):
            return "l"
        case .moveToAbsolute(_, _):
            return "L"
        default:
            return self.operand
        }
    }

    var description: String
    {
        let name = PathToken.name(forOperand: self.operand)
        switch self
        {
        case let .bad(badOperand, failureReason):
            return "unknown operand \(badOperand), reason: \(failureReason.description)"
        case .close:
            return name
        case let .moveTo(x, y):
            return "\(name) ∆x: \(x), ∆y: \(y)"
        case let .moveToAbsolute(x, y):
            return "\(name) x: \(x), y: \(y)"
        case let .lineTo(x, y):
            return "\(name) ∆x: \(x), ∆y: \(y)"
        case let .lineToAbsolute(x, y):
            return "\(name) x: \(x), y: \(y)"
        case .horizontalLineTo(let x):
            return "\(name) ∆x: \(x)"
        case .horizontalLineToAbsolute(let x):
            return "\(name) x: \(x)"
        case .verticalLineTo(let y):
            return "\(name) ∆y: \(y)"
        case .verticalLineToAbsolute(let y):
            return "\(name) y: \(y)"
        case let .cubicBezierTo(x₁, y₁, x₂, y₂, x, y):
            return "\(name) ∆x₁: \(x₁), ∆y₁: \(y₁), ∆x₂: \(x₂), ∆y₂: \(y₂), ∆x: \(x), ∆y: \(y)"
        case let .cubicBezierToAbsolute(x₁, y₁, x₂, y₂, x, y):
            return "\(name) x₁: \(x₁), y₁: \(y₁), x₂: \(x₂), y₂: \(y₂), x: \(x), y: \(y)"
        case let .quadraticBezierTo(x₁, y₁, x, y):
            return "\(name) ∆x₁: \(x₁), ∆y₁: \(y₁), ∆x: \(x), ∆y: \(y)"
        case let .quadraticBezierToAbsolute(x₁, y₁, x, y):
            return "\(name) x₁: \(x₁), y₁: \(y₁), x: \(x), y: \(y)"
        case let .smoothCubicBezierTo(x₂, y₂, x, y):
            return "\(name) ∆x₂: \(x₂), ∆y₂: \(y₂), ∆x: \(x), ∆y: \(y)"
        case let .smoothCubicBezierToAbsolute(x₂, y₂, x, y):
            return "\(name) x₂: \(x₂), y₂: \(y₂), x: \(x), y: \(y)"
        case let .smoothQuadraticBezierTo(x, y):
            return "\(name) ∆x: \(x), ∆y: \(y)"
        case let .smoothQuadraticBezierToAbsolute(x, y):
            return "\(name) x: \(x), y: \(y)"
        case let .arcTo(xRadius, yRadius, tiltAngle, largeArcFlag, sweepFlag, x, y):
            let largeArcString = (largeArcFlag == .large) ? "true" : "false"
            let sweepString = (sweepFlag == .clockwise) ? "true" : "false"
            return "\(name) r_x: \(xRadius), r_y: \(yRadius), Θ: \(tiltAngle)°‚ large Arc: \(largeArcString), clockwise: \(sweepString), ∆x: \(x), ∆y: \(y)"
        case let .arcToAbsolute(xRadius, yRadius, tiltAngle, largeArcFlag, sweepFlag, x, y):
            let largeArcString = (largeArcFlag == .large) ? "true" : "false"
            let sweepString = (sweepFlag == .clockwise) ? "true" : "false"
            return "\(name) r_x: \(xRadius), r_y: \(yRadius), Θ: \(tiltAngle)°‚ large Arc: \(largeArcString), clockwise: \(sweepString), x: \(x), y: \(y)"
        }
    }

    fileprivate static func isValidOperand(operand : UnicodeScalar) -> Bool
    {
        switch String(operand).lowercased()
        {
        case "z", "m",  "l",  "h",  "v",  "q",  "c",  "s",  "t",  "a":
            return true
        default:
            return false
        }
    }

    fileprivate static func parametersPerOperand(operand : UnicodeScalar) -> Int
    {
        switch String(operand).lowercased()
        {
        case "z":
            return 0
        case "m":
            return 2
        case "l":
            return 2
        case "h":
            return 1
        case "v":
            return 1
        case "q":
            return 4
        case "c":
            return 6
        case "s":
            return 4
        case "t":
            return 2
        case "a":
            return 7
        default:
            return 0
        }
    }

    fileprivate static func name(forOperand  operand: UnicodeScalar) -> String
    {
        var baseName : String
        let operandAsString = String(operand)
        let lowercaseOperandString = operandAsString.lowercased()
        switch lowercaseOperandString
        {
        case "z":
            return "close path"
        case "m":
            baseName = "move"
        case "l":
            baseName =  "lineto"
        case "h":
            baseName = "horizontal lineto"
        case "v":
            baseName = "vertical lineto"
        case "q":
            baseName = "quadratic Bezier"
        case "c":
            baseName = "cubic Bezier"
        case "s":
            baseName = "smooth cubic Bezier"
        case "t":
            baseName = "smooth quadratic Bezier"
        case "a":
            baseName = "arc"
        default:
            return "unknown"
        }

        if lowercaseOperandString != operandAsString
        {
            return "absolute \(baseName)"
        }
        else
        {
            return "relative \(baseName)"
        }
    }
}
