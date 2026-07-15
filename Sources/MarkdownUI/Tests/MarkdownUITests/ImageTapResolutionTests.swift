import XCTest

@testable import SendbirdMarkdownUI

/// `MarkdownImageTapInfo.resolving(url:alt:in:)` — builds the tap payload delivered to
/// `markdownImageTapHandler` from the tapped image and the document's clickable images.
/// Contract: `images` always contains the tapped image and `currentIndex` is always valid.
final class ImageTapResolutionTests: XCTestCase {

  private func info(_ url: String, _ alt: String) -> MarkdownImageInfo {
    MarkdownImageInfo(url: URL(string: url)!, alt: alt)
  }

  func testMatchesTappedImageByURLAndAlt() {
    let images = [info("https://e.com/1.png", "one"), info("https://e.com/2.png", "two")]
    let tap = MarkdownImageTapInfo.resolving(
      url: URL(string: "https://e.com/2.png")!, alt: "two", in: images
    )
    XCTAssertEqual(tap.currentIndex, 1)
    XCTAssertEqual(tap.images, images)
    XCTAssertEqual(tap.url.absoluteString, "https://e.com/2.png")
    XCTAssertEqual(tap.alt, "two")
  }

  func testSameURLDifferentAltMatchesTheAltOccurrence() {
    let images = [info("https://e.com/i.png", "first"), info("https://e.com/i.png", "second")]
    let tap = MarkdownImageTapInfo.resolving(
      url: URL(string: "https://e.com/i.png")!, alt: "second", in: images
    )
    XCTAssertEqual(tap.currentIndex, 1)
  }

  func testAltMismatchFallsBackToFirstURLMatch() {
    let images = [info("https://e.com/1.png", "one"), info("https://e.com/2.png", "two")]
    let tap = MarkdownImageTapInfo.resolving(
      url: URL(string: "https://e.com/2.png")!, alt: "stale alt", in: images
    )
    XCTAssertEqual(tap.currentIndex, 1)
  }

  func testIdenticalDuplicatesResolveToFirstOccurrence() {
    // Known limitation (deferred): occurrences of a fully identical url+alt image
    // cannot be distinguished; the first one wins. The pager list stays complete.
    let images = [info("https://e.com/i.png", "a"), info("https://e.com/i.png", "a")]
    let tap = MarkdownImageTapInfo.resolving(
      url: URL(string: "https://e.com/i.png")!, alt: "a", in: images
    )
    XCTAssertEqual(tap.currentIndex, 0)
    XCTAssertEqual(tap.images.count, 2)
  }

  func testTappedImageMissingFromListFallsBackToSingleItemPayload() {
    let images = [info("https://e.com/other.png", "other")]
    let tap = MarkdownImageTapInfo.resolving(
      url: URL(string: "https://e.com/tapped.png")!, alt: "tapped", in: images
    )
    XCTAssertEqual(tap.images, [info("https://e.com/tapped.png", "tapped")])
    XCTAssertEqual(tap.currentIndex, 0)
  }
}
