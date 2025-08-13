import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

// iOS 15+ 전용 AttributedString 관련 기능들
@available(iOS 15, *)
enum FontPropertiesAttribute: AttributedStringKey {
  typealias Value = FontProperties
  static let name = "fontProperties"
}

@available(iOS 15, *)
extension AttributeScopes {
  var markdownUI: MarkdownUIAttributes.Type {
    MarkdownUIAttributes.self
  }

  struct MarkdownUIAttributes: AttributeScope {
    let swiftUI: SwiftUIAttributes
    let fontProperties: FontPropertiesAttribute
  }
}

@available(iOS 15, *)
extension AttributeDynamicLookup {
  subscript<T: AttributedStringKey>(
    dynamicMember keyPath: KeyPath<AttributeScopes.MarkdownUIAttributes, T>
  ) -> T {
    return self[T.self]
  }
}

@available(iOS 15, *)
extension AttributedString {
  func resolvingFonts() -> AttributedString {
    var output = self

    for run in output.runs {
      guard let fontProperties = run.fontProperties else {
        continue
      }
      output[run.range].font = .withProperties(fontProperties)
      output[run.range].fontProperties = nil
    }

    return output
  }
}
