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
