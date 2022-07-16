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

    func test_load_deliversPrimaryImageDataOnPrimarySuccess() {
        let primaryImageData = anyData()
        let fallbackImageData = anyData()
        let expectedResult = FeedImageDataLoader.Result.success(primaryImageData)
        let (sut, _, _) = makeSUT(primaryResult: expectedResult, fallbackResult: .success(fallbackImageData))

        expect(sut, toCompleteWith: expectedResult)
    }

    func test_cancelLoadImageData_cancelsPrimaryLoaderTask() {
        let (sut, primaryLoader, _) = makeSUT()

        let url = anyURL()
        let task = sut.loadImageData(from: url) { _ in }
        task.cancel()

        XCTAssertEqual(primaryLoader.cancelledURLs, [url])
    }

    func test_load_deliversFallbackImageDataOnPrimaryFailure() {
        let primaryError = NSError()
        let fallbackImageData = anyData()
        let expectedResult = FeedImageDataLoader.Result.success(fallbackImageData)
        let (sut, _, _) = makeSUT(primaryResult: .failure(primaryError), fallbackResult: expectedResult)

        expect(sut, toCompleteWith: expectedResult)
    }

    func test_load_deliversFallbackErrorWhenBothPrimaryAndFallbackLoadsFails() {
        let primaryError = NSError(domain: "primary error", code: 0)
        let fallbackError = NSError(domain: "fallback error", code: 0)
        let expectedResult = FeedImageDataLoader.Result.failure(fallbackError)
        let (sut, _, _) = makeSUT(primaryResult: .failure(primaryError), fallbackResult: expectedResult)

        expect(sut, toCompleteWith: expectedResult)
    }

    func test_load_deliversPrimaryImageDataOnPrimarySuccess1() {
        let primaryImageData = anyData()
        let fallbackImageData = anyData()
        let expectedResult = FeedImageDataLoader.Result.success(primaryImageData)
        let (sut, _, _) = makeSUT(primaryResult: expectedResult, fallbackResult: .success(fallbackImageData))

        expect(sut, toCompleteWith: expectedResult)
    }

}

private extension FeedImageLoaderWithFallbackCompositeTests {

    func makeSUT(
        primaryResult: FeedImageDataLoader.Result = .success(anyData()),
        fallbackResult: FeedImageDataLoader.Result = .success(anyData()),
        file: StaticString = #file,
        line: UInt = #line
    ) -> (FeedImageLoaderWithFallbackComposite, LoaderSpy, LoaderSpy) {
        let primaryLoader = LoaderSpy(result: primaryResult)
        let fallbackLoader = LoaderSpy(result: fallbackResult)
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, primaryLoader, fallbackLoader)
    }

    func expect(
        _ sut: FeedImageLoaderWithFallbackComposite,
        toCompleteWith expectedResult: FeedImageDataLoader.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Expect remote feed")
        _ = sut.loadImageData(from: anyURL()) { receivedResult in
            switch (receivedResult, expectedResult) {
            case (.success(let receivedFeed), .success(let expectedFeed)):
                XCTAssertEqual(receivedFeed, expectedFeed, file: file, line: line)
            case (.failure(let receivedError), .failure(let expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) and received \(receivedResult)", file: file, line: line)
            }
            exp.fulfill()
        }
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
        private let result: FeedImageDataLoader.Result

        init(result: FeedImageDataLoader.Result) {
            self.result = result
        }

        func loadImageData(
            from url: URL,
            completion: @escaping (FeedImageDataLoader.Result) -> Void
        ) -> FeedImageDataLoaderTask {
            completion(result)
            return Task { [weak self] in
                self?.cancelledURLs.append(url)
            }
        }

        func save(_ data: Data, for url: URL, completion: @escaping (SaveResult) -> Void) {}
    }

}
