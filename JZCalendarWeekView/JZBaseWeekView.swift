//
//  JZBaseWeekView.swift
//  JZCalendarWeekView
//
//  Created by Jeff Zhang on 28/3/18.
//  Copyright © 2018 Jeff Zhang. All rights reserved.
//

#if os(iOS)

import UIKit

public protocol JZBaseViewDelegate: AnyObject {

    /// When initDate changed, this function will be called. You can get the current date by adding numOfDays on initDate
    ///
    /// - Parameters:
    ///   - weekView: current JZBaseWeekView
    ///   - initDate: the new value of initDate
    func initDateDidChange(_ weekView: JZBaseWeekView, initDate: Date)
    func didSwipePage(_ value: Int, weekView: JZBaseWeekView)
}

extension JZBaseViewDelegate {
    // Keep it optional
    func initDateDidChange(_ weekView: JZBaseWeekView, initDate: Date) {}
    func didSwipePage(_ value: Int, weekView: JZBaseWeekView) {}
}

open class JZBaseWeekView: UIView {
    
    public lazy var collectionView: JZCollectionView = {
        let collectionView = JZCollectionView(frame: frame, collectionViewLayout: flowLayout)
        collectionView.isDirectionalLockEnabled = true
        collectionView.bounces = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .white
        collectionView.isOpaque = true
        collectionView.layer.isDoubleSided = false
        return collectionView
    }()

    public var timelineRange: TimelineConfiguration.TimelineType = .full {
        didSet {
            flowLayout.timelineType = timelineRange
        }
    }
    
    public var zoom = ZoomConfiguration.ZoomLevel.default {
        didSet {
            flowLayout.currentZoom = zoom
        }
    }
    
    public var flowLayout: JZWeekViewFlowLayout = {
        let layout = JZWeekViewFlowLayout()
        layout.scrollDirection = .vertical
        return layout
    }()

    typealias RestrictOffsetY = (topY: CGFloat, bottomY: CGFloat)

    private var restrictOffset: RestrictOffsetY?
    
    /**
     - The initial date of current collectionView. When page is not scrolling, the inital date is always
     (numOfDays) days before current page first date, which means the start of the collectionView, not the current page first date
     - The core structure of JZCalendarWeekView is 3 pages, previous-current-next
     - If you want to update this value instead of using [updateWeekView(to date: Date)](), please **make sure the date is startOfDay**.
    */
    public var initDate: Date = Date() {
        didSet {
            baseDelegate?.initDateDidChange(self, initDate: initDate)
        }
    }

