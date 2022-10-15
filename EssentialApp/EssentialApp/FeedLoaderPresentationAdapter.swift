import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

final class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    var presenter: LoadResourcePresenter<[FeedImage], FeedViewAdapter>?
    private let feedLoader: () -> LocalFeedLoader.Publisher
    private var cancellable: Cancellable?
    init(feedLoader: @escaping () -> LocalFeedLoader.Publisher) {
        self.feedLoader = feedLoader
    }

    func didRequestFeedRefresh() {
        presenter?.didStartLoading()
        cancellable = feedLoader()
            .dispatchOnMainQueue()
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.presenter?.didFinishLoading(with: error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] feed in
                    self?.presenter?.didFinishLoading(with: feed)
                }
         )
    }
}
