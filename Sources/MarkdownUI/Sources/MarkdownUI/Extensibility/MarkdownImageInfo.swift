import Foundation

/// A clickable markdown image, as rendered by the ``Markdown`` view.
public struct MarkdownImageInfo: Hashable, Sendable {
  /// The resolved image URL.
  public let url: URL

  /// The rendered plain text of the image's alt content. Empty when the markdown has no alt text.
  public let alt: String

  public init(url: URL, alt: String) {
    self.url = url
    self.alt = alt
  }
}

extension MarkdownContent {
  /// The images that the ``Markdown`` view renders as tappable, in document order.
  ///
  /// Matches the view's render paths exactly: top-level images of paragraph blocks
  /// (single-image paragraphs, image-only flows, and paragraphs mixing text and images),
  /// including paragraphs nested in blockquotes and lists. Images wrapped in a markdown
  /// link keep their link behavior and are excluded, as are images whose URL cannot be
  /// resolved. Images in headings, tables, and inline containers (emphasis, links) render
  /// as inline text attachments and are not tappable, so they are not collected.
  ///
  /// - Parameter imageBaseURL: The base URL for resolving relative image URLs. Pass the
  ///   same value used for the ``Markdown`` view's `imageBaseURL`. The default is `nil`.
  public func clickableImages(relativeTo imageBaseURL: URL? = nil) -> [MarkdownImageInfo] {
    Self.clickableImages(in: self.blocks, imageBaseURL: imageBaseURL)
  }

  private static func clickableImages(
    in blocks: [BlockNode],
    imageBaseURL: URL?
  ) -> [MarkdownImageInfo] {
    blocks.flatMap { block -> [MarkdownImageInfo] in
      switch block {
      case .paragraph(let content):
        return content.compactMap { inline in
          guard case .image(let source, let children) = inline,
            let url = URL(string: source, relativeTo: imageBaseURL)
          else {
            return nil
          }
          return MarkdownImageInfo(url: url, alt: children.renderPlainText())
        }
      default:
        return self.clickableImages(in: block.children, imageBaseURL: imageBaseURL)
      }
    }
  }
}
