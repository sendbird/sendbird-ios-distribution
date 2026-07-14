import Foundation

/// A soft break in a Markdown content block.
///
/// A ``Markdown`` view displays a soft break according to its configured ``Mode``.
/// The default mode displays soft breaks as line breaks.
public struct SoftBreak: InlineContentProtocol {
  /// Creates a soft break inline element.
  public init() {}

  public var _inlineContent: InlineContent {
    .init(inlines: [.softBreak])
  }
}

extension SoftBreak {
  public enum Mode {
    /// Treat a soft break as a space
    case space

    /// Treat a soft break as a line break
    case lineBreak
  }
}
