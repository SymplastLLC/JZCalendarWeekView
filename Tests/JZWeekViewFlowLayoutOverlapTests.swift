//
//  JZWeekViewFlowLayoutOverlapTests.swift
//  JZCalendarWeekViewTests
//

import XCTest
@testable import JZCalendarWeekView

final class JZWeekViewFlowLayoutOverlapTests: XCTestCase {

    /// Regression case for the chain-overlap scenario from the example data:
    /// event "0-11" must not be covered by event "0" after overlap layout.
    func testAdjustItemsForOverlap_DoesNotOverlayChainOverlapScenario() {
        // Arrange
        let layout = JZWeekViewFlowLayout()
        layout.sectionWidth = 300

        let scenario: [(name: String, startY: CGFloat, endY: CGFloat)] = [
            ("0", 0, 60),
            ("0-1", 0, 30),
            ("0-11", 30, 90),
            ("0-2", 60, 120),
            ("0-3", 60, 90)
        ]

        let attributes = scenario.enumerated().map { index, item in
            makeAttribute(index: index, minY: item.startY, maxY: item.endY)
        }

        // Act
        layout.adjustItemsForOverlap(
            attributes,
            inSection: 0,
            sectionMinX: 0,
            currentSectionZ: 100,
            resourceIdx: 0,
            sectionWidth: 300
        )

        // Assert
        assertNoHorizontalIntersectionForOverlappingTime(attributes)
    }

    /// Stronger determinism guarantee than the order-independence test below: running the exact
    /// same schedule under two different input permutations must produce pixel-identical frames
    /// and z-indices per item (matched by indexPath), not merely two independently-valid
    /// non-intersecting layouts. `testAdjustItemsForOverlap_DoesNotDependOnInputOrder` would still
    /// pass even if placement were order-dependent, since it only re-checks non-intersection.
    func testAdjustItemsForOverlap_ProducesIdenticalResultsAcrossInputPermutations() {
        let scenario: [(name: String, startY: CGFloat, endY: CGFloat)] = [
            ("0", 0, 60),
            ("0-1", 0, 30),
            ("0-11", 30, 90),
            ("0-2", 60, 120),
            ("0-3", 60, 90),
            ("0-4", 45, 75)
        ]

        func layoutResult(order: [Int]) -> [IndexPath: (frame: CGRect, zIndex: Int)] {
            let layout = JZWeekViewFlowLayout()
            layout.sectionWidth = 300

            // Keep each item's indexPath tied to its identity (sourceIndex) rather than its
            // position in the input array, so results can be matched across permutations.
            let attributes = order.map { sourceIndex -> UICollectionViewLayoutAttributesResource in
                let item = scenario[sourceIndex]
                return makeAttribute(index: sourceIndex, minY: item.startY, maxY: item.endY)
            }

            layout.adjustItemsForOverlap(
                attributes,
                inSection: 0,
                sectionMinX: 0,
                currentSectionZ: 100,
                resourceIdx: 0,
                sectionWidth: 300
            )

            var result = [IndexPath: (frame: CGRect, zIndex: Int)]()
            for attribute in attributes {
                result[attribute.indexPath] = (attribute.frame, attribute.zIndex)
            }
            return result
        }

        let resultA = layoutResult(order: [0, 1, 2, 3, 4, 5])
        let resultB = layoutResult(order: [5, 3, 1, 4, 0, 2])

        XCTAssertEqual(Set(resultA.keys), Set(resultB.keys))
        for indexPath in resultA.keys {
            guard let a = resultA[indexPath], let b = resultB[indexPath] else {
                XCTFail("missing indexPath \(indexPath) in one of the permutations")
                continue
            }
            XCTAssertEqual(a.frame, b.frame, "frame for item \(indexPath.item) differs between input permutations")
            XCTAssertEqual(a.zIndex, b.zIndex, "zIndex for item \(indexPath.item) differs between input permutations")
        }
    }

