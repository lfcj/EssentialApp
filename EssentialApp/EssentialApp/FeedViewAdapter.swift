import EssentialFeed
import EssentialFeediOS
import Foundation
import UIKit

final class FeedViewAdapter: ResourceView {
    private weak var controller: FeedViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher

    private typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>

    init(controller: FeedViewController, loader: @escaping (URL) -> FeedImageDataLoader.Publisher) {
        self.controller = controller
        self.loader = loader
    }

    func display(_ viewModel: FeedViewModel) {
        controller?.display(
            viewModel.feed.map { [loader] model in
                let adapter = ImageDataPresentationAdapter(loader: { loader(model.url) })
                let view = FeedImageCellController(viewModel: FeedImagePresenter.map(model), delegate: adapter)
                adapter.presenter = LoadResourcePresenter(
                    mapper: UIImage.tryMake,
                    resourceView: WeakRefVirtualProxy(view),
                    loadingView: WeakRefVirtualProxy(view),
                    errorView: WeakRefVirtualProxy(view)
                )
                return view
            }
        )
    }

}

extension UIImage {
    static func tryMake(_ data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw InvalidImageData()
        }
        return image
    }
}
struct InvalidImageData: Error {}
