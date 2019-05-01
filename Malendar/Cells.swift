//  Cells.swift
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

import Foundation
import UIKit

// MARK: LabelCell

public class LabelCellOf<T: Equatable>: Cell<T>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func setup() {
        super.setup()
        selectionStyle = .none
    }
    
    public override func update() {
        super.update()
    }
}

public typealias LabelCell = LabelCellOf<String>

// MARK: ButtonCell

public class ButtonCellOf<T: Equatable>: Cell<T>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func setup() {
        super.setup()
    }
    
    public override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default
        accessoryType = .none
        editingAccessoryType = accessoryType
        textLabel?.textAlignment = .center
        textLabel?.textColor = tintColor
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        tintColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        textLabel?.textColor  = UIColor(red: red, green: green, blue: blue, alpha: row.isDisabled ? 0.3 : 1.0)
    }
    
    public override func didSelect() {
        super.didSelect()
        formViewController()?.tableView?.deselectRow(at: row.indexPath()! as IndexPath, animated: true)
    }
}

public typealias ButtonCell = ButtonCellOf<String>

// MARK: FieldCell

public protocol InputTypeInitiable {
    init?(string stringValue: String)
}

extension Int: InputTypeInitiable {

    public init?(string stringValue: String){
        self.init(stringValue, radix: 10)
    }
}
extension Float: InputTypeInitiable {
    public init?(string stringValue: String){
        self.init(stringValue)
    }
}
extension String: InputTypeInitiable {
    public init?(string stringValue: String){
        self.init(stringValue)
    }
}
extension NSURL: InputTypeInitiable {}

