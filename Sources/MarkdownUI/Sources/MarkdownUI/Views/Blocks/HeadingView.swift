import SwiftUI

struct HeadingView: View {
  @Environment(\.theme.headings) private var headings

  private let level: Int
  private let content: [InlineNode]

  init(level: Int, content: [InlineNode]) {
    self.level = level
    self.content = content
  }

  var body: some View {
    let safeLevel = max(1, min(self.level, self.headings.count))
    self.headings[safeLevel - 1].makeBody(
      configuration: .init(
        label: .init(InlineText(self.content)),
        content: .init(block: .heading(level: self.level, content: self.content))
      )
    )
    .id(content.renderPlainText().kebabCased())
  }
}
