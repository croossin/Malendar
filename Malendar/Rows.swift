//  Rows.swift
//  Eureka ( https://github.com/xmartlabs/Eureka )
//
//  Copyright (c) 2015 Xmartlabs ( http://xmartlabs.com )
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import Foundation

internal protocol FieldRowConformance : FormatterConformance {
    var textFieldPercentage : CGFloat? { get set }
    var placeholder : String? { get set }
    var placeholderColor : UIColor? { get set }
}

internal protocol TextAreaConformance : FormatterConformance {
    var placeholder : String? { get set }
}

internal protocol FormatterConformance: class {
    var formatter: Formatter? { get set }
    var useFormatterDuringInput: Bool { get set }
}

public class FieldRow<T: Any, Cell: CellType>: Row<T, Cell>, FieldRowConformance where Cell: BaseCell, Cell: TextFieldCell, Cell.Value == T {
    
    public var textFieldPercentage : CGFloat?
    public var placeholder : String?
    public var placeholderColor : UIColor?
    public var formatter: Formatter?
    public var useFormatterDuringInput: Bool
    
    public required init(tag: String?) {
        useFormatterDuringInput = false
        super.init(tag: tag)
        self.displayValueFor = { [unowned self] value in
            guard let v = value else {
                return nil
            }
            if let formatter = self.formatter {
                if self.cell.textField.isFirstResponder() {
                    if self.useFormatterDuringInput {
                        return formatter.editingString(for: v, for: as! AnyObject)
                    }
                    else {
                        return String(v)
                    }
                }
                return formatter.string(for: v, for: as! AnyObject)
            }
            else{
                return String(v)
            }
        }
    }
}

public protocol _DatePickerRowProtocol {
    var minimumDate : NSDate? { get set }
    var maximumDate : NSDate? { get set }
    var minuteInterval : Int? { get set }
}

public class _DateFieldRow: Row<NSDate, DateCell>, _DatePickerRowProtocol {
    
    public var minimumDate : NSDate?
    public var maximumDate : NSDate?
    public var minuteInterval : Int?
    public var dateFormatter: DateFormatter?
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = { [unowned self] value in
            guard let val = value, let formatter = self.dateFormatter else { return nil }
            return formatter.stringFromDate(val as Date)
        }
    }
}

public class _DateInlineFieldRow: Row<NSDate, DateInlineCell>, _DatePickerRowProtocol {
    
    public var minimumDate : NSDate?
    public var maximumDate : NSDate?
    public var minuteInterval : Int?
    public var dateFormatter: DateFormatter?
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = { [unowned self] value in
            guard let val = value, let formatter = self.dateFormatter else { return nil }
            return formatter.stringFromDate(val as Date)
        }
    }
}

public class _DateInlineRow: _DateInlineFieldRow {
    
    public typealias InlineRow = DatePickerRow
    
    public required init(tag: String?) {
        super.init(tag: tag)
        dateFormatter = DateFormatter()
        dateFormatter?.timeStyle = .none
        dateFormatter?.dateStyle = .medium
        dateFormatter?.locale = .current
    }
}

public class _DateTimeInlineRow: _DateInlineFieldRow {

    public typealias InlineRow = DateTimePickerRow
    
    public required init(tag: String?) {
        super.init(tag: tag)
        dateFormatter = DateFormatter()
        dateFormatter?.timeStyle = .short
        dateFormatter?.dateStyle = .short
        dateFormatter?.locale = .current
    }
}

public class _TimeInlineRow: _DateInlineFieldRow {
    
    public typealias InlineRow = TimePickerRow
    
    public required init(tag: String?) {
        super.init(tag: tag)
        dateFormatter = DateFormatter()
        dateFormatter?.timeStyle = .short
        dateFormatter?.dateStyle = .none
        dateFormatter?.locale = .current
    }
}

public class _CountDownInlineRow: _DateInlineFieldRow {
    
    public typealias InlineRow = CountDownPickerRow
    
    public required init(tag: String?) {
        super.init(tag: tag)
        displayValueFor =  {
            guard let date = $0 else {
                return nil
            }
            let hour = NSCalendar.current.component(.hour, from: date as Date)
            let min = NSCalendar.current.component(.minute, from: date as Date)
            if hour == 1{
                return "\(hour) hour \(min) min"
            }
            return "\(hour) hours \(min) min"
        }
    }
}

public class _TextRow: FieldRow<String, TextCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _IntRow: FieldRow<Int, IntCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = .current
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        formatter = numberFormatter
    }
}

