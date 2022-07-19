import EssentialApp
import EssentialFeed
import XCTest

final class FeedImageDataLoaderCacheDecoratorTests: XCTestCase, FeedImageDataLoaderTestCase {

    func test_init_doesNotLoadImageData() {
        let (_, loader) = makeSUT()
        XCTAssertTrue(loader.loadedURLs.isEmpty, "Expected no loaded URLs in the primary loader")
    }

    func test_load_deliversFeedImageOnLoaderSuccess() {
        let data = anyData()
        let (sut, loader) = makeSUT()

        expect(sut, toCompleteWith: .success(data)) {
            loader.complete(with: data)
        }
    }

    func test_cancelLoadImageData_cancelsLoaderTask() {
        let (sut, loader) = makeSUT()

        let url = anyURL()
        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()

        XCTAssertEqual(loader.cancelledURLs, [url])
    }

    func test_loadImageData_deliversErrorOnLoaderFailure() {
        let loaderError = NSError(domain: "loader error", code: 0)
        let (sut, loader) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(loaderError), when: {
            loader.complete(with: loaderError)
        })
    }

    func test_load_cachesLoadedImageDataOnLoaderSuccess() {
        let data = anyData()
        let cache = CacheSpy()
        let (sut, loader) = makeSUT(cache: cache)
        let url = anyURL()

        _ = sut.loadImageData(from: url) { _ in }
        loader.complete(with: data)

        XCTAssertEqual(cache.messages, [.save(data, url)], "Expected to cache feed on load success")
    }

    func test_load_doesNotCacheLoadedImageDataOnLoaderFailure() {
        let cache = CacheSpy()
        let (sut, loader) = makeSUT(cache: cache)
        let url = anyURL()

        _ = sut.loadImageData(from: url) { _ in }
        loader.complete(with: anyError())

        XCTAssertTrue(cache.messages.isEmpty)
    }

    func test_load_doesNotCacheLoadedImageDataWhenTaskIsCancelled() {
        let cache = CacheSpy()
        let (sut, loader) = makeSUT(cache: cache)
        let url = anyURL()

        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()
        loader.complete(with: anyError())

        XCTAssertTrue(cache.messages.isEmpty)
        XCTAssertEqual(loader.cancelledURLs, [url])
    }

}

// MARK: - Helpers

private extension FeedImageDataLoaderCacheDecoratorTests {

    func makeSUT(
        cache: CacheSpy = CacheSpy(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (FeedImageDataLoaderCacheDecorator, FeedImageDataLoaderSpy) {
        let decoratee = FeedImageDataLoaderSpy()
        let decorator = FeedImageDataLoaderCacheDecorator(decoratee: decoratee, cache: cache)
        trackForMemoryLeaks(decorator, file: file, line: line)
        return (decorator, decoratee)
    }

    class CacheSpy: FeedImageDataCache {
        enum Message: Equatable {
            case save(Data, URL)
        }
        private(set) var messages = [Message]()

        func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
            messages.append(.save(data, url))
            completion(.success(()))
        }
    }

}
