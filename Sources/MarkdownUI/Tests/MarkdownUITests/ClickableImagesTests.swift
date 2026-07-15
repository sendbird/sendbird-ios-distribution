import XCTest

@testable import SendbirdMarkdownUI

/// `MarkdownContent.clickableImages(relativeTo:)` — the parser-backed list of images that the
/// `Markdown` view renders as tappable. Must match the render paths exactly: top-level images
/// of paragraph blocks (single image / image flow / mixed paragraphs), document order,
/// link-wrapped images excluded (link priority), unresolvable URLs excluded.
final class ClickableImagesTests: XCTestCase {

  private func images(_ markdown: String) -> [(url: String, alt: String)] {
    MarkdownContent(markdown).clickableImages().map { ($0.url.absoluteString, $0.alt) }
  }

  // MARK: - Collection

  func testStandaloneImageIsClickable() {
    let result = images("![a cat](https://example.com/cat.png)")
    XCTAssertEqual(result.count, 1)
    XCTAssertEqual(result[0].url, "https://example.com/cat.png")
    XCTAssertEqual(result[0].alt, "a cat")
  }

  func testDocumentOrderAcrossParagraphsAndFlows() {
    let markdown = """
      ![one](https://e.com/1.png)

      text before ![two](https://e.com/2.png) text after

      ![three](https://e.com/3.png) ![four](https://e.com/4.png)
      """
    XCTAssertEqual(
      images(markdown).map(\.url),
      ["https://e.com/1.png", "https://e.com/2.png", "https://e.com/3.png", "https://e.com/4.png"]
    )
  }

  func testNestedParagraphsInBlockquoteAndListAreIncluded() {
    let markdown = """
      > ![quoted](https://e.com/q.png)

      - ![listed](https://e.com/l.png)
      """
    XCTAssertEqual(images(markdown).map(\.url), ["https://e.com/q.png", "https://e.com/l.png"])
  }

  func testIdenticalDuplicatesAreAllCollected() {
    let markdown = "![a](https://e.com/i.png) and ![a](https://e.com/i.png)"
    XCTAssertEqual(images(markdown).count, 2)
  }

  // MARK: - Exclusions (link priority, render parity)

  func testLinkWrappedImageIsExcluded() {
    let markdown = "[![badge](https://e.com/badge.png)](https://e.com/repo)"
    XCTAssertEqual(images(markdown).count, 0)
  }

  func testLinkWrappedImageInFlowIsExcludedButSiblingsRemain() {
    let markdown = "![a](https://e.com/a.png) [![b](https://e.com/b.png)](https://e.com/link)"
    XCTAssertEqual(images(markdown).map(\.url), ["https://e.com/a.png"])
  }

  func testImageInsideEmphasisIsNotClickable() {
    // Rendered through InlineText (inline image provider), not a tappable image view.
    XCTAssertEqual(images("*![a](https://e.com/i.png)*").count, 0)
  }

  func testImageInHeadingIsNotClickable() {
    XCTAssertEqual(images("# ![a](https://e.com/i.png)").count, 0)
  }

  func testImageInTableCellIsNotClickable() {
    let markdown = """
      | col |
      | --- |
      | ![a](https://e.com/i.png) |
      """
    XCTAssertEqual(images(markdown).count, 0)
  }

  func testEmptyDestinationIsExcluded() {
    XCTAssertEqual(images("![a]()").count, 0)
  }

  // MARK: - cmark parity (scanner divergences reported in review)

  func testImageInIndentedCodeBlockIsExcluded() {
    let markdown = "    ![a](https://e.com/i.png)"
    XCTAssertEqual(images(markdown).count, 0)
  }

  func testImageInFencedCodeBlockIsExcluded() {
    let markdown = """
      ```
      ![a](https://e.com/i.png)
      ```
      """
    XCTAssertEqual(images(markdown).count, 0)
  }

  func testAngleBracketDestinationIsCollected() {
    let result = images("![a](<https://e.com/i.png>)")
    XCTAssertEqual(result.map(\.url), ["https://e.com/i.png"])
  }

  func testUnclosedTitleIsLiteralTextNotAnImage() {
    XCTAssertEqual(images("![a](https://e.com/i.png \"title)").count, 0)
  }

  func testQuotedTitleIsCollectedWithoutTitleInURL() {
    let result = images("![a](https://e.com/i.png \"a title\")")
    XCTAssertEqual(result.map(\.url), ["https://e.com/i.png"])
  }

  func testStreamingPartialTokenIsNotAnImage() {
    XCTAssertEqual(images("look at this ![a](https://e.com/i.pn").count, 0)
  }

  // MARK: - Alt text is the rendered plain text

  func testAltTextRendersInlineFormatting() {
    let result = images("![_snake_case_ **bold** `code`](https://e.com/i.png)")
    XCTAssertEqual(result[0].alt, "snake_case bold code")
  }

  // MARK: - Base URL resolution

  func testRelativeSourceResolvesAgainstBaseURL() {
    let content = MarkdownContent("![a](/img/cat.png)")
    let result = content.clickableImages(relativeTo: URL(string: "https://example.com"))
    XCTAssertEqual(result.map(\.url.absoluteString), ["https://example.com/img/cat.png"])
  }
}
