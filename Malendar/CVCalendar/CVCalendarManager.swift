//
//  CVCalendarManager.swift
//  CVCalendar
//
//  Created by E. Mozharovsky on 12/26/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

private let YearUnit = NSCalendar.Unit.year
private let MonthUnit = NSCalendar.Unit.month
private let WeekUnit = NSCalendar.Unit.weekOfMonth
private let WeekdayUnit = NSCalendar.Unit.weekday
private let DayUnit = NSCalendar.Unit.day
private let AllUnits = YearUnit.union(MonthUnit).union(WeekUnit).union(WeekdayUnit).union(DayUnit)

public final class CVCalendarManager {
    // MARK: - Private properties
    private var components: NSDateComponents
    private unowned let calendarView: CalendarView
    
    public var calendar: NSCalendar
    
    // MARK: - Public properties
    public var currentDate: NSDate
    
    // MARK: - Private initialization
    
    public var starterWeekday: Int
    
    public init(calendarView: CalendarView) {
        self.calendarView = calendarView
        currentDate = NSDate()
        calendar = NSCalendar.current as NSCalendar
        components = calendar.components(MonthUnit.union(DayUnit), fromDate: currentDate as Date)
        
        starterWeekday = calendarView.firstWeekday.rawValue
        calendar.firstWeekday = starterWeekday
    }
    
    // MARK: - Common date analysis
    
    public func monthDateRange(date: NSDate) -> (countOfWeeks: NSInteger, monthStartDate: NSDate, monthEndDate: NSDate) {
        let units = (YearUnit.union(MonthUnit).union(WeekUnit))
        let components = calendar.components(units, fromDate: date as Date)
        
        // Start of the month.
        components.day = 1
        let monthStartDate = calendar.dateFromComponents(components)!
        
        // End of the month.
        components.month += 1
        components.day -= 1
        let monthEndDate = calendar.dateFromComponents(components)!
        
        // Range of the month.
        let range = calendar.rangeOfUnit(WeekUnit, inUnit: MonthUnit, forDate: date as Date)
        let countOfWeeks = range.length
        
        return (countOfWeeks, monthStartDate, monthEndDate)
    }
    
    public static func dateRange(date: NSDate) -> (year: Int, month: Int, weekOfMonth: Int, day: Int) {
        let components = componentsForDate(date: date)
        
        let year = components.year
        let month = components.month
        let weekOfMonth = components.weekOfMonth
        let day = components.day
        
        return (year, month, weekOfMonth, day)
    }
    
    public func weekdayForDate(date: NSDate) -> Int {
        let units = WeekdayUnit
        
        let components = calendar.components(units, fromDate: date as Date)
        
        //println("NSDate: \(date), Weekday: \(components.weekday)")
        
        let weekday = calendar.ordinalityOfUnit(units, inUnit: WeekUnit, forDate: date as Date)
        
        return Int(components.weekday)
    }
    
    // MARK: - Analysis sorting
    
