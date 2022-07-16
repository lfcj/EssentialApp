import EssentialFeed
import XCTest

class FeedImageLoaderWithFallbackComposite: FeedImageDataLoader {

    private let primaryLoader: FeedImageDataLoader
    private let fallbackLoader: FeedImageDataLoader

    init(primaryLoader: FeedImageDataLoader, fallbackLoader: FeedImageDataLoader) {
        self.primaryLoader = primaryLoader
        self.fallbackLoader = fallbackLoader
    }

    private class TaskWrapper: FeedImageDataLoaderTask {
        var wrapped: FeedImageDataLoaderTask?

        func cancel() {
            wrapped?.cancel()
        }
    }

    func loadImageData(
        from url: URL,
        completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> FeedImageDataLoaderTask {
        let taskWrapper = TaskWrapper()
        taskWrapper.wrapped = primaryLoader.loadImageData(from: url) { [weak self] primaryResult in
            guard let self = self else {
                return
            }
            switch primaryResult {
            case .success:
                completion(primaryResult)

            case .failure:
                taskWrapper.wrapped = self.fallbackLoader.loadImageData(from: url, completion: completion)
            }
        }
        return taskWrapper
    }
    
    func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {
        primaryLoader.save(data, for: url, completion: completion)
    }
    
}

final class FeedImageLoaderWithFallbackCompositeTests: XCTestCase {

    func test_init_doesNotLoadImageData() {
        let (_, primaryLoader, fallbackLoader) = makeSUT()
        XCTAssertTrue(primaryLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the primary loader")
        XCTAssertTrue(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the fallback loader")
    }

    func test_loadImageData_loadsFromPrimaryLoaderFirst() {
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }

        XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load URL from primary loader")
        XCTAssertTrue(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the fallback loader")
    }

    func test_cancelLoadImageData_cancelsPrimaryLoaderTask() {
        let (sut, primaryLoader, fallbackLoader) = makeSUT()

        let url = anyURL()
        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()

        XCTAssertEqual(primaryLoader.cancelledURLs, [url])
        XCTAssertTrue(fallbackLoader.cancelledURLs.isEmpty)
    }

    func test_loadImageData_loadsFromFallbackLoaderWhenPrimaryLoaderFails() {
        let primaryError = NSError()
        let url = anyURL()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()

        _ = sut.loadImageData(from: url) { _ in }
        primaryLoader.complete(with: primaryError)

        XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load URL from primary loader")
        XCTAssertEqual(fallbackLoader.loadedURLs, [url], "Expected to also load URL from fallback loader")
        
    }

    func test_cancelLoadImageData_cancelsFallbackLoaderTask() {
        let (sut, primaryLoader, fallbackLoader) = makeSUT()

        let url = anyURL()
        let task = sut.loadImageData(from: url) { _ in }
        primaryLoader.complete(with: NSError())
        task.cancel()

        XCTAssertTrue(primaryLoader.cancelledURLs.isEmpty)
        XCTAssertEqual(fallbackLoader.cancelledURLs, [url])
    }

    func test_loadImageData_deliversPrimaryDataOnPrimaryLoaderSuccess() {
        let primaryData = anyData()
        let (sut, primaryLoader, _) = makeSUT()
        
        expect(sut, toCompleteWith: .success(primaryData), when: {
            primaryLoader.complete(with: primaryData)
        })
    }

    func test_loadImageData_deliversFallbackDataOnFallbackLoaderSuccess() {
        let fallbackData = anyData()
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        expect(sut, toCompleteWith: .success(fallbackData), when: {
            primaryLoader.complete(with: NSError())
            fallbackLoader.complete(with: fallbackData)
        })
    }

    func test_loadImageData_deliversErrorOnBothPrimaryAndFallbackLoaderFailure() {
        let fallbackError = NSError(domain: "fallback error", code: 0)
        let (sut, primaryLoader, fallbackLoader) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(fallbackError), when: {
            primaryLoader.complete(with: NSError())
            fallbackLoader.complete(with: fallbackError)
        })
    }

}

private extension FeedImageLoaderWithFallbackCompositeTests {

    func makeSUT(
        file: StaticString = #file,
        line: UInt = #line
    ) -> (FeedImageLoaderWithFallbackComposite, LoaderSpy, LoaderSpy) {
        let primaryLoader = LoaderSpy()
        let fallbackLoader = LoaderSpy()
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, primaryLoader, fallbackLoader)
    }

    func expect(
        _ sut: FeedImageDataLoader,
        toCompleteWith expectedResult: FeedImageDataLoader.Result,
        when action: () -> Void,
        file: StaticString = #file,
        line: UInt = #line)
    {
        let exp = expectation(description: "Wait for load completion")
        
        _ = sut.loadImageData(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedFeed), .success(expectedFeed)):
                XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)
                
            case (.failure, .failure):
                break
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }

    final class Task: FeedImageDataLoaderTask {
        let callback: () -> Void
        init(callback: @escaping () -> Void) {
            self.callback = callback
        }
        func cancel() {
            callback()
        }
    }

    final class LoaderSpy: FeedImageDataLoader {
        private(set) var cancelledURLs: [URL] = []
        var loadedURLs: [URL] {
            messages.map { $0.url }
        }
        private var messages = [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)]()

        func loadImageData(
            from url: URL,
            completion: @escaping (FeedImageDataLoader.Result) -> Void
        ) -> FeedImageDataLoaderTask {
            messages.append((url: url, completion: completion))
            return Task { [weak self] in
                self?.cancelledURLs.append(url)
            }
        }

        func complete(with data: Data, at index: Int = 0) {
            messages[index].completion(.success(data))
        }

        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }

        func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {}
    }

}
