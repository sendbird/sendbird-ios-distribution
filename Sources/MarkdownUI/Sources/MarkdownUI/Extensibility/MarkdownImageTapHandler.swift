import SwiftUI

/// Information about a tapped standalone markdown image (`![alt](url)`).
public struct MarkdownImageTapInfo: Hashable, Sendable {
  /// The resolved image URL.
  public let url: URL

  /// The alt text of the image. Empty when the markdown has no alt text.
  public let alt: String

  public init(url: URL, alt: String) {
    self.url = url
    self.alt = alt
  }
}

extension View {
  /// Sets a handler invoked when a standalone (non link-wrapped) markdown image is tapped.
  ///
  /// The handler applies to standalone image paragraphs, image-only paragraphs
  /// rendered as an image flow, and images inside paragraphs that mix text and
  /// images. Images wrapped in a markdown link (`[![alt](img)](link)`) keep
  /// their link behavior and never trigger this handler.
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
}

private struct ImageTapHandlerKey: EnvironmentKey {
  static let defaultValue: ((MarkdownImageTapInfo) -> Void)? = nil
}

extension View {
  func imageTap(url: URL?, alt: String, enabled: Bool) -> some View {
    self.modifier(ImageTapModifier(url: url, alt: alt, enabled: enabled))
  }
}

struct ImageTapModifier: ViewModifier {
  @Environment(\.imageTapHandler) private var imageTapHandler

  let url: URL?
  let alt: String
  let enabled: Bool

  func body(content: Content) -> some View {
    if self.enabled, let url = self.url, let handler = self.imageTapHandler {
      Button {
        handler(.init(url: url, alt: self.alt))
      } label: {
        content
      }
      .buttonStyle(.plain)
    } else {
      content
    }
  }
}
