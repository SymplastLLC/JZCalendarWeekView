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
        )
    ]
    
    lazy var eventsByDate = JZWeekViewHelper.getIntraEventsByDate(originalEvents: events)

    var currentSelectedData: OptionsSelectedData!
}
