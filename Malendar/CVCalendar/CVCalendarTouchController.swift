//
//  CVCalendarTouchController.swift
//  CVCalendar Demo
//
//  Created by Eugene Mozharovsky on 17/03/15.
//  Copyright (c) 2015 GameApp. All rights reserved.
//

import UIKit

public final class CVCalendarTouchController {
    private unowned let calendarView: CalendarView
    
    // MARK: - Properties
    public var coordinator: Coordinator {
        get {
            return calendarView.coordinator
        }
    }
    
    /// Init.
    public init(calendarView: CalendarView) {
        self.calendarView = calendarView
    }
}

// MARK: - Events receive 

extension CVCalendarTouchController {
    public func receiveTouchLocation(location: CGPoint, inMonthView monthView: CVCalendarMonthView, withSelectionType selectionType: CVSelectionType) {
        let weekViews = monthView.weekViews
        if let dayView = ownerTouchLocation(location: location, onMonthView: monthView), dayView.isUserInteractionEnabled {
            receiveTouchOnDayView(dayView: dayView, withSelectionType: selectionType)
        }
    }
    
    public func receiveTouchLocation(location: CGPoint, inWeekView weekView: CVCalendarWeekView, withSelectionType selectionType: CVSelectionType) {
        let monthView = weekView.monthView
        let index = weekView.index
        let weekViews = monthView?.weekViews
        
        if let dayView = ownerTouchLocation(location: location, onWeekView: weekView), dayView.isUserInteractionEnabled {
            receiveTouchOnDayView(dayView: dayView, withSelectionType: selectionType)
        }
    }
    
    public func receiveTouchOnDayView(dayView: CVCalendarDayView) {
        coordinator.performDayViewSingleSelection(dayView: dayView)
    }
}

// MARK: - Events management 

private extension CVCalendarTouchController {
    func receiveTouchOnDayView(dayView: CVCalendarDayView, withSelectionType selectionType: CVSelectionType) {
        if let calendarView = dayView.weekView.monthView.calendarView {
            switch selectionType {
            case .Single:
                coordinator.performDayViewSingleSelection(dayView: dayView)
                calendarView.didSelectDayView(dayView: dayView)
                
            case let .Range(.Started):
                print("Received start of range selection.")
            case let .Range(.Changed):
                print("Received change of range selection.")
            case let .Range(.Ended):
                print("Received end of range selection.")
            default: break
            }
        }
        

    }

    func monthViewLocation(location: CGPoint, doesBelongToDayView dayView: CVCalendarDayView) -> Bool {
        var dayViewFrame = dayView.frame
        let weekIndex = dayView.weekView.index
        let appearance = dayView.calendarView.appearance
        
        if weekIndex ?? 0 > 0 {
            dayViewFrame.origin.y += dayViewFrame.height
            dayViewFrame.origin.y *= CGFloat(dayView.weekView.index)
        }
        
        if dayView != dayView.weekView.dayViews!.first! {
            dayViewFrame.origin.y += (appearance?.spaceBetweenWeekViews!)! * CGFloat(weekIndex)
        }
        
        if location.x >= dayViewFrame.origin.x && location.x <= dayViewFrame.maxX && location.y >= dayViewFrame.origin.y && location.y <= dayViewFrame.maxY {
            return true
        } else {
            return false
        }
    }
    
    func weekViewLocation(location: CGPoint, doesBelongToDayView dayView: CVCalendarDayView) -> Bool {
        let dayViewFrame = dayView.frame
        if location.x >= dayViewFrame.origin.x && location.x <= dayViewFrame.maxX && location.y >= dayViewFrame.origin.y && location.y <= dayViewFrame.maxY {
            return true
        } else {
            return false
        }
    }
    
    func ownerTouchLocation(location: CGPoint, onMonthView monthView: CVCalendarMonthView) -> DayView? {
        var owner: DayView?
        guard let weekViews = monthView.weekViews else { return nil}
        
        for weekView in weekViews {
            for dayView in weekView.dayViews! {
                if self.monthViewLocation(location: location, doesBelongToDayView: dayView) {
                    owner = dayView
                    return owner
                }
            }
        }

        
        return owner
    }
    
    func ownerTouchLocation(location: CGPoint, onWeekView weekView: CVCalendarWeekView) -> DayView? {
        var owner: DayView?
        guard let dayViews = weekView.dayViews else { return nil }
        for dayView in dayViews {
            if weekViewLocation(location: location, doesBelongToDayView: dayView) {
                owner = dayView
                return owner
            }
        }
        
        return owner
    }
}