public class _PhoneRow: FieldRow<String, PhoneCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _NameRow: FieldRow<String, NameCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _EmailRow: FieldRow<String, EmailCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _PasswordRow: FieldRow<String, PasswordCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _DecimalRow: FieldRow<Float, DecimalCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = .current
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        formatter = numberFormatter
    }
}

public class _URLRow: FieldRow<NSURL, URLCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _TwitterRow: FieldRow<String, TwitterCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _AccountRow: FieldRow<String, AccountCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _TimeRow: _DateFieldRow {
    required public init(tag: String?) {
        super.init(tag: tag)
        dateFormatter = DateFormatter()
        dateFormatter?.timeStyle = .short
        dateFormatter?.dateStyle = .none
        dateFormatter?.locale = NSLocale.current
    }
}

public class _DateRow: _DateFieldRow {
    required public init(tag: String?) {
        super.init(tag: tag)
        dateFormatter = DateFormatter()
        dateFormatter?.timeStyle = .none
        dateFormatter?.dateStyle = .medium
        dateFormatter?.locale = NSLocale.current
    }
}

public class _DateTimeRow: _DateFieldRow {
    required public init(tag: String?) {
        super.init(tag: tag)
        dateFormatter = DateFormatter()
        dateFormatter?.timeStyle = .short
        dateFormatter?.dateStyle = .short
        dateFormatter?.locale = NSLocale.current
    }
}

public class _CountDownRow: _DateFieldRow {
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = { [unowned self] value in
            guard let val = value else {
                return nil
            }
            if let formatter = self.dateFormatter {
                return formatter.stringFromDate(val as Date)
            }
            let components = NSCalendar.currentCalendar.components(NSCalendar.Unit.Minute.union(NSCalendar.Unit.Hour), from: val as Date)
            var hourString = "hour"
            if components.hour != 1{
                hourString += "s"
            }
            return  "\(components.hour) \(hourString) \(components.minute) min"
        }
    }
}

public class _DatePickerRow : Row<NSDate, DatePickerCell>, _DatePickerRowProtocol {
    
    public var minimumDate : NSDate?
    public var maximumDate : NSDate?
    public var minuteInterval : Int?
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
    }
}

public class _TextAreaRow: AreaRow<String, TextAreaCell> {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _LabelRow: Row<String, LabelCell> {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _CheckRow: Row<Bool, CheckCell> {
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
    }
}

public class _SwitchRow: Row<Bool, SwitchCell> {
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
    }
}

public class _PushRow<T: Equatable> : SelectorRow<T, SelectorViewController<T>>, PresenterRowType {
    
    public required init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .Show(controllerProvider: ControllerProvider.Callback { return SelectorViewController<T>(){ _ in } }, completionCallback: { vc in vc.navigationController?.popViewController(animated: true) })
    }
}

public class AreaRow<T: Equatable, Cell: CellType>: Row<T, Cell>, TextAreaConformance where Cell: BaseCell, Cell: AreaCell, Cell.Value == T {
    
    public var placeholder : String?
    public var formatter: Formatter?
    public var useFormatterDuringInput: Bool
    
    public required init(tag: String?) {
        useFormatterDuringInput = false
        super.init(tag: tag)
        self.displayValueFor = { [unowned self] value in
            guard let v = value else {
                return nil
            }
            if let formatter = self.formatter {
                if self.cell.textView.isFirstResponder() {
                    if self.useFormatterDuringInput {
                        return formatter.editingString(for: v, for: as! AnyObject)
                    }
                    else {
                        return String(v)
                    }
                }
                return formatter.string(for: v, for: as! AnyObject)
            }
            else{
                return String(v)
            }
        }
    }

}

public class OptionsRow<T: Equatable, Cell: CellType> : Row<T, Cell> where Cell: BaseCell, Cell.Value == T {
    
    public var options: [T] {
        get { return dataProvider?.arrayData ?? [] }
        set { dataProvider = DataProvider(arrayData: newValue) }
    }
    
