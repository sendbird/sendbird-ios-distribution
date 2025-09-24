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
            CompatTableCell(row: row, column: column, cell: self.rows[row].cells[column])
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