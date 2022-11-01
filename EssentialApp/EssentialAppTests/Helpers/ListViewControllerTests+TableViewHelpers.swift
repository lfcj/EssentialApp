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

    public override func loadViewIfNeeded() {
        super.loadViewIfNeeded()

        // To prevent the table view from rendering eagerly, we can set the tableView to a very small size so it cannot render anything until the methods to render are called.
        self.tableView.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
    }

    func simulateUserInitiatedReload() {
        refreshControl?.simulatePullToRefresh()
    }

    func numberOfRows(in section: Int) -> Int {
        tableView.numberOfSections > section ? tableView.numberOfRows(inSection: section) : 0
    }

    func cell(row: Int, section: Int) -> UITableViewCell? {
        guard numberOfRows(in: section) > row else {
            return nil
        }

        let dataSource = tableView.dataSource
        return dataSource?.tableView(tableView, cellForRowAt: IndexPath(row: row, section: section))
    }

}

// MARK: - Feed UI Helpers

extension ListViewController {

    private var feedImagesSection: Int { 0 }
    private var feedLoadMoreSection: Int { 1 }

    var loadMoreFeedErrorMessage: String? {
        loadMoreFeedCell()?.message
    }
    
    var isShowingLoadMoreFeedIndicator: Bool {
        loadMoreFeedCell()?.isLoading == true
    }

    var canLoadMoreFeed: Bool {
        loadMoreFeedCell() != nil
    }

    func numberOfRenderedFeedImageViews() -> Int {
        numberOfRows(in: feedImagesSection)
    }

    @discardableResult
    func simulateFeedImageViewVisible(at row: Int) -> FeedImageCell? {
        feedImageView(at: row) as? FeedImageCell
    }

    func simulateLoadMoreFeedAction() {
        guard let view = loadMoreFeedCell() else {
            return
        }

        let delegate = tableView.delegate
        let index = IndexPath(row: 0, section: feedLoadMoreSection)
        delegate?.tableView?(tableView, willDisplay: view, forRowAt: index)
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

    func simulateTapOnFeedImage(at row: Int) {
        let delegate = tableView.delegate
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didSelectRowAt: indexPath)
    }

    func feedImageView(at row: Int) -> UITableViewCell? {
        cell(row: row, section: feedImagesSection)
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

    func simulateTapOnLoadMoreFeedError() {
        let delegate = tableView.delegate
        let index = IndexPath(row: 0, section: feedLoadMoreSection)
        delegate?.tableView?(tableView, didSelectRowAt: index)
    }

    private func loadMoreFeedCell() -> LoadMoreCell? {
        cell(row: 0, section: feedLoadMoreSection) as? LoadMoreCell
    }

}

// MARK: - Comments UI Helpers

extension ListViewController {

    var commentsSection: Int { 0 }

    func numberOfRenderedComments() -> Int {
        tableView.numberOfSections == 0 ? 0 : tableView.numberOfRows(inSection: commentsSection)
    }

    func commentMessage(at row: Int) -> String? {
        let view = imageCommentView(at: row) as? ImageCommentCell
        return view?.messageLabel.text
    }

    func imageCommentView(at row: Int) -> UITableViewCell? {
        cell(row: row, section: commentsSection)
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

var feedTitle: String { FeedPresenter.title }
var commentsTitle: String { ImageCommentsPresenter.title }
var loadError: String { LoadResourcePresenter<Any, DummyView>.loadError }
private class DummyView: ResourceView {
    func display(_ viewModel: Any) {}
}

