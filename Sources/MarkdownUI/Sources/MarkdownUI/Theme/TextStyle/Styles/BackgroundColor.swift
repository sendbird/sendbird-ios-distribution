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
      // iOS 14 호환성을 위해 안전한 변환 사용
      if #available(iOS 15.0, *) {
        attributes.backgroundColor = UIColor(color)
      } else {
        // iOS 14 폴백: 기본 색상으로 처리하거나 무시
        // SwiftUI Color -> UIColor 직접 변환이 제한적이므로 건너뜀
      }
    }
    #elseif canImport(AppKit)
    if let color = self.backgroundColor {
      attributes.backgroundColor = NSColor(color)
    }
    #endif
  }
}