    /// Validates deterministic result regardless of item input order.
    func testAdjustItemsForOverlap_DoesNotDependOnInputOrder() {
        // Arrange
        let layout = JZWeekViewFlowLayout()
        layout.sectionWidth = 300

        let scenario: [(startY: CGFloat, endY: CGFloat)] = [
            (0, 60),
            (0, 30),
            (30, 90),
            (60, 120),
            (60, 90)
        ]

        let shuffledOrder = [0, 1, 3, 4, 2]
        let attributes = shuffledOrder.enumerated().map { outputIndex, sourceIndex in
            let item = scenario[sourceIndex]
            return makeAttribute(index: outputIndex, minY: item.startY, maxY: item.endY)
        }

        // Act
        layout.adjustItemsForOverlap(
            attributes,
            inSection: 0,
            sectionMinX: 0,
            currentSectionZ: 100,
            resourceIdx: 0,
            sectionWidth: 300
        )

        // Assert
        assertNoHorizontalIntersectionForOverlappingTime(attributes)
    }

    /// Acceptance-criterion coverage for the per-cluster (not whole-method) early-out: a schedule
    /// where some events overlap (so `adjustItemsForOverlap` does not early-return entirely) but
    /// at least one event overlaps nothing at all. That item's own cluster is a singleton, and
    /// must come out of the call byte-identical to how it went in — untouched frame, untouched
    /// zIndex — not merely "still non-intersecting".
    func testAdjustItemsForOverlap_LeavesSingletonClusterUntouched() {
        // Arrange
        let layout = JZWeekViewFlowLayout()
        layout.sectionWidth = 300

        let scenario: [(name: String, startY: CGFloat, endY: CGFloat)] = [
            ("a", 0, 30),
            ("b", 15, 45),          // overlaps "a", so the method has real work to do
            ("isolated", 200, 230)  // overlaps nothing else in the schedule
        ]

        let attributes = scenario.enumerated().map { index, item in
            makeAttribute(index: index, minY: item.startY, maxY: item.endY)
        }

        let isolated = attributes[2]
        let originalFrame = isolated.frame
        let originalZIndex = isolated.zIndex

        // Act
        layout.adjustItemsForOverlap(
            attributes,
            inSection: 0,
            sectionMinX: 0,
            currentSectionZ: 100,
            resourceIdx: 0,
            sectionWidth: 300
        )

        // Assert
        XCTAssertEqual(isolated.frame, originalFrame, "an item with no time overlap must keep its original full-width frame")
        XCTAssertEqual(isolated.zIndex, originalZIndex, "an item with no time overlap must keep its original zIndex")
    }

    /// FIRE-336 regression: minimised schedule found by fuzzing that, under the old greedy
    /// "largest overlap group first, spread evenly, ordered by a heuristic" algorithm, left
    /// "e10" completely unadjusted — still full 298pt width and the lowest zIndex — so it was
    /// painted underneath "e3" and "e8" and was invisible on the calendar day view.
    func testAdjustItemsForOverlap_Fire336DoesNotHideAnyEvent() {
        // Arrange
        let layout = JZWeekViewFlowLayout()
        layout.sectionWidth = 300

        // y == minutes
        let scenario: [(name: String, startY: CGFloat, endY: CGFloat)] = [
            ("e0", 705, 750),
            ("e1", 735, 855),
            ("e2", 720, 780),
            ("e3", 795, 1035),
            ("e4", 690, 750),
            ("e5", 660, 690),
            ("e6", 615, 645),
            ("e7", 480, 510),
            ("e8", 960, 1080),
            ("e9", 870, 900),
            ("e10", 1020, 1080)
        ]

        let attributes = scenario.enumerated().map { index, item in
            makeAttribute(index: index, minY: item.startY, maxY: item.endY)
        }

        // Act
        layout.adjustItemsForOverlap(
            attributes,
            inSection: 0,
            sectionMinX: 0,
            currentSectionZ: 100,
            resourceIdx: 0,
            sectionWidth: 300
        )

        // Assert
        assertItemFrameInvariants(attributes, sectionMinX: 0, sectionWidth: layout.sectionWidth)
        assertNoHorizontalIntersectionForOverlappingTime(attributes)
    }

