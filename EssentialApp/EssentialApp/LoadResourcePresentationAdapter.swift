import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation

final class LoadResourcePresentationAdapter<Resource, View: ResourceView> {
    typealias Publisher = AnyPublisher<Resource,  Error>

    var presenter: LoadResourcePresenter<Resource, View>?

    private let loader: () -> Publisher
    private var cancellable: Cancellable?
    private var isLoading: Bool = false

    init(loader: @escaping () -> Publisher) {
        self.loader = loader
    }

    func loadResource() {
        guard !isLoading else {
            return
        }

        isLoading = true
        presenter?.didStartLoading()
        cancellable = loader()
            .dispatchOnMainQueue()
            .handleEvents(
                receiveCancel: { [weak self] in
                    self?.isLoading = false
                }
            )
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.presenter?.didFinishLoading(with: error)
                    case .finished:
                        break
                    }
                    self?.isLoading = false
                },
                receiveValue: { [weak self] resource in
                    self?.presenter?.didFinishLoading(with: resource)
                }
         )
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
