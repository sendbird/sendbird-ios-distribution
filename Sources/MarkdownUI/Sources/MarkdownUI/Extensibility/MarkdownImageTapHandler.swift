import SwiftUI

/// Information about a tapped standalone markdown image (`![alt](url)`).
public struct MarkdownImageTapInfo: Equatable {
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
  /// Images wrapped in a markdown link (`[![alt](img)](link)`) keep their link
  /// behavior and never trigger this handler.
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
