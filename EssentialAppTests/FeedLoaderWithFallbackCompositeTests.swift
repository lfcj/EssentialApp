import EssentialFeed
import XCTest

final class FeedLoaderWithFallbackComposite {

    init(remote: FeedLoader, local: FeedLoader) {
        
    }
}

class FeedLoaderWithFallbackCompositeTests: XCTestCase {

    func test_load_deliversRemoteFeedOnRemoteSuccess() {
        let remoteLoader = LoaderStub()
        let localLoader = LoaderStub()
        let sut = FeedLoaderWithFallbackComposite(remote: remoteLoader, local: localLoader)

        let exp = expectation(description: "Expect remote feed")
        sut.load { result in
            if let receivedFeed = try? result.get() {
                XCTAssertEqual(receivedFeed, remoteFeed)
            } else {
                XCTFail("Expected feed and got result \(result)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    final class LoaderStub: FeedLoader {
        func load(completion: @escaping (Result<[FeedImage], Error>) -> Void) {}
    }
}
