import EssentialFeed
import EssentialFeediOS
import Foundation
import UIKit

final class FeedViewAdapter: ResourceView {
    private weak var controller: FeedViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher

    init(controller: FeedViewController, loader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.loader = loader
    }

    func display(_ viewModel: FeedViewModel) {
        controller?.display(
            viewModel.feed.map { model in
                let imagePresentationAdapter = FeedImageLoaderPresentationAdapter(feedImageLoader: loader, model: model)
                let feedCellController = FeedImageCellController(delegate: imagePresentationAdapter)
                imagePresentationAdapter.presenter = FeedImagePresenter(
                    feedImageView: WeakRefVirtualProxy(feedCellController),
                    imageTransformer: UIImage.init
                )
                return feedCellController
            }
        )
    }
}
