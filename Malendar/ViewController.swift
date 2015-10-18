//
//  ViewController.swift
//  Malendar
//
//  Created by Chase Roossin on 10/14/15.
//  Copyright © 2015 Smart Drive LLC. All rights reserved.
//

import UIKit
import EventKit

class EventTableViewCell : UITableViewCell {
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventNote: UILabel!
    @IBOutlet weak var eventStart: UILabel!
    @IBOutlet weak var eventEnd: UILabel!
    
    
    
    func loadItem(title: String, note: String, start: NSDate, end: NSDate) {
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        if(!title.isEmpty){
            eventTitle.text = title
        }else{
            eventTitle.text = "Missing Title..."
        }
        
        if(!note.isEmpty){
            eventNote.text = note
        }else{
            eventNote.text = "No note for this event.."
        }
        eventStart.text = dateFormatter.stringFromDate(start)
        eventEnd.text = dateFormatter.stringFromDate(end)
    }

}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var tableView: UITableView!
    

    var shouldShowDaysOut = true
    var animationFinished = true
    
    var tableViewContents: [String] = []
    
    var eventStore: EKEventStore!
    
    var defaultCalendar: EKCalendar!
    
    var eventsList: [EKEvent] = []
    
    var dropDownMenuView: BTNavigationDropdownMenu!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set month title
        monthLabel.text = CVDate(date: NSDate()).globalDescription
        
        //Initialize drop down menu
        //Menu
        let items = ["Monthly Calendar", "Weekly Calendar"]
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.0/255.0, green:180/255.0, blue:220/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        let dropDownMenuView = BTNavigationDropdownMenu(title: items.first!, items: items)
        dropDownMenuView.cellHeight = 50
        dropDownMenuView.cellBackgroundColor = self.navigationController?.navigationBar.barTintColor
        dropDownMenuView.cellSelectionColor = UIColor(red: 0.0/255.0, green:160.0/255.0, blue:195.0/255.0, alpha: 1.0)
        dropDownMenuView.cellTextLabelColor = UIColor.whiteColor()
        dropDownMenuView.cellTextLabelFont = UIFont(name: "Avenir-Heavy", size: 17)
        dropDownMenuView.arrowPadding = 15
        dropDownMenuView.animationDuration = 0.5
        dropDownMenuView.maskBackgroundColor = UIColor.blackColor()
        dropDownMenuView.maskBackgroundOpacity = 0.3
        dropDownMenuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> () in
            print("Did select item at index: \(indexPath)")
            self.dealWithNavBarSelection(indexPath)
        }
       
        // Initialize the event store
        self.eventStore = EKEventStore()

        //Initialize dropdown menu
        self.navigationItem.titleView = dropDownMenuView
        
        //Set up custom cell
        var nib = UINib(nibName: "EventTableViewCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "customCell")
    }
    
    override func viewDidAppear(animated: Bool) {
        // Check whether we are authorized to access Calendar
        self.checkEventStoreAccessForCalendar()
        self.eventsList = self.fetchEvents(NSDate())
        reloadTable()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        calendarView.commitCalendarViewUpdate()
        menuView.commitMenuViewUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Determines what to do when something in navbar is selected
    func dealWithNavBarSelection(indexSelected: Int){
        //monthly
        if(indexSelected == 0){
            self.calendarView.changeMode(.MonthView)
        }
        //weekly
        if(indexSelected == 1){
            self.calendarView.changeMode(.WeekView)
            print("week view")
        }
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.eventsList.count;
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:EventTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("customCell") as! EventTableViewCell!

        let cellTitle = self.eventsList[indexPath.row].title
        let cellNote = self.eventsList[indexPath.row].notes
        let cellStart = self.eventsList[indexPath.row].startDate
        let cellEnd = self.eventsList[indexPath.row].endDate
        
        
        cell.loadItem(cellTitle, note: cellNote!, start: cellStart, end: cellEnd)
        
        return cell
    }
    
    //CUSTOM ACTIONS WHEN SWIPE
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
       
        var editAction = UITableViewRowAction(style: .Normal, title: "Edit") { (action:
            UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            print("edit")
        }
        
        var deleteAction = UITableViewRowAction(style: .Normal, title: "Delete") { (action:
            UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let alertView = SCLAlertView()
            alertView.addButton("Yes"){
                
                tableView.beginUpdates()
                
                //actually delete calendar event
                do{
                    try self.eventStore.removeEvent(self.eventsList[indexPath.row], span: .ThisEvent)
                } catch{
                    print(error)
                }
                
                //update table to reflect delete
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                self.eventsList.removeAtIndex(indexPath.row)
                tableView.endUpdates()
            }
            alertView.addButton("No") {
                self.reloadTable()
            }
            alertView.showCloseButton = false
            alertView.showWarning("Delete?", subTitle: "Are you sure you want to delete this event?")
        }
        
        
        
        deleteAction.backgroundColor = UIColor.redColor()
        editAction.backgroundColor = UIColor.grayColor()
        return [editAction, deleteAction]
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("You selected cell #\(indexPath.row)!")
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    func reloadTable(){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    // Fetch all events happening in the next 24 hours
    private func fetchEvents(givenStartDate: NSDate) -> [EKEvent] {
        let startDate = givenStartDate
        
        //Create the end date components
        let tomorrowDateComponents = NSDateComponents()
        tomorrowDateComponents.day = 1
        
        let endDate = NSCalendar.currentCalendar().dateByAddingComponents(tomorrowDateComponents,
            toDate: startDate,
            options: [])!
        // We will only search the default calendar for our events
        let calendarArray: [EKCalendar] = [self.defaultCalendar]
        
        // Create the predicate
        let predicate = self.eventStore.predicateForEventsWithStartDate(startDate,
            endDate: endDate,
            calendars: calendarArray)
        
        // Fetch all events that match the predicate
        let events = self.eventStore.eventsMatchingPredicate(predicate)
        
        return events
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



// MARK: - CVCalendarViewDelegate & CVCalendarMenuViewDelegate

extension ViewController: CVCalendarViewDelegate, CVCalendarMenuViewDelegate {
    
    /// Required method to implement!
    func presentationMode() -> CalendarMode {
        return .MonthView
    }
    
    /// Required method to implement!
    func firstWeekday() -> Weekday {
        return .Sunday
    }
    
    // MARK: Optional methods
    
    func shouldShowWeekdaysOut() -> Bool {
        return shouldShowDaysOut
    }
    
    func shouldAnimateResizing() -> Bool {
        return true // Default value is true
    }
    
    func didSelectDayView(dayView: CVCalendarDayView) {
        let date = dayView.date
        print("\(calendarView.presentedDate.commonDescription) is selected!")
        
        // Fetch all events happening in the next 24 hours and put them into eventsList
        let currentDate = calendarView.presentedDate.convertedDate()
        self.eventsList = self.fetchEvents(currentDate!)

        // Update the UI with the above events
        reloadTable()
    }
    
    func presentedDateUpdated(date: CVDate) {
        if monthLabel.text != date.globalDescription && self.animationFinished {
            let updatedMonthLabel = UILabel()
            updatedMonthLabel.textColor = monthLabel.textColor
            updatedMonthLabel.font = monthLabel.font
            updatedMonthLabel.textAlignment = .Center
            updatedMonthLabel.text = date.globalDescription
            updatedMonthLabel.sizeToFit()
            updatedMonthLabel.alpha = 0
            updatedMonthLabel.center = self.monthLabel.center
            
            let offset = CGFloat(48)
            updatedMonthLabel.transform = CGAffineTransformMakeTranslation(0, offset)
            updatedMonthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
            
            UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.animationFinished = false
                self.monthLabel.transform = CGAffineTransformMakeTranslation(0, -offset)
                self.monthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
                self.monthLabel.alpha = 0
                
                updatedMonthLabel.alpha = 1
                updatedMonthLabel.transform = CGAffineTransformIdentity
                
                }) { _ in
                    
                    self.animationFinished = true
                    self.monthLabel.frame = updatedMonthLabel.frame
                    self.monthLabel.text = updatedMonthLabel.text
                    self.monthLabel.transform = CGAffineTransformIdentity
                    self.monthLabel.alpha = 1
                    updatedMonthLabel.removeFromSuperview()
            }
            
            self.view.insertSubview(updatedMonthLabel, aboveSubview: self.monthLabel)
        }
    }
    
    func topMarker(shouldDisplayOnDayView dayView: CVCalendarDayView) -> Bool {
        return true
    }
    
    func dotMarker(shouldShowOnDayView dayView: CVCalendarDayView) -> Bool {
//        let day = dayView.date.day
//        let randomDay = Int(arc4random_uniform(31))
//        if day == randomDay {
//            return true
//        }
//        
        return false
    }
    
    func dotMarker(colorOnDayView dayView: CVCalendarDayView) -> [UIColor] {
        let day = dayView.date.day
        
        let red = CGFloat(arc4random_uniform(600) / 255)
        let green = CGFloat(arc4random_uniform(600) / 255)
        let blue = CGFloat(arc4random_uniform(600) / 255)
        
        let color = UIColor(red: red, green: green, blue: blue, alpha: 1)
        
        let numberOfDots = Int(arc4random_uniform(3) + 1)
        switch(numberOfDots) {
        case 2:
            return [color, color]
        case 3:
            return [color, color, color]
        default:
            return [color] // return 1 dot
        }
    }
    
    func dotMarker(shouldMoveOnHighlightingOnDayView dayView: CVCalendarDayView) -> Bool {
        return true
    }
    
    func dotMarker(sizeOnDayView dayView: DayView) -> CGFloat {
        return 13
    }
    
    
    func weekdaySymbolType() -> WeekdaySymbolType {
        return .Short
    }
    
}

// MARK: - CVCalendarViewAppearanceDelegate

extension ViewController: CVCalendarViewAppearanceDelegate {
    func dayLabelPresentWeekdayInitallyBold() -> Bool {
        return false
    }
    
    func spaceBetweenDayViews() -> CGFloat {
        return 2
    }
}

// MARK: - IB Actions

extension ViewController {
    @IBAction func switchChanged(sender: UISwitch) {
        if sender.on {
            calendarView.changeDaysOutShowingState(false)
            shouldShowDaysOut = true
        } else {
            calendarView.changeDaysOutShowingState(true)
            shouldShowDaysOut = false
        }
    }
    
    @IBAction func todayMonthView() {
        calendarView.toggleCurrentDayView()
    }
    
    /// Switch to WeekView mode.
    @IBAction func toWeekView(sender: AnyObject) {
        calendarView.changeMode(.WeekView)
    }
    
    /// Switch to MonthView mode.
    @IBAction func toMonthView(sender: AnyObject) {
        calendarView.changeMode(.MonthView)
    }
    
    @IBAction func loadPrevious(sender: AnyObject) {
        calendarView.loadPreviousView()
    }
    
    
    @IBAction func loadNext(sender: AnyObject) {
        calendarView.loadNextView()
    }
}

// MARK: - Convenience API Demo

extension ViewController {
    func toggleMonthViewWithMonthOffset(offset: Int) {
        let calendar = NSCalendar.currentCalendar()
        let calendarManager = calendarView.manager
        let components = Manager.componentsForDate(NSDate()) // from today
        
        components.month += offset
        
        let resultDate = calendar.dateFromComponents(components)!
        
        self.calendarView.toggleViewWithDate(resultDate)
    }
}

class NativeEventFormViewController : FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeForm()
        
        self.navigationItem.leftBarButtonItem?.target = self
        self.navigationItem.leftBarButtonItem?.action = "cancelTapped:"
    }
    
    private func initializeForm() {
        
        form =
            
            TextRow("Title").cellSetup { cell, row in
                cell.textField.placeholder = row.tag
            }
            
            <<< TextRow("Location").cellSetup {
                $0.cell.textField.placeholder = $0.row.tag
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
            
            PushRow<RepeatInterval>("Repeat") {
                $0.title = $0.tag
                $0.options = RepeatInterval.allValues
                $0.value = .Never
        }
        
        form +++=
            
            PushRow<EventAlert>() {
                $0.title = "Alert"
                $0.options = EventAlert.allValues
                $0.value = .Never
                }
                .onChange { [weak self] row in
                    if row.value == .Never {
                        if let second : PushRow<EventAlert> = self?.form.rowByTag("Another Alert"), let secondIndexPath = second.indexPath() {
                            row.section?.removeAtIndex(secondIndexPath.row)
                        }
                    }
                    else{
                        guard let _ : PushRow<EventAlert> = self?.form.rowByTag("Another Alert") else {
                            let second = PushRow<EventAlert>("Another Alert") {
                                $0.title = $0.tag
                                $0.value = .Never
                                $0.options = EventAlert.allValues
                            }
                            row.section?.insert(second, atIndex: row.indexPath()!.row + 1)
                            return
                        }
                    }
        }
        
        form +++=
            
            PushRow<EventState>("Show As") {
                $0.title = "Show As"
                $0.options = EventState.allValues
        }
        
        form +++=
            
            URLRow("URL") {
                $0.placeholder = "URL"
            }
            
            <<< TextAreaRow("notes") {
                $0.placeholder = "Notes"
        }
        
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
}