    /// FIRE-336 expansion regression: without the rightward-expansion pass, a single long block
    /// spanning the whole day pulls every other event in its cluster down to 1/columnCount width
    /// even at times nothing else is scheduled — a visible regression against the pre-fix
    /// production layout. `shortA` here overlaps only "long" in time, not shortB/shortC (which
    /// overlap each other, forcing a 3rd column), so it has nothing blocking it one column to
    /// the right and must expand past its packed divisionWidth; shortB/shortC genuinely conflict
    /// with their right neighbour and must not.
    func testAdjustItemsForOverlap_ExpandsItemWithNoTimeNeighbourInAdjacentColumn() {
        // Arrange
        let layout = JZWeekViewFlowLayout()
        layout.sectionWidth = 300

        let scenario: [(name: String, startY: CGFloat, endY: CGFloat)] = [
            ("long", 0, 600),     // spans the whole test day, forces a real overlap cluster
            ("shortA", 10, 40),   // different time than shortB/shortC, nothing conflicts to its right
            ("shortB", 300, 360), // overlaps shortC, forcing a 3rd column to exist
            ("shortC", 320, 380)
        ]

        let attributes = scenario.enumerated().map { index, item in
            makeAttribute(index: index, minY: item.startY, maxY: item.endY)
        }

        // Act
        layout.adjustItemsForOverlap(
            attributes,
            inSection: 0,
            sectionMinX: 0,
            currentSectionZ: 100,
            resourceIdx: 0,
            sectionWidth: layout.sectionWidth
        )

        // Assert
        assertNoHorizontalIntersectionForOverlappingTime(attributes)
        assertItemFrameInvariants(attributes, sectionMinX: 0, sectionWidth: layout.sectionWidth)

        // The cluster needs 3 simultaneous-overlap columns to place ("long" + one of
        // shortB/shortC always overlap, and shortB/shortC overlap each other), so pure packing
        // alone would give every item 300/3 = 100pt. Derive that column count from the scenario
        // itself (rather than hard-coding "3") and assert it explicitly first, so a future change
        // to the scenario or to packing that produces a different column count fails loudly here
        // instead of leaving the two `LessThanOrEqual` assertions below vacuously true.
        let expectedColumnCount = maxOverlapCount(scenario.map { (start: $0.startY, end: $0.endY) })
        XCTAssertEqual(expectedColumnCount, 3, "scenario's true maximum overlap changed; the width assertions below assume 3 columns")
        let divisionWidth = layout.sectionWidth / CGFloat(expectedColumnCount)
        let shortA = attributes[1]
        let shortB = attributes[2]
        let shortC = attributes[3]

        XCTAssertGreaterThan(
            shortA.frame.width, divisionWidth,
            "shortA has no time-neighbour in the adjacent column and should have expanded past its packed divisionWidth of \(divisionWidth), got \(shortA.frame.width)"
        )
        XCTAssertLessThanOrEqual(shortB.frame.width, divisionWidth + 0.1, "shortB conflicts with shortC and must stay at its packed width")
        XCTAssertLessThanOrEqual(shortC.frame.width, divisionWidth + 0.1, "shortC conflicts with shortB and must stay at its packed width")
    }