    /// Make sure the endDate is always greater than startDate
    /// If call updateView to a date, which is not in the range, you weekview won't be able to scroll
    public var scrollableRange: (startDate: Date?, endDate: Date?) {
        didSet {
            self.scrollableRange = (self.scrollableRange.startDate?.startOfDay, self.scrollableRange.endDate?.startOfDay)
            setHorizontalEdgesOffsetX()
        }
    }
    public var numOfDays: Int = 0
    public var numOfResources: Int = 1
    public var minimalNumberOfResources = 7
    public var scrollType: JZScrollType = .pageScroll
    public var currentTimelineType: JZCurrentTimelineType = .page {
        didSet {
            let viewClass = currentTimelineType == .section ? JZCurrentTimelineSection.self : JZCurrentTimelinePage.self
            self.collectionView.register(viewClass, forSupplementaryViewOfKind: JZSupplementaryViewKinds.currentTimeline, withReuseIdentifier: JZSupplementaryViewKinds.currentTimeline)
        }
    }
    public var firstDayOfWeek: DayOfWeek = .sunday
    public var allEventsBySection: [Date: [JZBaseEvent]] = [:]
    public var notAllDayEventsBySection = [Date: [JZAllDayEvent]]()
    public var allDayEventsBySection = [Date: [JZAllDayEvent]]()
    public weak var baseDelegate: JZBaseViewDelegate?
    private var isNeedRestrictHorizontalScroll: Bool {
        numOfResources > minimalNumberOfResources
    }
    private var frameWidth: CGFloat {
        if let minWidth = minimalSubSectionWidth, isNeedRestrictHorizontalScroll {
            return minWidth * CGFloat(numOfResources) + flowLayout.rowHeaderWidth
        } else {
            return frame.width
        }
    }
    private var actualFrameWidth: CGFloat {
        frame.width - flowLayout.rowHeaderWidth - flowLayout.contentsMargin.left - flowLayout.contentsMargin.right
    }
    open var contentViewWidth: CGFloat {
        frameWidth - flowLayout.rowHeaderWidth - flowLayout.contentsMargin.left - flowLayout.contentsMargin.right
    }
    open var contentViewHeight: CGFloat {
        frame.height - flowLayout.allDayHeaderHeight - flowLayout.contentsMargin.top - flowLayout.contentsMargin.bottom - flowLayout.topHeaderHeight - flowLayout.columnHeaderHeight - safeAreaInsets.bottom
    }
    private var isFirstAppear: Bool = true
    public var isAllDaySupported: Bool = false
    private var isEnabledHorizontalScrolling: Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return false
        } else {
            return isNeedRestrictHorizontalScroll
        }
    }
    private var isEnabledPaggingEffect: Bool {
        false
    }
    internal var scrollDirection: ScrollDirection?

    // Scrollable Range
    internal var scrollableEdges: (leftX: CGFloat?, rightX: CGFloat?)
    
    public var minimalSubSectionWidth: CGFloat?
    public var currentDate = Date()
    private var viewMode: JZCalendarMode = .day

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    open func setup() {
        flowLayout = JZWeekViewFlowLayout()
        flowLayout.delegate = self
        flowLayout.didRestrictScrollOffset = { [weak self] (value) in
            self?.restrictOffset = value
        }
        flowLayout.timelineType = timelineRange
        
        addSubview(collectionView)
        collectionView.setAnchorConstraintsFullSizeTo(view: self)

        registerViewClasses()
    }

    /// Override this function to customise items, supplimentaryViews and decorationViews
    open func registerViewClasses() {
        // supplementary
        collectionView.registerSupplimentaryViews([JZColumnHeader.self,
                                                   JZCornerHeader.self,
                                                   JZRowHeader.self,
                                                   JZAllDayHeader.self,
                                                   JZTopHeaderView.self])
        // decoration
        flowLayout.registerDecorationViews([JZColumnHeaderBackground.self, JZRowHeaderBackground.self,
                                            JZAllDayHeaderBackground.self, JZAllDayCorner.self])
        flowLayout.register(JZGridLine.self, forDecorationViewOfKind: JZDecorationViewKinds.verticalGridline)
        flowLayout.register(JZGridLine.self, forDecorationViewOfKind: JZDecorationViewKinds.horizontalGridline)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        flowLayout.sectionHeight = contentViewHeight
        flowLayout.sectionWidth = getSectionWidth()
        if let minimalWidth = minimalSubSectionWidth, isNeedRestrictHorizontalScroll {
            flowLayout.subsectionWidth = minimalWidth
        } else {
            flowLayout.subsectionWidth = flowLayout.sectionWidth / CGFloat(max(numOfResources, 1))
        }
    }

    /// Was going to use toDecimal1Value as well, but the CGFloat is always got the wrong precision
    /// In order to make sure the width of all sections is the same, add few points to CGFloat
    private func getSectionWidth() -> CGFloat {
        let value = CGFloat(max(numOfDays, 1))
        var sectionWidth = contentViewWidth / value
        let remainder = sectionWidth.truncatingRemainder(dividingBy: 1)
        switch remainder {
        case 0...0.25:
            sectionWidth = sectionWidth.rounded(.down)
        case 0.25...0.75:
            sectionWidth = sectionWidth.rounded(.down) + 0.5
        default:
            sectionWidth = sectionWidth.rounded(.up)
        }
        // Maximum added width for row header should be 0.25 * numberOfRows
        let rowHeaderWidth = frameWidth - flowLayout.contentsMargin.left - flowLayout.contentsMargin.right - sectionWidth * value
        flowLayout.rowHeaderWidth = rowHeaderWidth
        return sectionWidth
    }
    
    open func reloadWithOptions(_ options: [JZCalendarReloadOption]) {
        options.forEach {
            switch $0 {
            case .date(let date):
                // Update Date
                updateWeekView(to: date)
            case .numOfDays(let days):
                // Update numOfDays
                numOfDays = days
                refreshWeekView()
            case .firstDayOfWeek(let date, let dayOfWeek):
                // Update FirstDayOfWeek
                updateFirstDayOfWeek(setDate: date, firstDayOfWeek: dayOfWeek)
            case .layout(let layout):
                // Update Layout
                updateFlowLayout(layout ?? flowLayout)
            case .events(let events):
                forceReload(reloadEvents: events)
            case .numberOfResources(let number):
                numOfResources = number
            case .mode(let mode):
                viewMode = mode
            case .timelineRange(let type):
                timelineRange = type
                // Check the screen orientation when initialisation
                JZWeekViewHelper.viewTransitionHandler(to: UIScreen.main.bounds.size,
                                                       weekView: self,
                                                       needRefresh: false)
                layoutSubviews()
                forceReload()
                updateFlowLayout(flowLayout)
            }
        }
    }

    /**
     Basic Setup method for JZCalendarWeekView,it **must** be called.
     
     - Parameters:
        - numOfDays: Number of days in a page
        - setDate: The initial set date, the first date in current page except WeekView (numOfDays = 7)
        - allEvents: The dictionary of all the events for present. JZWeekViewHelper.getIntraEventsByDate can help transform the data
        - firstDayOfWeek: First day of a week, **only works when numOfDays is 7**. Default value is Sunday
        - scrollType: The horizontal scroll type for this view. Default value is pageScroll
        - currentTimelineType: The current time line type for this view. Default value is section
        - visibleTime: WeekView will be scroll to this time, when it appears the **first time**. This visibleTime only determines **y** offset. Defaut value is current time.
        - scrollableRange: The scrollable area for this weekView, both start and end dates are included, set nil as unlimited in one side
    */
    open func setupCalendar(numOfDays: Int,
                            setDate: Date,
                            allEvents: [Date: [JZBaseEvent]],
                            scrollType: JZScrollType = .pageScroll,
                            firstDayOfWeek: DayOfWeek? = .sunday,
                            currentTimelineType: JZCurrentTimelineType = .section,
                            visibleTime: Date = Date(),
                            forceUpdateFirstDayOfWeek: Bool = false,
                            scrollableRange: (startDate: Date?, endDate: Date?)? = (nil, nil)) {
        currentDate = setDate
        self.numOfDays = numOfDays
        if numOfDays == 7 || forceUpdateFirstDayOfWeek {
            updateFirstDayOfWeek(setDate: setDate, firstDayOfWeek: firstDayOfWeek)
        } else {
            initDate = setDate.startOfDay.add(component: .day, value: -numOfDays)
        }
        self.allEventsBySection = allEvents
        self.scrollType = scrollType
        self.scrollableRange.startDate = scrollableRange?.startDate
        self.scrollableRange.endDate = scrollableRange?.endDate
        self.currentTimelineType = currentTimelineType
        
        collectionView.delegate = self
        collectionView.dataSource = self

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Check the screen orientation when initialisation
            JZWeekViewHelper.viewTransitionHandler(to: UIScreen.main.bounds.size,
                                                   weekView: self,
                                                   needRefresh: false)
            self.layoutSubviews()
            self.forceReload(reloadEvents: allEvents)

            if self.isFirstAppear {
                self.isFirstAppear = false
                self.scrollWeekView(to: visibleTime)
            }
        }
    }
    
    open func setupCalendarEvents(allEvents: [Date: [JZBaseEvent]]) {
        allEventsBySection = allEvents
        layoutSubviews()
        forceReload(reloadEvents: allEvents)
    }

    open func setupAllDayEvents() {
        notAllDayEventsBySection.removeAll()
        allDayEventsBySection.removeAll()
        for (date, events) in allEventsBySection {
            guard let allDayEvents = events as? [JZAllDayEvent] else { continue }
            notAllDayEventsBySection[date] = allDayEvents.filter { !$0.isAllDay }
            allDayEventsBySection[date] = allDayEvents.filter { $0.isAllDay }
        }
    }

    /// This function is used to update the AllDayBar height
    ///
    /// - Parameter isScrolling: Whether the collectionView is scrolling now
    open func updateAllDayBar(isScrolling: Bool) {
        guard isAllDaySupported else { return }
        var maxEventsCount: Int = 0
        getDatesInCurrentPage(isScrolling: isScrolling).forEach {
            let count = allDayEventsBySection[$0]?.count ?? 0
            if count > maxEventsCount {
                maxEventsCount = count
            }
        }
        let newAllDayHeader = getAllDayHeaderHeight(maxEventsCount: maxEventsCount)
        if newAllDayHeader != flowLayout.allDayHeaderHeight {
            // Check whether we need update the allDayHeaderHeight
            if !isScrolling || !willEffectContentSize(difference: flowLayout.allDayHeaderHeight - newAllDayHeader) {
                flowLayout.allDayHeaderHeight = newAllDayHeader
            }
        }
    }

    /// You can simply override this method to customise your preferred AllDayHeader height rule.
    ///
    /// If the actual height(contentSize height) is higher than this one, then the AllDayHeader will become scrollable.
    /// - Parameter maxEventsCount: Among all days appeared in current page, the maximum all-day events count in one day
    open func getAllDayHeaderHeight(maxEventsCount: Int) -> CGFloat {
        flowLayout.defaultAllDayOneLineHeight * CGFloat(min(maxEventsCount, 2))
    }

    /// Update collectionViewLayout with custom flowLayout. For some other values like gridThickness and contentsMargin, please inherit from JZWeekViewFlowLayout to change the default value
    /// - Parameter flowLayout: Custom CalendarWeekView flowLayout
    open func updateFlowLayout(_ flowLayout: JZWeekViewFlowLayout) {
        self.flowLayout.rowHeaderWidth = flowLayout.rowHeaderWidth
        self.flowLayout.columnHeaderHeight = flowLayout.columnHeaderHeight
        self.flowLayout.hourGridDivision = flowLayout.hourGridDivision
        self.flowLayout.invalidateLayoutCache()
        self.flowLayout.invalidateLayout()
    }

    /// Reload the collectionView and flowLayout
    /// - Parameters:
    ///   - reloadEvents: If provided new events, current events will be reloaded. Default value is nil.
    open func forceReload(reloadEvents: [Date: [JZBaseEvent]]? = nil) {
        if let events = reloadEvents { self.allEventsBySection = events }

        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.updateAllDayBar(isScrolling: false)
            // initial day is one page before the settle day
            let x: CGFloat
            if strongSelf.contentViewWidth < strongSelf.collectionView.contentOffset.x {
                x = strongSelf.collectionView.contentOffset.x
            } else {
                x = strongSelf.contentViewWidth
            }
            strongSelf.collectionView.setContentOffsetWithoutDelegate(CGPoint(x: x,
                                                                              y: strongSelf.getYOffset()),
                                                                      animated: false)
            strongSelf.flowLayout.invalidateLayoutCache()
            strongSelf.collectionView.reloadData()
            strongSelf.setHorizontalEdgesOffsetX()
        }
    }

    /// Notice: A temporary solution to fix the scroll from bottom issue when isScrolling
    /// The issue is because the decreased height value will cause the system to change the collectionView contentOffset, but the affected contentOffset will
    /// greater than the contentSize height, and the view will show some abnormal updates, this value will be used with isScrolling to check whether the in scroling change will be applied
    private func willEffectContentSize(difference: CGFloat) -> Bool {
        collectionView.contentOffset.y + difference + collectionView.bounds.height > collectionView.contentSize.height
    }

    /// Fix collectionView scroll from bottom (contentsize height decreased) wrong offset issue
    private func getYOffset() -> CGFloat {
        guard isAllDaySupported else { return collectionView.contentOffset.y }
        let bottomOffset = flowLayout.collectionViewContentSize.height - collectionView.bounds.height
        if collectionView.contentOffset.y > bottomOffset {
            return bottomOffset
        } else {
            return collectionView.contentOffset.y
        }
    }

    /// Reload the WeekView to date with no animation (Horizontally).
    /// If the date you set is out of scrollableRange, it will update to that date, but it won't be able to scroll.
    ///
    /// The vertical animated scroll method is *scrollWeekView(to time: Date)*.
    /// - Parameters:
    ///    - date: this date is the current date in one-day view rather than initDate
    open func updateWeekView(to date: Date, scrollToTime: Bool = false) {
        currentDate = date
        initDate = date.startOfDay.add(component: .day, value: -numOfDays)
        
        DispatchQueue.main.async { [weak self] in
            self?.layoutSubviews()
            self?.forceReload()
            
            if scrollToTime {
                self?.flowLayout.scrollCollectionViewTo(time: date,
                                                        position: .centerVertically)
            }
        }
    }

    /// Vertically scroll collectionView to the specific time in a day.
    /// If the time you set is too late, it will only reach the bottom 24:00 as the maximum value.
    ///
    /// The horizontal update method is *updateWeekView(to date: Date)*.
    ///
    /// - Parameter time: Only **hour and min** will be calulated for the Y offset
    open func scrollWeekView(to time: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let hour = CGFloat(components.hour!) + CGFloat(components.minute!) / 60
        let setTimeY = hour * flowLayout.hourHeightForZoomLevel + flowLayout.contentsMargin.top
        let maxOffsetY = collectionView.contentSize.height - collectionView.frame.height + flowLayout.columnHeaderHeight + flowLayout.allDayHeaderHeight + flowLayout.contentsMargin.bottom + flowLayout.contentsMargin.top + flowLayout.topHeaderHeight
        collectionView.setContentOffsetWithoutDelegate(CGPoint(x: collectionView.contentOffset.x,
                                                               y: max(0, min(setTimeY, maxOffsetY))),
                                                       animated: false)
    }

    /// Get current event with item indexPath
    ///
    /// - Parameter indexPath: The indexPath of an item in collectionView
    open func getCurrentEvent(with indexPath: IndexPath) -> JZBaseEvent? {
        let date = flowLayout.dateForColumnHeader(at: indexPath)
        return isAllDaySupported ? notAllDayEventsBySection[date]?[indexPath.row] : allEventsBySection[date]?[indexPath.row]
    }

    open func getDatesInCurrentPage(isScrolling: Bool) -> [Date] {
        var dates = [Date]()
        if !isScrolling {
            for i in numOfDays..<2*numOfDays {
                dates.append(initDate.set(day: initDate.day + i))
            }
            return dates
        }
        var startDate = getDateForContentOffsetX(collectionView.contentOffset.x)
        // substract 1 to make sure it won't include the next section when reach the boundary
        let endDate = getDateForContentOffsetX(collectionView.contentOffset.x + contentViewWidth - 1)
        repeat {
            dates.append(startDate)
            startDate = startDate.add(component: .day, value: 1)
        } while startDate <= endDate

        return dates
    }

    /**
        Used to Refresh the weekView when viewWillTransition
     
        **Must override viewWillTransition in the ViewController and call this function**
    */
    open func refreshWeekView() {
        updateWeekView(to: self.initDate.add(component: .day, value: numOfDays))
    }

    open func updateFirstDayOfWeek(setDate: Date, firstDayOfWeek: DayOfWeek?) {
        guard let firstDayOfWeek = firstDayOfWeek, viewMode == .week else { return }
        let setDayOfWeek = setDate.getDayOfWeek()
        var diff = setDayOfWeek.rawValue - firstDayOfWeek.rawValue
        if diff < 0 { diff = numOfDays - abs(diff) }
        initDate = setDate.startOfDay.add(component: .day, value: -numOfDays - diff)
        self.firstDayOfWeek = firstDayOfWeek
    }

    // MARK: - Date related getters

    /// Get Date for specific section.
    /// The 0 section start from previous page, which means the first date section in current page should be **numOfDays**.
    open func getDateForSection(_ section: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: section, to: initDate) ?? Date()
    }

    /**
     Get date excluding time from **collectionView contentOffset only** rather than gesture point in collectionView
        - Parameter contentOffsetX: collectionView contentOffset x
     */
    open func getDateForContentOffsetX(_ contentOffsetX: CGFloat) -> Date {
        let adjustedX = contentOffsetX - flowLayout.contentsMargin.left
        let section = Int(adjustedX / flowLayout.sectionWidth)
        return getDateForSection(section)
    }

    /**
     Get time excluding date from **collectionView contentOffset only** rather than gesture point in collectionView
        - Parameter contentOffsetY: collectionView contentOffset y
     */
    open func getDateForContentOffsetY(_ contentOffsetY: CGFloat) -> (hour: Int, minute: Int) {
        var adjustedY = contentOffsetY - flowLayout.contentsMargin.top
        adjustedY = max(0, adjustedY)
        var hour = Int(adjustedY / flowLayout.hourHeightForZoomLevel)
        if timelineRange != .full {
            hour += timelineRange.timeRange.lowerBound
            adjustedY += flowLayout.timeRangeLowerOffset
        }
        let minute = Int((adjustedY / flowLayout.hourHeightForZoomLevel - CGFloat(hour)) * 60)
        return (hour, minute)
    }

    /**
     Get full date from **collectionView contentOffset only** rather than gesture point in collectionView
        - Parameter contentOffset: collectionView contentOffset
     */
    open func getDateForContentOffset(_ contentOffset: CGPoint) -> Date {
        let yearMonthDay = getDateForContentOffsetX(contentOffset.x)
        let time = getDateForContentOffsetY(contentOffset.y)
        return yearMonthDay.set(hour: time.hour, minute: time.minute, second: 0)
    }

    /**
     Get date excluding time from **gesture point in collectionView only** rather than collectionView contentOffset
        - Parameter xCollectionView: gesture point x in collectionView
     */
    open func getDateForPointX(_ xCollectionView: CGFloat) -> Date {
        // RowHeader(horizontal UICollectionReusableView) should be considered in gesture point
        // Margin area for point X can also get actual date, because it is always the middle view unlike point Y
        let adjustedX = xCollectionView - flowLayout.rowHeaderWidth - flowLayout.contentsMargin.left
        let section = Int(adjustedX / flowLayout.sectionWidth)
        return getDateForSection(section)
    }

    /**
     Get time excluding date from **gesture point in collectionView only** rather than collectionView contentOffset
        - Parameter yCollectionView: gesture point y in collectionView
     */
    open func getDateForPointY(_ yCollectionView: CGFloat) -> (hour: Int, minute: Int) {
        // ColumnHeader and AllDayHeader(vertical UICollectionReusableView) should be considered in gesture point
        var adjustedY = yCollectionView - flowLayout.columnHeaderHeight - flowLayout.contentsMargin.top - flowLayout.allDayHeaderHeight
        let minY: CGFloat = 0
        // contentSize includes all reusableView, margin and scrollable area
        let maxY = collectionView.contentSize.height - flowLayout.contentsMargin.top - flowLayout.contentsMargin.bottom - flowLayout.allDayHeaderHeight - flowLayout.columnHeaderHeight - flowLayout.topHeaderHeight + flowLayout.timeRangeLowerOffset
        adjustedY = max(minY, min(adjustedY, maxY))
        var hour = Int(adjustedY / flowLayout.hourHeightForZoomLevel)
        if timelineRange != .full {
            hour += timelineRange.timeRange.lowerBound
            adjustedY += flowLayout.timeRangeLowerOffset
        }
        let minute = Int((adjustedY / flowLayout.hourHeightForZoomLevel - CGFloat(hour)) * 60)
        return (hour, minute)
    }

    /**
     Get full date from **gesture point in collectionView only** rather than collectionView contentOffset
        - Parameter point: gesture point in collectionView
     */
    open func getDateForPoint(_ point: CGPoint) -> Date {
        let yearMonthDay = getDateForPointX(point.x)
        let time = getDateForPointY(point.y)
        return yearMonthDay.set(hour: time.hour, minute: time.minute, second: 0)
    }
    
    // Override if needed in subclass
    open func collectionView(_ collectionView: UICollectionView, colorForOutsideScreenDecorationViewAt indexPath: IndexPath) -> UIColor? {
        nil
    }
    
    // Override if needed in subclass
    open func collectionView(_ collectionView: UICollectionView, restrictedAreasFor section: Int, resourceIndex: Int) -> Set<RestrictedArea>? {
        nil
    }
    
    // Override if needed in subclass
    open func collectionView(_ collectionView: UICollectionView, numberOfRestrictedLinesIn section: Int) -> Int {
        0
    }
    
    // Override if needed in subclass
    public func collectionView(_ collectionView: UICollectionView, layout: JZWeekViewFlowLayout, zIndexForItemAtIndexPath indexPath: IndexPath) -> Int {
        let date = flowLayout.dateForColumnHeader(at: indexPath)
        if let events = allEventsBySection[date], let event = events[safe: indexPath.item] {
            return event.zIndex
        } else {
            return 1
        }
    }
    
}

