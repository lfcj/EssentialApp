@testable import EssentialApp
import EssentialFeediOS
import XCTest

class SceneDelegateTests: XCTestCase {

    func test_sceneWillConnectToSession_configuresRootViewController() {
        let (sut, _) = makeSUT()

        sut.configureWindow()

        let root = sut.window?.rootViewController
        let rootNavigation = root as? UINavigationController
        let topController = rootNavigation?.topViewController

        XCTAssertNotNil(rootNavigation)
        XCTAssertTrue(topController is ListViewController)
    }

    func test_configureWindow_setsWindowAsKeyAndVisible() {
        let (sut, window) = makeSUT()

        sut.configureWindow()

        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1, "Expected to make window key and visible")
     }

}

// MARK: - Helpers

private extension SceneDelegateTests {

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> (SceneDelegate, UIWindowSpy) {
        let sut = SceneDelegate()
        let window = UIWindowSpy()
        sut.window = window

        return (sut, window)
    }

}

private class UIWindowSpy: UIWindow {
    var makeKeyAndVisibleCallCount = 0
    override func makeKeyAndVisible() {
        makeKeyAndVisibleCallCount = 1
    }
}
