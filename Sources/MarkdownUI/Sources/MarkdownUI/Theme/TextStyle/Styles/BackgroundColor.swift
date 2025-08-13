import SwiftUI

/// A text style that sets the text background color.
public struct BackgroundColor: TextStyle {
  private let backgroundColor: Color?

  /// Creates a background color text style.
  /// - Parameter backgroundColor: The background color.
  public init(_ backgroundColor: Color?) {
    self.backgroundColor = backgroundColor
  }

  public func _collectAttributes(in attributes: inout CompatAttributeContainer) {
    #if canImport(UIKit)
    if let color = self.backgroundColor {
      attributes.backgroundColor = UIColor(color)
    }
    #elseif canImport(AppKit)
    if let color = self.backgroundColor {
      attributes.backgroundColor = NSColor(color)
    }
    #endif
  }
}
