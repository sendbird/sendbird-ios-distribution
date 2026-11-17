import SwiftUI
import UIKit
import XCTest

@testable import SendbirdMarkdownUI

/// List item content is measured once per width and the result is kept. The kept size has to
/// follow the content when something inside it changes size later, such as an image that
/// finishes loading or a nested block that receives its margins.
@available(iOS 16.0, *)
@MainActor
final class ListItemContentLayoutTests: XCTestCase {
  private final class Model: ObservableObject {
    @Published var height: CGFloat = 10
  }

  /// Observes the model itself, so a change reaches only this view and not the layout around it.
  private struct Inner: View {
    @ObservedObject var model: Model

    var body: some View {
      Color.red.frame(width: 50, height: self.model.height)
    }
  }

  private func height(_ host: UIHostingController<some View>, width: CGFloat) -> CGFloat {
    host.view.frame = CGRect(x: 0, y: 0, width: width, height: 1000)
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    return host.sizeThatFits(in: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).height
  }

  func testKeptSizeFollowsAChangeInsideTheContent() {
    let model = Model()
    let host = UIHostingController(rootView: VStack(spacing: 0) { Inner(model: model).measuredOncePerWidth() })
    XCTAssertEqual(self.height(host, width: 320), 10)

    model.height = 40
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    XCTAssertEqual(self.height(host, width: 320), 40)

    model.height = 25
    RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    XCTAssertEqual(self.height(host, width: 320), 25)
  }

  func testDifferentWidthsAreMeasuredSeparately() {
    let host = UIHostingController(rootView: VStack(spacing: 0) {
      Text(String(repeating: "word ", count: 40)).measuredOncePerWidth()
    })
    let narrow = self.height(host, width: 120)
    let wide = self.height(host, width: 360)
    XCTAssertGreaterThan(narrow, wide)
    XCTAssertEqual(self.height(host, width: 120), narrow)
  }
}
