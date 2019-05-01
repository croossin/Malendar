//
//  CVCalendarViewDelegate.swift
//  CVCalendar
//
//  Created by E. Mozharovsky on 12/27/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

@objc
public protocol CVCalendarViewDelegate {
    func presentationMode() -> CalendarMode
    func firstWeekday() -> Weekday
    
    /**
    Determines whether resizing should cause related views' animation.
    */
    @objc optional func shouldAnimateResizing() -> Bool
    
    @objc optional func shouldAutoSelectDayOnWeekChange() -> Bool
    @objc optional func shouldAutoSelectDayOnMonthChange() -> Bool
    @objc optional func shouldShowWeekdaysOut() -> Bool
    @objc optional func didSelectDayView(dayView: DayView)
    @objc optional func presentedDateUpdated(date: Date)
    @objc optional func topMarker(shouldDisplayOnDayView dayView: DayView) -> Bool
    @objc optional func dotMarker(shouldMoveOnHighlightingOnDayView dayView: DayView) -> Bool
    @objc optional func dotMarker(shouldShowOnDayView dayView: DayView) -> Bool
    @objc optional func dotMarker(colorOnDayView dayView: DayView) -> [UIColor]
    @objc optional func dotMarker(moveOffsetOnDayView dayView: DayView) -> CGFloat
    @objc optional func dotMarker(sizeOnDayView dayView: DayView) -> CGFloat

    @objc optional func preliminaryView(viewOnDayView dayView: DayView) -> UIView
    @objc optional func preliminaryView(shouldDisplayOnDayView dayView: DayView) -> Bool
    
    @objc optional func supplementaryView(viewOnDayView dayView: DayView) -> UIView
    @objc optional func supplementaryView(shouldDisplayOnDayView dayView: DayView) -> Bool
}
