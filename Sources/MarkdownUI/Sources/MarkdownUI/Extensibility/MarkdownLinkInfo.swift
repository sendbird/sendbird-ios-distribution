import Foundation

/// A clickable link rendered by the ``Markdown`` view.
public struct MarkdownLinkInfo: Hashable, Sendable {
  /// The resolved link destination.
  public let url: URL

  /// The rendered plain text of the link's label. For a link-wrapped image this is
  /// the image's alt text. For an autolinked bare URL this is the URL string itself.
  public let text: String

  public init(url: URL, text: String) {
    self.url = url
    self.text = text
  }
}

extension MarkdownContent {
  /// The links that the ``Markdown`` view renders as clickable, in document order.
  ///
  /// Collected from the same cmark AST used for rendering: markdown links, GFM
  /// autolinked bare URLs, and link-wrapped images (outer destination) — wherever
  /// they render (paragraphs, headings, blockquotes, lists, tables). Standalone
  /// images are not links, code spans/blocks never produce links, and links whose
  /// destination cannot be resolved are excluded.
  ///
  /// - Parameter baseURL: The base URL for resolving relative destinations. Pass the
  ///   same value used for the ``Markdown`` view's `baseURL`. The default is `nil`.
  public func clickableLinks(relativeTo baseURL: URL? = nil) -> [MarkdownLinkInfo] {
    Self.clickableLinks(in: self.blocks, baseURL: baseURL)
  }

  private static func clickableLinks(in blocks: [BlockNode], baseURL: URL?) -> [MarkdownLinkInfo] {
    blocks.flatMap { block -> [MarkdownLinkInfo] in
      switch block {
      case .paragraph(let content), .heading(_, let content):
        return self.links(in: content, baseURL: baseURL)
      case .table(_, let rows):
        return rows.flatMap { row in
          row.cells.flatMap { self.links(in: $0.content, baseURL: baseURL) }
        }
      default:
        return self.clickableLinks(in: block.children, baseURL: baseURL)
      }
    }
  }

  private static func links(in inlines: [InlineNode], baseURL: URL?) -> [MarkdownLinkInfo] {
    inlines.flatMap { inline -> [MarkdownLinkInfo] in
      switch inline {
      case .link(let destination, let children):
        guard let url = URL(string: destination, relativeTo: baseURL) else { return [] }
        return [MarkdownLinkInfo(url: url, text: children.renderPlainText())]
      case .image:
        // Links inside an image's alt render as plain text, never as tappable links.
        return []
      default:
        return self.links(in: inline.children, baseURL: baseURL)
      }
    }
  }
}