    public func weeksWithWeekdaysForMonthDate(date: NSDate) -> (weeksIn: [[Int : [Int]]], weeksOut: [[Int : [Int]]]) {
        
        let countOfWeeks = self.monthDateRange(date: date).countOfWeeks
        let totalCountOfDays = countOfWeeks * 7
        let firstMonthDateIn = self.monthDateRange(date: date).monthStartDate
        let lastMonthDateIn = self.monthDateRange(date: date).monthEndDate
        let countOfDaysIn = Manager.dateRange(date: lastMonthDateIn).day
        let countOfDaysOut = totalCountOfDays - countOfDaysIn
        
        // Find all dates in.
        var datesIn = [NSDate]()
        for day in 1...countOfDaysIn {
            let components = Manager.componentsForDate(date: firstMonthDateIn)
            components.day = day
            let date = calendar.date(from: components as DateComponents)!
            datesIn.append(date as NSDate)
        }
        
        // Find all dates out.
        
        
        let firstMonthDateOut: NSDate? = {
            let firstMonthDateInWeekday = self.weekdayForDate(date: firstMonthDateIn)
            if firstMonthDateInWeekday == self.starterWeekday {
                return firstMonthDateIn
            }
            
            let components = Manager.componentsForDate(date: firstMonthDateIn)
            for _ in 1...7 {
                components.day -= 1
                let updatedDate = self.calendar.date(from: components as DateComponents)!
                updatedDate
                let updatedDateWeekday = self.weekdayForDate(date: updatedDate as NSDate)
                if updatedDateWeekday == self.starterWeekday {
                    updatedDate
                    return updatedDate as NSDate
                }
            }
            
            let diff = 7 - firstMonthDateInWeekday
            for _ in diff..<7 {
                components.day += 1
                let updatedDate = self.calendar.date(from: components as DateComponents)!
                let updatedDateWeekday = self.weekdayForDate(date: updatedDate as NSDate)
                if updatedDateWeekday == self.starterWeekday {
                    updatedDate
                    return updatedDate as NSDate
                }
            }
            
            return nil
            }()
        
        
        // Constructing weeks.
        
        var firstWeekDates = [NSDate]()
        var lastWeekDates = [NSDate]()
        
        var firstWeekDate = (firstMonthDateOut != nil) ? firstMonthDateOut! : firstMonthDateIn
        let components = Manager.componentsForDate(date: firstWeekDate)
        components.day += 6
        var lastWeekDate = calendar.date(from: components as DateComponents)!
        
        func nextWeekDateFromDate(date: NSDate) -> NSDate {
            let components = Manager.componentsForDate(date: date)
            components.day += 7
            let nextWeekDate = calendar.date(from: components as DateComponents)!
            return nextWeekDate as NSDate
        }
        
        for weekIndex in 1...countOfWeeks {
            firstWeekDates.append(firstWeekDate)
            lastWeekDates.append(lastWeekDate as NSDate)
            
            firstWeekDate = nextWeekDateFromDate(date: firstWeekDate)
            lastWeekDate = nextWeekDateFromDate(date: lastWeekDate as NSDate) as Date
        }
        
        // Dictionaries.
        
        var weeksIn = [[Int : [Int]]]()
        var weeksOut = [[Int : [Int]]]()
        
        let count = firstWeekDates.count
        
        for i in 0..<count {
            var weekdaysIn = [Int : [Int]]()
            var weekdaysOut = [Int : [Int]]()
            
            let firstWeekDate = firstWeekDates[i]
            let lastWeekDate = lastWeekDates[i]
            
            let components = Manager.componentsForDate(date: firstWeekDate)
            for weekday in 1...7 {
                let weekdate = calendar.date(from: components as DateComponents)!
                components.day += 1
                let day = Manager.dateRange(date: weekdate as NSDate).day
                
                func addDay( weekdays: inout [Int : [Int]]) {
                    var days = weekdays[weekday]
                    if days == nil {
                        days = [Int]()
                    }
                    
                    days!.append(day)
                    weekdays.updateValue(days!, forKey: weekday)
                }
                
                if i == 0 && day > 20 {
                    addDay(weekdays: &weekdaysOut)
                } else if i == countOfWeeks - 1 && day < 10 {
                    addDay(weekdays: &weekdaysOut)
                    
                } else {
                    addDay(weekdays: &weekdaysIn)
                }
            }
            
            if weekdaysIn.count > 0 {
                weeksIn.append(weekdaysIn)
            }
            
            if weekdaysOut.count > 0 {
                weeksOut.append(weekdaysOut)
            }
        }
        
        return (weeksIn, weeksOut)
    }
    
    // MARK: - Util methods
    
    public static func componentsForDate(date: NSDate) -> NSDateComponents {
        let units = YearUnit.union(MonthUnit).union(WeekUnit).union(DayUnit)
        let components = NSCalendar.currentCalendar.components(units, from: date as Date)
        
        return components
    }
    
    public static func dateFromYear(year: Int, month: Int, week: Int, day: Int) -> NSDate? {
        let comps = Manager.componentsForDate(date: NSDate())
        comps.year = year
        comps.month = month
        comps.weekOfMonth = week
        comps.day = day
        
        return NSCalendar.currentCalendar.dateComponents(comps)
    }
}
