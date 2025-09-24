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

    // 기존 AttributeContainer 속성들을 CompatAttributeContainer로 복사
    // Note: Font 변환은 복잡하므로 FontProperties로 처리

    if let foregroundColor = attributes.swiftUI.foregroundColor {
      #if canImport(UIKit)
      // iOS 15+에서만 실행되므로 UIColor(Color) 변환 안전
      compatAttributes.foregroundColor = UIColor(foregroundColor)
      #elseif canImport(AppKit)
      compatAttributes.foregroundColor = NSColor(foregroundColor)
      #endif
    }

    if let backgroundColor = attributes.swiftUI.backgroundColor {
      #if canImport(UIKit)
      // iOS 15+에서만 실행되므로 UIColor(Color) 변환 안전
      compatAttributes.backgroundColor = UIColor(backgroundColor)
      #elseif canImport(AppKit)
      compatAttributes.backgroundColor = NSColor(backgroundColor)
      #endif
    }

    if let kern = attributes.kern {
      compatAttributes.kern = kern
    }
    if let baselineOffset = attributes.baselineOffset {
      compatAttributes.baselineOffset = baselineOffset
    }
    if let link = attributes.link {
      compatAttributes.link = link
    }
    if let tracking = attributes.tracking {
      compatAttributes.tracking = tracking
    }
    if let underlineStyle = attributes.underlineStyle {
      let compatStyle = CompatLineStyle(underlineStyle)
      compatAttributes.underlineStyle = compatStyle.nsUnderlineStyle
    }
    if let strikethroughStyle = attributes.strikethroughStyle {
      let compatStyle = CompatLineStyle(strikethroughStyle)
      compatAttributes.strikethroughStyle = compatStyle.nsUnderlineStyle
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

    // UnderlineStyle 및 StrikethroughStyle 복사
    if let underlineStyle = compatAttributes.underlineStyle {
      let compatStyle = CompatLineStyle(underlineStyle)
      attributes.underlineStyle = compatStyle.textLineStyle
    }
    if let strikethroughStyle = compatAttributes.strikethroughStyle {
      let compatStyle = CompatLineStyle(strikethroughStyle)
      attributes.strikethroughStyle = compatStyle.textLineStyle
    }

    // 기타 텍스트 속성 복사
    if let kern = compatAttributes.kern {
      attributes.kern = kern
    }
    if let baselineOffset = compatAttributes.baselineOffset {
      attributes.baselineOffset = baselineOffset
    }
    if let link = compatAttributes.link {
      attributes.link = link
    }
    if let tracking = compatAttributes.tracking {
      attributes.tracking = tracking
    }

    // 폰트 관련 속성 - FontProperties로 처리되므로 직접 복사하지 않음
    // Note: Font는 FontProperties를 통해 처리됨
  }
  #endif
}