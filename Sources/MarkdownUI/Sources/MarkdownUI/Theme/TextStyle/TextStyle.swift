import SwiftUI

/// The appearance of a text inline in a Markdown view.
///
/// The styles of the different text inline types are brought together in a ``Theme``. You can customize the style of a
/// specific inline type by using the `markdownTextStyle(_:textStyle:)` modifier and combining one or more
/// built-in text styles like ``ForegroundColor`` or ``FontWeight``.
///
/// The following example applies a custom text style to each ``Theme/code`` inline in a ``Markdown`` view.
///
/// ```swift
/// Markdown {
///   """
///   Use `git status` to list all new or modified files
///   that haven't yet been committed.
///   """
/// }
/// .markdownTextStyle(\.code) {
///   FontFamilyVariant(.monospaced)
///   FontSize(.em(0.85))
///   ForegroundColor(.purple)
///   BackgroundColor(.purple.opacity(0.25))
/// }
/// ```
///
/// ![](CustomInlineCode)
///
/// You can also override the default text style inside the body of any block style by using the `markdownTextStyle(textStyle:)`
/// modifier. For example, you can define a ``Theme/blockquote`` style that uses a semibold lowercase small-caps text style:
///
/// ```swift
/// Markdown {
///   """
///   You can quote text with a `>`.
///
///   > Outside of a dog, a book is man's best friend. Inside of a
///   > dog it's too dark to read.
///
///   – Groucho Marx
///   """
/// }
/// .markdownBlockStyle(\.blockquote) { configuration in
///   configuration.label
///     .padding()
///     .markdownTextStyle {
///       FontCapsVariant(.lowercaseSmallCaps)
///       FontWeight(.semibold)
///       BackgroundColor(nil)
///     }
///     .overlay(alignment: .leading) {
///       Rectangle()
///         .fill(Color.teal)
///         .frame(width: 4)
///     }
///     .background(Color.teal.opacity(0.5))
/// }
/// ```
///
/// ![](CustomBlockquote)
public protocol TextStyle {
  func _collectAttributes(in attributes: inout CompatAttributeContainer)
  
  #if canImport(SwiftUI) && compiler(>=5.5)
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  func _collectAttributes(in attributes: inout AttributeContainer)
  #endif
}

// 기본 구현 제공
extension TextStyle {
  #if canImport(SwiftUI) && compiler(>=5.5)
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  public func _collectAttributes(in attributes: inout AttributeContainer) {
    // iOS 15+에서는 CompatAttributeContainer로 변환하여 처리
    var compatAttributes = CompatAttributeContainer()
    
    // AttributeContainer의 기존 속성을 CompatAttributeContainer로 복사
    if let fontProperties = attributes[FontPropertiesAttribute.self] {
      compatAttributes.fontProperties = fontProperties
    }
    
    // TextStyle 적용
    self._collectAttributes(in: &compatAttributes)
    
    // 결과를 다시 AttributeContainer로 복사
    if let fontProperties = compatAttributes.fontProperties {
      attributes[FontPropertiesAttribute.self] = fontProperties
    }
    
    // SwiftUI 속성 복사
    if let foregroundColor = compatAttributes.swiftUIForegroundColor {
      attributes.swiftUI.foregroundColor = foregroundColor
    }
    if let backgroundColor = compatAttributes.swiftUIBackgroundColor {
      attributes.swiftUI.backgroundColor = backgroundColor
    }
  }
  #endif
}