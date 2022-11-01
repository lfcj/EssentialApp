@testable import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

final class FeedAcceptanceTests: XCTestCase {

    func test_onLaunch_displaysRemoteFeedWhenUserHasConnectivity() {
        let feed = launch(httpClient: .online(response), store: .empty)

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 2)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertTrue(feed.canLoadMoreFeed)

        feed.simulateLoadMoreFeedAction()

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertTrue(feed.canLoadMoreFeed)

        feed.simulateLoadMoreFeedAction()

        XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(feed.renderedFeedImageData(at: 2), makeImageData2())
        XCTAssertFalse(feed.canLoadMoreFeed)
    }

    func test_onLaunch_displaysCachedFeedWhenUserHasNoConnectivity() {
        let sharedStore = InMemoryFeedStore.empty

        let onlineFeed = launch(httpClient: .online(response), store: sharedStore)
        onlineFeed.simulateFeedImageViewVisible(at: 0)
        onlineFeed.simulateFeedImageViewVisible(at: 1)
        onlineFeed.simulateLoadMoreFeedAction()
        onlineFeed.simulateFeedImageViewVisible(at: 2)

        let offlineFeed = launch(httpClient: .offline, store: sharedStore)

        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 3)
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 0), makeImageData0())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 1), makeImageData1())
        XCTAssertEqual(offlineFeed.renderedFeedImageData(at: 2), makeImageData2())
    }

    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
        let offlineFeed = launch(httpClient: .offline, store: .empty)

        XCTAssertEqual(offlineFeed.numberOfRenderedFeedImageViews(), 0)
    }

    func test_onEnteringBackground_deletesExpiredFeedCache() {
        let store = InMemoryFeedStore.withExpiredFeedCache

        enterBackground(with: store)

        XCTAssertNil(store.feedCache, "Expected to delete expired cache")
    }

    func test_onEnteringBackground_keepsNonExpiredFeedCache() {
        let store = InMemoryFeedStore.withNonExpiredFeedCache

        enterBackground(with: store)

        XCTAssertNotNil(store.feedCache, "Expected to keep expired cache")
    }
 
    func test_onFeedImageSelection_displaysComments() {
        let comments = showCommentsForFirstImage()

        XCTAssertEqual(comments.numberOfRenderedComments(), 1)
        XCTAssertEqual(comments.commentMessage(at: 0), makeCommentMessage())
    }

}

// MARK: - Helpers

private extension FeedAcceptanceTests {

    func launch(httpClient: HTTPClientStub, store: InMemoryFeedStore) -> ListViewController {
        let sut = makeSUT(store: store, httpClient: httpClient)
        sut.window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        sut.configureWindow()

        let nav = sut.window?.rootViewController as? UINavigationController
        let feed = nav?.topViewController as! ListViewController

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

        return sut
    }

    func enterBackground(with store: InMemoryFeedStore) {
        let sut = SceneDelegate(httpClient: HTTPClientStub.offline, store: store)
        sut.sceneWillResignActive(UIApplication.shared.connectedScenes.first!)
    }

    func showCommentsForFirstImage() -> ListViewController {
        let feed = launch(httpClient: .online(response), store: .empty)

        feed.simulateTapOnFeedImage(at: 0)
        // Make sure everything is rendered correctly before getting the updated stack.
        RunLoop.current.run(until: Date())

        let nav = feed.navigationController
        return nav?.topViewController as! ListViewController
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
        private(set) var feedCache: CachedFeed?
        private var feedImageDataCache: [URL: Data] = [:]

        private init(feedCache: CachedFeed? = nil) {
            self.feedCache = feedCache
        }

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

        static var withExpiredFeedCache: InMemoryFeedStore {
            InMemoryFeedStore(feedCache: (feed: [], timestamp: Date.distantPast))
        }

        static var withNonExpiredFeedCache: InMemoryFeedStore {
            InMemoryFeedStore(feedCache: (feed: [], timestamp: Date.distantFuture))
        }
    }

    func response(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (makeData(for: url), response)
    }

    func makeData(for url: URL) -> Data {
        switch url.path {
        case "/image-0":
            return makeImageData0()

        case "/image-1":
            return makeImageData1()

        case "/image-2":
            return makeImageData2()

        case "/essential-feed/v1/feed" where url.query?.contains("after_id") == false:
            return makeFirstFeedPageData()

        case "/essential-feed/v1/feed" where url.query?.contains("after_id=3E88AA2A-6DA7-4C02-B420-94E792AA434E") == true:
            return makeSecondFeedPageData()

        case "/essential-feed/v1/feed" where url.query?.contains("after_id=166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F") == true:
            return makeLastEmptyFeedPageData()

        case "/essential-feed/v1/image/16E43B55-2A1D-46E3-AE81-89AF689A1CFC/comments":
            return makeCommentsData()

        default:
            return Data()
        }
    }

    func makeImageData0() -> Data { UIImage.make(color: .red).pngData()! }
    func makeImageData1() -> Data { UIImage.make(color: .green).pngData()! }
    func makeImageData2() -> Data { UIImage.make(color: .blue).pngData()! }

    func makeFirstFeedPageData() -> Data {
        try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    ["id": "16E43B55-2A1D-46E3-AE81-89AF689A1CFC", "image": "http://feed.com/image-0"],
                    ["id": "3E88AA2A-6DA7-4C02-B420-94E792AA434E", "image": "http://feed.com/image-1"]
                ]
            ]
        )
    }

    func makeCommentsData() -> Data {
        try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    [
                        "id": UUID().uuidString,
                        "message": makeCommentMessage(),
                        "created_at": "2020-08-28T15:07:02+00:00",
                        "author": [
                            "username": "a user"
                        ]
                    ],
                ]
            ]
        )
    }

    func makeSecondFeedPageData() -> Data {
        try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    ["id": "166FCDD7-C9F4-420A-B2D6-CE2EAFA3D82F", "image": "http://feed.com/image-2"],
                ]
            ]
        )
    }

    func makeLastEmptyFeedPageData() -> Data {
        try! JSONSerialization.data(withJSONObject: ["items": []])
    }

    func makeCommentMessage() -> String {
        "a message"
    }

}
