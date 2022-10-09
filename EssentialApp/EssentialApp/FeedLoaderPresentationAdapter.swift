import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

final class FeedLoaderPresentationAdapter: FeedViewControllerDelegate {
    var presenter: FeedPresenter?
    private let feedLoader: () -> FeedLoader.Publisher
    private var cancellable: Cancellable?
    init(feedLoader: @escaping () -> FeedLoader.Publisher) {
        self.feedLoader = feedLoader
    }

    func didRequestFeedRefresh() {
        presenter?.didStartLoadingFeed()
        cancellable = feedLoader()
            .dispatchOnMainQueue()
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.presenter?.didFinishLoadingFeed(with: error)
                    case .finished:
                        break
                    }
                },
                receiveValue: { [weak self] feed in
                    self?.presenter?.didFinishLoadingFeed(with: feed)
                }
         )
    }
}
