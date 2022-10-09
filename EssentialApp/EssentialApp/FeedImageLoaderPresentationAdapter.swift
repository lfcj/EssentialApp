import Combine
import EssentialFeed
import EssentialFeediOS
import Foundation
import UIKit

final class FeedImageLoaderPresentationAdapter: FeedImageCellControllerDelegate {
    var presenter: FeedImagePresenter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>?
    private let feedImageLoader: (URL) -> FeedImageDataLoader.Publisher
    private let model: FeedImage

    private var cancellable: Cancellable?

    init(feedImageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher, model: FeedImage) {
        self.feedImageLoader = feedImageLoader
        self.model = model
    }

    func didRequestImageData() {
        presenter?.didStartLoadingImage(for: model)

        let model = self.model

        cancellable = feedImageLoader(model.url)
            .dispatchOnMainQueue()
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        self.presenter?.didFinishLoadingImageData(with: error, model: model)
                    }
                },
                receiveValue: { imageData in
                    self.presenter?.didFinishLoadingImageData(imageData, with: model)
                }
            )
    }

    func didRequestCancellingImageDataLoad() {
        cancellable?.cancel()
        cancellable = nil
    }
}
