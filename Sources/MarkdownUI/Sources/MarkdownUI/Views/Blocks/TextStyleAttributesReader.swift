import SwiftUI

// 속성 컨테이너 프로토콜
protocol AttributesContainer {
  var fontProperties: FontProperties? { get }
  var swiftUIForegroundColor: Color? { get }
  var swiftUIBackgroundColor: Color? { get }
}

// iOS 15+ AttributeContainer 확장
#if canImport(SwiftUI) && compiler(>=5.5)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AttributeContainer: AttributesContainer {
  var fontProperties: FontProperties? {
    self[FontPropertiesAttribute.self]
  }
  
  var swiftUIForegroundColor: Color? {
    self.swiftUI.foregroundColor
  }
  
  var swiftUIBackgroundColor: Color? {
    self.swiftUI.backgroundColor
  }
}
#endif

// iOS 14 CompatAttributeContainer 확장  
extension CompatAttributeContainer: AttributesContainer {}

// 통합 Reader
struct TextStyleAttributesReader<Content: View>: View {
  @Environment(\.textStyle) private var textStyle

  private let content: (AttributesContainer) -> Content

  init(@ViewBuilder content: @escaping (_ attributes: AttributesContainer) -> Content) {
    self.content = content
  }

  var body: some View {
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
      self.content(self.modernAttributes)
    } else {
      self.content(self.compatAttributes)
    }
  }

  #if canImport(SwiftUI) && compiler(>=5.5)
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
  private var modernAttributes: AttributeContainer {
    var attributes = AttributeContainer()
    self.textStyle._collectAttributes(in: &attributes)
    return attributes
  }
  #endif

  private var compatAttributes: CompatAttributeContainer {
    var attributes = CompatAttributeContainer()
    self.textStyle._collectAttributes(in: &attributes)
    return attributes
  }
}