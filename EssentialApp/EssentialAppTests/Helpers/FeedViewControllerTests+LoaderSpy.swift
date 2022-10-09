import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

extension FeedUIIntegrationTests {
    class LoaderSpy: FeedImageDataLoader {

        // MARK: - FeedLoader

        private var feedRequests = [PassthroughSubject<[FeedImage], Error>]()

        var loadFeedCallCount: Int { feedRequests.count }
        private(set) var cancelledImageURLs = [URL]()

        func loadPublisher() -> AnyPublisher<[FeedImage], Error> {
            let publisher = PassthroughSubject<[FeedImage], Error>()
            feedRequests.append(publisher)
            return publisher.eraseToAnyPublisher()
        }

        func completeFeedLoading(with feed: [FeedImage] = [], at index: Int = 0) {
            feedRequests[index].send(feed)
        }

        func completeFeedLoadingWithError(at index: Int = 0) {
            feedRequests[index].send(completion: .failure(anyNSError()))
        }

        private func anyNSError() -> NSError {
            NSError(domain: "any", code: 0, userInfo: nil)
        }

        // MARK: - FeedImageDataLoader

        private struct TaskSpy: FeedImageDataLoaderTask {
            let cancelCallback: () -> Void
            func cancel() { cancelCallback() }
        }

        typealias ImageRequestCompletion = (FeedImageDataLoader.Result) -> Void
        var loadedImageURLs: [URL] { imageRequests.map { $0.url } }
        private(set) var cancelledImagesURLs = [URL]()

        private var imageRequests = [(url: URL, completion: ImageRequestCompletion)]()

        func loadImageData(from url: URL, completion: @escaping ImageRequestCompletion) -> FeedImageDataLoaderTask {
            imageRequests.append((url, completion))
            return TaskSpy { [weak self] in
                self?.cancelledImageURLs.append(url)
            }
        }

        func completeImageLoading(with imageData: Data = Data(), at index: Int = 0) {
            imageRequests[index].completion(.success(imageData))
        }

        func completeImageLoadingWithError(at index: Int = 0) {
            imageRequests[index].completion(.failure(anyNSError()))
        }

    }
}
