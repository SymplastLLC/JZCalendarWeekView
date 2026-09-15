//
//  DefaultViewModel.swift
//  JZCalendarViewExample
//
//  Created by Jeff Zhang on 3/4/18.
//  Copyright © 2018 Jeff Zhang. All rights reserved.
//

import UIKit
import JZCalendarWeekView

class DefaultViewModel: NSObject {

    private let firstDate = Date().add(component: .hour, value: 1)
    private let secondDate = Date().add(component: .day, value: 1)
    private let thirdDate = Date().add(component: .day, value: 2)

    // FIRE-336 repro day: a burst of short 7:30 appointments alongside one tall 7:30-12:00
    // appointment, plus several 11:00 appointments that sit fully inside the tall one's
    // time span. Under the pre-fix overlap algorithm the 11:00 events could end up unplaced
    // at full column width with the lowest zIndex, painted underneath the tall event and
    // therefore invisible. With the interval-graph column-packing fix, every event in this
    // cluster must render side by side and be fully visible.
    private let fire336Day = Date().add(component: .day, value: 3)

    // Overlap-expansion demo day: a full working-day block plus isolated short appointments
    // that have no time-neighbour to their right, and one small pair that does overlap each
    // other. Demonstrates the rightward-expansion pass: events with free space to their right
    // should stretch wide instead of being squeezed to a uniform 1/N column width.
    private let expansionDemoDay = Date().add(component: .day, value: 4)

    private func makeEvent(id: String, title: String, day: Date, startHour: Int, startMinute: Int,
                            durationMinutes: Int, location: String) -> DefaultEvent {
        let start = Calendar.current.date(bySettingHour: startHour, minute: startMinute, second: 0, of: day)!
        let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return DefaultEvent(id: id, title: title, startDate: start, endDate: end, location: location)
    }

    private lazy var fire336Events: [DefaultEvent] = {
        var events = (1...5).map { index in
            makeEvent(id: "fire336-730-\(index)", title: "7:30 #\(index)", day: fire336Day,
                      startHour: 7, startMinute: 30, durationMinutes: 30, location: "Room \(index)")
        }
        events.append(makeEvent(id: "fire336-tall", title: "Tall 7:30-12:00", day: fire336Day,
                                 startHour: 7, startMinute: 30, durationMinutes: 270, location: "Main Theatre"))
        events.append(contentsOf: (1...3).map { index in
            makeEvent(id: "fire336-1100-\(index)", title: "11:00 #\(index)", day: fire336Day,
                      startHour: 11, startMinute: 0, durationMinutes: 30, location: "Room \(index + 5)")
        })
        return events
    }()

    private lazy var expansionDemoEvents: [DefaultEvent] = {
        var events = [makeEvent(id: "expansion-full-day", title: "Full Day 8:00-18:00", day: expansionDemoDay,
                                 startHour: 8, startMinute: 0, durationMinutes: 600, location: "Main Theatre")]
        let isolated: [(hour: Int, minute: Int, title: String)] = [
            (9, 0, "Isolated 9:00"),
            (13, 0, "Isolated 13:00"),
            (16, 30, "Isolated 16:30")
        ]
        events.append(contentsOf: isolated.map { slot in
            makeEvent(id: "expansion-isolated-\(slot.hour)-\(slot.minute)", title: slot.title, day: expansionDemoDay,
                      startHour: slot.hour, startMinute: slot.minute, durationMinutes: 30, location: "Consult Room")
        })
        events.append(contentsOf: (1...2).map { index in
            makeEvent(id: "expansion-pair-\(index)", title: "Pair #\(index)", day: expansionDemoDay,
                      startHour: 14, startMinute: 0, durationMinutes: 45, location: "Room \(index)")
        })
        return events
    }()

    lazy var events: [DefaultEvent] = [
        DefaultEvent(id: "0", title: "One", startDate: firstDate, endDate: firstDate.add(component: .hour, value: 1), location: "Melbourne"),
        DefaultEvent(id: "1", title: "Two", startDate: secondDate, endDate: secondDate.add(component: .hour, value: 4), location: "Sydney"),
        DefaultEvent(id: "2", title: "Three", startDate: thirdDate, endDate: thirdDate.add(component: .hour, value: 2), location: "Tasmania"),
        DefaultEvent(id: "3", title: "Four", startDate: thirdDate, endDate: thirdDate.add(component: .hour, value: 26), location: "Canberra")
    ] + fire336Events + expansionDemoEvents

    lazy var eventsByDate = JZWeekViewHelper.getIntraEventsByDate(originalEvents: events)

    var currentSelectedData: OptionsSelectedData!
}
