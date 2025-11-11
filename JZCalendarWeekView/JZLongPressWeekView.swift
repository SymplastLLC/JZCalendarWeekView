//
//  JZLongPressWeekView.swift
//  JZCalendarWeekView
//
//  Created by Jeff Zhang on 26/4/18.
//  Copyright © 2018 Jeff Zhang. All rights reserved.
//

#if os(iOS)

import UIKit

public protocol JZLongPressViewDelegate: AnyObject {

    /// When addNew long press gesture ends, this function will be called.
    /// You should handle what should be done after creating a new event.
    /// - Parameters:
    ///   - weekView: current long pressed JZLongPressWeekView
    ///   - startDate: the startDate of the event when gesture ends
    func weekView(
        _ weekView: JZLongPressWeekView,
        didEndAddNewLongPressAt startDate: Date,
        in column: Int,
        insideParkingLotArea: Bool
    )

    /// When Move long press gesture ends, this function will be called.
    /// You should handle what should be done after editing (moving) a existed event.
    /// - Parameters:
    ///   - weekView: current long pressed JZLongPressWeekView
    ///   - editingEvent: the moving (existed, editing) event
    ///   - startDate: the startDate of the event when gesture ends
    func weekView(
        _ weekView: JZLongPressWeekView,
        editingEvent: JZBaseEvent,
        didEndMoveLongPressAt startDate: Date,
        in column: Int,
        insideParkingLotArea: Bool
    )

    /// Sometimes the longPress will be cancelled because some curtain reason.
    /// Normally this function no need to be implemented.
    /// - Parameters:
    ///   - weekView: current long pressed JZLongPressWeekView
    ///   - longPressType: the long press type when gusture cancels
    ///   - startDate: the startDate of the event when gesture cancels
    func weekView(
        _ weekView: JZLongPressWeekView,
        longPressType: JZLongPressWeekView.LongPressType,
        didCancelLongPressAt startDate: Date?
    )
    
    func weekView(
        _ weekView: JZLongPressWeekView,
        didStartResizing event: JZBaseEvent
    )
    
    func weekView(
        _ weekView: JZLongPressWeekView,
        resizingEvent: JZBaseEvent,
        didEndResizingAt startDate: Date,
        endDate: Date
    )
}

public protocol JZLongPressViewDataSource: AnyObject {
    /// Implement this function to customise your own AddNew shortPressView
    /// - Parameters:
    ///   - weekView: current long pressed JZLongPressWeekView
    ///   - startDate: the startDate when initialise the shortPressView (if you want, you can get the section with startDate)
    /// - Returns: AddNew type of LongPressView (dragging with your finger when move this view)
    func weekView(
        _ weekView: JZLongPressWeekView,
        viewForAddNewLongPressAt startDate: Date
    ) -> UIView

    /// The default way to get move type shortPressView is create a snapshot for the selectedCell.
    /// Implement this function to customise your own Move shortPressView
    /// - Parameters:
    ///   - weekView: current long pressed JZLongPressWeekView
    ///   - movingCell: the exsited cell currently is moving
    ///   - startDate: the startDate when initialise the shortPressView
    /// - Returns: Move type of ShortPressView (dragging with your finger when move event)
    func weekView(
        _ weekView: JZLongPressWeekView,
        movingCell: UICollectionViewCell,
        viewForMoveLongPressAt startDate: Date
    ) -> UIView
    
    func weekView(
        _ weekView: JZLongPressWeekView,
        viewForResizing cell: UICollectionViewCell
    ) -> UIView
}

extension JZLongPressViewDelegate {
    // Keep them optional
    public func weekView(
        _ weekView: JZLongPressWeekView,
        longPressType: JZLongPressWeekView.LongPressType,
        didCancelLongPressAt startDate: Date?
    ) {}
    public func weekView(
        _ weekView: JZLongPressWeekView,
        didEndAddNewLongPressAt startDate: Date,
        in column: Int,
        insideParkingLotArea: Bool
    ) {}
    public func weekView(
        _ weekView: JZLongPressWeekView,
        editingEvent: JZBaseEvent,
        didEndMoveLongPressAt startDate: Date,
        in column: Int,
        insideParkingLotArea: Bool
    ) {}
    public func weekView(
        _ weekView: JZLongPressWeekView,
        didStartResizing event: JZBaseEvent
    ) {}
    public func weekView(
        _ weekView: JZLongPressWeekView,
        resizingEvent: JZBaseEvent,
        didEndResizingAt startDate: Date,
        endDate: Date
    ) {}
}

extension JZLongPressViewDataSource {
    // Default snapshot method
    public func weekView(
        _ weekView: JZLongPressWeekView,
        movingCell: UICollectionViewCell,
        viewForMoveLongPressAt startDate: Date
    ) -> UIView {
        createSnapshotView(for: movingCell)
    }

    public func weekView(
        _ weekView: JZLongPressWeekView,
        viewForResizing cell: UICollectionViewCell
    ) -> UIView {
        createSnapshotView(for: cell)
    }
    