    public var selectorTitle: String?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public class _ActionSheetRow<T: Equatable>: OptionsRow<T, AlertSelectorCell<T>>, PresenterRowType {
    
    public var onPresentCallback : ((FormViewController, SelectorAlertController<T>)->())?
    lazy public var presentationMode: PresentationMode<SelectorAlertController<T>>? = {
        return .PresentModally(controllerProvider: ControllerProvider.Callback { [unowned self] in
            let vc = SelectorAlertController<T>(title: self.selectorTitle, message: nil, preferredStyle: .actionSheet)
            vc.row = self
            return vc
            },
            completionCallback: { [unowned self] in
                $0.dismiss(animated: true, completion: nil)
                self.cell?.formViewController()?.tableView?.reloadData()
            })
        }()
    
    public required init(tag: String?) {
        super.init(tag: tag)
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if let presentationMode = presentationMode, !isDisabled {
            if let controller = presentationMode.createController(){
                controller.row = self
                onPresentCallback?(cell.formViewController()!, controller)
                presentationMode.presentViewController(viewController: controller, row: self, presentingViewController: cell.formViewController()!)
            }
            else{
                presentationMode.presentViewController(viewController: nil, row: self, presentingViewController: cell.formViewController()!)
            }
        }
    }
}

public class _AlertRow<T: Equatable>: OptionsRow<T, AlertSelectorCell<T>>, PresenterRowType {
    
    public var onPresentCallback : ((FormViewController, SelectorAlertController<T>)->())?
    lazy public var presentationMode: PresentationMode<SelectorAlertController<T>>? = {
        return .PresentModally(controllerProvider: ControllerProvider.Callback { [unowned self] in
            let vc = SelectorAlertController<T>(title: self.selectorTitle, message: nil, preferredStyle: .alert)
            vc.row = self
            return vc
            }, completionCallback: { [unowned self] in
                $0.dismiss(animated: true, completion: nil)
                self.cell?.formViewController()?.tableView?.reloadData()
            }
        )
        
        }()
        
    public required init(tag: String?) {
        super.init(tag: tag)
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if let presentationMode = presentationMode, !isDisabled  {
            if let controller = presentationMode.createController(){
                controller.row = self
                onPresentCallback?(cell.formViewController()!, controller)
                presentationMode.presentViewController(viewController: controller, row: self, presentingViewController: cell.formViewController()!)
            }
            else{
                presentationMode.presentViewController(viewController: nil, row: self, presentingViewController: cell.formViewController()!)
            }
        }
    }
}

public class _ImageRow : SelectorRow<UIImage, ImagePickerController>, PresenterRowType {
    public required init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .PresentModally(controllerProvider: ControllerProvider.Callback { return ImagePickerController() }, completionCallback: { vc in vc.dismiss(animated: true, completion: nil) })
        self.displayValueFor = nil
    }
    
    public override func customUpdateCell() {
        super.customUpdateCell()
        cell.accessoryType = .none
        if let image = self.value {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
            imageView.contentMode = .scaleAspectFill
            imageView.image = image
            imageView.clipsToBounds = true
            cell.accessoryView = imageView
        }
        else{
            cell.accessoryView = nil
        }
    }
}

public class _MultipleSelectorRow<T: Hashable> : GenericMultipleSelectorRow<T, MultipleSelectorViewController<T>>, PresenterRowType {
    public required init(tag: String?) {
        super.init(tag: tag)
        self.displayValueFor = {
            if let t = $0 {
                return t.map({ String($0) }).joinWithSeparator(", ")
            }
            return nil
        }
    }
}

public class _ButtonRowOf<T: Equatable> : Row<T, ButtonCellOf<T>> {
    public var presentationMode: PresentationMode<UIViewController>?
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
        cellStyle = .default
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            if let presentationMode = presentationMode {
                if let controller = presentationMode.createController(){
                    presentationMode.presentViewController(viewController: controller, row: self, presentingViewController: self.cell.formViewController()!)
                }
                else{
                    presentationMode.presentViewController(viewController: nil, row: self, presentingViewController: self.cell.formViewController()!)
                }
            }
        }
    }
    
    public override func customUpdateCell() {
        super.customUpdateCell()
        let leftAligmnment = presentationMode != nil
        cell.textLabel?.textAlignment = leftAligmnment ? .left : .center
        cell.accessoryType = !leftAligmnment || isDisabled ? .none : .disclosureIndicator
        cell.editingAccessoryType = cell.accessoryType;
        if (!leftAligmnment){
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            cell.tintColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            cell.textLabel?.textColor  = UIColor(red: red, green: green, blue: blue, alpha:isDisabled ? 0.3 : 1.0)
        }
        else{
            cell.textLabel?.textColor = nil
        }
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue) {
        super.prepareForSegue(segue: segue)
        let rowVC = segue.destination as? RowControllerType
        rowVC?.completionCallback = self.presentationMode?.completionHandler
    }
}

public class _ButtonRowWithPresent<T: Equatable, VCType: TypedRowControllerType>: Row<T, ButtonCellOf<T>>, PresenterRowType where VCType: UIViewController, VCType.RowValue == T {
    