public class _FieldCell<T> : Cell<T>, UITextFieldDelegate, TextFieldCell where T: Equatable, T: InputTypeInitiable {
    lazy public var textField : UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    public var titleLabel : UILabel? {
        textLabel?.translatesAutoresizingMaskIntoConstraints = false
        textLabel?.setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        textLabel?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000), for: .horizontal)
        return textLabel
    }

    private var dynamicConstraints = [NSLayoutConstraint]()
    
    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        titleLabel?.removeObserver(self, forKeyPath: "text")
        imageView?.removeObserver(self, forKeyPath: "image")
    }
    
    public override func setup() {
        super.setup()
        selectionStyle = .none
        contentView.addSubview(titleLabel!)
        contentView.addSubview(textField)

        titleLabel?.addObserver(self, forKeyPath: "text", options: NSKeyValueObservingOptions.old.union(.new), context: nil)
        imageView?.addObserver(self, forKeyPath: "image", options: NSKeyValueObservingOptions.old.union(.new), context: nil)
        textField.addTarget(self, action: "textFieldDidChange:", for: .editingChanged)
        
    }
    
    public override func update() {
        super.update()
        detailTextLabel?.text = nil
        if let title = row.title {
            textField.textAlignment = title.isEmpty ? .left : .right
            textField.clearButtonMode = title.isEmpty ? .whileEditing : .never
        }
        else{
            textField.textAlignment =  .left
            textField.clearButtonMode =  .whileEditing
        }
        textField.delegate = self
        textField.text = row.displayValueFor?(row.value)
        textField.isEnabled = !row.isDisabled
        textField.textColor = row.isDisabled ? .gray : .black()
        textField.font = .preferredFont(forTextStyle: UIFont.TextStyle.body)
        if let placeholder = (row as? FieldRowConformance)?.placeholder {
            if let color = (row as? FieldRowConformance)?.placeholderColor {
                textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: color])
            }
            else{
                textField.placeholder = (row as? FieldRowConformance)?.placeholder
            }
        }
    }
    
    public override func cellCanBecomeFirstResponder() -> Bool {
        return !row.isDisabled && textField.canBecomeFirstResponder
    }
    
    public override func cellBecomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    public override func cellResignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let obj = object, let keyPathValue = keyPath, let changeType = change?[NSKeyValueChangeKindKey], ((obj === titleLabel && keyPathValue == "text") || (obj === imageView && keyPathValue == "image")) && changeType.unsignedLongValue == NSKeyValueChange.Setting.rawValue {
            contentView.setNeedsUpdateConstraints()
        }
    }
    
    // Mark: Helpers
    
    public override func updateConstraints(){
        contentView.removeConstraints(dynamicConstraints)
        dynamicConstraints = []
        var views : [String: AnyObject] =  ["textField": textField]
        dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-11-[textField]-11-|", options: .alignAllLastBaseline, metrics: nil, views: ["textField": textField])
        
        if let label = titleLabel, let text = label.text, !text.isEmpty {
            dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-11-[titleLabel]-11-|", options: .alignAllLastBaseline, metrics: nil, views: ["titleLabel": label])
            dynamicConstraints.append(NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: textField, attribute: .centerY, multiplier: 1, constant: 0))
        }
        if let imageView = imageView, let _ = imageView.image {
            views["imageView"] = imageView
            if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                views["label"] = titleLabel
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-[label]-[textField]-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views)
                dynamicConstraints.append(NSLayoutConstraint(item: textField, attribute: .width, relatedBy: (row as? FieldRowConformance)?.textFieldPercentage != nil ? .equal : .greaterThanOrEqual, toItem: contentView, attribute: .width, multiplier: (row as? FieldRowConformance)?.textFieldPercentage ?? 0.3, constant: 0.0))
            }
            else{
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-[textField]-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
            }
        }
        else{
            if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                views["label"] = titleLabel
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-[textField]-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views)
                dynamicConstraints.append(NSLayoutConstraint(item: textField, attribute: .width, relatedBy: (row as? FieldRowConformance)?.textFieldPercentage != nil ? .equal : .greaterThanOrEqual, toItem: contentView, attribute: .width, multiplier: (row as? FieldRowConformance)?.textFieldPercentage ?? 0.3, constant: 0.0))
            }
            else{
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[textField]-|", options: .alignAllLeft, metrics: nil, views: views)
            }
        }
        contentView.addConstraints(dynamicConstraints)
        super.updateConstraints()
    }
    
    public func textFieldDidChange(textField : UITextField){
        guard let textValue = textField.text else {
            row.value = nil
            return
        }
        if let fieldRow = row as? FieldRowConformance, let formatter = fieldRow.formatter, fieldRow.useFormatterDuringInput {
            let value: AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(UnsafeMutablePointer<T>.allocate(capacity: 1))
            let errorDesc: AutoreleasingUnsafeMutablePointer<NSString?>? = nil
            if formatter.getObjectValue(value, for: textValue, errorDescription: errorDesc) {
                row.value = value.memory as? T
                if var selStartPos = textField.selectedTextRange?.start {
                    let oldVal = textField.text
                    textField.text = row.displayValueFor?(row.value)
                    if let f = formatter as? FormatterProtocol {
                        selStartPos = f.getNewPosition(forPosition: selStartPos, inTextInput: textField, oldValue: oldVal, newValue: textField.text)
                    }
                    textField.selectedTextRange = textField.textRangeFromPosition(selStartPos, toPosition: selStartPos)
                }
                return
            }
        }
        guard !textValue.isEmpty else {
            row.value = nil
            return
        }
        guard let newValue = T.init(string: textValue) else {
            row.updateCell()
            return
        }
        row.value = newValue
    }
    
    //MARK: TextFieldDelegate
    
    public func textFieldDidBeginEditing(textField: UITextField) {
        formViewController()?.beginEditing(cell: self)
        if let fieldRowConformance = (row as? FieldRowConformance), let _ = fieldRowConformance.formatter, !fieldRowConformance.useFormatterDuringInput {
                textField.text = row.displayValueFor?(row.value)
        }
    }
    
    public func textFieldDidEndEditing(textField: UITextField) {
        formViewController()?.endEditing(cell: self)
        if let fieldRowConformance = (row as? FieldRowConformance), let _ = fieldRowConformance.formatter, !fieldRowConformance.useFormatterDuringInput {
            textField.text = row.displayValueFor?(row.value)
        }
    }
}

public class TextCell : _FieldCell<String>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .sentences
        textField.keyboardType = .default
    }
}


public class IntCell : _FieldCell<Int>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .none
        textField.keyboardType = .numberPad
    }
}

public class PhoneCell : _FieldCell<String>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.keyboardType = .phonePad
    }
}

public class NameCell : _FieldCell<String>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        textField.keyboardType = .namePhonePad
    }
}

public class EmailCell : _FieldCell<String>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .emailAddress
    }
}

public class PasswordCell : _FieldCell<String>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .asciiCapable
        textField.isSecureTextEntry = true
    }
}

public class DecimalCell : _FieldCell<Float>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.keyboardType = .decimalPad
    }
}

public class URLCell : _FieldCell<NSURL>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.keyboardType = .URL
    }
}

