@testable import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

final class FeedAcceptanceTests: XCTestCase {

    func test_onLaunch_displaysRemoteFeedWhenUserHasConnectivity() {
        let feed = launch(httpClient: .online(response), store: .empty)

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData())
    }

    func test_onLaunch_displaysCachedFeedWhenUserHasNoConnectivity() {
        
    }

    func test_onLaunch_displaysEmptyFeedWhenCusotmerHasNoConnectivityAndNoCache() {
        
    }

}

// MARK: - Helpers

private extension FeedAcceptanceTests {

    func launch(httpClient: HTTPClientStub, store: InMemoryFeedStore) -> FeedViewController {
        let sut = makeSUT(store: store, httpClient: httpClient)
        sut.configureWindow()

        let nav = sut.window?.rootViewController as? UINavigationController
        let feed = nav?.topViewController as! FeedViewController

        return feed
    }

    func makeSUT(
        store: FeedStore & FeedImageDataStore,
        httpClient: HTTPClient,
        file: StaticString = #file,
        line: UInt = #line
    ) -> SceneDelegate {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow()

        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    final class HTTPClientStub: HTTPClient {
        private class Task: HTTPClientTask {
            func cancel() {}
        }

        private let stub: (URL) -> HTTPClient.Result

        init(stub: @escaping (URL) -> HTTPClient.Result) {
            self.stub = stub
        }

        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
            completion(stub(url))
            return Task()
        }

        static var offline: HTTPClientStub {
            HTTPClientStub { _ in .failure(NSError(domain: "offline", code: 0)) }
        }

        static func online(_ stub: @escaping (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
            HTTPClientStub { url in .success(stub(url))}
        }
    }

    final class InMemoryFeedStore: FeedStore, FeedImageDataStore {
        private var feedCache: CachedFeed?
        private var feedImageDataCache: [URL: Data] = [:]

        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            feedCache = nil
            completion(.success(()))
        }

        func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            feedCache = CachedFeed(feed: feed, timestamp: timestamp)
            completion(.success(()))
        }

        func insert(_ data: Data, for url: URL, completion: @escaping (InsertionResult) -> Void) {
            feedImageDataCache[url] = data
            completion(.success(()))
        }

        func retrieve(completion: @escaping RetrievalCompletion) {
            completion(.success(feedCache))
        }

        func retrieve(dataForURL url: URL, completion: @escaping (FeedImageDataStore.RetrievalResult) -> Void) {
            completion(.success(feedImageDataCache[url]))
        }

        static var empty: InMemoryFeedStore {
            InMemoryFeedStore()
        }
    }

    func response(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (makeData(for: url), response)
    }

    func makeData(for url: URL) -> Data {
        switch url.absoluteString {
        case "http://image.com":
            return makeImageData()
        default:
            return makeFeedData()
        }
    }

    func makeImageData() -> Data {
        UIImage.make(color: .red).pngData()!
    }

    func makeFeedData() -> Data {
        try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    ["id": UUID().uuidString, "image": "http://image.com"],
                    ["id": UUID().uuidString, "image": "http://image.com"]
                ]
            ]
        )
    }

    

}
