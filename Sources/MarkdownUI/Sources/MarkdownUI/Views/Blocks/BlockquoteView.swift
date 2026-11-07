import SwiftUI

// 테마의 인용문 여백과 막대는 단계마다 더해진다. 7단계쯤이면 글이 한 글자씩 세로로 늘어서고, 8단계부터는 글이 보이지 않았다.
// 이 단계보다 안쪽 인용문은 테마를 다시 입히지 않고 내용만 그려, 가장 깊은 단계와 같은 너비에 보인다.
let maxStyledBlockquoteLevel = 4

struct BlockquoteView: View {
  @Environment(\.theme.blockquote) private var blockquote
  @Environment(\.blockquoteLevel) private var blockquoteLevel

  private let children: [BlockNode]

  init(children: [BlockNode]) {
    self.children = children
  }

  var body: some View {
    if self.blockquoteLevel >= maxStyledBlockquoteLevel {
      BlockSequence(self.children)
    } else {
      self.blockquote.makeBody(
        configuration: .init(
          label: .init(BlockSequence(self.children)),
          content: .init(block: .blockquote(children: self.children))
        )
      )
      .environment(\.blockquoteLevel, self.blockquoteLevel + 1)
    }
  }
}
