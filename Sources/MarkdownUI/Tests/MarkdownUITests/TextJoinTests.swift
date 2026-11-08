import SwiftUI
import XCTest

@testable import SendbirdMarkdownUI

/// Inline text is joined as a balanced tree instead of one `+` per inline. The result has to
/// look exactly like the old left-to-right join.
@available(iOS 16.0, *)
@MainActor
final class TextJoinTests: XCTestCase {

  private func pixels(_ text: Text) -> Data? {
    let renderer = ImageRenderer(content: text.frame(width: 320, alignment: .leading))
    renderer.scale = 2
    return renderer.uiImage?.pngData()
  }

  private var pieces: [Text] {
    [
      Text("Plain "), Text("bold").bold(), Text(" and "), Text("italic").italic(),
      Text("\n"), Text("code").font(.system(.body, design: .monospaced)), Text(" "),
      Text("link").foregroundColor(.blue).underline(), Text(" "), Text(Image(systemName: "star.fill")),
      Text(" 한글과 English가 섞인 긴 문장이 줄을 넘겨 감싸지도록 충분히 길게 씁니다."),
    ]
  }

  func testBalancedJoinLooksTheSameAsSequentialJoin() {
    for count in [1, 2, 3, 5, 8, 11] {
      let slice = Array(self.pieces.prefix(count))
      let sequential = slice.reduce(Text(""), +)
      let balanced = Text.joinedBalanced(slice[...])
      let expected = self.pixels(sequential)
      XCTAssertNotNil(expected, "\(count) pieces")
      XCTAssertEqual(self.pixels(balanced), expected, "\(count) pieces")
    }
  }
}
