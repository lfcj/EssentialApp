import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

final class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    typealias Publisher = AnyPublisher<Resource,  Error>

    var presenter: LoadResourcePresenter<Resource, View>?

    private let loader: () -> Publisher
    private var cancellable: Cancellable?

    init(loader: @escaping () -> Publisher) {
        self.loader = loader
    }

    func loadResource() {
        presenter?.didStartLoading()
        cancellable = loader()
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
                receiveValue: { [weak self] resource in
                    self?.presenter?.didFinishLoading(with: resource)
                }
         )
    }
}

// MARK: - FeedViewControllerDelegate

extension LoadResourcePresentationAdapter: FeedViewControllerDelegate {

    func didRequestFeedRefresh() {
        loadResource()
    }

}

// MARK: - FeedImageCellControllerDelegate

extension LoadResourcePresentationAdapter: FeedImageCellControllerDelegate {

    func didRequestImageData() {
        loadResource()
    }

    func didRequestCancellingImageDataLoad() {
        cancellable?.cancel()
        cancellable = nil
    }

}
