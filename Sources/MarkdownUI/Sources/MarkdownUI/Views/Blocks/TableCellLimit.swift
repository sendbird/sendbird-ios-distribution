import Foundation

/// 표 하나에 그리는 칸 수의 상한.
///
/// `TableView`(Grid)와 `CompatTableView`는 지연 생성 없이 모든 칸을 main에서 한꺼번에 만든다.
/// 시간은 칸 수에 비례해 iOS 26.4 시뮬레이터에서 1,000칸에 약 0.2초, 1만 칸에 약 2.8초가 걸린다.
/// 그래서 머리글을 포함해 1,000칸 안에 들어가는 행까지만 그리고 나머지 행은 그리지 않는다(안내 없음).
/// 열이 1,000개를 넘으면 앞의 1,000열의 머리글 행만 그린다.
enum TableCellLimit {
  static let maxCells = 1_000

  static func limit(
    columnAlignments: [RawTableColumnAlignment],
    rows: [RawTableRow]
  ) -> (columnAlignments: [RawTableColumnAlignment], rows: [RawTableRow]) {
    let columnCount = max(columnAlignments.count, 1)
    guard columnCount * rows.count > maxCells else {
      return (columnAlignments, rows)
    }
    let keptColumns = min(columnAlignments.count, maxCells)
    let keptRows = max(1, maxCells / max(keptColumns, 1))
    let limitedRows = rows.prefix(keptRows).map { row in
      RawTableRow(cells: Array(row.cells.prefix(keptColumns)))
    }
    return (Array(columnAlignments.prefix(keptColumns)), limitedRows)
  }
}
