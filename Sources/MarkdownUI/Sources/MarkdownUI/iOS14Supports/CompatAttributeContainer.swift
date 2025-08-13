//
//  CompatAttributeContainer.swift
//  swift-markdown-ui
//
//  Created by Tez Park on 8/11/25.

@_weakLinked import _Concurrency
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// iOS 14에서도 동일한 사용감을 주기 위한 호환 래퍼
/// - iOS 15+: 내부 값을 실제 AttributeContainer로 브리징 가능
/// - iOS 14 : NSAttributedString.Key 딕셔너리로 브리징
public struct CompatAttributeContainer {
    // 대표 속성들 (필요 시 추가 가능)
    #if canImport(UIKit)
    public var font: UIFont?
    public var foregroundColor: UIColor?
    public var backgroundColor: UIColor?
    #elseif canImport(AppKit)
    public var font: NSFont?
    public var foregroundColor: NSColor?
    public var backgroundColor: NSColor?
    #endif
    public var kern: CGFloat?
    public var underlineStyle: NSUnderlineStyle?
    public var strikethroughStyle: NSUnderlineStyle?
    public var baselineOffset: CGFloat?
    public var link: URL?
    public var paragraphStyle: NSParagraphStyle?
    public var fontProperties: FontProperties?
    public var tracking: CGFloat?

    public init() {}

    // MARK: - Merge (AttributeContainer의 merge와 동일 컨셉: other가 우선)
    public func merged(with other: CompatAttributeContainer) -> CompatAttributeContainer {
        var result = self
        result.mergeInPlace(other)
        return result
    }

    public mutating func mergeInPlace(_ other: CompatAttributeContainer) {
        if let v = other.font { self.font = v }
        if let v = other.foregroundColor { self.foregroundColor = v }
        if let v = other.backgroundColor { self.backgroundColor = v }
        if let v = other.kern { self.kern = v }
        if let v = other.underlineStyle { self.underlineStyle = v }
        if let v = other.strikethroughStyle { self.strikethroughStyle = v }
        if let v = other.baselineOffset { self.baselineOffset = v }
        if let v = other.link { self.link = v }
        if let v = other.paragraphStyle { self.paragraphStyle = v }
        if let v = other.fontProperties { self.fontProperties = v }
        if let v = other.tracking { self.tracking = v }
    }

    // MARK: - NSAttributedString 브리징 (iOS 14 포함 전 버전에서 사용)
    public func asNSAttributes() -> [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [:]
        if let font = font { attrs[.font] = font }
        if let color = foregroundColor { attrs[.foregroundColor] = color }
        if let bg = backgroundColor { attrs[.backgroundColor] = bg }
        if let k = kern { attrs[.kern] = k }
        if let u = underlineStyle { attrs[.underlineStyle] = u.rawValue }
        if let s = strikethroughStyle { attrs[.strikethroughStyle] = s.rawValue }
        if let b = baselineOffset { attrs[.baselineOffset] = b }
        if let l = link { attrs[.link] = l }
        if let p = paragraphStyle { attrs[.paragraphStyle] = p }
        return attrs
    }
}

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - Color 변환 헬퍼
#if canImport(SwiftUI)
extension CompatAttributeContainer {
    #if canImport(UIKit)
    public var swiftUIForegroundColor: Color? {
        guard let foregroundColor = foregroundColor else { return nil }
        return Color(foregroundColor)
    }
    
    public var swiftUIBackgroundColor: Color? {
        guard let backgroundColor = backgroundColor else { return nil }
        return Color(backgroundColor)
    }
    #elseif canImport(AppKit)
    public var swiftUIForegroundColor: Color? {
        guard let foregroundColor = foregroundColor else { return nil }
        return Color(foregroundColor)
    }
    
    public var swiftUIBackgroundColor: Color? {
        guard let backgroundColor = backgroundColor else { return nil }
        return Color(backgroundColor)
    }
    #endif
}
#endif