// MARK: - UICollectionViewDataSource
extension JZBaseWeekView: UICollectionViewDataSource {
    
    // In order to keep efficiency, only 3 pages exist at the same time, previous-current-next
    open func numberOfSections(in collectionView: UICollectionView) -> Int {
        3 * numOfDays
    }

    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let date = flowLayout.dateForColumnHeader(at: IndexPath(item: 0, section: section))

        if let events = allEventsBySection[date] {
            return isAllDaySupported ? notAllDayEventsBySection[date]!.count : events.count
        } else {
            return 0
        }
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        preconditionFailure("This method must be overridden")
    }

    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var view = UICollectionReusableView()

        switch kind {
        case JZSupplementaryViewKinds.topHeader:
            if let topHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as? JZTopHeaderView {
                view = topHeader
            }
        case JZSupplementaryViewKinds.columnHeader:
            if let columnHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as? JZColumnHeader {
                columnHeader.updateView(date: flowLayout.dateForColumnHeader(at: indexPath))
                view = columnHeader
            }
        case JZSupplementaryViewKinds.rowHeader:
            if let rowHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as? JZRowHeader {
                rowHeader.updateView(date: flowLayout.timeForRowHeader(at: indexPath))
                view = rowHeader
            }
        case JZSupplementaryViewKinds.cornerHeader:
            if let cornerHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as? JZCornerHeader {
                view = cornerHeader
            }
        case JZSupplementaryViewKinds.allDayHeader:
            if let alldayHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as? JZAllDayHeader {
                alldayHeader.updateView(views: [])
                view = alldayHeader
            }
        case JZSupplementaryViewKinds.currentTimeline:
            if currentTimelineType == .page {
                if let currentTimeline = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as? JZCurrentTimelinePage {
                    view = getPageTypeCurrentTimeline(timeline: currentTimeline, indexPath: indexPath)
                }
            } else {
                if let currentTimeline = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as? JZCurrentTimelineSection {
                    view = getSectionTypeCurrentTimeline(timeline: currentTimeline, indexPath: indexPath)
                }
            }
        default: break
        }
        return view
    }
}