    private func createSnapshotView(for cell: UICollectionViewCell) -> UIView {
        let cellSnapshot = cell.snapshotView(afterScreenUpdates: true)
        let viewSnapshot = UIView(frame: cell.frame)
        if let cellSnapshot {
            viewSnapshot.addSubview(cellSnapshot)
        }
        cellSnapshot?.setAnchorConstraintsFullSizeTo(view: viewSnapshot)
        return viewSnapshot
    }
}

open class JZLongPressWeekView: JZBaseWeekView {

    public enum LongPressType {
        /// when short press position is not on a existed event, this type will create a new event view allowing user to move
        case addNew
        /// when short press position is on a existed event, this type will allow user to move the existed event
        case move
        /// when long press position is on a existed event, this type will allow user to resize the existed event
        case resize
    }

    /// This structure is used to save editing information before reusing collectionViewCell (Type Move used only)
    private struct CurrentEditingInfo {
        /// The editing event when move type long press(used to be currentMovingCell, it is a reference of cell but item will be reused in CollectionView!!)
        var event: JZBaseEvent?
        /// The editing cell original size, get it from the long press status began
        var cellSize: CGSize = .zero
        var originalCellSize: CGSize = .zero
        /// Save current all changed opacity cell contentViews to change them back when end or cancel longPress, have to save them because of cell reusage
        var allOpacityContentViews = [UIView]()
    }
    /// When moving the longPress view, if it causes the collectionView scrolling
    private var isScrolling: Bool = false
    private var isShortPressing: Bool = false
    private var currentPressType: LongPressType = .move
    private var shortPressView: UIView?
    private var longPressView: UIView?
    private var upDotView: UIView?
    private var downDotView: UIView?
    private var parkingCornerView: UIView?
    private var currentEditingInfo = CurrentEditingInfo()
    private lazy var coverViewForResizing: UIView = {
        let coverView = UIView(frame: collectionView.bounds)
        coverView.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(endResizingModeTap))
        coverView.addGestureRecognizer(tap)
        return coverView
    }()
    /// Get this value when long press began and save the current relative X and Y value until it ended or cancelled
    private var pressPosition: (xToViewLeft: CGFloat, yToViewTop: CGFloat)?

    public weak var longPressDelegate: JZLongPressViewDelegate?
    public weak var longPressDataSource: JZLongPressViewDataSource?

    // You can modify these properties below
    public var longPressTypes = [LongPressType]()
    /// It is used to identify the minimum time interval(Minute) when dragging the event view (minimum value is 1, maximum is 60)
    public var moveTimeMinInterval: Int = 15
    /// For an addNew event, the event duration mins determine the add new event duration and height
    public var addNewDurationMins: Int = 120
    /// Magic value to calculate date correctly
    public var magicDragYOffset: CGFloat = 0
    /// Minimum height for resized events as a fraction of hour height (default: 0.5 = 30 mins)
    public var minResizeHeightFraction: CGFloat = 0.3
    /// Parking lot area to handle drag & drop inside
    public var parkingLotArea: CGRect?
    public var parkingLotIcon: UIImage? = UIImage(systemName: "parkingsign")
    /// The longPressTimeLabel along with shortPressView, can be customised
    public var pressTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
        label.minimumScaleFactor = 0.8
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    /// The moving cell contentView layer opacity (when you move the existing cell, the previous cell will be translucent)
    /// If your cell background alpha below this value, you should decrease this value as well
    public var movingCellOpacity: Float = 0.6
    
    /// The resizing cell contentView layer opacity (when you move the existing cell, the previous cell will be translucent)
    /// If your cell background alpha below this value, you should decrease this value as well
    public var resizingCellOpacity: Float = 0.3
    
    /// The most top Y in the collectionView that you want longPress gesture enable.
    /// If you customise some decoration and supplementry views on top, **must** override this variable
    open var longPressTopMarginY: CGFloat { flowLayout.columnHeaderHeight + flowLayout.allDayHeaderHeight }
    /// The most bottom Y in the collectionView that you want longPress gesture enable.
    /// If you customise some decoration and supplementry views on bottom, **must** override this variable
    open var longPressBottomMarginY: CGFloat { frame.height }
    /// The most left X in the collectionView that you want longPress gesture enable.
    /// If you customise some decoration and supplementry views on left, **must** override this variable
    open var longPressLeftMarginX: CGFloat { flowLayout.rowHeaderWidth }
    /// The most right X in the collectionView that you want longPress gesture enable.
    /// If you customise some decoration and supplementry views on right, **must** override this variable
    open var longPressRightMarginX: CGFloat { frame.width }
    
    private var isResizingPressRecognized = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGestures()
    }

    private func setupGestures() {
        let shortPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleShortPress)
        )
        shortPress.delegate = self
        collectionView.addGestureRecognizer(shortPress)
        let longPress = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        longPress.minimumPressDuration = 1.5
        longPress.delegate = self
        collectionView.addGestureRecognizer(longPress)
    }

    /// Updating time label in shortPressView during dragging
    private func updateTimeLabel(time: Date, pointInSelfView: CGPoint) {
        updateTimeLabelText(time: time)
        updateTimeLabelPosition(pointInSelfView: pointInSelfView)
    }

    /// Update time label content, this method can be overridden
    open func updateTimeLabelText(time: Date) {
        pressTimeLabel.text = " \(time.getTimeIgnoreSecondsFormat()) "
    }

    /// Update the position for the time label
    private func updateTimeLabelPosition(pointInSelfView: CGPoint) {
        guard let pressPosition else { return }
        let isOutsideLeftMargin = pointInSelfView.x - pressPosition.xToViewLeft < longPressLeftMarginX
        pressTimeLabel.frame.origin.x = isOutsideLeftMargin ? currentEditingInfo.cellSize.width - pressTimeLabel.frame.width : 0

        guard let shortPressView else { return }
        let labelHeight = pressTimeLabel.frame.height
        let isBeyondTopMargin = pointInSelfView.y - pressPosition.yToViewTop - labelHeight < longPressTopMarginY
        let yPosition = isBeyondTopMargin ? shortPressView.frame.height : -labelHeight
        if pressTimeLabel.frame.origin.y != yPosition {
            pressTimeLabel.frame.origin.y = yPosition
        }
    }

    /// When dragging the shortPressView, the collectionView should scroll with the drag point.
    /// - The logic of vertical scroll is top scroll depending on **shortPressView top** to longPressTopMarginY, bottom scroll denpending on **finger point** to LongPressBottomMarginY.
    /// - The logic of horizontal scroll is left scroll depending on **finger point** to longPressLeftMarginY, bottom scroll denpending on **finger point** to LongPressRightMarginY.
    private func updateScroll(pointInSelfView: CGPoint) {
        if isScrolling { return }

        // vertical
        if let pressPosition, pointInSelfView.y - pressPosition.yToViewTop < longPressTopMarginY + 10 {
            isScrolling = true
            scrollingTo(direction: .up)
            return
        } else if pointInSelfView.y > longPressBottomMarginY - 40 {
            isScrolling = true
            scrollingTo(direction: .down)
            return
        }
        // horizontal
        if pointInSelfView.x < longPressLeftMarginX + 10 {
            isScrolling = true
            scrollingTo(direction: .right)
            return
        } else if pointInSelfView.x > longPressRightMarginX - 20 {
            isScrolling = true
            scrollingTo(direction: .left)
            return
        }
    }

    /*
     NOTICE: Existing issue: In some scenarios, longPress to edge cannot trigger collectionView scrolling
     Generally, it is because isScrolling set true previously but doesn't set false back, which cause cannot scroll next time because isScrolling is true
        1. In section scroll, when keep longPressing and scrolling, sometimes it will become unscrollable. (Should be caused by forceReload async, page scroll got enough time to async reload)
        2. In both scroll types, if you end longPress at the left or right edge when collectionView is scrolling, it might cause isScrolling cannot set back to false either.
     This issue exists before 0.7.0 (not caused by pagination redesign), will be fixed when async forceReload issue has been resolved
    */
    private func scrollingTo(direction: LongPressScrollDirection) {
        let currentOffset = collectionView.contentOffset
        let minOffsetY: CGFloat = 0, maxOffsetY = collectionView.contentSize.height - collectionView.bounds.height
        let defaultOffset: CGFloat = 50
        
        if direction == .up || direction == .down {
            let yOffset: CGFloat

            if direction == .up {
                yOffset = max(minOffsetY, currentOffset.y - defaultOffset)
            } else {
                yOffset = min(maxOffsetY, currentOffset.y + defaultOffset)
            }
            collectionView.setContentOffset(CGPoint(x: currentOffset.x, y: yOffset), animated: true)
            // scrollview didEndAnimation will not set isScrolling, should be set manually
            if yOffset == minOffsetY || yOffset == maxOffsetY {
                isScrolling = false
            }
        } else {
            var contentOffsetX: CGFloat
            switch scrollType {
            case .sectionScroll:
                let scrollSections: CGFloat = direction == .left ? -1 : 1
                contentOffsetX = currentOffset.x - flowLayout.sectionWidth! * scrollSections
            case .pageScroll:
                contentOffsetX = direction == .left ? contentViewWidth * 2 : 0
            }
            // Take the horizontal scrollable edges into account
            let contentOffsetXWithScrollableEdges = min(max(contentOffsetX, scrollableEdges.leftX ?? -1), scrollableEdges.rightX ?? CGFloat.greatestFiniteMagnitude)
            if contentOffsetXWithScrollableEdges == currentOffset.x {
                // scrollViewDidEndScrollingAnimation will not be called
                isScrolling = false
            } else {
                collectionView.setContentOffset(CGPoint(x: contentOffsetXWithScrollableEdges, y: currentOffset.y), animated: true)
            }
        }
    }

    /// Calculate the expected start date with timeMinInterval
    func getLongPressStartDate(date: Date, dateInSection: Date, timeMinInterval: Int) -> Date {
        let daysBetween = Date.daysBetween(start: dateInSection, end: date, ignoreHours: true)
        let startDate: Date

        if daysBetween == 1 {
            // Below the bottom set as the following day
            startDate = date.startOfDay
        } else if daysBetween == -1 {
            // Beyond the top set as the current day
            startDate = dateInSection.startOfDay
        } else {
            let currentMin = Calendar.current.component(.minute, from: date)
            // Choose previous time interval (currentMin/timeMinInterval = Int)
            let minValue = (currentMin/timeMinInterval) * timeMinInterval
            startDate = date.set(minute: minValue)
        }
        return startDate
    }
    
    private func createDotView(
        for parent: UIView,
        onUp: Bool
    ) -> UIView {
        let dotView = UIView(
            frame: CGRect(
                origin: CGPoint(
                    x: parent.frame.midX - 10,
                    y: onUp ? parent.frame.origin.y - 5 : (parent.bounds.height + parent.frame.origin.y) - 15
                ),
                size: CGSize(width: 20, height: 20)
            )
        )
        dotView.backgroundColor = UIColor.white
        dotView.layer.cornerRadius = 10
        dotView.layer.borderWidth = 2
        dotView.layer.borderColor = UIColor.systemBlue.cgColor
        return dotView
    }

    /// Initialise the long press duration view with longPressTimeLabel.
    open func initLongPressView(
        selectedCell: UICollectionViewCell?
    ) -> UIView? {
        guard let longPressDataSource, let selectedCell else { return nil }
        let snapshot = longPressDataSource.weekView(self, viewForResizing: selectedCell)
        snapshot.clipsToBounds = false
        snapshot.setDefaultShadow()
        return snapshot
    }
    
    /// Initialise the long press view with longPressTimeLabel.
    open func initShortPressView(
        selectedCell: UICollectionViewCell?,
        type: LongPressType,
        startDate: Date
    ) -> UIView? {
        guard let longPressDataSource else { return nil }
        
        // timeText width will change from 00:00 - 24:00, and for each time the length will be different
        // add 5 to ensure the max width
        let labelHeight: CGFloat = 20
        let textWidth = UILabel.getLabelWidth(labelHeight, font: pressTimeLabel.font, text: "23:59 PM")
        let timeLabelWidth: CGFloat
        
        let pressView: UIView
        switch type {
        case .move, .resize:
            guard let selectedCell else { return nil }
            pressView = longPressDataSource.weekView(
                self,
                movingCell: selectedCell,
                viewForMoveLongPressAt: startDate
            )
            timeLabelWidth = min(selectedCell.bounds.width, textWidth)
        case .addNew:
            pressView = longPressDataSource.weekView(self, viewForAddNewLongPressAt: startDate)
            timeLabelWidth = min(widthInColumn, textWidth)
        }
        pressView.clipsToBounds = false
        pressTimeLabel.frame = CGRect(x: 0, y: -labelHeight, width: timeLabelWidth, height: labelHeight)
        pressView.addSubview(pressTimeLabel)
        pressView.setDefaultShadow()
        return pressView
    }

    /// Overload for base class with left and right margin check for LongPress
    open func getDateForPointX(xCollectionView: CGFloat, xSelfView: CGFloat) -> Date {
        let date = getDateForPointX(xCollectionView)
        // when isScrolling equals true, means it will scroll to previous date
        if xSelfView < longPressLeftMarginX && isScrolling == false {
            // should add one date to put the view inside current page
            return date.add(component: .day, value: 1)
        } else if xSelfView > longPressRightMarginX && isScrolling == false {
            // normally this condition will not enter
            // should substract one date to put the view inside current page
            return date.add(component: .day, value: -1)
        } else {
            return date
        }
    }

    /// Overload for base class with modified date for X
    open func getDateForPoint(pointCollectionView: CGPoint, pointSelfView: CGPoint) -> Date {
        let yearMonthDay = getDateForPointX(xCollectionView: pointCollectionView.x, xSelfView: pointSelfView.x)
        let hourMinute = getDateForPointY(pointCollectionView.y)
        return yearMonthDay.set(hour: hourMinute.0, minute: hourMinute.1, second: 0)
    }

    // Only being called when setContentOffset ends animition by scrollingTo method
    // scrollViewDidEndScrollingAnimation won't be called in JZBaseWeekView, then should load page here
    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // vertical scroll should not load page, handled in loadPage method
        loadPage()
        isScrolling = false
    }

    // Following three functions are used to Handle collectionView items reusued

    /// when the previous cell is reused, have to find current one
    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard isShortPressing == true
                && (currentPressType == .move
                    || currentPressType == .resize) else { return }

        let cellContentView = cell.contentView

        if isOriginalEditingCell(cell) {
            cellContentView.layer.opacity = movingCellOpacity
            if !currentEditingInfo.allOpacityContentViews.contains(cellContentView) {
                currentEditingInfo.allOpacityContentViews.append(cellContentView)
            }
        } else {
            cellContentView.layer.opacity = 1
            if let index = currentEditingInfo.allOpacityContentViews.firstIndex(where: {$0 == cellContentView}) {
                currentEditingInfo.allOpacityContentViews.remove(at: index)
            }
        }
    }

    /// Use the event id to check the cell item is the original cell
    private func isOriginalEditingCell(_ cell: UICollectionViewCell) -> Bool {
        if let cell = cell as? JZLongPressEventCell, let editId = currentEditingInfo.event?.id {
            cell.event.id == editId
        } else {
            false
        }
    }

     /*** Because of reusability, we set some cell contentViews to translucent, then when those views are reused, if you don't scroll back
     the willDisplayCell will not be called, then those reused contentViews will be translucent and cannot be found */
    /// Get the current moving cells to change to alpha (crossing days will have more than one cells)
    private func getCurrentEditingCells() -> [UICollectionViewCell] {
        var editingCells = [UICollectionViewCell]()
        for cell in collectionView.visibleCells {
            if isOriginalEditingCell(cell) {
                editingCells.append(cell)
            }
        }
        return editingCells
    }
}

