//
//  CVCalendarWeekView.swift
//  CVCalendar
//
//  Created by E. Mozharovsky on 12/26/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

public final class CVCalendarWeekView: UIView {
    // MARK: - Non public properties
    private var interactiveView: UIView!
    
    public override var frame: CGRect {
        didSet {
            if let calendarView = calendarView {
                if calendarView.calendarMode == CalendarMode.WeekView {
                    updateInteractiveView()
                }
            }
        }
    }
    
    private var touchController: CVCalendarTouchController {
        return calendarView.touchController
    }
    
    // MARK: - Public properties
    
    public weak var monthView: CVCalendarMonthView!
    public var dayViews: [CVCalendarDayView]!
    public var index: Int!
    
    public var weekdaysIn: [Int : [Int]]?
    public var weekdaysOut: [Int : [Int]]?
    public var utilizable = false /// Recovery service.
    
    public weak var calendarView: CVCalendarView! {
        get {
            var calendarView: CVCalendarView!
            if let monthView = monthView, let activeCalendarView = monthView.calendarView {
                calendarView = activeCalendarView
            }
            
            return calendarView
        }
    }
    
    // MARK: - Initialization
    
    public init(monthView: CVCalendarMonthView, index: Int) {
        
        
        self.monthView = monthView
        self.index = index
        
        if let size = monthView.calendarView.weekViewSize {
            super.init(frame: CGRect(x: 0, y: CGFloat(index) * size.height, width: size.width, height: size.height))
        } else {
            super.init(frame: CGRect.zero)
        }
        
        // Get weekdays in.
        let weeksIn = self.monthView!.weeksIn!
        self.weekdaysIn = weeksIn[self.index!]
        
        // Get weekdays out.
        if let weeksOut = self.monthView!.weeksOut {
            if self.weekdaysIn?.count ?? 0 < 7 {
                if weeksOut.count > 1 {
                    let daysOut = 7 - self.weekdaysIn!.count
                    
                    var result: [Int : [Int]]?
                    for weekdaysOut in weeksOut {
                        if weekdaysOut.count == daysOut {
                            let manager = calendarView.manager
                            
                            
                            let key = weekdaysOut.keys.first!
                            let value = weekdaysOut[key]![0]
                            if value > 20 {
                                if self.index == 0 {
                                    result = weekdaysOut
                                    break
                                }
                            } else if value < 10 {
                                if self.index == manager?.monthDateRange(date: self.monthView!.date!).countOfWeeks ?? 0 - 1 {
                                    result = weekdaysOut
                                    break
                                }
                            }
                        }
                    }
                    
                    self.weekdaysOut = result!
                } else {
                    self.weekdaysOut = weeksOut[0]
                }
                
            }
        }
        
        self.createDayViews()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func mapDayViews(body: (DayView) -> ()) {
        if let dayViews = dayViews {
            for dayView in dayViews {
                body(dayView)
            }
        }
    }
}

// MARK: - Interactive view setup & management

extension CVCalendarWeekView {
    public func updateInteractiveView() {
        safeExecuteBlock(block: {
            
            let mode = self.monthView!.calendarView!.calendarMode!
            if mode == .WeekView {
                if let interactiveView = self.interactiveView {
                    interactiveView.frame = self.bounds
                    interactiveView.removeFromSuperview()
                    self.addSubview(interactiveView)
                } else {
                    self.interactiveView = UIView(frame: self.bounds)
                    self.interactiveView.backgroundColor = .clear()
                    
                    let tapRecognizer = UITapGestureRecognizer(target: self, action: "didTouchInteractiveView:")
                    let pressRecognizer = UILongPressGestureRecognizer(target: self, action: "didPressInteractiveView:")
                    pressRecognizer.minimumPressDuration = 0.3
                    
                    self.interactiveView.addGestureRecognizer(pressRecognizer)
                    self.interactiveView.addGestureRecognizer(tapRecognizer)
                    
                    self.addSubview(self.interactiveView)
                }
            }
            
            }, collapsingOnNil: false, withObjects: monthView, monthView?.calendarView)
    }
    
    public func didPressInteractiveView(recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.location(in: self.interactiveView)
        let state: UIGestureRecognizer.State = recognizer.state
        
        switch state {
        case .began:
            touchController.receiveTouchLocation(location: location, inWeekView: self, withSelectionType: .Range(.Started))
        case .changed:
            touchController.receiveTouchLocation(location: location, inWeekView: self, withSelectionType: .Range(.Changed))
        case .ended:
            touchController.receiveTouchLocation(location: location, inWeekView: self, withSelectionType: .Range(.Ended))
            
        default: break
        }
    }
    
    public func didTouchInteractiveView(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self.interactiveView)
        touchController.receiveTouchLocation(location: location, inWeekView: self, withSelectionType: .Single)
    }
}

// MARK: - Content fill & reload

extension CVCalendarWeekView {
    public func createDayViews() {
        dayViews = [CVCalendarDayView]()
        for i in 1...7 {
            let dayView = CVCalendarDayView(weekView: self, weekdayIndex: i)
            
            safeExecuteBlock(block: {
                self.dayViews!.append(dayView)
            }, collapsingOnNil: true, withObjects: dayViews as AnyObject?)
            
            addSubview(dayView)
        }
    }
    
    public func reloadDayViews() {
        
        if let size = calendarView.dayViewSize, let dayViews = dayViews {
            let hSpace = calendarView.appearance.spaceBetweenDayViews!
            
            for (index, dayView) in dayViews.enumerated() {
                let hSpace = calendarView.appearance.spaceBetweenDayViews!
                let x = CGFloat(index) * CGFloat(size.width + hSpace) + hSpace/2
                dayView.frame = CGRect(x: x, y: 0, width: size.width, height: size.height)
                dayView.reloadContent()
            }
        }
    }
}

// MARK: - Safe execution

extension CVCalendarWeekView {
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
