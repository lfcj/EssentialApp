import EssentialApp
import EssentialFeed
import XCTest

final class FeedImageLoaderWithFallbackCompositeTests: XCTestCase, FeedImageDataLoaderTestCase {

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
    ) -> (FeedImageLoaderWithFallbackComposite, FeedImageDataLoaderSpy, FeedImageDataLoaderSpy) {
        let primaryLoader = FeedImageDataLoaderSpy()
        let fallbackLoader = FeedImageDataLoaderSpy()
        let sut = FeedImageLoaderWithFallbackComposite(primaryLoader: primaryLoader, fallbackLoader: fallbackLoader)

        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)

        return (sut, primaryLoader, fallbackLoader)
    }

}