    /// FIRE-336 stress test: deterministic pseudo-random (fixed xorshift seed, not random per
    /// run) generation of ~3000 realistic single-column day schedules — start times 07:00-17:00
    /// on a 15-min grid, durations of 15/30/45/60/120/240 minutes, 4-15 events per schedule.
    /// Asserts the same two invariants as the regression case above, plus that every item ends
    /// up with a positive width and stays inside the section.
    ///
    /// Runs the identical seeded schedule set at both a normal (300pt) and a narrow (40pt)
    /// section width — the section width has no bearing on schedule generation, so resetting the
    /// same seed for each width keeps both runs deterministic and exercises the narrow width
    /// against the exact same schedules as the wide one. The narrow width is what reaches the
    /// `min(1, divisionWidth)` floor branch and `toDecimal1Value()`'s rounding-overflow branch in
    /// `adjustItemsForOverlap` (a resource column with many providers, or a deep overlap cluster
    /// packed into few pixels) — neither is reachable at 300pt with only 4-15 events.
    func testAdjustItemsForOverlap_Fire336StressDoesNotHideOrOverlapEvents() {
        for sectionWidth: CGFloat in [300, 40] {
            var seedState: UInt64 = 0x9E3779B97F4A7C15
            func rnd(_ upperBound: Int) -> Int {
                seedState ^= seedState << 13
                seedState ^= seedState >> 7
                seedState ^= seedState << 17
                return Int(seedState % UInt64(upperBound))
            }

            for iteration in 0..<3000 {
                let count = 4 + rnd(12)
                var scenario: [(name: String, startY: CGFloat, endY: CGFloat)] = []
                for i in 0..<count {
                    let start = 420 + rnd(41) * 15           // 07:00 .. 17:00, 15-min grid
                    let duration = [15, 30, 30, 45, 60, 120, 240][rnd(7)]
                    scenario.append(("e\(i)[\(start),\(start + duration)]", CGFloat(start), CGFloat(start + duration)))
                }

                let layout = JZWeekViewFlowLayout()
                layout.sectionWidth = sectionWidth
                let attributes = scenario.enumerated().map { index, item in
                    makeAttribute(index: index, minY: item.startY, maxY: item.endY, fullWidth: sectionWidth - 2)
                }

                layout.adjustItemsForOverlap(
                    attributes,
                    inSection: 0,
                    sectionMinX: 0,
                    currentSectionZ: 100,
                    resourceIdx: 0,
                    sectionWidth: sectionWidth
                )

                assertNoHorizontalIntersectionForOverlappingTime(attributes, iteration: iteration)
                assertItemFrameInvariants(attributes, sectionMinX: 0, sectionWidth: layout.sectionWidth, iteration: iteration)
            }
        }
    }

    /// Computes the maximum number of intervals overlapping at any single instant (the classic
    /// "meeting rooms" sweep-line count), independent of `adjustItemsForOverlap`'s own
    /// greedy-packing implementation. Used to derive an expected column count from a scenario's
    /// raw start/end times, per the method's documented guarantee that a cluster's column count
    /// always equals its true maximum overlap.
    private func maxOverlapCount(_ intervals: [(start: CGFloat, end: CGFloat)]) -> Int {
        var events: [(time: CGFloat, delta: Int)] = []
        for interval in intervals {
            events.append((time: interval.start, delta: 1))
            events.append((time: interval.end, delta: -1))
        }
        // An end at the same instant as a start closes first (touching intervals don't overlap).
        events.sort { lhs, rhs in
            if lhs.time != rhs.time { return lhs.time < rhs.time }
            return lhs.delta < rhs.delta
        }

        var current = 0
        var maxCount = 0
        for event in events {
            current += event.delta
            maxCount = max(maxCount, current)
        }
        return maxCount
    }

    /// Creates a synthetic event attribute with full-width initial frame,
    /// so the test validates only overlap-adjustment behavior. `fullWidth` defaults to 298 (the
    /// production `sectionWidth - 2*itemMargin` for the 300pt width every other test in this file
    /// uses); callers exercising a different section width must pass the matching full width so a
    /// singleton (untouched) item's initial frame still represents a real caller's layout.
    private func makeAttribute(index: Int, minY: CGFloat, maxY: CGFloat, fullWidth: CGFloat = 298) -> UICollectionViewLayoutAttributesResource {
        let indexPath = IndexPath(item: index, section: 0)
        let attribute = UICollectionViewLayoutAttributesResource(forCellWith: indexPath)
        attribute.frame = CGRect(x: 0, y: minY, width: fullWidth, height: maxY - minY)
        attribute.resourceIndex = 0
        return attribute
    }

