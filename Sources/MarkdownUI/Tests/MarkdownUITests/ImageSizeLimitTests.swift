import ImageIO
import SwiftUI
import UIKit
import UniformTypeIdentifiers
import XCTest

@testable import SendbirdMarkdownUI
@testable import SendbirdNetworkImage

/// A Markdown image is downloaded whole and decoded at its original resolution. A small PNG of
/// one color can decode into hundreds of MB, and a link to a large file is read into memory in
/// full, so one message can push the app over the memory limit.
///
/// - `CachingAsyncImageView` is the block image view the AI Agent uses.
/// - `DefaultNetworkImageLoader` is what `DefaultInlineImageProvider` (inline images) uses, and it
///   keeps what it decodes in `DefaultNetworkImageCache.shared`.
final class ImageSizeLimitTests: XCTestCase {
  /// The decoded image budget: 2048 x 2048 pixels, 16MB at 4 bytes a pixel.
  private let maxPixelCount = 2048 * 2048
  private let maxDataLength = 20 * 1024 * 1024

  override func setUp() {
    super.setUp()
    URLProtocol.registerClass(StubImageProtocol.self)
  }

  override func tearDown() {
    URLProtocol.unregisterClass(StubImageProtocol.self)
    StubImageProtocol.reset()
    super.tearDown()
  }

  // MARK: Inline images (DefaultNetworkImageLoader)

  func testInlineLoaderDownsamplesLargeImage() async throws {
    let png = Self.makePNG(width: 4000, height: 3000)
    let loader = Self.loader(serving: png)

    let image = try await loader.image(from: Self.uniqueURL())

    XCTAssertLessThanOrEqual(image.width * image.height, maxPixelCount)
    XCTAssertGreaterThan(image.width, image.height, "The aspect ratio is kept")
  }

  func testInlineLoaderKeepsSmallImageSize() async throws {
    let png = Self.makePNG(width: 300, height: 200)
    let loader = Self.loader(serving: png)

    let image = try await loader.image(from: Self.uniqueURL())

    XCTAssertEqual(image.width, 300)
    XCTAssertEqual(image.height, 200)
  }

  func testInlineLoaderRejectsOversizedBody() async throws {
    let body = Self.padded(Self.makePNG(width: 300, height: 200), to: maxDataLength + 1)
    let loader = Self.loader(serving: body)

    do {
      let image = try await loader.image(from: Self.uniqueURL())
      XCTFail("A \(body.count) byte body was decoded into \(image.width)x\(image.height)")
    } catch {}
  }

  func testSharedInlineCacheBoundsDecodedBytes() throws {
    let images = try (0..<10).map { _ in try XCTUnwrap(Self.makeCGImage(width: 2048, height: 2048)) }
    let cost = images[0].bytesPerRow * images[0].height
    let cache = DefaultNetworkImageCache.shared
    let urls = (0..<10).map { _ in Self.uniqueURL() }

    zip(images, urls).forEach { cache.setImage($0, for: $1) }

    let kept = urls.filter { cache.image(for: $0) != nil }.count
    XCTAssertLessThanOrEqual(
      kept * cost, 64 * 1024 * 1024,
      "\(kept) images of \(cost) bytes are kept"
    )
  }

  // MARK: Block images (CachingAsyncImageView)

  @MainActor
  func testCachingAsyncImageViewDownsamplesLargeImage() throws {
    guard #available(iOS 15.0, *) else { throw XCTSkip("CachingAsyncImageView needs iOS 15") }
    let url = Self.uniqueURL()
    StubImageProtocol.bodies[url] = Self.makePNG(width: 3000, height: 3000)

    let image = try XCTUnwrap(loadCachingAsyncImage(url, timeout: 10))

    let pixels = Int(image.size.width * image.scale) * Int(image.size.height * image.scale)
    XCTAssertLessThanOrEqual(pixels, maxPixelCount)
  }

