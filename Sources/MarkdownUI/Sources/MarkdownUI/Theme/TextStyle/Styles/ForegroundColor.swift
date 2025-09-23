import SwiftUI

/// A text style that sets the foreground color of the text.
public struct ForegroundColor: TextStyle {
  private let foregroundColor: Color?

  /// Creates a foreground color text style.
  /// - Parameter foregroundColor: The foreground color.
  public init(_ foregroundColor: Color?) {
    self.foregroundColor = foregroundColor
  }

  public func _collectAttributes(in attributes: inout CompatAttributeContainer) {
    #if canImport(UIKit)
    if let color = self.foregroundColor {
      // iOS 14 호환성을 위해 안전한 변환 사용
      if #available(iOS 15.0, *) {
        attributes.foregroundColor = UIColor(color)
      } else {
        // iOS 14 폴백: 기본 색상으로 처리하거나 무시
        // SwiftUI Color -> UIColor 직접 변환이 제한적이므로 건너뜀
      }
    }
    #elseif canImport(AppKit)
    if let color = self.foregroundColor {
      attributes.foregroundColor = NSColor(color)
    }
    #endif
  }
}
