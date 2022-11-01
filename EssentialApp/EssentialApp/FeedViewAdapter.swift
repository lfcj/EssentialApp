import EssentialFeed
import EssentialFeediOS
import Foundation
import UIKit

final class FeedViewAdapter: ResourceView {
    typealias FeedImageSelectionHandler = (FeedImage) -> Void

    private weak var controller: ListViewController?
    private let loader: (URL) -> FeedImageDataLoader.Publisher
    private let selectionHandler: FeedImageSelectionHandler
    private let currentFeed: [FeedImage: CellController]

    private typealias ImageDataPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>
    private typealias LoadMorePresentationAdapter = LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>

    init(
        currentFeed: [FeedImage: CellController] = [:],
        controller: ListViewController,
        loader: @escaping (URL) -> FeedImageDataLoader.Publisher,
        selectionHandler: @escaping FeedImageSelectionHandler
    ) {
        self.currentFeed = currentFeed
        self.controller = controller
        self.loader = loader
        self.selectionHandler = selectionHandler
    }

    func display(_ viewModel: Paginated<FeedImage>) {
        guard let controller = controller else {
            return
        }

        var currentFeed = self.currentFeed

        let feed = viewModel.items.map { [loader] model in
            if let controller = currentFeed[model] {
                return controller
            }

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
            let controller = CellController(id: model, view)
            currentFeed[model] = controller
            return controller
        }
        
        guard let loadMorePublisher = viewModel.loadMorePublisher else {
            controller.display(feed)
            return
        }

        let loadMoreAdapter = LoadMorePresentationAdapter(loader: loadMorePublisher)
        let loadMore = LoadMoreCellController(loadMoreHandler: loadMoreAdapter.loadResource)

        loadMoreAdapter.presenter = LoadResourcePresenter(
            resourceView: FeedViewAdapter(
                currentFeed: currentFeed,
                controller: controller,
                loader: loader,
                selectionHandler: selectionHandler
            ),
            loadingView: WeakRefVirtualProxy(loadMore),
            errorView: WeakRefVirtualProxy(loadMore)
        )
        let loadMoreSection = [CellController(id: UUID(), loadMore)]

        controller.display(feed, loadMoreSection)
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