// MARK: - iOS 15+ 전용: 실제 AttributeContainer로 브리징
@available(iOS 15, *)
extension CompatAttributeContainer {
    public func asAttributeContainer() -> AttributeContainer {
        var container = AttributeContainer()

        if let font = font {
            #if canImport(SwiftUI)
            container.font = Font(font as CTFont)
            #endif
        }

        if let color = foregroundColor {
            #if canImport(UIKit)
            container.foregroundColor = Color(color)
            #elseif canImport(AppKit)
            container.foregroundColor = Color(color)
            #endif
        }

        if let bg = backgroundColor {
            #if canImport(UIKit)
            container.backgroundColor = Color(bg)
            #elseif canImport(AppKit)
            container.backgroundColor = Color(bg)
            #endif
        }

        if let k = kern {
            container.kern = k
        }

        if let u = underlineStyle {
            let compatStyle = CompatLineStyle(u)
            container.underlineStyle = compatStyle.textLineStyle
        }

        if let s = strikethroughStyle {
            let compatStyle = CompatLineStyle(s)
            container.strikethroughStyle = compatStyle.textLineStyle
        }

        if let b = baselineOffset {
            container.baselineOffset = b
        }

        if let l = link {
            container.link = l
        }

        if paragraphStyle != nil {
            // 기본적인 단락 속성만 설정 (복잡한 변환은 생략)
            // iOS 15+에서 지원되는 속성만 매핑
            // Note: AttributeContainer의 paragraphStyle은 제한적이므로 단순화
        }

        return container
    }
}

// MARK: - 편의 생성자들
public extension CompatAttributeContainer {
    #if canImport(UIKit)
    static func font(_ font: UIFont) -> Self {
        var c = Self(); c.font = font; return c
    }
    static func foregroundColor(_ color: UIColor) -> Self {
        var c = Self(); c.foregroundColor = color; return c
    }
    static func backgroundColor(_ color: UIColor) -> Self {
        var c = Self(); c.backgroundColor = color; return c
    }
    #elseif canImport(AppKit)
    static func font(_ font: NSFont) -> Self {
        var c = Self(); c.font = font; return c
    }
    static func foregroundColor(_ color: NSColor) -> Self {
        var c = Self(); c.foregroundColor = color; return c
    }
    static func backgroundColor(_ color: NSColor) -> Self {
        var c = Self(); c.backgroundColor = color; return c
    }
    #endif
    static func kern(_ value: CGFloat) -> Self {
        var c = Self(); c.kern = value; return c
    }
    static func underline(_ style: NSUnderlineStyle) -> Self {
        var c = Self(); c.underlineStyle = style; return c
    }
    static func strikethrough(_ style: NSUnderlineStyle) -> Self {
        var c = Self(); c.strikethroughStyle = style; return c
    }
    static func baselineOffset(_ value: CGFloat) -> Self {
        var c = Self(); c.baselineOffset = value; return c
    }
    static func link(_ url: URL) -> Self {
        var c = Self(); c.link = url; return c
    }
    static func paragraphStyle(_ style: NSParagraphStyle) -> Self {
        var c = Self(); c.paragraphStyle = style; return c
    }
}

// MARK: - 연산자 병합 (오른쪽 우선)
public func + (lhs: CompatAttributeContainer, rhs: CompatAttributeContainer) -> CompatAttributeContainer {
    lhs.merged(with: rhs)
}

// MARK: - UIKit/AppKit 적용 헬퍼
#if canImport(UIKit)
public extension UILabel {
    /// iOS 14에서도 사용 가능한 적용기
    func setText(_ text: String, attributes: CompatAttributeContainer) {
        self.attributedText = NSAttributedString(string: text, attributes: attributes.asNSAttributes())
    }
}

public extension UITextView {
    func setText(_ text: String, attributes: CompatAttributeContainer) {
        self.attributedText = NSAttributedString(string: text, attributes: attributes.asNSAttributes())
    }
}
#elseif canImport(AppKit)
public extension NSTextField {
    func setText(_ text: String, attributes: CompatAttributeContainer) {
        self.attributedStringValue = NSAttributedString(string: text, attributes: attributes.asNSAttributes())
    }
}