    public var presentationMode: PresentationMode<VCType>?
    public var onPresentCallback : ((FormViewController, VCType)->())?
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
        cellStyle = .default
    }
    
    public override func customUpdateCell() {
        super.customUpdateCell()
        let leftAligmnment = presentationMode != nil
        cell.textLabel?.textAlignment = leftAligmnment ? .left : .center
        cell.accessoryType = !leftAligmnment || isDisabled ? .none : .disclosureIndicator
        cell.editingAccessoryType = cell.accessoryType;
        if (!leftAligmnment){
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            cell.tintColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            cell.textLabel?.textColor  = UIColor(red: red, green: green, blue: blue, alpha:isDisabled ? 0.3 : 1.0)
        }
        else{
            cell.textLabel?.textColor = nil
        }
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            if let presentationMode = presentationMode {
                if let controller = presentationMode.createController(){
                    controller.row = self
                    onPresentCallback?(cell.formViewController()!, controller)
                    presentationMode.presentViewController(viewController: controller, row: self, presentingViewController: self.cell.formViewController()!)
                }
                else{
                    presentationMode.presentViewController(viewController: nil, row: self, presentingViewController: self.cell.formViewController()!)
                }
            }
        }
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue) {
        super.prepareForSegue(segue: segue)
        guard let rowVC = segue.destination as? VCType else {
            return
        }
        if let callback = self.presentationMode?.completionHandler{
            rowVC.completionCallback = callback
        }
        onPresentCallback?(cell.formViewController()!, rowVC)
        rowVC.row = self
    }
    
}


//MARK: Rows

public final class CheckRow: _CheckRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class SwitchRow: _SwitchRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class LabelRow: _LabelRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class DateRow: _DateRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row in
            let color = cell.detailTextLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
}

public final class TimeRow: _TimeRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row in
            let color = cell.detailTextLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
}

public final class DateTimeRow: _DateTimeRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row in
            let color = cell.detailTextLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
}

public final class CountDownRow: _CountDownRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row in
            let color = cell.detailTextLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
}

public final class DateInlineRow: _DateInlineRow, RowType, InlineRowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onExpandInlineRow { cell, row, _ in
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            toggleInlineRow()
        }
    }
}

public final class TimeInlineRow: _TimeInlineRow, RowType, InlineRowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onExpandInlineRow { cell, row, _ in
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            toggleInlineRow()
        }
    }
}

public final class DateTimeInlineRow: _DateTimeInlineRow, RowType, InlineRowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onExpandInlineRow { cell, row, _ in
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            toggleInlineRow()
        }
    }
}

public final class CountDownInlineRow: _CountDownInlineRow, RowType, InlineRowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onExpandInlineRow { cell, row, _ in
            let color = cell.detailTextLabel?.textColor
            row.onCollapseInlineRow { cell, _, _ in
                cell.detailTextLabel?.textColor = color
            }
            cell.detailTextLabel?.textColor = cell.tintColor
        }
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            toggleInlineRow()
        }
    }
}

public final class DatePickerRow : _DatePickerRow, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class TimePickerRow : _DatePickerRow, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class DateTimePickerRow : _DatePickerRow, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class CountDownPickerRow : _DatePickerRow, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class TextRow: _TextRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class NameRow: _NameRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class PasswordRow: _PasswordRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class EmailRow: _EmailRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class TwitterRow: _TwitterRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class AccountRow: _AccountRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class IntRow: _IntRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class DecimalRow: _DecimalRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class URLRow: _URLRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class PhoneRow: _PhoneRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        onCellHighlight { cell, row  in
            let color = cell.textLabel?.textColor
            row.onCellUnHighlight { cell, _ in
                cell.textLabel?.textColor = color
            }
            cell.textLabel?.textColor = cell.tintColor
        }
    }
}

public final class TextAreaRow: _TextAreaRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class SegmentedRow<T: Equatable>: OptionsRow<T, SegmentedCell<T>>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class ActionSheetRow<T: Equatable>: _ActionSheetRow<T>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class AlertRow<T: Equatable>: _AlertRow<T>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class ImageRow : _ImageRow, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class PushRow<T: Equatable> : _PushRow<T>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class MultipleSelectorRow<T: Hashable> : _MultipleSelectorRow<T>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public final class ButtonRowOf<T: Equatable> : _ButtonRowOf<T>, RowType {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}

public typealias ButtonRow = ButtonRowOf<String>

public final class ButtonRowWithPresent<T: Equatable, VCType: TypedRowControllerType> : _ButtonRowWithPresent<T, VCType>, RowType where VCType: UIViewController, VCType.RowValue == T {
    public required init(tag: String?) {
        super.init(tag: tag)
    }
}
