import SwiftUI

/// iOS 14/15 호환 테이블 뷰 - VStack/HStack 조합으로 Grid 대신 구현
struct CompatTableView: View {
  @Environment(\.theme.table) private var table
  @Environment(\.tableBorderStyle.strokeStyle.lineWidth) private var borderWidth

  private let columnAlignments: [RawTableColumnAlignment]
  private let rows: [RawTableRow]

  init(columnAlignments: [RawTableColumnAlignment], rows: [RawTableRow]) {
    self.columnAlignments = columnAlignments
    self.rows = rows
  }

  var body: some View {
    self.table.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(block: .table(columnAlignments: self.columnAlignments, rows: self.rows))
      )
    )
  }

  private var label: some View {
    VStack(spacing: self.borderWidth) {
      ForEach(0..<self.rowCount, id: \.self) { row in
        HStack(alignment: .top, spacing: self.borderWidth) {
          ForEach(0..<self.columnCount, id: \.self) { column in
            CompatTableCell(row: row, column: column, cell: self.cell(row: row, column: column))
              .frame(maxWidth: .infinity, alignment: self.alignment(for: column))
          }
        }
      }
    }
    .padding(self.borderWidth)
    .tableDecoration(
      rowCount: self.rowCount,
      columnCount: self.columnCount,
      background: TableBackgroundView.init,
      overlay: TableBorderView.init
    )
  }

  private var rowCount: Int {
    self.rows.count
  }

  private var columnCount: Int {
    self.columnAlignments.count
  }

  // 행의 셀이 열 수보다 적으면 빈 셀을 그린다. 셀을 건너뛰면 TableBounds 의 anchor 가 비어 테두리가 어긋난다.
  private func cell(row: Int, column: Int) -> RawTableCell {
    let cells = self.rows[row].cells
    return cells.indices.contains(column) ? cells[column] : RawTableCell(content: [])
  }

  private func alignment(for column: Int) -> Alignment {
    switch self.columnAlignments[column] {
    case .none, .left:
      return .leading
    case .center:
      return .center
    case .right:
      return .trailing
    }
  }
}