public extension NSTextView {
    func setText(_ text: String, attributes: CompatAttributeContainer) {
        self.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: attributes.asNSAttributes()))
    }
}
#endif

#if canImport(SwiftUI)
// iOS 15+ AttributedString 지원 (하위 호환성)
@available(iOS 15, *)
public extension AttributedString {
    init(_ string: String, attributes: CompatAttributeContainer) {
        // iOS 15에서는 NSAttributedString 생성 후 AttributedString으로 변환
        let nsString = NSAttributedString(string: string, attributes: attributes.asNSAttributes())
        self = AttributedString(nsString)
    }
    
    init(_ string: String, compat: CompatAttributeContainer) {
        if #available(iOS 15, *) {
            var a = AttributedString(string)
            a.mergeAttributes(compat.asAttributeContainer())
            self = a
        } else {
            // iOS 14 폴백
            let nsString = NSAttributedString(string: string, attributes: compat.asNSAttributes())
            self = AttributedString(nsString)
        }
    }
    
    mutating func mergeAttributes(_ container: AttributeContainer) {
        // 간단한 속성 병합 - 전체 문자열에 속성 추가
        let range = self.startIndex..<self.endIndex
        var existing = self[range].runs.first?.attributes ?? AttributeContainer()
        existing.merge(container)
        // 모든 실행에 동일한 속성 적용
        for run in self.runs {
            self[run.range].setAttributes(existing)
        }
    }
}

@available(iOS 15, *)
public extension Text {
    /// SwiftUI Text에 호환 컨테이너 적용 (iOS 15+)
    init(_ string: String, compat: CompatAttributeContainer) {
        let attr = AttributedString(string, compat: compat)
        self = Text(attr)
    }
}
#endif

// MARK: - iOS 14 호환 LineStyle 래퍼
#if canImport(SwiftUI)

/// iOS 14에서도 LineStyle과 동일한 사용감을 주기 위한 호환 래퍼
public struct CompatLineStyle {
    private let underlineStyle: NSUnderlineStyle
    
    public init(_ underlineStyle: NSUnderlineStyle = .single) {
        self.underlineStyle = underlineStyle
    }
    
    /// NSUnderlineStyle로 변환
    public var nsUnderlineStyle: NSUnderlineStyle {
        return underlineStyle
    }
    
    /// iOS 15+에서 실제 Text.LineStyle로 변환
    @available(iOS 15, *)
    public var textLineStyle: Text.LineStyle {
        switch underlineStyle {
        case .single:
            return .single
        case .thick:
            return .single // Text.LineStyle에 thick가 없다면 single로 폴백
        case .double:
            return .single // Text.LineStyle에 double이 없다면 single로 폴백
        default:
            return .single
        }
    }
    
    // MARK: - 편의 생성자들
    public static let single = CompatLineStyle(NSUnderlineStyle.single)
    public static let thick = CompatLineStyle(NSUnderlineStyle.thick) 
    public static let double = CompatLineStyle(NSUnderlineStyle.double)
}

// iOS 15+에서는 실제 Text.LineStyle 사용 가능
@available(iOS 15, *)
public extension CompatLineStyle {
    init(_ textLineStyle: Text.LineStyle) {
        // Text.LineStyle에서 NSUnderlineStyle로 역변환
        // 정확한 매핑을 위해서는 Text.LineStyle의 내부 구조를 알아야 하지만
        // 기본적으로 .single로 매핑
        self.underlineStyle = .single
    }
}

#endif

// MARK: - iOS 14.5+ 호환 TitleAndIcon LabelStyle 래퍼
/// iOS 14.0에서도 titleAndIcon과 동일한 사용감을 주기 위한 호환 래퍼
public struct CompatTitleAndIconLabelStyle: LabelStyle {
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
            configuration.title
        }
    }
}