// MARK: - UICollectionViewDelegate: UIScrollViewDelegate for Pagination Effect
extension JZBaseWeekView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    /// Get scrolling direction when first time start beginning dragging until scrolling ends
    internal func getBeginDraggingScrollDirection() -> ScrollDirection {
        let velocity = self.collectionView.panGestureRecognizer.velocity(in: self)
        if abs(velocity.x) >= abs(velocity.y) {
            // if velocity exists both x and y, the lower value side should be locked
            return ScrollDirection(direction: .horizontal, lockedAt: velocity.x == 0 ? nil : self.collectionView.contentOffset.y)
        } else {
            return ScrollDirection(direction: .vertical, lockedAt: velocity.y == 0 ? nil : self.collectionView.contentOffset.x)
        }
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard isEnabledHorizontalScrolling else { return }
        
        // Only check when scroll direction is nil to ensure the direction for this scroll before it ends
        // Because if swipe again before scroll ends, this method will be called again but the direction should be the same
        if self.scrollDirection != nil { return }
        // Warning: scrollViewWillBeginDragging contentOffset value might be incorrect, 0.5 or 1 pixel difference, ignored for now
        self.scrollDirection = self.getBeginDraggingScrollDirection()
        // deceleration rate should be normal in vertical scroll
        scrollView.decelerationRate = self.scrollDirection!.direction == .horizontal ? .fast : .normal
    }

    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard isEnabledHorizontalScrolling else { return }
        
        // vertical scroll should not call paginationEffect
        guard let scrollDirection = self.scrollDirection, scrollDirection.direction == .horizontal else { return }
        
        guard isEnabledPaggingEffect else { return }
        paginationEffect(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard isEnabledHorizontalScrolling else { return }
        
        // handle the situation scrollViewDidEndDecelerating not being called
        if !decelerate { self.endOfScroll() }
    }

    // This function will be called when veritical scrolling ends
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard isEnabledHorizontalScrolling else { return }
        
        self.endOfScroll()
    }

    /// Some actions need to be done when scroll ends
    private func endOfScroll() {
        // vertical scroll should not load page, handled in loadPage method
        loadPage()
        self.scrollDirection = nil
    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isEnabledHorizontalScrolling else {
            collectionView.contentOffset.x = contentViewWidth
            return
        }
        
        guard let scrollDirection = scrollDirection else { return }
        if let lockedAt = scrollDirection.lockedAt {
            if scrollDirection.direction == .horizontal {
                scrollView.contentOffset.y = lockedAt
            } else {
                scrollView.contentOffset.x = lockedAt
            }
        }
        
        // all day bar update and check scrollable range when scrolling horizontally
        guard flowLayout.sectionWidth != nil, scrollDirection.direction == .horizontal else { return }
        checkScrollableRange(contentOffsetX: scrollView.contentOffset.x)
        updateAllDayBar(isScrolling: true)
        
        guard isNeedRestrictHorizontalScroll else { return }
        let rightLock = ((contentViewWidth - actualFrameWidth) + contentViewWidth)
        if scrollView.contentOffset.x < contentViewWidth {
            collectionView.contentOffset.x = contentViewWidth
        } else if scrollView.contentOffset.x > rightLock {
            collectionView.contentOffset.x = rightLock
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 100)
    }
    
    private func paginationEffect(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let currentContentOffset = scrollView.contentOffset
        let pageWidth: CGFloat = scrollType == .sectionScroll ? flowLayout.sectionWidth : contentViewWidth
        // current section will always get current section, applied floor Int here
        let currentSection = Int(currentContentOffset.x / flowLayout.sectionWidth)
        let currentPage = scrollType == .sectionScroll ? currentSection : (currentSection >= numOfDays ? 1 : 0)  // The divider section for 0 and 1 page is at numOfDays
        let isVelocitySatisfied = abs(velocity.x) > 0.4
        var shouldScrollToPage: Int

        if isVelocitySatisfied {
            // If velocity is satisfied, then scroll to next page or current page(currentSection calculated by floor Int)
            shouldScrollToPage = currentPage + (velocity.x > 0 ? 1 : 0)
        } else {
            // If velocity unsatisfied, then using half distance(round) to check whether scroll to next or current
            let scrollDistanceX = currentContentOffset.x - CGFloat(currentPage) * pageWidth
            shouldScrollToPage = currentPage + Int(round(scrollDistanceX / pageWidth))
        }
        let shouldScrollToContentOffsetX = CGFloat(shouldScrollToPage) * pageWidth
        // if shouldScrollToContentOffsetX equals currentContentOffsetX which means scrollViewDidEndDecelerating won't be called
        // This case is now handled in scrollViewDidEndDragging
        targetContentOffset.pointee = CGPoint(x: shouldScrollToContentOffsetX, y: currentContentOffset.y)
    }

    /// Load the page after horizontal scroll action.
    ///
    /// Can be overridden to do some operations before reload.
    public func loadPage() {
        // It means collectionView is scrolling back to previous contentOffsetX or It is vertical scroll
        // Each scroll should always start from the middle, which is contentViewWidth
        if collectionView.contentOffset.x == contentViewWidth { return }
        scrollType == .pageScroll ? loadPagePageScroll() : loadPageSectionScroll()
    }

    // sectionScroll load page
    private func loadPageSectionScroll() {
        let newDate = getDateForContentOffsetX(collectionView.contentOffset.x)
        let currentInitDate = newDate.add(component: .day, value: -numOfDays)
        self.initDate = currentInitDate
        self.forceReload()
    }

    /// pageScroll loading next page or previous page (Only three pages (3*numOfDays) exist at the same time)
    private func loadPagePageScroll() {
        let minOffsetX: CGFloat = 0, maxOffsetX = collectionView.contentSize.width - collectionView.frame.width
        let currentOffsetX = collectionView.contentOffset.x

        if currentOffsetX >= maxOffsetX {
            //load next page
            loadNextOrPrevPage(isNext: true)
        }
        if currentOffsetX <= minOffsetX {
            //load previous page
            loadNextOrPrevPage(isNext: false)
        }
    }

    private func loadNextOrPrevPage(isNext: Bool) {
        let addValue = isNext ? numOfDays : -numOfDays
        currentDate = currentDate.add(component: .day, value: addValue)
        baseDelegate?.didSwipePage(addValue, weekView: self)
        initDate = initDate.add(component: .day, value: addValue)
        forceReload()
    }

}

