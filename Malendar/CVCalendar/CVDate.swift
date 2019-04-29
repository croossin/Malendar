//
//  CVDate.swift
//  CVCalendar
//
//  Created by Мак-ПК on 12/31/14.
//  Copyright (c) 2014 GameApp. All rights reserved.
//

import UIKit

public final class CVDate: NSObject {
    private let date: NSDate
    
    public let year: Int
    public let month: Int
    public let week: Int
    public let day: Int
    
   public init(date: NSDate) {
    let dateRange = Manager.dateRange(date: date)
        
        self.date = date
        self.year = dateRange.year
        self.month = dateRange.month
        self.week = dateRange.weekOfMonth
        self.day = dateRange.day
        
        super.init()
    }
    
    public init(day: Int, month: Int, week: Int, year: Int) {
        if let date = Manager.dateFromYear(year: year, month: month, week: week, day: day) {
            self.date = date
        } else {
            self.date = NSDate()
        }
        
        self.year = year
        self.month = month
        self.week = week
        self.day = day
        
        super.init()
    }
}

extension CVDate {
    public func convertedDate() -> NSDate? {
        let calendar = NSCalendar.current
        let comps = Manager.componentsForDate(date: NSDate())
        
        comps.year = year
        comps.month = month
        comps.weekOfMonth = week
        comps.day = day
        
        return calendar.dateComponents(comps)
    }
}

extension CVDate {
    public var globalDescription: String {
        get {
            let month = dateFormattedStringWithFormat(format: "MMMM", fromDate: date)
            return "\(month), \(year)"
        }
    }
    
    public var commonDescription: String {
        get {
            let month = dateFormattedStringWithFormat(format: "MMMM", fromDate: date)
            return "\(day) \(month), \(year)"
        }
    }
}

private extension CVDate {
    func dateFormattedStringWithFormat(format: String, fromDate date: NSDate) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.stringFromDate(date as Date)
    }
}
