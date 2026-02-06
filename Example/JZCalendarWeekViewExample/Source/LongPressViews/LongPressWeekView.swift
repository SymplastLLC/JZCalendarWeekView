//
//  LongPressWeekView.swift
//  JZCalendarWeekViewExample
//
//  Created by Jeff Zhang on 30/4/18.
//  Copyright © 2018 Jeff Zhang. All rights reserved.
//

import UIKit
import JZCalendarWeekView

/// All-Day & Long Press
class LongPressWeekView: JZLongPressWeekView {

    override func registerViewClasses() {
        super.registerViewClasses()

        self.collectionView.register(UINib(nibName: LongPressEventCell.className, bundle: nil), forCellWithReuseIdentifier: LongPressEventCell.className)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LongPressEventCell.className, for: indexPath) as? LongPressEventCell,
            let event = getCurrentEvent(with: indexPath) as? AllDayEvent {
            cell.configureCell(event: event)
            return cell
        }
        preconditionFailure("LongPressEventCell and AllDayEvent should be casted")
    }
    
    override func collectionView(_ collectionView: UICollectionView, colorForOutsideScreenDecorationViewAt indexPath: IndexPath) -> UIColor? {
        let event = getCurrentEvent(with: indexPath)
        
        if event?.id == "0" {
            return .systemYellow
        } else if event?.id == "1" {
            return .systemRed
        } else if event?.id == "11" {
            return .systemBrown
        } else if event?.id == "2" {
            return .systemCyan
        } else if event?.id == "12" {
            return .systemOrange
        } else if event?.id == "3" {
            return .systemMint
        }
        return UIColor(hex: 0x0899FF)
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == JZSupplementaryViewKinds.allDayHeader {
            guard let alldayHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kind, for: indexPath) as? JZAllDayHeader else {
                preconditionFailure("SupplementaryView should be JZAllDayHeader")
            }
            let date = flowLayout.dateForColumnHeader(at: indexPath)
            let events = allDayEventsBySection[date]
            let views = getAllDayHeaderViews(allDayEvents: events as? [AllDayEvent] ?? [])
            alldayHeader.updateView(views: views)
            return alldayHeader
        }
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }

    private func getAllDayHeaderViews(allDayEvents: [AllDayEvent]) -> [UIView] {
        var allDayViews = [UIView]()
        for event in allDayEvents {
            if let view = UINib(nibName: LongPressEventCell.className, bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? LongPressEventCell {
                view.configureCell(event: event, isAllDay: true)
                allDayViews.append(view)
            }
        }
        return allDayViews
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let selectedEvent = getCurrentEvent(with: indexPath) as? AllDayEvent {
            ToastUtil.toastMessageInTheMiddle(message: selectedEvent.title + "\(selectedEvent.startDate) - \(selectedEvent.endDate)")
        }
    }
}
