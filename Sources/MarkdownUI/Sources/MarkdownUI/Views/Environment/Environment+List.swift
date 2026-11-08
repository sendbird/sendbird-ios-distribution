import SwiftUI

extension EnvironmentValues {
  var listLevel: Int {
    get { self[ListLevelKey.self] }
    set { self[ListLevelKey.self] = newValue }
  }

  // 지금 그리는 블록을 감싼, 테마를 입힌 인용문의 수.
  var blockquoteLevel: Int {
    get { self[BlockquoteLevelKey.self] }
    set { self[BlockquoteLevelKey.self] = newValue }
  }

  var tightSpacingEnabled: Bool {
    get { self[TightSpacingEnabledKey.self] }
    set { self[TightSpacingEnabledKey.self] = newValue }
  }
}

private struct ListLevelKey: EnvironmentKey {
  static var defaultValue = 0
}

private struct BlockquoteLevelKey: EnvironmentKey {
  static var defaultValue = 0
}

private struct TightSpacingEnabledKey: EnvironmentKey {
  static var defaultValue = false
}
