import SwiftUI

/// Information about a tapped standalone markdown image (`![alt](url)`).
public struct MarkdownImageTapInfo: Hashable, Sendable {
  /// The resolved URL of the tapped image.
  public let url: URL

  /// The alt text of the tapped image. Empty when the markdown has no alt text.
  public let alt: String

  /// All clickable images of the rendered document, in document order
  /// (see ``MarkdownContent/clickableImages(relativeTo:)``).
  /// Always contains the tapped image.
  public let images: [MarkdownImageInfo]

  /// The index of the tapped image within ``images``. When a fully identical
  /// url+alt image occurs multiple times in one document, the occurrences cannot
  /// be distinguished and the first one wins; the list itself stays complete.
  public let currentIndex: Int

  public init(url: URL, alt: String, images: [MarkdownImageInfo], currentIndex: Int) {
    self.url = url
    self.alt = alt
    self.images = images
    self.currentIndex = currentIndex
  }

  /// Builds the tap payload for a tapped image against the rendered document's
  /// clickable images. A tapped image is always present in the rendered list;
  /// should they ever diverge, the payload degrades to a single-item list so the
  /// caller can still open the tapped image.
  static func resolving(url: URL, alt: String, in images: [MarkdownImageInfo]) -> MarkdownImageTapInfo {
    if let index = images.firstIndex(where: { $0.url == url && $0.alt == alt })
      ?? images.firstIndex(where: { $0.url == url })
    {
      return .init(url: url, alt: alt, images: images, currentIndex: index)
    }
    return .init(url: url, alt: alt, images: [.init(url: url, alt: alt)], currentIndex: 0)
  }
}

extension View {
  /// Sets a handler invoked when a standalone (non link-wrapped) markdown image is tapped.
  ///
  /// The handler applies to standalone image paragraphs, image-only paragraphs
  /// rendered as an image flow, and images inside paragraphs that mix text and
  /// images. Images wrapped in a markdown link (`[![alt](img)](link)`) keep
  /// their link behavior and never trigger this handler.
  ///
  /// The payload carries the tapped image plus the document's full clickable image
  /// list and the tapped index, resolved from the same cmark AST that rendered the view.
  public func markdownImageTapHandler(
    _ handler: ((MarkdownImageTapInfo) -> Void)?
  ) -> some View {
    self.environment(\.imageTapHandler, handler)
  }
}

extension EnvironmentValues {
  var imageTapHandler: ((MarkdownImageTapInfo) -> Void)? {
    get { self[ImageTapHandlerKey.self] }
    set { self[ImageTapHandlerKey.self] = newValue }
  }

  /// Set by the root ``Markdown`` view: the user handler wrapped with the rendered
  /// document's clickable images, so tap sites only need to report (url, alt).
  var resolvedImageTapHandler: ((URL, String) -> Void)? {
    get { self[ResolvedImageTapHandlerKey.self] }
    set { self[ResolvedImageTapHandlerKey.self] = newValue }
  }
}

private struct ImageTapHandlerKey: EnvironmentKey {
  static let defaultValue: ((MarkdownImageTapInfo) -> Void)? = nil
}

private struct ResolvedImageTapHandlerKey: EnvironmentKey {
  static let defaultValue: ((URL, String) -> Void)? = nil
}

extension View {
  func imageTap(url: URL?, alt: String, enabled: Bool) -> some View {
    self.modifier(ImageTapModifier(url: url, alt: alt, enabled: enabled))
  }
}

struct ImageTapModifier: ViewModifier {
  @Environment(\.resolvedImageTapHandler) private var resolvedImageTapHandler

  let url: URL?
  let alt: String
  let enabled: Bool

  func body(content: Content) -> some View {
    if self.enabled, let url = self.url, let handler = self.resolvedImageTapHandler {
      Button {
        handler(url, self.alt)
      } label: {
        content
      }
      .buttonStyle(.plain)
    } else {
      content
    }
  }
}
