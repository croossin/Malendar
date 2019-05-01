//
//  CVCalendarMonthContentViewController.swift
//  CVCalendar Demo
//
//  Created by Eugene Mozharovsky on 12/04/15.
//  Copyright (c) 2015 GameApp. All rights reserved.
//

import UIKit

public final class CVCalendarMonthContentViewController: CVCalendarContentViewController {
    private var monthViews: [Identifier : MonthView]
    
    public override init(calendarView: CalendarView, frame: CGRect) {
        monthViews = [Identifier : MonthView]()
        super.init(calendarView: calendarView, frame: frame)
        initialLoad(date: presentedMonthView.date)
    }
    
    public init(calendarView: CalendarView, frame: CGRect, presentedDate: NSDate) {
        monthViews = [Identifier : MonthView]()
        super.init(calendarView: calendarView, frame: frame)
        presentedMonthView = MonthView(calendarView: calendarView, date: presentedDate)
        presentedMonthView.updateAppearance(frame: scrollView.bounds)
        initialLoad(date: presentedDate)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Load & Reload
    
    public func initialLoad(date: NSDate) {
        insertMonthView(monthView: getPreviousMonth(date: date), withIdentifier: Previous)
        insertMonthView(monthView: presentedMonthView, withIdentifier: Presented)
        insertMonthView(monthView: getFollowingMonth(date: date), withIdentifier: Following)
        
        presentedMonthView.mapDayViews { dayView in
            if self.calendarView.shouldAutoSelectDayOnMonthChange && self.matchedDays(lhs: dayView.date, Date(date: date)) {
                self.calendarView.coordinator.flush()
                self.calendarView.touchController.receiveTouchOnDayView(dayView: dayView)
                dayView.circleView?.removeFromSuperview()
            }
        }
        
        calendarView.presentedDate = CVDate(date: presentedMonthView.date)
    }
    
    public func reloadMonthViews() {
        for (identifier, monthView) in monthViews {
            monthView.frame.origin.x = CGFloat(indexOfIdentifier(identifier: identifier)) * scrollView.frame.width
            monthView.removeFromSuperview()
            scrollView.addSubview(monthView)
        }
    }
    
    // MARK: - Insertion
    
    public func insertMonthView(monthView: MonthView, withIdentifier identifier: Identifier) {
        let index = CGFloat(indexOfIdentifier(identifier: identifier))
        
        monthView.frame.origin = CGPoint(x: scrollView.bounds.width * index, y: 0)
        monthViews[identifier] = monthView
        scrollView.addSubview(monthView)
    }
    
    public func replaceMonthView(monthView: MonthView, withIdentifier identifier: Identifier, animatable: Bool) {
        var monthViewFrame = monthView.frame
        monthViewFrame.origin.x = monthViewFrame.width * CGFloat(indexOfIdentifier(identifier: identifier))
        monthView.frame = monthViewFrame
        
        monthViews[identifier] = monthView
        
        if animatable {
            scrollView.scrollRectToVisible(monthViewFrame, animated: false)
        }
    }
    
    // MARK: - Load management
    
    public func scrolledLeft() {
        if let presented = monthViews[Presented], let following = monthViews[Following] {
            if pageLoadingEnabled  {
                pageLoadingEnabled = false
                
                monthViews[Previous]?.removeFromSuperview()
                replaceMonthView(monthView: presented, withIdentifier: Previous, animatable: false)
                replaceMonthView(monthView: following, withIdentifier: Presented, animatable: true)
                
                insertMonthView(monthView: getFollowingMonth(date: following.date), withIdentifier: Following)
            }
            
        }
    }
    
    public func scrolledRight() {
        if let previous = monthViews[Previous], let presented = monthViews[Presented] {
            if pageLoadingEnabled  {
                pageLoadingEnabled = false
                
                monthViews[Following]?.removeFromSuperview()
                replaceMonthView(monthView: previous, withIdentifier: Presented, animatable: true)
                replaceMonthView(monthView: presented, withIdentifier: Following, animatable: false)
                
                insertMonthView(monthView: getPreviousMonth(date: previous.date), withIdentifier: Previous)
            }
        }
    }
    
    // MARK: - Override methods
    
    public override func updateFrames(frame rect: CGRect) {
        super.updateFrames(frame: rect)
        
        for monthView in monthViews.values {
            monthView.reloadViewsWithRect(frame: rect != CGRect.zero ? rect : scrollView.bounds)
        }
        
        reloadMonthViews()

        if let presented = monthViews[Presented] {
            if scrollView.frame.height != presented.potentialSize.height {
                updateHeight(height: presented.potentialSize.height, animated: false)
            }
            
            scrollView.scrollRectToVisible(presented.frame, animated: false)
        }
    }
    
    public override func performedDayViewSelection(dayView: DayView) {
        if dayView.isOut {
            if dayView.date.day > 20 {
                let presentedDate = dayView.monthView.date
                calendarView.presentedDate = Date(date: self.dateBeforeDate(date: presentedDate ?? <#default value#>))
                presentPreviousView(dayView)
            } else {
                let presentedDate = dayView.monthView.date
                calendarView.presentedDate = Date(date: self.dateAfterDate(date: presentedDate ?? <#default value#>))
                presentNextView(dayView)
            }
        }
    }
    
    public override func presentPreviousView(view: UIView?) {
        if presentationEnabled {
            presentationEnabled = false
            if let extra = monthViews[Following], let presented = monthViews[Presented], let previous = monthViews[Previous] {
                UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.CurveEaseInOut, animations: {
                    self.prepareTopMarkersOnMonthView(monthView: presented, hidden: true)
                    
                    extra.frame.origin.x += self.scrollView.frame.width
                    presented.frame.origin.x += self.scrollView.frame.width
                    previous.frame.origin.x += self.scrollView.frame.width
                    
                    self.replaceMonthView(monthView: presented, withIdentifier: self.Following, animatable: false)
                    self.replaceMonthView(monthView: previous, withIdentifier: self.Presented, animatable: false)
                    self.presentedMonthView = previous
                    
                    self.updateLayoutIfNeeded()
                }) { _ in
                    extra.removeFromSuperview()
                    self.insertMonthView(monthView: self.getPreviousMonth(date: previous.date), withIdentifier: self.Previous)
                    self.updateSelection()
                    self.presentationEnabled = true
                    
                    for monthView in self.monthViews.values {
                        self.prepareTopMarkersOnMonthView(monthView: monthView, hidden: false)
                    }
                }
            }
        }
    }
    
    public override func presentNextView(view: UIView?) {
        if presentationEnabled {
            presentationEnabled = false
            if let extra = monthViews[Previous], let presented = monthViews[Presented], let following = monthViews[Following] {
                UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.CurveEaseInOut, animations: {
                    self.prepareTopMarkersOnMonthView(monthView: presented, hidden: true)
                    
                    extra.frame.origin.x -= self.scrollView.frame.width
                    presented.frame.origin.x -= self.scrollView.frame.width
                    following.frame.origin.x -= self.scrollView.frame.width
                    
                    self.replaceMonthView(monthView: presented, withIdentifier: self.Previous, animatable: false)
                    self.replaceMonthView(monthView: following, withIdentifier: self.Presented, animatable: false)
                    self.presentedMonthView = following
                    
                    self.updateLayoutIfNeeded()
                }) { _ in
                    extra.removeFromSuperview()
                    self.insertMonthView(monthView: self.getFollowingMonth(date: following.date), withIdentifier: self.Following)
                    self.updateSelection()
                    self.presentationEnabled = true
                    
                    for monthView in self.monthViews.values {
                        self.prepareTopMarkersOnMonthView(monthView: monthView, hidden: false)
                    }
                }
            }
        }
    }
    
    public override func updateDayViews(hidden: Bool) {
        setDayOutViewsVisible(visible: hidden)
    }
    
    private var togglingBlocked = false
    public override func togglePresentedDate(date: NSDate) {
        let presentedDate = Date(date: date)
        if let presented = monthViews[Presented], let selectedDate = calendarView.coordinator.selectedDayView?.date {
            if !matchedDays(lhs: selectedDate, presentedDate) && !togglingBlocked {
                if !matchedMonths(lhs: presentedDate, selectedDate) {
                    togglingBlocked = true
                    
                    monthViews[Previous]?.removeFromSuperview()
                    monthViews[Following]?.removeFromSuperview()
                    insertMonthView(monthView: getPreviousMonth(date: date), withIdentifier: Previous)
                    insertMonthView(monthView: getFollowingMonth(date: date), withIdentifier: Following)
                    
                    let currentMonthView = MonthView(calendarView: calendarView, date: date)
                    currentMonthView.updateAppearance(frame: scrollView.bounds)
                    currentMonthView.alpha = 0
                    
                    insertMonthView(monthView: currentMonthView, withIdentifier: Presented)
                    presentedMonthView = currentMonthView
                    
                    calendarView.presentedDate = Date(date: date)
                    
                    UIView.animate(withDuration: 0.8, delay: 0, options: UIView.AnimationOptions.CurveEaseInOut, animations: {
                        presented.alpha = 0
                        currentMonthView.alpha = 1
                    }) { _ in
                        presented.removeFromSuperview()
                        self.selectDayViewWithDay(day: presentedDate.day, inMonthView: currentMonthView)
                        self.togglingBlocked = false
                        self.updateLayoutIfNeeded()
                    }
                } else {
                    if let currentMonthView = monthViews[Presented] {
                        selectDayViewWithDay(day: presentedDate.day, inMonthView: currentMonthView)
                    }
                }
            }
        }
    }
}

// MARK: - Month management

extension CVCalendarMonthContentViewController {
    public func getFollowingMonth(date: NSDate) -> MonthView {
        let firstDate = calendarView.manager.monthDateRange(date: date).monthStartDate
        let components = Manager.componentsForDate(date: firstDate)
        
        components.month += 1
        
        let newDate = NSCalendar.currentCalendar.dateComponents(components)!
        let frame = scrollView.bounds
        let monthView = MonthView(calendarView: calendarView, date: newDate)
        
        monthView.updateAppearance(frame)
        
        return monthView
    }
    
    public func getPreviousMonth(date: NSDate) -> MonthView {
        let firstDate = calendarView.manager.monthDateRange(date: date).monthStartDate
        let components = Manager.componentsForDate(date: firstDate)
        
        components.month -= 1
        
        let newDate = NSCalendar.currentCalendar.dateComponents(components)!
        let frame = scrollView.bounds
        let monthView = MonthView(calendarView: calendarView, date: newDate)
        
        monthView.updateAppearance(frame)
        
        return monthView
    }
}

// MARK: - Visual preparation

extension CVCalendarMonthContentViewController {
    public func prepareTopMarkersOnMonthView(monthView: MonthView, hidden: Bool) {
        monthView.mapDayViews { dayView in
            dayView.topMarker?.isHidden = hidden
        }
    }
    
    public func setDayOutViewsVisible(visible: Bool) {
        for monthView in monthViews.values {
            monthView.mapDayViews { dayView in
                if dayView.isOut {
                    if !visible {
                        dayView.alpha = 0
                        dayView.isHidden = false
                    }
                    
                    UIView.animate(withDuration: 0.5, delay: 0, options: UIView.AnimationOptions.CurveEaseInOut, animations: {
                        dayView.alpha = visible ? 0 : 1
                        }) { _ in
                            if visible {
                                dayView.alpha = 1
                                dayView.isHidden = true
                                dayView.isUserInteractionEnabled = false
                            } else {
                                dayView.isUserInteractionEnabled = true
                            }
                    }
                }
            }
        }
    }
    
    public func updateSelection() {
        let coordinator = calendarView.coordinator
        if let selected = coordinator?.selectedDayView {
            for (index, monthView) in monthViews {
                if indexOfIdentifier(identifier: index) != 1 {
                    monthView.mapDayViews {
                        dayView in
                        
                        if dayView == selected {
                            dayView.setDeselectedWithClearing(clearing: true)
                            coordinator?.dequeueDayView(dayView: dayView)
                        }
                    }
                }
            }
        }
        
        if let presentedMonthView = monthViews[Presented] {
            self.presentedMonthView = presentedMonthView
            calendarView.presentedDate = Date(date: presentedMonthView.date)
            
            if let selected = coordinator?.selectedDayView, let selectedMonthView = selected.monthView, !matchedMonths(lhs: Date(date: selectedMonthView.date), Date(date: presentedMonthView.date)) && calendarView.shouldAutoSelectDayOnMonthChange {
                let current = Date(date: NSDate())
                let presented = Date(date: presentedMonthView.date)
                
                if matchedMonths(lhs: current, presented) {
                    selectDayViewWithDay(day: current.day, inMonthView: presentedMonthView)
                } else {
                    selectDayViewWithDay(day: Date(date: calendarView.manager.monthDateRange(date: presentedMonthView.date).monthStartDate).day, inMonthView: presentedMonthView)
                }
            }
        }
        
    }
    
    public func selectDayViewWithDay(day: Int, inMonthView monthView: CVCalendarMonthView) {
        let coordinator = calendarView.coordinator
        monthView.mapDayViews { dayView in
            if dayView.date.day == day && !dayView.isOut {
                if let selected = coordinator?.selectedDayView, selected != dayView {
                    self.calendarView.didSelectDayView(dayView: dayView)
                }
                
                coordinator?.performDayViewSingleSelection(dayView: dayView)
            }
        }
    }
}

// MARK: - UIScrollViewDelegate

extension CVCalendarMonthContentViewController {
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
        }
        
        let page = Int(floor((scrollView.contentOffset.x - scrollView.frame.width / 2) / scrollView.frame.width) + 1)
        if currentPage != page {
            currentPage = page
        }
        
        lastContentOffset = scrollView.contentOffset.x
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if let presented = monthViews[Presented] {
            prepareTopMarkersOnMonthView(monthView: presented, hidden: true)
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if pageChanged {
            switch direction {
            case .Left: scrolledLeft()
            case .Right: scrolledRight()
            default: break
            }
        }
        
        updateSelection()
        updateLayoutIfNeeded()
        pageLoadingEnabled = true
        direction = .None
        
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            let rightBorder = scrollView.frame.width
            if scrollView.contentOffset.x <= rightBorder {
                direction = .Right
            } else  {
                direction = .Left
            }
        }
        
        for monthView in monthViews.values {
            prepareTopMarkersOnMonthView(monthView: monthView, hidden: false)
        }
    }
}
