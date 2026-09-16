//
//  AllDayViewModel.swift
//  JZCalendarWeekViewExample
//
//  Created by Jeff Zhang on 30/5/18.
//  Copyright © 2018 Jeff Zhang. All rights reserved.
//

import Foundation
import JZCalendarWeekView

class AllDayViewModel: NSObject {

    private let firstDate = Date().add(component: .hour, value: 1)
    private let secondDate = Date().add(component: .day, value: 1)
    private let thirdDate = Date().add(component: .day, value: 2)

    lazy var events = [
        // ----------------------------------------------------------------------------------------------
        // to test the issue https://linear.app/symplast/issue/EFF-250/appt-cut-off-on-calendar-vip-suria
        AllDayEvent(
            id: "0",
            title: "One-0",
            startDate: firstDate,
            endDate: firstDate.add(component: .hour, value: 1),
            location: "Melbourne",
            isAllDay: false
        ),
        AllDayEvent(
            id: "0-1",
            title: "One-1",
            startDate: firstDate,
            endDate: firstDate.add(component: .minute, value: 30),
            location: "Melbourne-1",
            isAllDay: false
        ),
        // half of this event under One-0
        AllDayEvent(
            id: "0-11",
            title: "One-1.1",
            startDate: firstDate.add(component: .minute, value: 30),
            endDate: firstDate.add(component: .minute, value: 90),
            location: "Melbourne-1.1",
            isAllDay: false
        ),
        AllDayEvent(
            id: "0-2",
            title: "One-2",
            startDate: firstDate.add(component: .hour, value: 1),
            endDate: firstDate.add(component: .hour, value: 2),
            location: "Melbourne-2",
            isAllDay: false
        ),
        AllDayEvent(
            id: "0-3",
            title: "One-3",
            startDate: firstDate.add(component: .minute, value: 60),
            endDate: firstDate.add(component: .minute, value: 90),
            location: "Melbourne-3",
            isAllDay: false
        ),
        // --------------------------------------------------------------------------------------------
        AllDayEvent(
            id: "1",
            title: "Two",
            startDate: secondDate.add(component: .hour, value: -2),
            endDate: secondDate.add(component: .hour, value: -1),
            location: "Sydney",
            isAllDay: false
        ),
        AllDayEvent(
            id: "12",
            title: "Two-2",
            startDate: secondDate.add(component: .hour, value: -1),
            endDate: secondDate.add(component: .hour, value: 1),
            location: "Sydney",
            isAllDay: false
        ),
        AllDayEvent(
            id: "11",
            title: "Two-1",
            startDate: secondDate,
            endDate: secondDate.add(component: .hour, value: 4),
            location: "Sydney",
            isAllDay: false
        ),
        AllDayEvent(
            id: "2",
            title: "Three",
            startDate: thirdDate.add(component: .hour, value: -1),
            endDate: thirdDate,
            location: "Tasmania",
            isAllDay: false
        ),
        AllDayEvent(
            id: "3",
            title: "Four",
            startDate: thirdDate,
            endDate: thirdDate.add(component: .hour, value: 26),
            location: "Canberra",
            isAllDay: false
        ),
        AllDayEvent(
            id: "4",
            title: "AllDay1",
            startDate: firstDate.startOfDay,
            endDate: firstDate.startOfDay,
            location: "Gold Coast",
            isAllDay: true
        ),
        AllDayEvent(
            id: "5",
            title: "AllDay2",
            startDate: firstDate.startOfDay,
            endDate: firstDate.startOfDay,
            location: "Adelaide",
            isAllDay: true
        ),
        AllDayEvent(
            id: "6",
            title: "AllDay3",
            startDate: firstDate.startOfDay,
            endDate: firstDate.startOfDay,
            location: "Cairns",
            isAllDay: true
        ),
        AllDayEvent(
            id: "7",
            title: "AllDay4",
            startDate: thirdDate.startOfDay,
            endDate: thirdDate.startOfDay,
            location: "Brisbane",
            isAllDay: true
        ),
        // ----------------------------------------------------------------------------------------------
        // to test the issue https://linear.app/symplast/issue/FIRE-336/appts-not-showing-up-on-schedule-when-setting-location-to-all
        // a burst of short 7:30 appointments alongside one tall 7:30-12:00 appointment, plus several
        // 11:00 appointments that sit fully inside the tall one's time span; before the fix the 11:00
        // ones were painted underneath the tall event and invisible
        AllDayEvent(
            id: "fire336-730-1",
            title: "7:30 #1",
            startDate: fire336StartOfDay(hour: 7, minute: 30),
            endDate: fire336StartOfDay(hour: 8, minute: 0),
            location: "Room 1",
            isAllDay: false
        ),
        AllDayEvent(
            id: "fire336-730-2",
            title: "7:30 #2",
            startDate: fire336StartOfDay(hour: 7, minute: 30),
            endDate: fire336StartOfDay(hour: 8, minute: 0),
            location: "Room 2",
            isAllDay: false
        ),
        AllDayEvent(
            id: "fire336-730-3",
            title: "7:30 #3",
            startDate: fire336StartOfDay(hour: 7, minute: 30),
            endDate: fire336StartOfDay(hour: 8, minute: 0),
            location: "Room 3",
            isAllDay: false
        ),
        AllDayEvent(
            id: "fire336-730-4",
            title: "7:30 #4",
            startDate: fire336StartOfDay(hour: 7, minute: 30),
            endDate: fire336StartOfDay(hour: 8, minute: 0),
            location: "Room 4",
            isAllDay: false
        ),
        AllDayEvent(
            id: "fire336-730-5",
            title: "7:30 #5",
            startDate: fire336StartOfDay(hour: 7, minute: 30),
            endDate: fire336StartOfDay(hour: 8, minute: 0),
            location: "Room 5",
            isAllDay: false
        ),
        AllDayEvent(
            id: "fire336-tall",
            title: "Tall 7:30-12:00",
            startDate: fire336StartOfDay(hour: 7, minute: 30),
            endDate: fire336StartOfDay(hour: 12, minute: 0),
            location: "Main Theatre",
            isAllDay: false
        ),
        AllDayEvent(
            id: "fire336-1100-1",
            title: "11:00 #1",
            startDate: fire336StartOfDay(hour: 11, minute: 0),
            endDate: fire336StartOfDay(hour: 11, minute: 30),
            location: "Room 6",
            isAllDay: false
        ),
        AllDayEvent(
            id: "fire336-1100-2",
            title: "11:00 #2",
            startDate: fire336StartOfDay(hour: 11, minute: 0),
            endDate: fire336StartOfDay(hour: 11, minute: 30),
            location: "Room 7",
            isAllDay: false
        ),
        AllDayEvent(
            id: "fire336-1100-3",
            title: "11:00 #3",
            startDate: fire336StartOfDay(hour: 11, minute: 0),
            endDate: fire336StartOfDay(hour: 11, minute: 30),
            location: "Room 8",
            isAllDay: false
        ),
        // ----------------------------------------------------------------------------------------------
        // to test the issue https://linear.app/symplast/issue/FIRE-336/appts-not-showing-up-on-schedule-when-setting-location-to-all
        // a full working-day block plus isolated short appointments with no time-neighbour to their
        // right, and one overlapping pair; events with free space to their right should stretch wide
        // instead of being squeezed to a uniform 1/N column width
        AllDayEvent(
            id: "expansion-full-day",
            title: "Full Day 8:00-18:00",
            startDate: expansionStartOfDay(hour: 8, minute: 0),
            endDate: expansionStartOfDay(hour: 18, minute: 0),
            location: "Main Theatre",
            isAllDay: false
        ),
        AllDayEvent(
            id: "expansion-isolated-9",
            title: "Isolated 9:00",
            startDate: expansionStartOfDay(hour: 9, minute: 0),
            endDate: expansionStartOfDay(hour: 9, minute: 30),
            location: "Consult Room",
            isAllDay: false
        ),
        AllDayEvent(
            id: "expansion-isolated-13",
            title: "Isolated 13:00",
            startDate: expansionStartOfDay(hour: 13, minute: 0),
            endDate: expansionStartOfDay(hour: 13, minute: 30),
            location: "Consult Room",
            isAllDay: false
        ),
        AllDayEvent(
            id: "expansion-isolated-1630",
            title: "Isolated 16:30",
            startDate: expansionStartOfDay(hour: 16, minute: 30),
            endDate: expansionStartOfDay(hour: 17, minute: 0),
            location: "Consult Room",
            isAllDay: false
        ),
        AllDayEvent(
            id: "expansion-pair-1",
            title: "Pair #1",
            startDate: expansionStartOfDay(hour: 14, minute: 0),
            endDate: expansionStartOfDay(hour: 14, minute: 45),
            location: "Room 1",
            isAllDay: false
        ),
        AllDayEvent(
            id: "expansion-pair-2",
            title: "Pair #2",
            startDate: expansionStartOfDay(hour: 14, minute: 0),
            endDate: expansionStartOfDay(hour: 14, minute: 45),
            location: "Room 2",
            isAllDay: false
        )
        // ----------------------------------------------------------------------------------------------
    ]

    lazy var eventsByDate = JZWeekViewHelper.getIntraEventsByDate(originalEvents: events)

    var currentSelectedData: OptionsSelectedData!

    private func fire336StartOfDay(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: thirdDate)!
    }

    private func expansionStartOfDay(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date().add(component: .day, value: 3))!
    }
}