// MARK: - Current time line
extension JZBaseWeekView {

    /// Get the section Type current timeline
    public func getSectionTypeCurrentTimeline(timeline: JZCurrentTimelineSection, indexPath: IndexPath) -> UICollectionReusableView {
        let date = flowLayout.dateForColumnHeader(at: indexPath)
        timeline.isHidden = !date.isToday
        return timeline
    }

    /// Get the page Type current timeline
    /// Rules are quite confused for now
    public func getPageTypeCurrentTimeline(timeline: JZCurrentTimelinePage, indexPath: IndexPath) -> UICollectionReusableView {
        let date = flowLayout.dateForColumnHeader(at: indexPath)
        let daysToToday = Date.daysBetween(start: date, end: Date(), ignoreHours: true)
        timeline.isHidden = abs(daysToToday) > numOfDays - 1
        timeline.updateView(needShowBallView: daysToToday == 0)
        return timeline
    }

}

// MARK: - Horizontal scrollable range methods
extension JZBaseWeekView {

    private func checkScrollableRange(contentOffsetX: CGFloat) {
        if let leftX = scrollableEdges.leftX, contentOffsetX < leftX {
            collectionView.setContentOffset(CGPoint(x: leftX, y: collectionView.contentOffset.y), animated: false)
        }

        if let rightX = scrollableEdges.rightX, contentOffsetX > rightX {
            collectionView.setContentOffset(CGPoint(x: rightX, y: collectionView.contentOffset.y), animated: false)
        }
    }

