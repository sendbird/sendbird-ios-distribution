import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
struct TableView: View {
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
    Grid(horizontalSpacing: self.borderWidth, verticalSpacing: self.borderWidth) {
      ForEach(0..<self.rowCount, id: \.self) { row in
        GridRow {
          ForEach(0..<self.columnCount, id: \.self) { column in
            TableCell(row: row, column: column, cell: self.cell(row: row, column: column))
              .gridColumnAlignment(.init(self.columnAlignments[column]))
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
}

extension HorizontalAlignment {
  fileprivate init(_ rawTableColumnAlignment: RawTableColumnAlignment) {
    switch rawTableColumnAlignment {
    case .none, .left:
      self = .leading
    case .center:
      self = .center
    case .right:
      self = .trailing
    }
  }
}