  @MainActor
  func testCachingAsyncImageViewKeepsSmallImageSize() throws {
    guard #available(iOS 15.0, *) else { throw XCTSkip("CachingAsyncImageView needs iOS 15") }
    let url = Self.uniqueURL()
    StubImageProtocol.bodies[url] = Self.makePNG(width: 300, height: 200)

    let image = try XCTUnwrap(loadCachingAsyncImage(url, timeout: 10))

    XCTAssertEqual(image.size.width * image.scale, 300)
    XCTAssertEqual(image.size.height * image.scale, 200)
  }

  @MainActor
  func testCachingAsyncImageViewRejectsOversizedBody() throws {
    guard #available(iOS 15.0, *) else { throw XCTSkip("CachingAsyncImageView needs iOS 15") }
    let url = Self.uniqueURL()
    StubImageProtocol.bodies[url] = Self.padded(Self.makePNG(width: 300, height: 200), to: maxDataLength + 1)

    // The body is served in full, then the view gets a few seconds to decode and cache it.
    let image = loadCachingAsyncImage(url, timeout: 5)

    XCTAssertTrue(StubImageProtocol.served.contains(url), "The view requested the image")
    XCTAssertNil(image, "A body over the limit is not drawn")
  }

  // MARK: Helpers

  /// Shows a `CachingAsyncImageView` in a window and waits until its image lands in the cache.
  @available(iOS 15.0, *)
  @MainActor
  private func loadCachingAsyncImage(_ url: URL, timeout: TimeInterval) -> UIImage? {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = UIHostingController(
      rootView: CachingAsyncImageView(url: url).frame(width: 300, height: 200)
    )
    window.makeKeyAndVisible()
    defer { window.isHidden = true }

    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if let image = CachingAsyncImageView.cache.object(forKey: url as NSURL) {
        return image
      }
      RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }
    return nil
  }

  private static func loader(serving body: Data) -> DefaultNetworkImageLoader {
    DefaultNetworkImageLoader(cache: DefaultNetworkImageCache()) { url in
      let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
      return (body, response)
    }
  }

  private static func uniqueURL() -> URL {
    URL(string: "https://image-size-limit.test/\(UUID().uuidString).png")!
  }

  private static func makeCGImage(width: Int, height: Int) -> CGImage? {
    let context = CGContext(
      data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
    context?.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
    context?.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return context?.makeImage()
  }

  /// One color, so a large image compresses to a few KB: the body is small, the bitmap is not.
  private static func makePNG(width: Int, height: Int) -> Data {
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, makeCGImage(width: width, height: height)!, nil)
    CGImageDestinationFinalize(destination)
    return data as Data
  }

  /// A valid image followed by bytes the decoder ignores, standing in for a large file.
  private static func padded(_ image: Data, to length: Int) -> Data {
    image + Data(count: max(0, length - image.count))
  }
}

/// Serves registered bodies to `URLSession.shared`.
private final class StubImageProtocol: URLProtocol {
  private static let lock = NSLock()
  private static var _bodies: [URL: Data] = [:]
  private static var _served: Set<URL> = []

  static var bodies: [URL: Data] {
    get { locked { _bodies } }
    set { locked { _bodies = newValue } }
  }

  static var served: Set<URL> {
    locked { _served }
  }

  static func reset() {
    locked {
      _bodies = [:]
      _served = []
    }
  }

  private static func locked<T>(_ body: () -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return body()
  }

  override class func canInit(with request: URLRequest) -> Bool {
    request.url?.host == "image-size-limit.test"
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    guard let url = request.url, let body = Self.bodies[url] else {
      client?.urlProtocol(self, didFailWithError: URLError(.fileDoesNotExist))
      return
    }
    let response = HTTPURLResponse(
      url: url, statusCode: 200, httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "image/png", "Content-Length": "\(body.count)"]
    )!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: body)
    Self.locked { _ = Self._served.insert(url) }
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}