public class TwitterCell : _FieldCell<String>, CellType {

    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .twitter
    }
}

public class AccountCell : _FieldCell<String>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.keyboardType = .asciiCapable
    }
}

public class DateCell : Cell<NSDate>, CellType {
    
    lazy public var datePicker : UIDatePicker = {
        return UIDatePicker()
    }()
    
    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func setup() {
        super.setup()
        accessoryType = .none
        editingAccessoryType =  .none
        datePicker.datePickerMode = datePickerMode()
        datePicker.addTarget(self, action: Selector("datePickerValueChanged:"), for: .valueChanged)
    }
    
    
    public override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default
        detailTextLabel?.text = row.displayValueFor?(row.value)
        datePicker.setDate((row.value ?? NSDate()) as Date, animated: row is CountDownPickerRow)
        datePicker.minimumDate = (row as? _DatePickerRowProtocol)?.minimumDate as Date?
        datePicker.maximumDate = (row as? _DatePickerRowProtocol)?.maximumDate as Date?
        if let minuteIntervalValue = (row as? _DatePickerRowProtocol)?.minuteInterval{
            datePicker.minuteInterval = minuteIntervalValue
        }
    }
    
    public override func didSelect() {
        super.didSelect()
        formViewController()?.tableView?.deselectRow(at: row.indexPath()! as IndexPath, animated: true)
    }
    
    override public var inputView : UIView? {
        if let v = row.value{
            datePicker.setDate(v as Date, animated:row is CountDownRow)
        }
        return datePicker
    }
    
    func datePickerValueChanged(sender: UIDatePicker){
        row.value = sender.date as NSDate
        detailTextLabel?.text = row.displayValueFor?(row.value)
    }
    
    private func datePickerMode() -> UIDatePicker.Mode{
        switch row {
        case is DateRow:
            return .date
        case is TimeRow:
            return .time
        case is DateTimeRow:
            return .dateAndTime
        case is CountDownRow:
            return .countDownTimer
        default:
            return .date
        }
    }
    
    public override func cellCanBecomeFirstResponder() -> Bool {
        return canBecomeFirstResponder()
    }
    
    public override func canBecomeFirstResponder() -> Bool {
        return !row.isDisabled;
    }
}

public class DateInlineCell : Cell<NSDate>, CellType {
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func setup() {
        super.setup()
        accessoryType = .none
        editingAccessoryType =  .none
    }
    
    public override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default
        detailTextLabel?.text = row.displayValueFor?(row.value)
    }
    
    public override func didSelect() {
        super.didSelect()
        formViewController()?.tableView?.deselectRow(at: row.indexPath()! as IndexPath, animated: true)
    }
}

public class DatePickerCell : Cell<NSDate>, CellType {
    
    public lazy var datePicker: UIDatePicker = { [unowned self] in
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(picker)
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[picker]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["picker": picker]))
        self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[picker]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["picker": picker]))
        picker.addTarget(self, action: "datePickerValueChanged:", for: .valueChanged)
        return picker
        }()
    
    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func setup() {
        super.setup()
        height = { 213 }
        accessoryType = .none
        editingAccessoryType =  .none
        datePicker.datePickerMode = datePickerMode()
    }
    
    public override func update() {
        super.update()
        selectionStyle = row.isDisabled ? .none : .default
        datePicker.isUserInteractionEnabled = !row.isDisabled
        detailTextLabel?.text = nil
        textLabel?.text = nil
        datePicker.setDate((row.value ?? NSDate()) as Date, animated: row is CountDownPickerRow)
        datePicker.minimumDate = (row as? _DatePickerRowProtocol)?.minimumDate as Date?
        datePicker.maximumDate = (row as? _DatePickerRowProtocol)?.maximumDate as Date?
        if let minuteIntervalValue = (row as? _DatePickerRowProtocol)?.minuteInterval{
            datePicker.minuteInterval = minuteIntervalValue
        }
    }
    
    func datePickerValueChanged(sender: UIDatePicker){
        row.value = sender.date as NSDate
    }
    
    private func datePickerMode() -> UIDatePicker.Mode{
        switch row {
        case is DatePickerRow:
            return .date
        case is TimePickerRow:
            return .time
        case is DateTimePickerRow:
            return .dateAndTime
        case is CountDownPickerRow:
            return .countDownTimer
        default:
            return .date
        }
    }
}

