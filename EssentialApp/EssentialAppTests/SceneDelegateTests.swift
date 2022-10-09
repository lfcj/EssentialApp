@testable import EssentialApp
import EssentialFeediOS
import XCTest

class SceneDelegateTests: XCTestCase {

    func test_sceneWillConnectToSession_configuresRootViewController() {
        let sut = makeSUT()

        sut.configureWindow()

        let root = sut.window?.rootViewController
        let rootNavigation = root as? UINavigationController
        let topController = rootNavigation?.topViewController

        XCTAssertNotNil(rootNavigation)
        XCTAssertTrue(topController is FeedViewController)
    }

    func test_configureWindow_setsWindowAsKeyAndVisible() {
         let window = UIWindow()
         let sut = SceneDelegate()
         sut.window = window

         sut.configureWindow()

         XCTAssertTrue(window.isKeyWindow, "Expected window to be the key window")
         XCTAssertFalse(window.isHidden, "Expected window to be visible")
     }

}

// MARK: - Helpers

private extension SceneDelegateTests {

    func makeSUT(file: StaticString = #file, line: UInt = #line) -> SceneDelegate {
        let sut = SceneDelegate()
        sut.window = UIWindow()

        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

}
