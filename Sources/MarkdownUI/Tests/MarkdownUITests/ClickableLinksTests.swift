import XCTest

@testable import SendbirdMarkdownUI

/// `MarkdownContent.clickableLinks(relativeTo:)` — the parser-backed list of links the
/// rendered document exposes, in document order. Covers markdown links, GFM autolinked
/// bare URLs, and link-wrapped images (outer destination). Standalone images are not
/// links. Same cmark AST as rendering, so code spans/blocks and streaming-partial
/// tokens never produce phantom links.
final class ClickableLinksTests: XCTestCase {

  private func links(_ markdown: String) -> [(text: String, url: String)] {
    MarkdownContent(markdown).clickableLinks().map { ($0.text, $0.url.absoluteString) }
  }

  func testMarkdownLinkIsCollected() {
    let result = links("[the docs](https://sendbird.com/docs)")
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].text, "the docs")
    XCTAssertEqual(result[0].url, "https://sendbird.com/docs")
  }

  func testBareURLIsAutolinked() {
    let result = links("see https://example.com/page for details")
    XCTAssertEqual(result.map(\.url), ["https://example.com/page"])
    XCTAssertEqual(result.map(\.text), ["https://example.com/page"])
  }

  func testLinkWrappedImageUsesOuterDestinationAndAltAsText() {
    // Regression (PR #588 review): the VoiceOver link action must open the outer
    // link, not the inner image URL.
    let result = links("[![badge](https://e.com/badge.png)](https://e.com/repo)")
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].url, "https://e.com/repo")
    XCTAssertEqual(result[0].text, "badge")
  }

  func testStandaloneImageIsNotALink() {
    // Regression (PR #588 review): image syntax must not produce a link action.
    XCTAssertEqual(links("![alt](https://e.com/i.png)").count, 0)
  }

  func testDocumentOrderAcrossBlocks() {
    let markdown = """
      # heading [first](https://e.com/1)

      body [second](https://e.com/2) and https://e.com/3
      """
    XCTAssertEqual(links(markdown).map(\.url), ["https://e.com/1", "https://e.com/2", "https://e.com/3"])
  }

  func testLinkInCodeSpanIsNotCollected() {
    XCTAssertEqual(links("`[a](https://e.com)` and https://e.com/real").map(\.url), ["https://e.com/real"])
  }

  func testDuplicateLinksAreAllCollected() {
    let markdown = "[a](https://e.com/x) then again https://e.com/x"
    XCTAssertEqual(links(markdown).count, 2)
  }

  func testEmptyOrInvalidDestinationIsExcluded() {
    XCTAssertEqual(links("[text]()").count, 0)
  }

  func testRelativeDestinationResolvesAgainstBaseURL() {
    let content = MarkdownContent("[docs](/docs)")
    let result = content.clickableLinks(relativeTo: URL(string: "https://sendbird.com"))
    XCTAssertEqual(result.map(\.url.absoluteString), ["https://sendbird.com/docs"])
  }

  func testNestedEmphasisTextIsRenderedPlain() {
    let result = links("[**bold** _label_](https://e.com)")
    XCTAssertEqual(result[0].text, "bold label")
  }
}
