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

    /// Creates a synthetic event attribute with full-width initial frame,
    /// so the test validates only overlap-adjustment behavior.
    private func makeAttribute(index: Int, minY: CGFloat, maxY: CGFloat) -> UICollectionViewLayoutAttributesResource {
        let indexPath = IndexPath(item: index, section: 0)
        let attribute = UICollectionViewLayoutAttributesResource(forCellWith: indexPath)
        attribute.frame = CGRect(x: 0, y: minY, width: 298, height: maxY - minY)
        attribute.resourceIndex = 0
        return attribute
    }

    /// Asserts invariant of the overlap layout:
    /// if two items overlap in time (Y axis), they must not overlap in horizontal space (X axis).
    private func assertNoHorizontalIntersectionForOverlappingTime(_ attributes: [UICollectionViewLayoutAttributesResource], file: StaticString = #filePath, line: UInt = #line) {
        for i in 0..<attributes.count {
            for j in (i + 1)..<attributes.count {
                let first = attributes[i]
                let second = attributes[j]
                guard first.frame.minY < second.frame.maxY && second.frame.minY < first.frame.maxY else {
                    continue
                }

                let horizontalIntersection = min(first.frame.maxX, second.frame.maxX) - max(first.frame.minX, second.frame.minX)
                XCTAssertLessThanOrEqual(
                    horizontalIntersection,
                    0.1,
                    "Overlapping-by-time events must not overlap horizontally. first=\(first.frame), second=\(second.frame)",
                    file: file,
                    line: line
                )
            }
        }
    }
}