// MARK: - iOS 15+ 호환 AnyShapeStyle 래퍼
/// iOS 14.0에서도 AnyShapeStyle과 동일한 사용감을 주기 위한 호환 래퍼
public enum CompatAnyShapeStyle {
    case color(Color)
    case gradient(LinearGradient)
    case other(AnyView)
    
    public init<S: ShapeStyle>(_ style: S) {
        if let color = style as? Color {
            self = .color(color)
        } else if let gradient = style as? LinearGradient {
            self = .gradient(gradient)
        } else {
            // 기타 ShapeStyle들을 AnyView로 래핑
            self = .other(AnyView(Rectangle().fill(style)))
        }
    }
    
    /// ShapeStyle로서 작동할 수 있도록 View 형태로 렌더링
    @ViewBuilder
    public func fill<S: Shape>(_ shape: S) -> some View {
        switch self {
        case .color(let color):
            shape.fill(color)
        case .gradient(let gradient):
            shape.fill(gradient)
        case .other(let view):
            view
        }
    }
}

// MARK: - iOS 15+ 호환 Font 확장 래퍼
#if canImport(SwiftUI)
extension Font {
    /// iOS 14.0에서도 monospaced와 동일한 효과를 주는 호환 메서드
    func compatMonospaced() -> Font {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return self.monospaced()
        } else {
            // iOS 14 폴백: 시스템 모노스페이스 폰트로 변경
            #if canImport(UIKit)
            return Font.custom("Menlo", size: 17) // iOS 기본 모노스페이스 폰트
            #elseif canImport(AppKit)
            return Font.custom("Menlo", size: 13) // macOS 기본 모노스페이스 폰트
            #else
            return Font.system(.body, design: .monospaced)
            #endif
        }
    }
    
    /// iOS 14.0에서도 monospacedDigit과 동일한 효과를 주는 호환 메서드
    func compatMonospacedDigit() -> Font {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return self.monospacedDigit()
        } else {
            // iOS 14 폴백: monospaced 폰트 사용
            return self.compatMonospaced()
        }
    }
    
    /// iOS 14.0에서도 smallCaps와 동일한 효과를 주는 호환 메서드 
    func compatSmallCaps() -> Font {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return self.smallCaps()
        } else {
            // iOS 14 폴백: 기존 폰트 반환 (smallCaps 효과 없음)
            return self
        }
    }
    
    /// iOS 14.0에서도 lowercaseSmallCaps와 동일한 효과를 주는 호환 메서드
    func compatLowercaseSmallCaps() -> Font {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return self.lowercaseSmallCaps()
        } else {
            // iOS 14 폴백: 기존 폰트 반환 (smallCaps 효과 없음)
            return self
        }
    }
    
    /// iOS 14.0에서도 uppercaseSmallCaps와 동일한 효과를 주는 호환 메서드
    func compatUppercaseSmallCaps() -> Font {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return self.uppercaseSmallCaps()
        } else {
            // iOS 14 폴백: 기존 폰트 반환 (smallCaps 효과 없음) 
            return self
        }
    }
}

// MARK: - iOS 15+ 호환 Text 확장 래퍼
extension Text {
    /// iOS 14.0에서도 monospacedDigit과 동일한 효과를 주는 호환 메서드
    func compatMonospacedDigit() -> Text {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return self.monospacedDigit()
        } else {
            // iOS 14 폴백: 모노스페이스 폰트 적용
            return self.font(Font.system(.body, design: .monospaced))
        }
    }
}

// MARK: - iOS 15+ 호환 Image 확장 래퍼
extension Image {
    /// iOS 14.0에서도 foregroundStyle과 동일한 효과를 주는 호환 메서드
    func compatForegroundStyle<S: ShapeStyle>(_ primary: S) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return AnyView(self.foregroundStyle(primary))
        } else {
            // iOS 14 폴백: foregroundColor 사용
            if let color = primary as? Color {
                return AnyView(self.foregroundColor(color))
            } else {
                return AnyView(self)
            }
        }
    }
    
    /// iOS 14.0에서도 두 개 매개변수의 foregroundStyle과 동일한 효과를 주는 호환 메서드
    func compatForegroundStyle<S1: ShapeStyle, S2: ShapeStyle>(_ primary: S1, _ secondary: S2) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return AnyView(self.foregroundStyle(primary, secondary))
        } else {
            // iOS 14 폴백: 첫 번째 색상만 사용
            if let color = primary as? Color {
                return AnyView(self.foregroundColor(color))
            } else {
                return AnyView(self)
            }
        }
    }
}