public class _TextAreaCell<T> : Cell<T>, UITextViewDelegate, AreaCell where T: Equatable, T: InputTypeInitiable {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public lazy var placeholderLabel : UILabel = {
        let v = UILabel()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.numberOfLines = 0
        v.textColor = UIColor(white: 0, alpha: 0.22)
        return v
    }()
    
    public lazy var textView : UITextView = {
        let v = UITextView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private var dynamicConstraints = [NSLayoutConstraint]()
    
    public override func setup() {
        super.setup()
        height = { 110 }
        textView.keyboardType = .default
        textView.delegate = self
        textView.font = .preferredFont(forTextStyle: UIFont.TextStyle.body)
        placeholderLabel.font = textView.font
        selectionStyle = .none
        contentView.addSubview(textView)
        contentView.addSubview(placeholderLabel)
        
        let views : [String: AnyObject] =  ["textView": textView, "label": placeholderLabel]
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-8-[label]", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[textView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        contentView.addConstraint(NSLayoutConstraint(item: textView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0))
        contentView.addConstraint(NSLayoutConstraint(item: textView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[textView]-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
    }
    
    public override func update() {
        super.update()
        textLabel?.text = nil
        detailTextLabel?.text = nil
        textView.isEditable = !row.isDisabled
        textView.textColor = row.isDisabled ? .gray : .black
        textView.text = row.displayValueFor?(row.value)
        placeholderLabel.text = (row as? TextAreaConformance)?.placeholder
        placeholderLabel.sizeToFit()
        placeholderLabel.isHidden = textView.text.count != 0
    }
    
    public override func cellCanBecomeFirstResponder() -> Bool {
        return !row.isDisabled && textView.canBecomeFirstResponder
    }
    
    public override func cellBecomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }
    
    public override func cellResignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }
    
    public func textViewDidBeginEditing(textView: UITextView) {
        formViewController()?.beginEditing(cell: self)
        if let textAreaConformance = (row as? TextAreaConformance), let _ = textAreaConformance.formatter, !textAreaConformance.useFormatterDuringInput {
            textView.text = row.displayValueFor?(row.value)
        }
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        formViewController()?.endEditing(cell: self)
        if let textAreaConformance = (row as? TextAreaConformance), let _ = textAreaConformance.formatter, !textAreaConformance.useFormatterDuringInput {
            textView.text = row.displayValueFor?(row.value)
        }
    }
    
    public func textViewDidChange(textView: UITextView) {
        placeholderLabel.isHidden = textView.text.count != 0
        guard let textValue = textView.text else {
            row.value = nil
            return
        }
        if let fieldRow = row as? TextAreaConformance, let formatter = fieldRow.formatter, fieldRow.useFormatterDuringInput {
            let value: AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(UnsafeMutablePointer<T>.allocate(capacity: 1))
            let errorDesc: AutoreleasingUnsafeMutablePointer<NSString?>? = nil
            if formatter.getObjectValue(value, forString: textValue, errorDescription: errorDesc) {
                row.value = value.memory as? T
                if var selStartPos = textView.selectedTextRange?.start {
                    let oldVal = textView.text
                    textView.text = row.displayValueFor?(row.value)
                    if let f = formatter as? FormatterProtocol {
                        selStartPos = f.getNewPosition(forPosition: selStartPos, inTextInput: textView, oldValue: oldVal, newValue: textView.text)
                    }
                    textView.selectedTextRange = textView.textRangeFromPosition(selStartPos, toPosition: selStartPos)
                }
                return
            }
        }
        guard !textValue.isEmpty else {
            row.value = nil
            return
        }
        guard let newValue = T.init(string: textValue) else {
            row.updateCell()
            return
        }
        row.value = newValue
    }
    
}

public class TextAreaCell : _TextAreaCell<String>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
}

public class CheckCell : Cell<Bool>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        accessoryType = row.value == true ? .checkmark : .none
        editingAccessoryType = accessoryType
        selectionStyle = .default
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        tintColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        if row.isDisabled {
            tintColor = UIColor(red: red, green: green, blue: blue, alpha: 0.3)
            selectionStyle = .none
        }
        else {
            tintColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        }
    }

    public override func setup() {
        super.setup()
        accessoryType =  .checkmark
        editingAccessoryType = accessoryType
    }
    
    public override func didSelect() {
        row.value = row.value ?? false ? false : true
        formViewController()?.tableView?.deselectRow(at: row.indexPath()! as IndexPath, animated: true)
        row.updateCell()
    }
    
}

