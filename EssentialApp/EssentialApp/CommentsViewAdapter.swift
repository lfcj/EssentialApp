import EssentialFeed
import EssentialFeediOS
import Foundation
import UIKit

final class CommentsViewAdapter: ResourceView {
    private weak var controller: ListViewController?

    private typealias CommentsPresentationAdapter = LoadResourcePresentationAdapter<Data, WeakRefVirtualProxy<FeedImageCellController>>

    init(controller: ListViewController) {
        self.controller = controller
    }

    func display(_ viewModel: ImageCommentsViewModel) {
        controller?.display(
            viewModel.comments.map { model in
                CellController(id: model, ImageCommentCellController(model: model))
            }
        )
    }

}
