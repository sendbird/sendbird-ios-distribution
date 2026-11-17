import SwiftUI
import XCTest

@testable import SendbirdMarkdownUI

/// Every blockquote adds its theme's margin and bar around the one inside it. Seven levels left
/// the text one character wide and eight left no room at all, so the text disappeared. Quotes past
/// the styled limit are drawn as their content only, so they look like the deepest styled level.
@available(iOS 16.0, *)
@MainActor
final class BlockquoteDepthTests: XCTestCase {

  private let themes: [(name: String, theme: Theme)] = [
    ("basic", .basic), ("gitHub", .gitHub), ("docC", .docC),
  ]

  private func pixels(_ markdown: String, theme: Theme) -> Data? {
    let view = Markdown(markdown)
      .markdownTheme(theme)
      .frame(width: 320, alignment: .leading)
    let renderer = ImageRenderer(content: view)
    renderer.scale = 2
    return renderer.uiImage?.pngData()
  }

  private func quote(_ depth: Int, _ text: String) -> String {
    String(repeating: ">", count: depth) + " " + text
  }

  private let text = "한글과 English가 섞인 인용문입니다. **굵게**와 `code`도 들어 있습니다."

  // MARK: - Past the limit (the text disappeared before the fix)

  func testQuotesPastTheLimitLookLikeTheLimit() throws {
    for (name, theme) in self.themes {
      let expected = try XCTUnwrap(self.pixels(self.quote(maxStyledBlockquoteLevel, self.text), theme: theme), name)
      for depth in [maxStyledBlockquoteLevel + 1, 8, 12] {
        XCTAssertEqual(self.pixels(self.quote(depth, self.text), theme: theme), expected, "\(name) depth \(depth)")
      }
    }
  }

  func testDeepQuoteKeepsTheQuotesAroundIt() throws {
    // Outer levels with their own text stay as they are, and only the levels past the limit flatten.
    let outer = "> a\n>\n>> b\n>>\n"
    for (name, theme) in self.themes {
      let expected = try XCTUnwrap(self.pixels(outer + self.quote(maxStyledBlockquoteLevel, self.text), theme: theme), name)
      XCTAssertEqual(self.pixels(outer + self.quote(9, self.text), theme: theme), expected, name)
    }
  }

  func testListInsideADeepQuoteIsKept() throws {
    func list(inside depth: Int) -> String {
      let quotes = String(repeating: "> ", count: depth)
      return "\(quotes)- one\n\(quotes)- two"
    }
    for (name, theme) in self.themes {
      let expected = try XCTUnwrap(self.pixels(list(inside: maxStyledBlockquoteLevel), theme: theme), name)
      XCTAssertEqual(self.pixels(list(inside: 9), theme: theme), expected, name)
    }
  }

  // MARK: - Up to the limit (unchanged)

  func testQuotesUpToTheLimitStillIndent() throws {
    for (name, theme) in self.themes {
      for depth in 1...maxStyledBlockquoteLevel {
        let inner = try XCTUnwrap(self.pixels(self.quote(depth, self.text), theme: theme), "\(name) \(depth)")
        let outer = try XCTUnwrap(self.pixels(self.quote(depth - 1, self.text), theme: theme), "\(name) \(depth - 1)")
        XCTAssertNotEqual(inner, outer, "\(name) depth \(depth) should be drawn inside one more quote")
      }
    }
  }

  func testQuoteModelIsUnchanged() {
    // Only drawing stops at the limit. The parsed blocks keep every level.
    let blocks = MarkdownContent(self.quote(8, "x")).blocks
    let expected = (1..<8).reduce(BlockNode.blockquote(children: [.paragraph(content: [.text("x")])])) { inner, _ in
      .blockquote(children: [inner])
    }
    XCTAssertEqual(blocks, [expected])
  }
}
