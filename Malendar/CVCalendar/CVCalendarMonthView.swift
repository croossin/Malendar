//
//  CVCalendarMonthView.swift
//  CVCalendar
//
//  Created by E. Mozharovsky on 12/26/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

public final class CVCalendarMonthView: UIView {
    // MARK: - Non public properties
    private var interactiveView: UIView!
    
    public override var frame: CGRect {
        didSet {
            if let calendarView = calendarView {
                if calendarView.calendarMode == CalendarMode.MonthView {
                    updateInteractiveView()
                }
            }
        }
    }
    
    private var touchController: CVCalendarTouchController {
        return calendarView.touchController
    }
    
    // MARK: - Public properties
    
    public weak var calendarView: CVCalendarView!
    public var date: NSDate!
    public var numberOfWeeks: Int!
    public var weekViews: [CVCalendarWeekView]!
    
    public var weeksIn: [[Int : [Int]]]?
    public var weeksOut: [[Int : [Int]]]?
    public var currentDay: Int?
    
    public var potentialSize: CGSize {
        get {
            return CGSize(width: bounds.width, height: CGFloat(weekViews.count) * weekViews[0].bounds.height + calendarView.appearance.spaceBetweenWeekViews! * CGFloat(weekViews.count))
        }
    }
    
    // MARK: - Initialization
    
    public init(calendarView: CVCalendarView, date: NSDate) {
        super.init(frame: CGRect.zero)
        self.calendarView = calendarView
        self.date = date
        commonInit()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func mapDayViews(body: (DayView) -> Void) {
        for weekView in self.weekViews {
            for dayView in weekView.dayViews {
                body(dayView)
            }
        }
    }
}

// MARK: - Creation and destruction

extension CVCalendarMonthView {
    public func commonInit() {
        let calendarManager = calendarView.manager
        safeExecuteBlock(block: {
            self.numberOfWeeks = calendarManager?.monthDateRange(date: self.date).countOfWeeks
            self.weeksIn = calendarManager?.weeksWithWeekdaysForMonthDate(date: self.date).weeksIn
            self.weeksOut = calendarManager?.weeksWithWeekdaysForMonthDate(date: self.date).weeksOut
            self.currentDay = Manager.dateRange(date: NSDate()).day
            }, collapsingOnNil: true, withObjects: date)
    }
}

// MARK: Content reload

extension CVCalendarMonthView {
    public func reloadViewsWithRect(frame: CGRect) {
        self.frame = frame
        
        safeExecuteBlock(block: {
            for (index, weekView) in self.weekViews.enumerate() {
                if let size = self.calendarView.weekViewSize {
                    weekView.frame = CGRect(0, size.height * CGFloat(index), size.width, size.height)
                    weekView.reloadDayViews()
                }
            }
        }, collapsingOnNil: true, withObjects: weekViews as AnyObject?)
    }
}

// MARK: - Content fill & update

extension CVCalendarMonthView {
    public func updateAppearance(frame: CGRect) {
        self.frame = frame
        createWeekViews()
    }
    
    public func createWeekViews() {
        weekViews = [CVCalendarWeekView]()
        
        safeExecuteBlock(block: {
            for i in 0..<self.numberOfWeeks! {
                let weekView = CVCalendarWeekView(monthView: self, index: i)
                
                self.safeExecuteBlock(block: {
                    self.weekViews!.append(weekView)
                }, collapsingOnNil: true, withObjects: self.weekViews as AnyObject?)
                
                self.addSubview(weekView)
            }
        }, collapsingOnNil: true, withObjects: numberOfWeeks as AnyObject?)
    }
}

// MARK: - Interactive view management & update

extension CVCalendarMonthView {
    public func updateInteractiveView() {
        safeExecuteBlock(block: {
            let mode = self.calendarView!.calendarMode!
            if mode == .MonthView {
                if let interactiveView = self.interactiveView {
                    interactiveView.frame = self.bounds
                    interactiveView.removeFromSuperview()
                    self.addSubview(interactiveView)
                } else {
                    self.interactiveView = UIView(frame: self.bounds)
                    self.interactiveView.backgroundColor = .clear
                    
                    let tapRecognizer = UITapGestureRecognizer(target: self, action: "didTouchInteractiveView:")
                    let pressRecognizer = UILongPressGestureRecognizer(target: self, action: "didPressInteractiveView:")
                    pressRecognizer.minimumPressDuration = 0.3
                    
                    self.interactiveView.addGestureRecognizer(pressRecognizer)
                    self.interactiveView.addGestureRecognizer(tapRecognizer)
                    
                    self.addSubview(self.interactiveView)
                }
            }
            
            }, collapsingOnNil: false, withObjects: calendarView)
    }
    
    public func didPressInteractiveView(recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.location(in: self.interactiveView)
        let state: UIGestureRecognizer.State = recognizer.state
        
        switch state {
        case .began:
            touchController.receiveTouchLocation(location: location, inMonthView: self, withSelectionType: .Range(.Started))
        case .changed:
            touchController.receiveTouchLocation(location: location, inMonthView: self, withSelectionType: .Range(.Changed))
        case .ended:
            touchController.receiveTouchLocation(location: location, inMonthView: self, withSelectionType: .Range(.Ended))
            
        default: break
        }
    }
    
    public func didTouchInteractiveView(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self.interactiveView)
        touchController.receiveTouchLocation(location: location, inMonthView: self, withSelectionType: .Single)
    }
}

// MARK: - Safe execution

extension CVCalendarMonthView {
    public func safeExecuteBlock(block: () -> Void, collapsingOnNil collapsing: Bool, withObjects objects: AnyObject?...) {
        for object in objects {
            if object == nil {
                if collapsing {
                    fatalError("Object { \(object) } must not be nil!")
                } else {
                    return
                }
            }
        }
        
        block()
    }
}