    /// This method will be called automatically when ForceReload or resetting the scrollableRange value
    /// **If you want to reset the scrollType, numsOfDays, initDate without calling forceReload, you should call this method**
    public func setHorizontalEdgesOffsetX() {
        let currentPageFirstDate = initDate.add(component: .day, value: numOfDays)
        let currentPageLastDate = initDate.add(component: .day, value: numOfDays * 2 - 1)

        if let endDate = scrollableRange.endDate, endDate < currentPageFirstDate {
            // out of range
            scrollableEdges.leftX = contentViewWidth
        } else {
            if let startDate = scrollableRange.startDate {
                if startDate >= currentPageFirstDate {
                    scrollableEdges.leftX = contentViewWidth
                } else {
                    if scrollType == .pageScroll || startDate <= initDate {
                        scrollableEdges.leftX = nil
                    } else {
                        let days = Date.daysBetween(start: initDate, end: startDate, ignoreHours: true)
                        scrollableEdges.leftX = (flowLayout.sectionWidth ?? 0) * CGFloat(days)
                    }
                }
            } else {
                scrollableEdges.leftX = nil
            }
        }

        if let startDate = scrollableRange.startDate, startDate > currentPageLastDate {
            // out of range
            scrollableEdges.rightX = contentViewWidth
        } else {
            if let endDate = scrollableRange.endDate {
                if endDate <= currentPageLastDate {
                    scrollableEdges.rightX = contentViewWidth
                } else {
                    let lastDateInView = initDate.add(component: .day, value: numOfDays * 3 - 1)
                    if scrollType == .pageScroll || endDate >= lastDateInView {
                        scrollableEdges.rightX = nil
                    } else {
                        let days = Date.daysBetween(start: initDate, end: endDate, ignoreHours: true)
                        scrollableEdges.rightX = (flowLayout.sectionWidth ?? 0) * CGFloat(days - numOfDays + 1)
                    }
                }
            } else {
                scrollableEdges.rightX = nil
            }
        }
    }

}

