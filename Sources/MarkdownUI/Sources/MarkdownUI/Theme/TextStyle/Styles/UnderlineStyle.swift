import SwiftUI

/// A text style that sets the underline line style of the text.
public struct UnderlineStyle: TextStyle {
  private let lineStyle: CompatLineStyle?

  /// Creates an underline style text style.
  /// - Parameter lineStyle: The line style.
  public init(_ lineStyle: CompatLineStyle?) {
    self.lineStyle = lineStyle
  }
  
  /// iOS 15+ Text.LineStyle 호환성 초기화
  @available(iOS 15, *)
  public init(_ lineStyle: Text.LineStyle?) {
    if let lineStyle = lineStyle {
      self.lineStyle = CompatLineStyle(lineStyle)
    } else {
      self.lineStyle = nil
    }
  }

  public func _collectAttributes(in attributes: inout CompatAttributeContainer) {
    if let lineStyle = self.lineStyle {
      attributes.underlineStyle = lineStyle.nsUnderlineStyle
    }
  }
}
