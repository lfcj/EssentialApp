import EssentialFeed
import EssentialFeediOS
import Foundation
import UIKit

final class FeedViewAdapter: ResourceView {
    typealias FeedImageSelectionHandler = (FeedImage) -> Void

    private weak var controller: ListViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    private let selectionHandler: FeedImageSelectionHandler

    private typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>

    init(
        controller: ListViewController,
        loader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selectionHandler: @escaping FeedImageSelectionHandler
    ) {
        self.controller = controller
        self.loader = loader
        self.selectionHandler = selectionHandler
    }

    func display(_ viewModel: Paginated<FeedImage>) {
        controller?.display(
            viewModel.items.map { [loader] model in
                let adapter = ImageDataPresentationAdapter(loader: { loader(model.url) })
                let view = FeedImageCellController(
                    viewModel: FeedImagePresenter.map(model),
                    delegate: adapter,
                    selectionHandler: { [selectionHandler] in
                        selectionHandler(model)
                    }
                )
                adapter.presenter = LoadResourcePresenter(
                    mapper: UIImage.tryMake,
                    resourceView: WeakRefVirtualProxy(view),
                    loadingView: WeakRefVirtualProxy(view),
                    errorView: WeakRefVirtualProxy(view)
                )
                return CellController(id: model, view)
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