// MARK: - WeekViewFlowLayoutDelegate
extension JZBaseWeekView: WeekViewFlowLayoutDelegate {

    public func collectionView(_ collectionView: UICollectionView, layout: JZWeekViewFlowLayout, dayForSection section: Int) -> Date {
        return getDateForSection(section)
    }

    public func collectionView(_ collectionView: UICollectionView, layout: JZWeekViewFlowLayout, startTimeForItemAtIndexPath indexPath: IndexPath) -> Date {
        let date = flowLayout.dateForColumnHeader(at: indexPath)

        if let events = allEventsBySection[date] {
            guard let event = isAllDaySupported ? notAllDayEventsBySection[date]?[safe: indexPath.item] : events[safe: indexPath.item] else { return Date() }
            return event.intraStartDate
        } else {
            return Date()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout: JZWeekViewFlowLayout, endTimeForItemAtIndexPath indexPath: IndexPath) -> Date {
        let date = flowLayout.dateForColumnHeader(at: indexPath)

        if let events = allEventsBySection[date] {
            guard let event = isAllDaySupported ? notAllDayEventsBySection[date]?[safe: indexPath.item] : events[safe: indexPath.item] else { return Date() }
            return event.intraEndDate
        } else {
            return Date()
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout: JZWeekViewFlowLayout, resourceIndexForItemAtIndexPath indexPath: IndexPath) -> Int {
        let date = flowLayout.dateForColumnHeader(at: indexPath)

        if let events = allEventsBySection[date] {
            guard let event = isAllDaySupported ? notAllDayEventsBySection[date]?[safe: indexPath.item] : events[safe: indexPath.item] else { return 0 }
            return min(event.resourceIndex ?? 0, self.numOfResources - 1)
        } else {
            return 0
        }
    }

    public func collectionView(_ collectionView: UICollectionView, resourceCountWithLayout: JZWeekViewFlowLayout) -> Int {
        numOfResources
    }

    // TODO: Only used when multiple cell types are used and need different overlap rules => layoutItemsAttributes
    public func collectionView(_ collectionView: UICollectionView, layout: JZWeekViewFlowLayout, cellTypeForItemAtIndexPath indexPath: IndexPath) -> String {
        let date = flowLayout.dateForColumnHeader(at: indexPath)

        guard let events = allEventsBySection[date], let event = events[safe: indexPath.item] else {
            return JZSupplementaryViewKinds.eventCell
        }
        
        if event.isPlaceholder {
            return JZSupplementaryViewKinds.placeholderCell
        } else if event.isCalendarBlock {
            return JZSupplementaryViewKinds.calendarBlockCell
        } else {
            return JZSupplementaryViewKinds.eventCell
        }
    }
    
}

#endif
