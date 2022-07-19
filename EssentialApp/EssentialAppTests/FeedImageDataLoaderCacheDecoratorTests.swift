import EssentialApp
import EssentialFeed
import XCTest

protocol FeedImageDataCache {
    typealias SaveResult = Swift.Result<Void, Swift.Error>
    func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void)
}

final class FeedImageDataLoaderCacheDecorator: FeedImageDataLoader {

    private class TaskWrapper: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?

        func cancel() {
            wrapped?.cancel()
        }
    }

    private let decoratee: FeedImageDataLoader
    private let cache: FeedImageDataCache

    init(decoratee: FeedImageDataLoader, cache: FeedImageDataCache) {
        self.decoratee = decoratee
        self.cache = cache
    }

    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> FeedImageDataLoaderTask {
        decoratee.loadImageData(from: url) { [weak self] result in
            completion(result.map { imageData in
                self?.cache.saveIgnoringResult(imageData, for: url)
                return imageData
            })
        }
    }

    func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {}

}

private extension FeedImageDataCache {
    func saveIgnoringResult(_ data: Data, for url: URL) {
        self.save(data, for: url) { _ in }
    }
}

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
