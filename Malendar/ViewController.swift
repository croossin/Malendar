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
    
    
    
    func loadItem(title: String, note: String?, start: NSDate, end: NSDate) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
    
        
        eventTitle.text = title
        if(note != nil){
           eventNote.text = note
        }else{
            eventNote.text = "No note..."
        }
        eventStart.text = dateFormatter.stringFromDate(start as Date)
        eventEnd.text = dateFormatter.stringFromDate(end as Date)
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
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.0/255.0, green:180/255.0, blue:220/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        let dropDownMenuView = BTNavigationDropdownMenu(title: items.first!, items: items as [AnyObject])
        dropDownMenuView.cellHeight = 50
        dropDownMenuView.cellBackgroundColor = self.navigationController?.navigationBar.barTintColor
        dropDownMenuView.cellSelectionColor = UIColor(red: 0.0/255.0, green:160.0/255.0, blue:195.0/255.0, alpha: 1.0)
        dropDownMenuView.cellTextLabelColor = UIColor.white
        dropDownMenuView.cellTextLabelFont = UIFont(name: "Avenir-Heavy", size: 17)
        dropDownMenuView.arrowPadding = 15
        dropDownMenuView.animationDuration = 0.5
        dropDownMenuView.maskBackgroundColor = UIColor.black
        dropDownMenuView.maskBackgroundOpacity = 0.3
        dropDownMenuView.didSelectItemAtIndexHandler = {(indexPath: Int) -> () in
            print("Did select item at index: \(indexPath)")
            self.dealWithNavBarSelection(indexSelected: indexPath)
        }
       
        // Initialize the event store
        self.eventStore = EKEventStore()

        //Initialize dropdown menu
        self.navigationItem.titleView = dropDownMenuView
        
        //Set up custom cell
        let nib = UINib(nibName: "EventTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "customCell")
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Check whether we are authorized to access Calendar
        self.checkEventStoreAccessForCalendar()
        self.eventsList = self.fetchEvents(givenStartDate: NSDate())
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
            self.calendarView.changeMode(mode: .MonthView)
        }
        //weekly
        if(indexSelected == 1){
            self.calendarView.changeMode(mode: .WeekView)
            print("week view")
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.eventsList.count;
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:EventTableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "customCell") as! EventTableViewCell? ?? <#default value#>

        guard let cellTitle = self.eventsList[indexPath.row].title else { return <#default value#> }
        let cellNote = self.eventsList[indexPath.row].notes
        let cellStart = self.eventsList[indexPath.row].startDate
        let cellEnd = self.eventsList[indexPath.row].endDate
        
        cell.loadItem(title: cellTitle, note: cellNote, start: cellStart as! NSDate, end: cellEnd as! NSDate)
        
        return cell
    }
    
    //CUSTOM ACTIONS WHEN SWIPE
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
       
        let editAction = UITableViewRowAction(style: .Normal, title: "Edit") { (action:
            UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            print("edit")
            globalEditEvent.event = self.eventsList[indexPath.row]
            self.performSegueWithIdentifier("editEvent", sender: nil)
        }
        
        let deleteAction = UITableViewRowAction(style: .Normal, title: "Delete") { (action:
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
        return [deleteAction, editAction]
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
        
        let endDate = NSCalendar.currentCalendar.dateByAddingComponents(tomorrowDateComponents,
            toDate: startDate,
            options: [])!
        // We will only search the default calendar for our events
        if(self.defaultCalendar != nil){
            let calendarArray: [EKCalendar] = [self.defaultCalendar]
        }else{
            self.checkEventStoreAccessForCalendar()
        }
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
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch status {
            // Update our UI if the user has granted access to their Calendar
        case .authorized:
            self.eventStore = EKEventStore()
            self.defaultCalendar = self.eventStore.defaultCalendarForNewEvents
            
            // Prompt the user for access to Calendar if there is no definitive answer
        case .notDetermined:
            self.eventStore = EKEventStore()
            self.requestCalendarAccess()
            // Display a message if the user has denied or restricted access to Calendar
        case .denied, .restricted:
            print("denied")
        }
    }
    
    // Prompt the user for access to their Calendar
    private func requestCalendarAccess() {
        self.eventStore.requestAccess(to: EKEntityType.event) {[weak self] granted, error in
            if granted {
                // Let's ensure that our code will be executed from the main queue
                dispatch_get_main_queue().async() {
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
        print("\(calendarView.presentedDate.commonDescription) is selected!")
        
        // Fetch all events happening in the next 24 hours and put them into eventsList
        let currentDate = calendarView.presentedDate.convertedDate()
        self.eventsList = self.fetchEvents(givenStartDate: currentDate!)

        // Update the UI with the above events
        reloadTable()
    }
    
    func presentedDateUpdated(date: CVDate) {
        if monthLabel.text != date.globalDescription && self.animationFinished {
            let updatedMonthLabel = UILabel()
            updatedMonthLabel.textColor = monthLabel.textColor
            updatedMonthLabel.font = monthLabel.font
            updatedMonthLabel.textAlignment = .center
            updatedMonthLabel.text = date.globalDescription
            updatedMonthLabel.sizeToFit()
            updatedMonthLabel.alpha = 0
            updatedMonthLabel.center = self.monthLabel.center
            
            let offset = CGFloat(48)
            updatedMonthLabel.transform = CGAffineTransform(translationX: 0, y: offset)
            updatedMonthLabel.transform = CGAffineTransform(scaleX: 1, y: 0.1)
            
            UIView.animate(withDuration: 0.35, delay: 0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                self.animationFinished = false
                self.monthLabel.transform = CGAffineTransform(translationX: 0, y: -offset)
                self.monthLabel.transform = CGAffineTransform(scaleX: 1, y: 0.1)
                self.monthLabel.alpha = 0
                
                updatedMonthLabel.alpha = 1
                updatedMonthLabel.transform = CGAffineTransform.identity
                
                }) { _ in
                    
                    self.animationFinished = true
                    self.monthLabel.frame = updatedMonthLabel.frame
                    self.monthLabel.text = updatedMonthLabel.text
                    self.monthLabel.transform = CGAffineTransform.identity
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
        var tempEventsList: [EKEvent] = []
        tempEventsList = fetchEvents(givenStartDate: dayView.date.convertedDate()!)
        if(!tempEventsList.isEmpty){
            return true
        }
        return false
    }
    
    func dotMarker(colorOnDayView dayView: CVCalendarDayView) -> [UIColor] {
        return [UIColor.red]
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
        if sender.isOn {
            calendarView.changeDaysOutShowingState(shouldShow: false)
            shouldShowDaysOut = true
        } else {
            calendarView.changeDaysOutShowingState(shouldShow: true)
            shouldShowDaysOut = false
        }
    }
    
    @IBAction func todayMonthView() {
        calendarView.toggleCurrentDayView()
    }
    
    /// Switch to WeekView mode.
    @IBAction func toWeekView(sender: AnyObject) {
        calendarView.changeMode(mode: .WeekView)
    }
    
    /// Switch to MonthView mode.
    @IBAction func toMonthView(sender: AnyObject) {
        calendarView.changeMode(mode: .MonthView)
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
        let calendar = NSCalendar.current
        let calendarManager = calendarView.manager
        let components = Manager.componentsForDate(date: NSDate()) // from today
        
        components.month += offset
        
        let resultDate = calendar.dateComponents(components)!
        
        self.calendarView.toggleViewWithDate(resultDate)
    }
}


//Global Edit Event
class globalEditEvent{
    static var event: EKEvent?
}
