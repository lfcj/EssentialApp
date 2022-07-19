import EssentialFeed
import Foundation

final class FeedImageDataLoaderSpy: FeedImageDataLoader {
    final class Task: FeedImageDataLoaderTask {
        let callback: () -> Void
        init(callback: @escaping () -> Void) {
            self.callback = callback
        }
        func cancel() {
            callback()
        }
    }

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