    /// Asserts invariant of the overlap layout:
    /// if two items overlap in time (Y axis), they must not overlap in horizontal space (X axis).
    private func assertNoHorizontalIntersectionForOverlappingTime(_ attributes: [UICollectionViewLayoutAttributesResource], iteration: Int? = nil, file: StaticString = #filePath, line: UInt = #line) {
        for i in 0..<attributes.count {
            for j in (i + 1)..<attributes.count {
                let first = attributes[i]
                let second = attributes[j]
                guard first.frame.minY < second.frame.maxY && second.frame.minY < first.frame.maxY else {
                    continue
                }

                let horizontalIntersection = min(first.frame.maxX, second.frame.maxX) - max(first.frame.minX, second.frame.minX)
                let iterationPrefix = iteration.map { "iteration \($0): " } ?? ""
                XCTAssertLessThanOrEqual(
                    horizontalIntersection,
                    0.1,
                    "\(iterationPrefix)Overlapping-by-time events must not overlap horizontally. first=\(first.frame), second=\(second.frame)",
                    file: file,
                    line: line
                )
            }
        }
    }

    /// Asserts invariants of the overlap layout that hold by definition and survive rightward
    /// expansion (unlike a fixed "did this item stay near full width" check, which becomes
    /// ambiguous once expansion can legitimately widen an item back toward the full column):
    /// every item ends up with at least the documented `min(1, divisionWidth)` floor width, and
    /// every item's frame stays within the section bounds (0.1pt tolerance for rounding). Both
    /// thresholds are derived from the `sectionMinX`/`sectionWidth` the caller actually used,
    /// never from a literal.
    private func assertItemFrameInvariants(_ attributes: [UICollectionViewLayoutAttributesResource], sectionMinX: CGFloat, sectionWidth: CGFloat, iteration: Int? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let iterationPrefix = iteration.map { "iteration \($0): " } ?? ""

        // A cluster's real divisionWidth is `sectionWidth / columnCount`, and `columnCount` for
        // any cluster is at most the total item count passed in (a cluster can't have more
        // columns than it has items, and a cluster can't have more items than the whole
        // schedule). So `sectionWidth / attributes.count` is always <= the real divisionWidth for
        // every cluster in this call, which makes `min(1, sectionWidth / attributes.count)` a
        // sound (if not always tight) lower bound for `min(1, divisionWidth)` — the floor
        // `adjustItemsForOverlap` documents. A regression to hairline (e.g. 0.2pt) cells fails
        // this bound, which is the FIRE-336 failure mode restated.
        let widthFloor = min(1, sectionWidth / CGFloat(attributes.count))
        for attribute in attributes {
            XCTAssertGreaterThanOrEqual(
                attribute.frame.width, widthFloor,
                "\(iterationPrefix)item \(attribute.indexPath) width \(attribute.frame.width) is below the documented min(1, divisionWidth) floor (bound: \(widthFloor))",
                file: file,
                line: line
            )
            XCTAssertGreaterThanOrEqual(
                attribute.frame.minX, sectionMinX - 0.1,
                "\(iterationPrefix)item \(attribute.indexPath) minX \(attribute.frame.minX) is left of the section",
                file: file,
                line: line
            )
            XCTAssertLessThanOrEqual(
                attribute.frame.maxX, sectionMinX + sectionWidth + 0.1,
                "\(iterationPrefix)item \(attribute.indexPath) maxX \(attribute.frame.maxX) is right of the section",
                file: file,
                line: line
            )
        }
    }
}
