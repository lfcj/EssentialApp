import EssentialFeed
import EssentialFeediOS
import UIKit

// MARK: - Shared UI Helpers

extension ListViewController {

    var errorMessage: String? {
        errorView.message
    }

    var isShowingLoadingIndicator: Bool {
        refreshControl?.isRefreshing == true
    }

    var loadError: String { LoadResourcePresenter<Any, DummyView>.loadError }

    public override func loadViewIfNeeded() {
        super.loadViewIfNeeded()

        // To prevent the table view from rendering eagerly, we can set the tableView to a very small size so it cannot render anything until the methods to render are called.
        self.tableView.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
    }

    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }

}

// MARK: - Feed UI Helpers

extension ListViewController {

    var feedTitle: String { FeedPresenter.title }

    var feedImagesSection: Int { 0 }

    func numberOfRenderedFeedImageViews() -> Int {
        tableView.numberOfSections == 0 ? 0 : tableView.numberOfRows(inSection: feedImagesSection)
    }

    @discardableResult
    func simulateFeedImageViewVisible(at row: Int) -> FeedImageCell? {
        feedImageView(at: row) as? FeedImageCell
    }

    func renderedFeedImageData(at index: Int) -> Data? {
        simulateFeedImageViewVisible(at: index)?.renderedImage
    }

    @discardableResult
    func simulateFeedImageNotVisible(at row: Int) -> FeedImageCell? {
        let view = simulateFeedImageViewVisible(at: row)

        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)

        return view
    }

    func feedImageView(at row: Int) -> UITableViewCell? {
        guard numberOfRenderedFeedImageViews() > row else {
            return nil
        }
        let dataSource = tableView.dataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        return dataSource?.tableView(tableView, cellForRowAt: index)
    }

    func simulateFeedImageViewNearlyVisible(at row: Int = 0) {
        let dataSource = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        dataSource?.tableView(tableView, prefetchRowsAt: [index])
    }

    func simulateFeedImageViewNotNearlyVisible(at row: Int = 0) {
        simulateFeedImageViewVisible(at: row)

        let dataSource = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        dataSource?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
    }

}

// MARK: - Comments UI Helpers

extension ListViewController {

    var commentsTitle: String { ImageCommentsPresenter.title }

    var commentsSection: Int { 0 }

    func numberOfRenderedComments() -> Int {
        tableView.numberOfSections == 0 ? 0 : tableView.numberOfRows(inSection: feedImagesSection)
    }

    func imageCommentView(at row: Int) -> UITableViewCell? {
        guard numberOfRenderedComments() > row else {
            return nil
        }
        let dataSource = tableView.dataSource
        let index = IndexPath(row: row, section: commentsSection)
        return dataSource?.tableView(tableView, cellForRowAt: index)
    }

}

private extension UIRefreshControl {

    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }

}

private class DummyView: ResourceView {
    func display(_ viewModel: Any) {}
}