// Long press Gesture methods
extension JZLongPressWeekView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    // Override this function to customise gesture begin conditions
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let pointInSelfView = gestureRecognizer.location(in: self)
        let pointInCollectionView = gestureRecognizer.location(in: collectionView)

        if gestureRecognizer.state == .possible {
            // Long press on ouside margin area should not begin
            let isOutsideBeginArea = pointInSelfView.x < longPressLeftMarginX || pointInSelfView.x > longPressRightMarginX ||
                                     pointInSelfView.y < longPressTopMarginY || pointInSelfView.y > longPressBottomMarginY
            if isOutsideBeginArea { return false  }
        }

        let hasItemAtPoint = collectionView.indexPathForItem(at: pointInCollectionView) != nil
        // Short press should not begin if there are events at short press position and move not required
        if hasItemAtPoint && !longPressTypes.contains(.move) {
            return false
        }

        // Short press should not begin if no events at short press position and addNew not required
        if !hasItemAtPoint && !longPressTypes.contains(.addNew) {
            return false
        }
        // Long press should not begin if no events at long press position and addNew not required
        if !hasItemAtPoint && !longPressTypes.contains(.resize) {
            return false
        }
        return true
    }
    
    private func resetDataForShortPress() {
        pressTimeLabel.removeFromSuperview()
        isShortPressing = false
        if !isResizingPressRecognized {
            pressPosition = nil
        }

        if currentPressType == .move {
            currentEditingInfo.allOpacityContentViews.forEach { $0.layer.opacity = 1 }
            currentEditingInfo.allOpacityContentViews.removeAll()
        }
    }
    
    private func resetDataForLongPress() {
        isResizingPressRecognized = false
        currentPressType = .move
        currentEditingInfo.allOpacityContentViews.forEach { $0.layer.opacity = 1 }
        currentEditingInfo.allOpacityContentViews.removeAll()
        coverViewForResizing.removeFromSuperview()
        collectionView.isScrollEnabled = true
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            self.longPressView?.alpha = 0
            self.upDotView?.alpha = 0
            self.downDotView?.alpha = 0
        }, completion: { _ in
            self.longPressView?.removeFromSuperview()
            self.upDotView?.removeFromSuperview()
            self.downDotView?.removeFromSuperview()
            self.upDotView = nil
            self.downDotView = nil
        })
    }
    
    @objc private func handleUpDotPanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let longPressView else { return }

        let state = gesture.state
        let translationY = gesture.translation(in: longPressView.superview).y
        let pointInSelfView = gesture.location(in: self)
        let labelHeight: CGFloat = 20

        switch state {
        case .began:
            let textWidth = UILabel.getLabelWidth(labelHeight, font: pressTimeLabel.font, text: "23:59 PM")
            let timeLabelWidth = min(longPressView.bounds.width, textWidth)
            pressTimeLabel.frame = CGRect(
                x: longPressView.frame.origin.x,
                y: longPressView.frame.origin.y - labelHeight,
                width: timeLabelWidth,
                height: labelHeight
            )
            collectionView.addSubview(pressTimeLabel)
        case .changed:
            // Calculate new top position using translation (smoother than direct positioning)
            let originalTopY = longPressView.frame.origin.y
            var newTopY = originalTopY + translationY

            // Apply boundary constraints with smooth resistance
            let minTopY = collectionView.bounds.minY
            if newTopY < minTopY {
                // Smooth resistance near boundary
                let resistance = (minTopY - newTopY) * 0.3
                newTopY = minTopY - resistance
            }

            let currentBottomY = longPressView.frame.maxY

            // Calculate new height with minimum constraint
            let minHeight = max(flowLayout.hourHeightForZoomLevel * minResizeHeightFraction, 20.0) // Minimum 0.5 hour or 20pt
            let newHeight = max(currentBottomY - newTopY, minHeight)

            guard newHeight > minHeight else {
                // Reset translation for next iteration (smooth continuous dragging)
                gesture.setTranslation(.zero, in: longPressView.superview)
                return
            }
            // Only update if there's a meaningful change to prevent jitter
            if abs(translationY) > 1.0 {
                // Update frame smoothly
                longPressView.frame.origin.y = newTopY
                longPressView.frame.size.height = newHeight
                upDotView?.frame.origin.y = newTopY - 5

                // Update cellSize for consistency
                currentEditingInfo.cellSize.height = newHeight
                let resizeDate = getDateForPoint(
                    CGPoint(
                        x: longPressView.frame.origin.x,
                        y: longPressView.frame.origin.y - magicDragYOffset
                    )
                )
                updateTimeLabelText(time: resizeDate)
                pressTimeLabel.frame.origin = CGPoint(
                    x: longPressView.frame.origin.x,
                    y: (newTopY - labelHeight) + magicDragYOffset
                )
                updateScroll(pointInSelfView: pointInSelfView)
                // Reset translation for next iteration (smooth continuous dragging)
                gesture.setTranslation(.zero, in: longPressView.superview)
            }
        case .ended, .cancelled:
            // Gesture ended, finalize resize - could add snap-to-grid or inertia here if needed
            gesture.setTranslation(.zero, in: longPressView.superview)
            pressTimeLabel.removeFromSuperview()
        default:
            break
        }
    }
    
    @objc private func handleDownDotPanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let longPressView else { return }

        let state = gesture.state
        let translationY = gesture.translation(in: longPressView.superview).y
        let pointInSelfView = gesture.location(in: self)
        
        switch state {
        case .began:
            let labelHeight: CGFloat = 20
            let textWidth = UILabel.getLabelWidth(labelHeight, font: pressTimeLabel.font, text: "23:59 PM")
            let timeLabelWidth = min(longPressView.bounds.width, textWidth)
            pressTimeLabel.frame = CGRect(
                x: longPressView.frame.origin.x,
                y: longPressView.frame.origin.y + longPressView.frame.height,
                width: timeLabelWidth,
                height: labelHeight
            )
            collectionView.addSubview(pressTimeLabel)
        case .changed:
            // Calculate new bottom position using translation (smoother than direct positioning)
            let originalBottomY = longPressView.frame.maxY
            var newBottomY = originalBottomY + translationY
            
            // Apply boundary constraints with smooth resistance
            let maxBottomY = collectionView.bounds.maxY
            if newBottomY > maxBottomY {
                // Smooth resistance near boundary
                let resistance = (newBottomY - maxBottomY) * 0.3
                newBottomY = maxBottomY + resistance
            }
            
            let currentTopY = longPressView.frame.minY
            
            // Calculate new height with minimum constraint
            let minHeight = max(flowLayout.hourHeightForZoomLevel * minResizeHeightFraction, 20.0) // Minimum 0.5 hour or 20pt
            let newHeight = max(newBottomY - currentTopY, minHeight)

            guard newHeight > minHeight else {
                // Reset translation for next iteration (smooth continuous dragging)
                gesture.setTranslation(.zero, in: longPressView.superview)
                return
            }
            // Only update if there's a meaningful change to prevent jitter
            if abs(translationY) > 1.0 {
                // Update frame smoothly (only height changes, origin stays the same)
                longPressView.frame.size.height = newHeight
                downDotView?.frame.origin.y = newBottomY - 15

                // Update cellSize for consistency
                currentEditingInfo.cellSize.height = newHeight
                let updatedMaxY = longPressView.frame.origin.y + newHeight
                let resizeDate = getDateForPoint(
                    CGPoint(
                        x: longPressView.frame.origin.x,
                        y: updatedMaxY - magicDragYOffset
                    )
                )
                updateTimeLabelText(time: resizeDate)
                pressTimeLabel.frame.origin = CGPoint(
                    x: longPressView.frame.origin.x,
                    y: updatedMaxY
                )
                updateScroll(pointInSelfView: pointInSelfView)
                // Reset translation for next iteration (smooth continuous dragging)
                gesture.setTranslation(.zero, in: longPressView.superview)
            }
        case .ended, .cancelled:
            // Gesture ended, finalize resize - could add snap-to-grid or inertia here if needed
            gesture.setTranslation(.zero, in: longPressView.superview)
            pressTimeLabel.removeFromSuperview()
        default:
            break
        }
    }
    
    @objc private func endResizingModeTap(_ gesture: UIGestureRecognizer) {
        if let longPressView,
           let event = currentEditingInfo.event,
           longPressView.frame.height != currentEditingInfo.originalCellSize.height {
            let startDate = getDateForPoint(
                CGPoint(
                    x: longPressView.frame.origin.x,
                    y: longPressView.frame.origin.y - magicDragYOffset
                )
            )
            let endDate = getDateForPoint(
                CGPoint(
                    x: longPressView.frame.origin.x,
                    y: longPressView.frame.origin.y + longPressView.frame.height - magicDragYOffset
                )
            )
            longPressDelegate?.weekView(
                self,
                resizingEvent: event,
                didEndResizingAt: startDate,
                endDate: endDate
            )
            print(startDate, endDate)
        }
        resetResizingMode()
    }
    
    public func resetResizingMode() {
        resetDataForLongPress()
        currentEditingInfo.event = nil
        currentEditingInfo.cellSize = .zero
        currentEditingInfo.originalCellSize = .zero
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let state = gesture.state
        
        switch state {
        case .began:
            let pointInCollectionView = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: pointInCollectionView),
               let currentCell = collectionView.cellForItem(at: indexPath),
               let event = (currentCell as? JZLongPressEventCell)?.event,
               event.isAvailableForResizing
            {
                isResizingPressRecognized = true
                resetDataForShortPress()
                shortPressView?.removeFromSuperview()
                
                collectionView.addSubview(coverViewForResizing)
                collectionView.isScrollEnabled = false
                
                longPressView = initLongPressView(selectedCell: currentCell)
                longPressView?.frame = currentCell.frame
                longPressView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                if let longPressView {
                    collectionView.addSubview(longPressView)
                }
                
                let panDownDotGesture = UIPanGestureRecognizer(
                    target: self,
                    action: #selector(handleDownDotPanGesture)
                )
                let panUpDotGesture = UIPanGestureRecognizer(
                    target: self,
                    action: #selector(handleUpDotPanGesture)
                )
                let upDot = createDotView(for: currentCell, onUp: true)
                let downDot = createDotView(for: currentCell, onUp: false)
                upDot.clipsToBounds = false
                upDot.setDefaultShadow()
                downDot.clipsToBounds = false
                downDot.setDefaultShadow()
                collectionView.addSubview(upDot)
                collectionView.addSubview(downDot)
                upDot.addGestureRecognizer(panUpDotGesture)
                downDot.addGestureRecognizer(panDownDotGesture)
                // Store references to the dots for repositioning during resize
                upDotView = upDot
                downDotView = downDot
                
                currentEditingInfo.cellSize = currentCell.frame.size
                currentEditingInfo.originalCellSize = currentCell.frame.size
                currentEditingInfo.event = event
                getCurrentEditingCells().forEach {
                    $0.contentView.layer.opacity = resizingCellOpacity
                    currentEditingInfo.allOpacityContentViews.append($0.contentView)
                }
                
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 5,
                    options: .curveEaseOut,
                    animations: { [weak self] in
                        self?.longPressView?.transform = CGAffineTransform.identity
                    }
                )
                currentPressType = .resize
                longPressDelegate?.weekView(self, didStartResizing: event)
            }
        case .cancelled where isResizingPressRecognized:
            longPressDelegate?.weekView(
                self,
                longPressType: currentPressType,
                didCancelLongPressAt: nil
            )
            resetDataForLongPress()
        default:
            break
        }
    }
    
    /// The basic shortPressView position logic is moving with your finger's original position.
    /// - The Move type shortPressView will keep the relative position during this longPress, that's how Apple Calendar did.
    /// - The AddNew type shortPressView will be created centrally at your finger press position
    @objc private func handleShortPress(_ gesture: UILongPressGestureRecognizer) {
        if isResizingPressRecognized {
            resetDataForShortPress()
            shortPressView?.removeFromSuperview()
            return
        }
        
        let pointInSelfView = gesture.location(in: self)
        /// Used for get startDate of shortPressView
        let pointInCollectionView = gesture.location(in: collectionView)

        let state = gesture.state
        var currentMovingCell: UICollectionViewCell?
        
        if isShortPressing == false {
            if let indexPath = collectionView.indexPathForItem(at: pointInCollectionView) {
                // Can add some conditions for allowing only few types of cells can be moved
                currentPressType = .move
                currentMovingCell = collectionView.cellForItem(at: indexPath)
            } else {
                currentPressType = .addNew
            }
            isShortPressing = true
        }
        
        // The startDate of the shortPressView (the date of top Y in shortPressView)
        var shortPressViewStartDate: Date?
        var isAvailableForMoving: Bool {
            guard currentPressType == .move else { return true }
            let event = currentEditingInfo.event ?? (currentMovingCell as? JZLongPressEventCell)?.event
            return event?.isAvailableForMoving ?? false
        }

        // pressPosition is nil only when state equals began
        if pressPosition != nil {
            shortPressViewStartDate = getShortPressViewStartDate(
                pointInCollectionView: pointInCollectionView,
                pointInSelfView: pointInSelfView
            )
        }
        
        switch state {
        case .began:
            switch currentPressType {
            case .addNew:
                currentEditingInfo.cellSize = CGSize(
                    width: widthInColumn,
                    height: flowLayout.hourHeightForZoomLevel * CGFloat(addNewDurationMins)/60
                )
                pressPosition = (currentEditingInfo.cellSize.width/2, currentEditingInfo.cellSize.height/2)
            case .move where isAvailableForMoving:
                if let currentMovingCell {
                    currentEditingInfo.cellSize = currentMovingCell.frame.size
                    pressPosition = (
                        pointInCollectionView.x - currentMovingCell.frame.origin.x,
                        pointInCollectionView.y - currentMovingCell.frame.origin.y
                    )
                }
            case .move:
                return
            case .resize:
                break
            }
            let longPressDate = getShortPressViewStartDate(
                pointInCollectionView: pointInCollectionView,
                pointInSelfView: pointInSelfView
            )
            shortPressViewStartDate = longPressDate
            shortPressView = initShortPressView(
                selectedCell: currentMovingCell,
                type: currentPressType,
                startDate: longPressDate
            )
            shortPressView?.frame.size = currentEditingInfo.cellSize
            shortPressView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            if let shortPressView {
                addSubview(shortPressView)
            }

            if let pressPosition {
                shortPressView?.center = CGPoint(
                    x: pointInSelfView.x - pressPosition.xToViewLeft + currentEditingInfo.cellSize.width/2,
                    y: pointInSelfView.y - pressPosition.yToViewTop + currentEditingInfo.cellSize.height/2
                )
            }
            if currentPressType == .move {
                currentEditingInfo.event = (currentMovingCell as? JZLongPressEventCell)?.event
                getCurrentEditingCells().forEach {
                    $0.contentView.layer.opacity = movingCellOpacity
                    currentEditingInfo.allOpacityContentViews.append($0.contentView)
                }
            }

            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 5,
                options: .curveEaseOut,
                animations: { self.shortPressView?.transform = CGAffineTransform.identity }
            )
        case .changed where isAvailableForMoving:
            if let pressPosition {
                let topYPoint = max(pointInSelfView.y - pressPosition.yToViewTop, longPressTopMarginY)
                shortPressView?.center = CGPoint(
                    x: pointInSelfView.x - pressPosition.xToViewLeft + currentEditingInfo.cellSize.width/2,
                    y: topYPoint + currentEditingInfo.cellSize.height/2
                )
                if parkingCornerView == nil,
                   let parkingLotIcon,
                   let shortPressView,
                   let parkingLotArea,
                   parkingLotArea.intersects(shortPressView.frame) {
                    let parkingView = UIView(
                        frame: CGRect(
                            x: 5,
                            y: 5,
                            width: 30,
                            height: 30
                        )
                    )
                    parkingView.backgroundColor = .white
                    parkingView.layer.cornerRadius = 15
                    let plImageView = UIImageView(image: parkingLotIcon)
                    plImageView.contentMode = .scaleAspectFit
                    plImageView.frame = CGRect(x: 5, y: 5, width: 20, height: 20)
                    parkingView.addSubview(plImageView)
                    shortPressView.addSubview(parkingView)
                    parkingCornerView = parkingView
                } else if parkingCornerView != nil,
                          let shortPressView,
                          let parkingLotArea,
                          !parkingLotArea.intersects(shortPressView.frame) {
                    self.parkingCornerView?.removeFromSuperview()
                    self.parkingCornerView = nil
                }

            }
        case .cancelled where isAvailableForMoving:
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
                self.shortPressView?.alpha = 0
            }, completion: { _ in
                self.shortPressView?.removeFromSuperview()
            })
            if let shortPressViewStartDate {
                longPressDelegate?.weekView(
                    self,
                    longPressType: currentPressType,
                    didCancelLongPressAt: shortPressViewStartDate
                )
            }
        case .ended where isAvailableForMoving:
            shortPressView?.removeFromSuperview()
            if let shortPressViewStartDate {
                var column: Int = 1
                if numOfResources > 1 {
                    let originalWidth = widthInColumn
                    for idx in 0..<numOfResources {
                        let sectionX1 = CGFloat(idx) * originalWidth
                        let sectionX2 = sectionX1 + originalWidth
                        if sectionX1...sectionX2 ~= pointInSelfView.x {
                            column = idx
                            break
                        }
                    }
                }
                
                switch currentPressType {
                case .addNew:
                    longPressDelegate?.weekView(
                        self,
                        didEndAddNewLongPressAt: shortPressViewStartDate,
                        in: column,
                        insideParkingLotArea: parkingCornerView != nil
                    )
                case .move:
                    if let currentEditEvent = currentEditingInfo.event, !Calendar.current.isDate(
                        currentEditEvent.startDate,
                        equalTo: shortPressViewStartDate,
                        toGranularity: .minute
                    ) {
                        longPressDelegate?.weekView(
                            self,
                            editingEvent: currentEditEvent,
                            didEndMoveLongPressAt: shortPressViewStartDate,
                            in: column,
                            insideParkingLotArea: parkingCornerView != nil
                        )
                    }
                case .resize:
                    break
                }
            }
        default:
            break
        }
        
        guard isAvailableForMoving else {
            isShortPressing = false
            pressPosition = nil
            return
        }
        
        if (state == .began || state == .changed), let shortPressViewStartDate {
            updateTimeLabel(time: shortPressViewStartDate, pointInSelfView: pointInSelfView)
            updateScroll(pointInSelfView: pointInSelfView)
        }

        if state == .ended || state == .cancelled {
            resetDataForShortPress()
        }
    }

    /// used by handleShortPressGesture only
    private func getShortPressViewStartDate(pointInCollectionView: CGPoint, pointInSelfView: CGPoint) -> Date {
        let shortPressViewTopDate = getDateForPoint(
            pointCollectionView: CGPoint(
                x: pointInCollectionView.x,
                y: pointInCollectionView.y - (pressPosition?.yToViewTop ?? 0) - magicDragYOffset
            ),
            pointSelfView: pointInSelfView
        )
        let shortPressViewStartDate = getLongPressStartDate(
            date: shortPressViewTopDate,
            dateInSection: getDateForPointX(
                xCollectionView: pointInCollectionView.x,
                xSelfView: pointInSelfView.x
            ),
            timeMinInterval: moveTimeMinInterval
        )
        return shortPressViewStartDate
    }
}

extension JZLongPressWeekView {
    /// For indicating which direction should collectionView scroll to in LongPressWeekView
    enum LongPressScrollDirection {
        case up
        case down
        case left
        case right
    }
}

#endif
