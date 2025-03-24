import Cocoa
import XCTest
import FlutterMacOS
import integration_test_macos

class RunnerTests: XCTestCase {
  func testRunner() {
    let testBundle = Bundle(for: type(of: self))
    IntegrationTestMacosRunner.runFromXCTest(testBundle)
  }
}
