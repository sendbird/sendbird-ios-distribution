import SwiftUI

struct TextStyleAttributesReader<Content: View>: View {
  @Environment(\.textStyle) private var textStyle

  private let content: (CompatAttributeContainer) -> Content

  init(@ViewBuilder content: @escaping (_ attributes: CompatAttributeContainer) -> Content) {
    self.content = content
  }

  var body: some View {
    self.content(self.attributes)
  }

  private var attributes: CompatAttributeContainer {
    var attributes = CompatAttributeContainer()
    self.textStyle._collectAttributes(in: &attributes)
    return attributes
  }
}