public class SwitchCell : Cell<Bool>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var switchControl: UISwitch? {
        return accessoryView as? UISwitch
    }
    
    public override func setup() {
        super.setup()
        selectionStyle = .none
        accessoryView = UISwitch()
        editingAccessoryView = accessoryView
        switchControl?.addTarget(self, action: "valueChanged", for: .valueChanged)
    }
    
    public override func update() {
        super.update()
        switchControl?.isOn = row.value ?? false
        switchControl?.isEnabled = !row.isDisabled
    }
    
    func valueChanged() {
        row.value = switchControl?.on.boolValue ?? false
    }
}

public class SegmentedCell<T: Equatable> : Cell<T>, CellType {
    
    public var titleLabel : UILabel? {
        textLabel?.translatesAutoresizingMaskIntoConstraints = false
        textLabel?.setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        return textLabel
    }
    lazy public var segmentedControl : UISegmentedControl = {
        let result = UISegmentedControl()
        result.translatesAutoresizingMaskIntoConstraints = false
        result.setContentHuggingPriority(UILayoutPriority(rawValue: 500), for: .horizontal)
        return result
    }()
    private var dynamicConstraints = [NSLayoutConstraint]()
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        titleLabel?.removeObserver(self, forKeyPath: "text")
    }
    
    public override func setup() {
        super.setup()
        selectionStyle = .none
        contentView.addSubview(titleLabel!)
        contentView.addSubview(segmentedControl)
        titleLabel?.addObserver(self, forKeyPath: "text", options: NSKeyValueObservingOptions.old.union(.new), context: nil)
        segmentedControl.addTarget(self, action: "valueChanged", for: .valueChanged)
        contentView.addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    public override func update() {
        super.update()
        detailTextLabel?.text = nil

        updateSegmentedControl()
        segmentedControl.selectedSegmentIndex = selectedIndex() ?? UISegmentedControl.noSegment
        segmentedControl.isEnabled = !row.isDisabled
    }
    
    func valueChanged() {
        row.value =  (row as! SegmentedRow<T>).options[segmentedControl.selectedSegmentIndex]
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let obj = object, let changeType = change, let _ = keyPath, obj === titleLabel && keyPath == "text" && changeType[NSKeyValueChangeKindKey]?.unsignedLongValue == NSKeyValueChange.Setting.rawValue{
            contentView.setNeedsUpdateConstraints()
        }
    }
    
    func updateSegmentedControl() {
        segmentedControl.removeAllSegments()
        for item in items().enumerated() {
            segmentedControl.insertSegmentWithTitle(item.element, atIndex: item.index, animated: false)
        }
    }
    
    public override func updateConstraints() {
        contentView.removeConstraints(dynamicConstraints)
        dynamicConstraints = []
        var views : [String: AnyObject] =  ["segmentedControl": segmentedControl]
        if (titleLabel?.text?.isEmpty == false) {
            views["titleLabel"] = titleLabel
            dynamicConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[titleLabel]-16-[segmentedControl]-|", options: .alignAllCenterY, metrics: nil, views: views)
            dynamicConstraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("V:|-12-[titleLabel]-12-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        }
        else{
            dynamicConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[segmentedControl]-|", options: .alignAllCenterY, metrics: nil, views: views)
        }
        contentView.addConstraints(dynamicConstraints)
        super.updateConstraints()
    }
    
    func items() -> [String] {// or create protocol for options
        var result = [String]()
        for object in (row as! SegmentedRow<T>).options{
            result.append(row.displayValueFor?(object) ?? "")
        }
        return result
    }
    
    func selectedIndex() -> Int? {
        guard let value = row.value else { return nil }
        return (row as! SegmentedRow<T>).options.firstIndex(of:value)
    }
}

public class AlertSelectorCell<T: Equatable> : Cell<T>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        accessoryType = .none
        editingAccessoryType = accessoryType
        selectionStyle = row.isDisabled ? .none : .default
    }
    
    public override func didSelect() {
        super.didSelect()
        formViewController()?.tableView?.deselectRow(at: row.indexPath()! as IndexPath, animated: true)
    }
}

public class PushSelectorCell<T: Equatable> : Cell<T>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func update() {
        super.update()
        accessoryType = .disclosureIndicator
        editingAccessoryType = accessoryType
        selectionStyle = row.isDisabled ? .none : .default
    }
}


