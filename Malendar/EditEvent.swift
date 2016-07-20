//
//  EditEvent.swift
//  Malendar
//
//  Created by Chase Roossin on 10/20/15.
//  Copyright © 2015 Smart Drive LLC. All rights reserved.
//

import Foundation
import UIKit
import EventKitUI

//To edit an event
class EditNativeEventNavigationController: UINavigationController, RowControllerType {
    var completionCallback : ((UIViewController) -> ())?
    
    
}

class EditNativeEventFormViewController : FormViewController {
    
    
    var defaultCalendar: EKCalendar!
    var eventToEdit: EKEvent?
    var eventStore: EKEventStore!
    var eventTitle: String =  ""
    var eventLocation: String = ""
    var eventAllday: Bool = false
    var eventStart: NSDate = NSDate()
    var eventEnd: NSDate = NSDate()
    var eventNotes: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem?.target = self
        self.navigationItem.leftBarButtonItem?.action = #selector(EditNativeEventFormViewController.cancelTapped(_:))
        
        self.navigationItem.rightBarButtonItem?.target = self
        self.navigationItem.rightBarButtonItem?.action = #selector(EditNativeEventFormViewController.editEvent(_:))
        
        initializeForm()
        // Initialize the event store
        self.eventStore = EKEventStore()
        eventToEdit = globalEditEvent.event
        self.checkEventStoreAccessForCalendar()
    }
    
    
    private func initializeForm() {
        
        form =
            
            
            TextRow("Title").cellSetup { cell, row in
                cell.textField.placeholder = self.eventToEdit?.title
                }.onChange { [weak self] row in
                    let inputTitle = row.value as String?
                    if(inputTitle != nil){
                        self!.eventTitle = row.value as String!
                    }else{
                        self!.eventTitle = ""
                    }
                    
            }
            
            
            <<< TextRow("Location").cellSetup {
                $0.cell.textField.placeholder = $0.row.tag
                }.onChange { [weak self] row in
                    let inputTitle = row.value as String?
                    if(inputTitle != nil){
                        self!.eventLocation = row.value as String!
                    }else{
                        self!.eventLocation = ""
                    }
                    
            }
            
            +++
            
            SwitchRow("All-day") {
                $0.title = $0.tag
                }.onChange { [weak self] row in
                    let startDate: DateTimeInlineRow! = self?.form.rowByTag("Starts")
                    let endDate: DateTimeInlineRow! = self?.form.rowByTag("Ends")
                    
                    if row.value ?? false {
                        startDate.dateFormatter?.dateStyle = .MediumStyle
                        startDate.dateFormatter?.timeStyle = .NoStyle
                        endDate.dateFormatter?.dateStyle = .MediumStyle
                        endDate.dateFormatter?.timeStyle = .NoStyle
                    }
                    else {
                        startDate.dateFormatter?.dateStyle = .ShortStyle
                        startDate.dateFormatter?.timeStyle = .ShortStyle
                        endDate.dateFormatter?.dateStyle = .ShortStyle
                        endDate.dateFormatter?.timeStyle = .ShortStyle
                    }
                    startDate.updateCell()
                    endDate.updateCell()
                    startDate.inlineRow?.updateCell()
                    endDate.inlineRow?.updateCell()
                    self!.eventAllday = row.value as Bool!
            }
            
            <<< DateTimeInlineRow("Starts") {
                $0.title = $0.tag
                $0.value = NSDate().dateByAddingTimeInterval(60*60*24)
                }
                .onChange { [weak self] row in
                    let endRow: DateTimeInlineRow! = self?.form.rowByTag("Ends")
                    if row.value?.compare(endRow.value!) == .OrderedDescending {
                        endRow.value = NSDate(timeInterval: 60*60*24, sinceDate: row.value!)
                        endRow.cell!.backgroundColor = .whiteColor()
                        endRow.updateCell()
                    }
                    self!.eventStart = row.value as NSDate!
                }
                .onExpandInlineRow { cell, row, inlineRow in
                    inlineRow.cellUpdate { [weak self] cell, dateRow in
                        let allRow: SwitchRow! = self?.form.rowByTag("All-day")
                        if allRow.value ?? false {
                            cell.datePicker.datePickerMode = .Date
                        }
                        else {
                            cell.datePicker.datePickerMode = .DateAndTime
                        }
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
                    
            }
            
            <<< DateTimeInlineRow("Ends"){
                $0.title = $0.tag
                $0.value = NSDate().dateByAddingTimeInterval(60*60*25)
                }
                .onChange { [weak self] row in
                    let startRow: DateTimeInlineRow! = self?.form.rowByTag("Starts")
                    if row.value?.compare(startRow.value!) == .OrderedAscending {
                        row.cell!.backgroundColor = .redColor()
                    }
                    else{
                        row.cell!.backgroundColor = .whiteColor()
                    }
                    row.updateCell()
                    self!.eventEnd = row.value as NSDate!
                }
                .onExpandInlineRow { cell, row, inlineRow in
                    inlineRow.cellUpdate { [weak self] cell, dateRow in
                        let allRow: SwitchRow! = self?.form.rowByTag("All-day")
                        if allRow.value ?? false {
                            cell.datePicker.datePickerMode = .Date
                        }
                        else {
                            cell.datePicker.datePickerMode = .DateAndTime
                        }
                    }
                    let color = cell.detailTextLabel?.textColor
                    row.onCollapseInlineRow { cell, _, _ in
                        cell.detailTextLabel?.textColor = color
                    }
                    cell.detailTextLabel?.textColor = cell.tintColor
        }
        
        form +++=
            
            TextAreaRow("notes") {
                print(self.eventToEdit)
                $0.placeholder = "Notes"
                }.onChange { [weak self] row in
                    let inputTitle = row.value as String?
                    if(inputTitle != nil){
                        self!.eventNotes = row.value as String!
                    }else{
                        self!.eventNotes = ""
                    }
                    
        }
        
    }
    
    func cancelTapped(barButtonItem: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func editEvent(barButtonItem: UIBarButtonItem) {
        let event = eventStore.eventWithIdentifier((eventToEdit?.eventIdentifier)!)
        event!.title = eventTitle
        event!.startDate = eventStart
        event!.endDate = eventEnd
        event!.notes = eventNotes
        event!.allDay = eventAllday
        event!.location = eventLocation
        event!.calendar = eventStore.defaultCalendarForNewEvents
        do{
            try self.eventStore.saveEvent(event!, span: .ThisEvent)
            
        }catch{
            print(error)
        }
        print("Saved Event")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    enum RepeatInterval : String, CustomStringConvertible {
        case Never = "Never"
        case Every_Day = "Every Day"
        case Every_Week = "Every Week"
        case Every_2_Weeks = "Every 2 Weeks"
        case Every_Month = "Every Month"
        case Every_Year = "Every Year"
        
        var description : String { return rawValue }
        
        static let allValues = [Never, Every_Day, Every_Week, Every_2_Weeks, Every_Month, Every_Year]
    }
    
    enum EventAlert : String, CustomStringConvertible {
        case Never = "None"
        case At_time_of_event = "At time of event"
        case Five_Minutes = "5 minutes before"
        case FifTeen_Minutes = "15 minutes before"
        case Half_Hour = "30 minutes before"
        case One_Hour = "1 hour before"
        case Two_Hour = "2 hours before"
        case One_Day = "1 day before"
        case Two_Days = "2 days before"
        
        var description : String { return rawValue }
        
        static let allValues = [Never, At_time_of_event, Five_Minutes, FifTeen_Minutes, Half_Hour, One_Hour, Two_Hour, One_Day, Two_Days]
    }
    
    enum EventState {
        case Busy
        case Free
        
        static let allValues = [Busy, Free]
    }
    
    // Check the authorization status of our application for Calendar
    private func checkEventStoreAccessForCalendar() {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        
        switch status {
            // Update our UI if the user has granted access to their Calendar
        case .Authorized: self.defaultCalendar = self.eventStore.defaultCalendarForNewEvents
            // Prompt the user for access to Calendar if there is no definitive answer
        case .NotDetermined: self.requestCalendarAccess()
            // Display a message if the user has denied or restricted access to Calendar
        case .Denied, .Restricted:
            print("denied")
        }
    }
    
    // Prompt the user for access to their Calendar
    private func requestCalendarAccess() {
        self.eventStore.requestAccessToEntityType(.Event) {[weak self] granted, error in
            if granted {
                // Let's ensure that our code will be executed from the main queue
                dispatch_async(dispatch_get_main_queue()) {
                    // The user has granted access to their Calendar; let's populate our UI with all events occuring in the next 24 hours.
                    self?.accessGrantedForCalendar()
                }
            }
        }
    }
    
    // This method is called when the user has granted permission to Calendar
    private func accessGrantedForCalendar() {
        // Let's get the default calendar associated with our event store
        self.defaultCalendar = self.eventStore.defaultCalendarForNewEvents
    }
}