// MARK: - iOS 15+ 호환 View 확장 래퍼
extension View {
    /// iOS 14.0에서도 task(id:_:)와 동일한 효과를 주는 호환 메서드
    func compatTask<T: Equatable>(id value: T, priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async -> Void) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return self.task(id: value, priority: priority, action)
        } else {
            // iOS 14 폴백: onAppear와 onChange 조합 사용
            return self
                .onAppear {
                    Task {
                        await action()
                    }
                }
                .onChange(of: value) { _ in
                    Task {
                        await action()
                    }
                }
        }
    }
    
    /// iOS 14.0에서도 task(_:)와 동일한 효과를 주는 호환 메서드
    func compatTask(priority: TaskPriority = .userInitiated, _ action: @escaping @Sendable () async -> Void) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return self.task(priority: priority, action)
        } else {
            // iOS 14 폴백: onAppear 사용
            return self.onAppear {
                Task {
                    await action()
                }
            }
        }
    }
    
    /// iOS 14.0에서도 background(alignment:content:)와 동일한 효과를 주는 호환 메서드
    func compatBackground<V: View>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return AnyView(self.background(alignment: alignment, content: content))
        } else {
            // iOS 14 폴백: overlay 사용
            return AnyView(
                self.overlay(
                    content()
                        .allowsHitTesting(false), // background는 터치를 받지 않음
                    alignment: alignment
                )
            )
        }
    }
    
    // iOS 13+
    @ViewBuilder
    func compatBackground(_ view: some View) -> some View {
        self.background(view)
    }
    
    // iOS 13+ (사용 편의를 위해 Color 전용 오버로드)
    func compatBackground(_ color: Color) -> some View {
        self.background(color)
    }
    
    // iOS 15+: ShapeStyle 지원
    @available(iOS 15, *)
    func compatBackground<S: ShapeStyle>(_ style: S) -> some View {
        self.background(style)
    }
    
//    /// iOS 14.0에서도 background(_:)와 동일한 효과를 주는 호환 메서드
//    func compatBackground<S: ShapeStyle>(_ style: S) -> some View {
//        // iOS 14에서도 background(_:)는 사용 가능하지만, 혹시 모를 경우를 위해 래핑
//        return self.background(style)
//    }
//    
//    /// iOS 14.0에서도 background(ignoresSafeAreaEdges:)와 동일한 효과를 주는 호환 메서드
//    func compatBackground<S: ShapeStyle>(_ style: S, ignoresSafeAreaEdges edges: Edge.Set) -> some View {
//        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
//            return AnyView(self.background(style, ignoresSafeAreaEdges: edges))
//        } else {
//            // iOS 14 폴백: 일반 background 사용
//            return AnyView(self.background(style))
//        }
//    }
}

// MARK: - iOS 15+ 호환 Color 확장 래퍼
#if canImport(UIKit)
extension Color {
    /// iOS 14.0에서도 init(uiColor:)와 동일한 효과를 주는 호환 생성자
    public static func compatColor(uiColor: UIColor) -> Color {
        if #available(iOS 15.0, *) {
            return Color(uiColor: uiColor)
        } else {
            // iOS 14 폴백: UIColor -> Color 변환
            return Color(uiColor)
        }
    }
}
#endif
#endif

// MARK: - 보조: NSTextAlignment ↔ TextAlignment
@available(iOS 15, *)
private extension TextAlignment {
    init(_ ui: NSTextAlignment) {
        switch ui {
        case .left: self = .leading
        case .right: self = .trailing
        case .center: self = .center
        default: self = .leading
        }
    }
}
