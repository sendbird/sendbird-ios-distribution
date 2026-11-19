import XCTest

@testable import SendbirdMarkdownUI

/// `^[text](key: value)` inline attributes.
///
/// cmark parses this syntax into an `attribute` node that wraps the text. The parser had no case for
/// it, so the node reached `default:` in `InlineNode.init`: Debug builds stopped on
/// `assertionFailure`, and Release builds returned `nil` and dropped the wrapped text.
final class InlineAttributeTests: XCTestCase {

  func testAttributeInAParagraphKeepsItsText() {
    let blocks = [BlockNode](markdown: "앞 ^[가운데](rainbow: 'extreme') 뒤")

    XCTAssertEqual(blocks, [.paragraph(content: [.text("앞 "), .text("가운데"), .text(" 뒤")])])
  }

  func testAttributeKeepsTheFormattingInside() {
    let blocks = [BlockNode](markdown: "^[**굵게** 보통](k: v)")

    XCTAssertEqual(blocks, [.paragraph(content: [.strong(children: [.text("굵게")]), .text(" 보통")])])
  }

  func testAttributeInsideEmphasisHeadingAndTableCell() {
    let markdown = """
      # 제목 ^[속성](k: v)

      *기울임 ^[속성](k: v)*

      | 칸 |
      | --- |
      | ^[속성](k: v) |
      """

    let text = [BlockNode](markdown: markdown).renderPlainText()

    XCTAssertEqual(text.components(separatedBy: "속성").count - 1, 3, text)
  }

  func testNestedAttributesKeepTheInnermostText() {
    let markdown = String(repeating: "^[", count: 100) + "x" + String(repeating: "](k: v)", count: 100)

    let text = [BlockNode](markdown: markdown).renderPlainText()

    XCTAssertTrue(text.contains("x"), text)
  }

  func testLinkAndFootnoteLikeTextAreUnchanged() {
    XCTAssertEqual(
      [BlockNode](markdown: "[링크](https://example.com) ^text"),
      [.paragraph(content: [.link(destination: "https://example.com", children: [.text("링크")]), .text(" ^text")])]
    )
  }
}
