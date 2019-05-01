//  Core.swift
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

//MARK: Controller Protocols

public protocol RowControllerType : NSObjectProtocol {
    var completionCallback : ((UIViewController) -> ())? { get set }
}

public protocol TypedRowControllerType : RowControllerType {
    associatedtype RowValue: Equatable
    var row : RowOf<Self.RowValue>! { get set }
}

public protocol FormDelegate : class {
    func sectionsHaveBeenAdded(sections: [Section], atIndexes: NSIndexSet)
    func sectionsHaveBeenRemoved(sections: [Section], atIndexes: NSIndexSet)
    func sectionsHaveBeenReplaced(oldSections oldSections:[Section], newSections: [Section], atIndexes: NSIndexSet)
    func rowsHaveBeenAdded(rows: [BaseRow], atIndexPaths:[NSIndexPath])
    func rowsHaveBeenRemoved(rows: [BaseRow], atIndexPaths:[NSIndexPath])
    func rowsHaveBeenReplaced(oldRows oldRows:[BaseRow], newRows: [BaseRow], atIndexPaths: [NSIndexPath])
    func rowValueHasBeenChanged(row: BaseRow, oldValue: Any, newValue: Any)
}

//MARK: Header Footer Protocols

public protocol HeaderFooterViewRepresentable {
    func viewForSection(section: Section, type: HeaderFooterType, controller: FormViewController) -> UIView?
    var title: String? { get set }
    var height: (()->CGFloat)? { get set }
}

//MARK: Row Protocols

public protocol Taggable : AnyObject {
    var tag: String? { get set }
}

public protocol BaseRowType : Taggable {

    var baseCell: BaseCell! { get }
    var section: Section? { get }
    
    var cellStyle : UITableViewCell.CellStyle { get set }
    var title: String? { get set }
    func updateCell()
    func didSelect()
}

public protocol TypedRowType : BaseRowType {
    
    associatedtype Value : Equatable
    associatedtype Cell : BaseCell, CellType
    var cell : Self.Cell! { get }
    var value : Self.Value? { get set }
}

public protocol RowType : TypedRowType {
    init(_ tag: String?, _ initializer: ((Self) -> ()))
}

public protocol BaseInlineRowType {
    func expandInlineRow()
    func collapseInlineRow()
    func toggleInlineRow()
}

public protocol InlineRowType: TypedRowType, BaseInlineRowType {
    associatedtype InlineRow: RowType
}

extension InlineRowType where Self: BaseRow, Self.InlineRow : BaseRow, Self.Cell : TypedCellType, Self.Cell.Value == Self.Value, Self.InlineRow.Cell.Value == Self.InlineRow.Value, Self.InlineRow.Value == Self.Value {
    
    public var inlineRow : Self.InlineRow? { return _inlineRow as? Self.InlineRow }
    
    public func expandInlineRow() {
        guard inlineRow == nil else { return }
        if var section = section, let form = section.form {
            let inline = InlineRow.init() { _ in }
            inline.value = value
            inline.onChange { [weak self] in
                self?.value = $0.value
                self?.updateCell()
            }
            if (form.inlineRowHideOptions ?? Form.defaultInlineRowHideOptions).contains(.AnotherInlineRowIsShown) {
                for row in form.allRows {
                    if let inlineRow = row as? BaseInlineRowType {
                        inlineRow.collapseInlineRow()
                    }
                }
            }
            if let onExpandInlineRowCallback = onExpandInlineRowCallback {
                onExpandInlineRowCallback(cell, self, inline)
            }
            if let indexPath = indexPath() {
                section.insert(inline, atIndex: indexPath.row + 1)
                _inlineRow = inline
            }
        }
    }
    
    public func collapseInlineRow() {
        if let selectedRowPath = indexPath(), let inlineRow = _inlineRow {
            if let onCollapseInlineRowCallback = onCollapseInlineRowCallback {
                onCollapseInlineRowCallback(cell, self, inlineRow as! InlineRow)
            }
            section?.removeAtIndex(selectedRowPath.row + 1)
            _inlineRow = nil
        }
    }
    
    public func toggleInlineRow() {
        if let _ = inlineRow {
            collapseInlineRow()
        }
        else{
            expandInlineRow()
        }
    }
    
    public func onExpandInlineRow(callback: (Cell, Self, InlineRow)->()) -> Self {
        callbackOnExpandInlineRow = callback
        return self
    }
    
    public func onCollapseInlineRow(callback: (Cell, Self, InlineRow)->()) -> Self {
        callbackOnCollapseInlineRow = callback
        return self
    }
    
    public var onCollapseInlineRowCallback: ((Cell, Self, InlineRow)->())? {
        return callbackOnCollapseInlineRow as! ((Cell, Self, InlineRow)->())?
    }
    
    public var onExpandInlineRowCallback: ((Cell, Self, InlineRow)->())? {
        return callbackOnExpandInlineRow as! ((Cell, Self, InlineRow)->())?
    }
}

public protocol PresenterRowType: TypedRowType {
    
    associatedtype ProviderType : UIViewController, TypedRowControllerType
    var presentationMode: PresentationMode<ProviderType>? { get set }
    var onPresentCallback: ((FormViewController, ProviderType)->())? { get set }
}

//MARK: Cell Protocols

public protocol BaseCellType : class {
    
    var height : (()->CGFloat)? { get }
    func setup()
    func update()
    func didSelect()
    func highlight()
    func unhighlight()
    func cellCanBecomeFirstResponder() -> Bool
    func cellBecomeFirstResponder() -> Bool
    func cellResignFirstResponder() -> Bool
    func formViewController () -> FormViewController?
}


public protocol TypedCellType : BaseCellType {
    associatedtype Value : Equatable
    var row : RowOf<Value>! { get set }
}

public protocol CellType: TypedCellType {}

//MARK: Form

public final class Form {

    public static var defaultNavigationOptions = RowNavigationOptions.Enabled.union(.SkipCanNotBecomeFirstResponderRow)
    public static var defaultInlineRowHideOptions = InlineRowHideOptions.FirstResponderChanges.union(.AnotherInlineRowIsShown)
    public var inlineRowHideOptions : InlineRowHideOptions?
    
    public weak var delegate: FormDelegate?

    public init(){}
    
    public subscript(indexPath: NSIndexPath) -> BaseRow {
        return self[indexPath.section][indexPath.row]
    }
    
    public func rowByTag<T: Equatable>(tag: String) -> RowOf<T>? {
        let row: BaseRow? = rowByTag(tag: tag)
        return row as? RowOf<T>
    }
    
    public func rowByTag<Row: RowType>(tag: String) -> Row? {
        let row: BaseRow? = rowByTag(tag: tag)
        return row as? Row
    }
    
    public func rowByTag(tag: String) -> BaseRow? {
        return rowsByTag[tag]
    }
    
    public func sectionByTag(tag: String) -> Section? {
        return kvoWrapper._allSections.filter( { $0.tag == tag }).first
    }
    
    public func values(includeHidden includeHidden: Bool = false) -> [String: Any?]{
        if includeHidden {
            return allRows.filter({ $0.tag != nil })
                          .reduce([String: Any?]()) {
                               var result = $0
                               result[$1.tag!] = $1.baseValue
                               return result
                          }
        }
        return rows.filter({ $0.tag != nil })
                   .reduce([String: Any?]()) {
                        var result = $0
                        result[$1.tag!] = $1.baseValue
                        return result
                    }
    }
    
    public func setValues(values: [String: Any]){
        for (key, value) in values{
            let row: BaseRow? = rowByTag(tag: key)
            row?.baseValue = value
        }
    }
    
    public var rows: [BaseRow] { return flatMap { $0 } }
    public var allRows: [BaseRow] { return kvoWrapper._allSections.map({ $0.kvoWrapper._allRows }).flatMap { $0 } }
    
    public func hideInlineRows() {
        for row in self.allRows {
            if let inlineRow = row as? BaseInlineRowType {
                inlineRow.collapseInlineRow()
            }
        }
    }
    
    //MARK: Private
    
    var rowObservers = [String: [ConditionType: [Taggable]]]()
    var rowsByTag = [String: BaseRow]()
    private lazy var kvoWrapper : KVOWrapper = { [unowned self] in return KVOWrapper(form: self) }()
}

extension Form : MutableCollectionType {
    
    // MARK: MutableCollectionType
    
    public var startIndex: Int { return 0 }
    public var endIndex: Int { return kvoWrapper.sections.count }
    public subscript (position: Int) -> Section {
        get { return kvoWrapper.sections[position] as! Section }
        set { kvoWrapper.sections[position] = newValue }
    }
}

extension Form : RangeReplaceableCollectionType {
    
    // MARK: RangeReplaceableCollectionType
    
    public func append(formSection: Section){
        kvoWrapper.sections.insert(formSection, at: kvoWrapper.sections.count)
        kvoWrapper._allSections.append(formSection)
        formSection.wasAddedToForm(form: self)
    }

    public func appendContentsOf<S : SequenceType>(newElements: S) where S.Generator.Element == Section {
        kvoWrapper.sections.addObjectsFromArray(newElements.map { $0 })
        kvoWrapper._allSections.appendContentsOf(newElements)
        for section in newElements{
            section.wasAddedToForm(self)
        }
    }
    
    public func reserveCapacity(n: Int){}

    public func replaceRange<C : CollectionType>(subRange: Range<Int>, with newElements: C) where C.Generator.Element == Section {
        for (var i = subRange.startIndex; i < subRange.endIndex; i++) {
            if let section = kvoWrapper.sections.objectAtIndex(i) as? Section {
                section.willBeRemovedFromForm()
                kvoWrapper._allSections.removeAtIndex(kvoWrapper._allSections.firstIndex(of:section)!)
            }
        }
        kvoWrapper.sections.replaceObjectsInRange(NSMakeRange(subRange.startIndex, subRange.endIndex - subRange.startIndex), withObjectsFromArray: newElements.map { $0 })
        for section in newElements{
            section.wasAddedToForm(self)
        }
    }
    
    public func removeAll(keepCapacity keepCapacity: Bool = false) {
        // not doing anything with capacity
        for section in kvoWrapper._allSections{
            section.willBeRemovedFromForm()
        }
        kvoWrapper.sections.removeAllObjects()
        kvoWrapper._allSections.removeAll()
    }
}

extension Form {
    
    // MARK: Private Helpers
    
    private class KVOWrapper : NSObject {
        dynamic var _sections = NSMutableArray()
        var sections : NSMutableArray { return mutableArrayValue(forKey: "_sections") }
        var _allSections = [Section]()
        weak var form: Form?
        
        init(form: Form){
            self.form = form
            super.init()
            addObserver(self, forKeyPath: "_sections", options: NSKeyValueObservingOptions.new.union(.old), context:nil)
        }
        
        deinit { removeObserver(self, forKeyPath: "_sections") }
        
        override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
            
            let newSections = change?[NSKeyValueChangeNewKey] as? [Section] ?? []
            let oldSections = change?[NSKeyValueChangeOldKey] as? [Section] ?? []
            guard let delegateValue = form?.delegate, let keyPathValue = keyPath, let changeType = change?[NSKeyValueChangeKindKey] else { return }
            guard keyPathValue == "_sections" else { return }
            switch changeType.unsignedLongValue {
                case NSKeyValueChange.Setting.rawValue:
                    let indexSet = change![NSKeyValueChangeIndexesKey] as? NSIndexSet ?? NSIndexSet(index: 0)
                    delegateValue.sectionsHaveBeenAdded(newSections, atIndexes: indexSet)
                case NSKeyValueChange.Insertion.rawValue:
                    let indexSet = change![NSKeyValueChangeIndexesKey] as! NSIndexSet
                    delegateValue.sectionsHaveBeenAdded(newSections, atIndexes: indexSet)
                case NSKeyValueChange.Removal.rawValue:
                    let indexSet = change![NSKeyValueChangeIndexesKey] as! NSIndexSet
                    delegateValue.sectionsHaveBeenRemoved(oldSections, atIndexes: indexSet)
                case NSKeyValueChange.Replacement.rawValue:
                    let indexSet = change![NSKeyValueChangeIndexesKey] as! NSIndexSet
                    delegateValue.sectionsHaveBeenReplaced(oldSections: oldSections, newSections: newSections, atIndexes: indexSet)
                default:
                    assertionFailure()
            }
        }
    }
    
    func dictionaryValuesToEvaluatePredicate() -> [String: AnyObject] {
        return rowsByTag.reduce([String: AnyObject]()) {
            var result = $0
            result[$1.0] = $1.1.baseValue as? AnyObject ?? NSNull()
            return result
        }
    }
    
    func addRowObservers(taggable: Taggable, rowTags: [String], type: ConditionType) {
        for rowTag in rowTags{
            if let _ = rowObservers[rowTag]?[type]{
                if !rowObservers[rowTag]![type]!.contains(where: { $0 === taggable }){
                    rowObservers[rowTag]?[type]!.append(taggable)
                }
            }
            else{
                rowObservers[rowTag] = Dictionary()
                rowObservers[rowTag]?[type] = [taggable]
            }
        }
    }
    
    public func removeRowObservers(taggable: Taggable, rows: [String], type: ConditionType) {
        for row in rows{
            guard var arr = rowObservers[row]?[type], let index = arr.firstIndex(of:{ $0 === taggable }) else { continue }
            arr.removeAtIndex(index)
        }
    }
    
    internal func nextRowForRow(currentRow: BaseRow) -> BaseRow? {
        let allRows = rows
        guard let index = allRows.firstIndex(of:currentRow) else { return nil }
        guard index < allRows.count - 1 else { return nil }
        return allRows[index + 1]
    }
    
    internal func previousRowForRow(currentRow: BaseRow) -> BaseRow? {
        let allRows = rows
        guard let index = allRows.firstIndex(of:currentRow) else { return nil }
        guard index > 0 else { return nil }
        return allRows[index - 1]
    }
    
    private func hideSection(section: Section){
        kvoWrapper.sections.remove(section)
    }
    
    private func showSection(section: Section){
        guard !kvoWrapper.sections.contains(section) else { return }
        guard var index = kvoWrapper._allSections.firstIndex(of:section) else { return }
        var formIndex = NSNotFound
        while (formIndex == NSNotFound && index > 0){
            let previous = kvoWrapper._allSections[index-=1]
            formIndex = kvoWrapper.sections.indexOfObject(previous)
        }
        kvoWrapper.sections.insertObject(section, atIndex: formIndex == NSNotFound ? 0 : ++formIndex)
    }
}


// MARK: Section

extension Section : Equatable {}

public func ==(lhs: Section, rhs: Section) -> Bool{
    return lhs === rhs
}

extension Section : Hidable {}

public class Section {

    public var tag: String?
    public private(set) weak var form: Form?
    public var header: HeaderFooterViewRepresentable?
    public var footer: HeaderFooterViewRepresentable?
    
    public var index: Int? { return form?.firstIndex(of:self) }
    
    public var hidden : Condition? {
        willSet { removeFromRowObservers() }
        didSet { addToRowObservers() }
    }
    
    public var isHidden : Bool { return hiddenCache }
    
    public required init(){}
    
    public init(_ initializer: (Section) -> ()){
        initializer(self)
    }

    public init(_ header: HeaderFooterView<UIView>, _ initializer: (Section) -> () = { _ in }){
        self.header = header
        initializer(self)
    }
    
    public init(header: HeaderFooterView<UIView>, footer: HeaderFooterView<UIView>, _ initializer: (Section) -> () = { _ in }){
        self.header = header
        self.footer = footer
        initializer(self)
    }
    
    public init(footer: HeaderFooterView<UIView>, _ initializer: (Section) -> () = { _ in }){
        self.footer = footer
        initializer(self)
    }
    
    //MARK: Private
    private lazy var kvoWrapper: KVOWrapper = { [unowned self] in return KVOWrapper(section: self) }()
    public var headerView: UIView?
    public var footerView: UIView?
    private var hiddenCache = false
}


extension Section : MutableCollectionType {
    
//MARK: MutableCollectionType
    
    public var startIndex: Int { return 0 }
    public var endIndex: Int { return kvoWrapper.rows.count }
    public subscript (position: Int) -> BaseRow {
        get {
            if position >= kvoWrapper.rows.count{
                assertionFailure("Section: Index out of bounds")
            }
            return kvoWrapper.rows[position] as! BaseRow
        }
        set { kvoWrapper.rows[position] = newValue }
    }
}

extension Section : RangeReplaceableCollectionType {

// MARK: RangeReplaceableCollectionType
    
    public func append(formRow: BaseRow){
        kvoWrapper.rows.insert(formRow, at: kvoWrapper.rows.count)
        kvoWrapper._allRows.append(formRow)
        formRow.wasAddedToFormInSection(self)
    }
    
    public func appendContentsOf<S : SequenceType>(newElements: S) where S.Generator.Element == BaseRow {
        kvoWrapper.rows.addObjectsFromArray(newElements.map { $0 })
        kvoWrapper._allRows.appendContentsOf(newElements)
        for row in newElements{
            row.wasAddedToFormInSection(self)
        }
    }
    
    public func reserveCapacity(n: Int){}
    
    public func replaceRange<C : CollectionType>(subRange: Range<Int>, with newElements: C) where C.Generator.Element == BaseRow {
        for (var i = subRange.startIndex; i < subRange.endIndex; i++) {
            if let row = kvoWrapper.rows.objectAtIndex(i) as? BaseRow {
                row.willBeRemovedFromForm()
                kvoWrapper._allRows.removeAtIndex(kvoWrapper._allRows.firstIndex(of:row)!)
            }
        }
        kvoWrapper.rows.replaceObjectsInRange(NSMakeRange(subRange.startIndex, subRange.endIndex - subRange.startIndex), withObjectsFromArray: newElements.map { $0 })
        kvoWrapper._allRows.appendContentsOf(newElements)
        for row in newElements{
            row.wasAddedToFormInSection(self)
        }
    }
    
    public func removeAll(keepCapacity keepCapacity: Bool = false) {
        // not doing anything with capacity
        for row in kvoWrapper._allRows{
            row.willBeRemovedFromForm()
        }
        kvoWrapper.rows.removeAllObjects()
        kvoWrapper._allRows.removeAll()
    }
}

public enum HeaderFooterProvider<ViewType: UIView> {
    case Class
    case Callback(()->ViewType)
    case NibFile(name: String, bundle: Bundle?)
    
    internal func createView() -> ViewType {
        switch self {
            case .Class:
                return ViewType.init()
            case .Callback(let builder):
                return builder()
            case .NibFile(let nibName, let bundle):
                return (bundle ?? Bundle(for: ViewType.self)).loadNibNamed(nibName, owner: nil, options: nil)?[0] as! ViewType
        }
    }
}

public enum HeaderFooterType {
    case Header, Footer
}

public struct HeaderFooterView<ViewType: UIView> : ExpressibleByStringLiteral, HeaderFooterViewRepresentable {
    
    public var title: String?
    public var viewProvider: HeaderFooterProvider<ViewType>?
    public var onSetupView: ((_ view: ViewType, _ section: Section, _ form: FormViewController) -> ())?
    public var height: (()->CGFloat)?

    lazy internal var staticView : ViewType? = {
        guard let view = self.viewProvider?.createView() else { return nil }
        return view;
    }()
    
    public func viewForSection(section: Section, type: HeaderFooterType, controller: FormViewController) -> UIView? {
        var view: ViewType?
        if type == .Header {
            view = section.headerView as? ViewType
            if view == nil {
                view = viewProvider?.createView()
                section.headerView = view
            }
        }
        else {
            view = section.footerView as? ViewType
            if view == nil {
                view = viewProvider?.createView()
                section.footerView = view
            }
        }
        guard let v = view else { return nil }
        onSetupView?(v, section, controller)
        v.setNeedsUpdateConstraints()
        v.updateConstraintsIfNeeded()
        v.setNeedsLayout()
        v.layoutIfNeeded()
        return v
    }
    
    init?(title: String?){
        guard let t = title else { return nil }
        self.init(stringLiteral: t)
    }
    
    public init(_ provider: HeaderFooterProvider<ViewType>){
        viewProvider = provider
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.title  = value
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.title = value
    }

    public init(stringLiteral value: String) {
        self.title = value
    }
}


extension Section {
    
    private class KVOWrapper : NSObject{
        
        dynamic var _rows = NSMutableArray()
        var rows : NSMutableArray {
            get {
                return mutableArrayValue(forKey: "_rows")
            }
        }
        public var _allRows = [BaseRow]()
        
        weak var section: Section?
        
        init(section: Section){
            self.section = section
            super.init()
            addObserver(self, forKeyPath: "_rows", options: NSKeyValueObservingOptions.new.union(.old), context:nil)
        }
        
        deinit{
            removeObserver(self, forKeyPath: "_rows")
        }
        
        override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
            let newRows = change![NSKeyValueChangeNewKey] as? [BaseRow] ?? []
            let oldRows = change![NSKeyValueChangeOldKey] as? [BaseRow] ?? []
            guard let delegateValue = section?.form?.delegate, let keyPathValue = keyPath, let changeType = change?[NSKeyValueChangeKindKey] else{ return }
            guard keyPathValue == "_rows" else { return }
            switch changeType.unsignedLongValue {
                case NSKeyValueChange.Setting.rawValue:
                    delegateValue.rowsHaveBeenAdded(newRows, atIndexPaths:[NSIndexPath(index: 0)])
                case NSKeyValueChange.Insertion.rawValue:
                    let indexSet = change![NSKeyValueChangeIndexesKey] as! NSIndexSet
                    delegateValue.rowsHaveBeenAdded(newRows, atIndexPaths: indexSet.map { NSIndexPath(forRow: $0, inSection: section!.index! ) } )
                case NSKeyValueChange.Removal.rawValue:
                    let indexSet = change![NSKeyValueChangeIndexesKey] as! NSIndexSet
                    delegateValue.rowsHaveBeenRemoved(oldRows, atIndexPaths: indexSet.map { NSIndexPath(forRow: $0, inSection: section!.index! ) } )
                case NSKeyValueChange.Replacement.rawValue:
                    let indexSet = change![NSKeyValueChangeIndexesKey] as! NSIndexSet
                    delegateValue.rowsHaveBeenReplaced(oldRows: oldRows, newRows: newRows, atIndexPaths: indexSet.map { NSIndexPath(forRow: $0, inSection: section!.index!)})
                default:
                    assertionFailure()
            }
        }
    }
    
    public func rowByTag<Row: RowType>(tag: String) -> Row? {
        guard let index = kvoWrapper._allRows.firstIndex(of:{ $0.tag == tag }) else { return nil }
        return kvoWrapper._allRows[index] as? Row
    }
}

extension Section /* Condition */{
    
    //MARK: Hidden/Disable Engine
    
    public func evaluateHidden(){
        if let h = hidden, let f = form {
            switch h {
                case .Function(_ , let callback):
                    hiddenCache = callback(f)
                case .Predicate(let predicate):
                    hiddenCache = predicate.evaluate(with: self, substitutionVariables: f.dictionaryValuesToEvaluatePredicate())
            }
            if hiddenCache {
                form?.hideSection(self)
            }
            else{
                form?.showSection(self)
            }
        }
    }
    
    func wasAddedToForm(form: Form) {
        self.form = form
        addToRowObservers()
        evaluateHidden()
        for row in kvoWrapper._allRows {
            row.wasAddedToFormInSection(self)
        }
    }
    
    func addToRowObservers(){
        guard let h = hidden else { return }
        switch h {
            case .Function(let tags, _):
                form?.addRowObservers(taggable: self, rowTags: tags, type: .Hidden)
            case .Predicate(let predicate):
                form?.addRowObservers(taggable: self, rowTags: predicate.predicateVars, type: .Hidden)
        }
    }
    
    func willBeRemovedFromForm(){
        for row in kvoWrapper._allRows {
            row.willBeRemovedFromForm()
        }
        removeFromRowObservers()
        self.form = nil
    }
    
    func removeFromRowObservers(){
        guard let h = hidden else { return }
        switch h {
            case .Function(let tags, _):
                form?.removeRowObservers(taggable: self, rows: tags, type: .Hidden)
            case .Predicate(let predicate):
                form?.removeRowObservers(taggable: self, rows: predicate.predicateVars, type: .Hidden)
        }
    }
    
    internal func hideRow(row: BaseRow){
        row.baseCell.cellResignFirstResponder()
        (row as? BaseInlineRowType)?.collapseInlineRow()
        kvoWrapper.rows.remove(row)
    }
    
    internal func showRow(row: BaseRow){
        guard !kvoWrapper.rows.contains(row) else { return }
        guard var index = kvoWrapper._allRows.firstIndex(of:row) else { return }
        var formIndex = NSNotFound
        while (formIndex == NSNotFound && index > 0){
            let previous = kvoWrapper._allRows[index-=1]
            formIndex = kvoWrapper.rows.indexOfObject(previous)
        }
        kvoWrapper.rows.insertObject(row, atIndex: formIndex == NSNotFound ? 0 : ++formIndex)
    }
}

// MARK: Row

internal protocol Disableable : Taggable {
    func evaluateDisabled()
    var disabled : Condition? { get set }
    var isDisabled : Bool { get }
}

internal protocol Hidable: Taggable {
    func evaluateHidden()
    var hidden : Condition? { get set }
    var isHidden : Bool { get }
}

extension PresenterRowType {
    public func onPresent(callback: @escaping (FormViewController, ProviderType)->()) -> Self {
        onPresentCallback = callback
        return self
    }
}

extension RowType where Self: BaseRow, Cell : TypedCellType, Cell.Value == Value {
    
    public init(_ tag: String? = nil, _ initializer: ((Self) -> ()) = { _ in }) {
        self.init(tag: tag)
        RowDefaults.rowInitialization["\(type(of: self))"]?(self)
        initializer(self)
    }
}

internal class RowDefaults {
    public static var cellUpdate = Dictionary<String, (BaseCell, BaseRow) -> Void>()
    public static var cellSetup = Dictionary<String, (BaseCell, BaseRow) -> Void>()
    public static var onCellHighlight = Dictionary<String, (BaseCell, BaseRow) -> Void>()
    public static var onCellUnHighlight = Dictionary<String, (BaseCell, BaseRow) -> Void>()
    public static var rowInitialization = Dictionary<String, (BaseRow) -> Void>()
    public static var rawCellUpdate = Dictionary<String, Any>()
    public static var rawCellSetup = Dictionary<String, Any>()
    public static var rawOnCellHighlight = Dictionary<String, Any>()
    public static var rawOnCellUnHighlight = Dictionary<String, Any>()
    public static var rawRowInitialization = Dictionary<String, Any>()
    
}

extension RowType where Self : BaseRow, Cell : TypedCellType, Cell.Value == Value {
    
    public static var defaultCellUpdate:((Cell, Self) -> ())? {
        set {
            if let newValue = newValue {
                let wrapper : (BaseCell, BaseRow) -> Void = { (baseCell: BaseCell, baseRow: BaseRow) in
                newValue(baseCell as! Cell, baseRow as! Self)
                }
                RowDefaults.cellUpdate["\(self)"] = wrapper
                RowDefaults.rawCellUpdate["\(self)"] = newValue
            }
            else {
                RowDefaults.cellUpdate["\(self)"] = nil
                RowDefaults.rawCellUpdate["\(self)"] = nil
            }
        }
        get{ return RowDefaults.rawCellUpdate["\(self)"] as? ((Cell, Self) -> ()) }
    }
    
    public static var defaultCellSetup:((Cell, Self) -> ())? {
        set {
            if let newValue = newValue {
                let wrapper : (BaseCell, BaseRow) -> Void = { (baseCell: BaseCell, baseRow: BaseRow) in
                newValue(baseCell as! Cell, baseRow as! Self)
                }
                RowDefaults.cellSetup["\(self)"] = wrapper
                RowDefaults.rawCellSetup["\(self)"] = newValue
        }
        else {
                RowDefaults.cellSetup["\(self)"] = nil
                RowDefaults.rawCellSetup["\(self)"] = nil
            }
        }
        get{ return RowDefaults.rawCellSetup["\(self)"] as? ((Cell, Self) -> ()) }
    }
    
    public static var defaultOnCellHighlight:((Cell, Self) -> ())? {
        set {
            if let newValue = newValue {
                let wrapper : (BaseCell, BaseRow) -> Void = { (baseCell: BaseCell, baseRow: BaseRow) in
                    newValue(baseCell as! Cell, baseRow as! Self)
                }
                RowDefaults.onCellHighlight["\(self)"] = wrapper
                RowDefaults.rawOnCellHighlight["\(self)"] = newValue
            }
            else {
                RowDefaults.onCellHighlight["\(self)"] = nil
                RowDefaults.rawOnCellHighlight["\(self)"] = nil
            }
        }
        get{ return RowDefaults.rawOnCellHighlight["\(self)"] as? ((Cell, Self) -> ()) }
    }
    
    public static var defaultOnCellUnHighlight:((Cell, Self) -> ())? {
        set {
            if let newValue = newValue {
            let wrapper : (BaseCell, BaseRow) -> Void = { (baseCell: BaseCell, baseRow: BaseRow) in
                newValue(baseCell as! Cell, baseRow as! Self)
            }
                RowDefaults.onCellUnHighlight ["\(self)"] = wrapper
                RowDefaults.rawOnCellUnHighlight["\(self)"] = newValue
            }
            else {
                RowDefaults.onCellUnHighlight["\(self)"] = nil
                RowDefaults.rawOnCellUnHighlight["\(self)"] = nil
            }
        }
        get { return RowDefaults.rawOnCellUnHighlight["\(self)"] as? ((Cell, Self) -> ()) }
    }
    
    public static var defaultRowInitializer:((Self) -> ())? {
        set {
            if let newValue = newValue {
                let wrapper : (BaseRow) -> Void = { (baseRow: BaseRow) in
                    newValue(baseRow as! Self)
                }
                RowDefaults.rowInitialization["\(self)"] = wrapper
                RowDefaults.rawRowInitialization["\(self)"] = newValue
            }
            else {
                RowDefaults.rowInitialization["\(self)"] = nil
                RowDefaults.rawRowInitialization["\(self)"] = nil
            }
        }
        get { return RowDefaults.rawRowInitialization["\(self)"] as? ((Self) -> ()) }
    }
    
    public func onChange(callback: @escaping (Self) -> ()) -> Self{
        callbackOnChange = { [unowned self] in callback(self) }
        return self
    }
    
    public func cellUpdate(callback: @escaping ((_ cell: Cell, _ row: Self) -> ())) -> Self{
        callbackCellUpdate = { [unowned self] in  callback(self.cell, self) }
        return self
    }
    
    public func cellSetup(callback: @escaping ((_ cell: Cell, _ row: Self) -> ())) -> Self{
        callbackCellSetup = { [unowned self] (cell:Cell) in  callback(cell, self) }
        return self
    }
    
    public func onCellSelection(callback: @escaping ((_ cell: Cell, _ row: Self) -> ())) -> Self{
        callbackCellOnSelection = { [unowned self] in  callback(self.cell, self) }
        return self
    }
    
    public func onCellHighlight(callback: @escaping (_ cell: Cell, _ row: Self)->()) -> Self {
        callbackOnCellHighlight = { [unowned self] in  callback(self.cell, self) }
        return self
    }
    
    public func onCellUnHighlight(callback: @escaping (_ cell: Cell, _ row: Self)->()) -> Self {
        callbackOnCellUnHighlight = { [unowned self] in  callback(self.cell, self) }
        return self
    }
}


public class BaseRow : BaseRowType {

    public var callbackOnChange: (()->Void)?
    public var callbackCellUpdate: (()->Void)?
    public var callbackCellSetup: Any?
    public var callbackCellOnSelection: (()->Void)?
    public var callbackOnCellHighlight: (()->Void)?
    public var callbackOnCellUnHighlight: (()->Void)?
    public var callbackOnExpandInlineRow: Any?
    public var callbackOnCollapseInlineRow: Any?
    public var _inlineRow: BaseRow?
    
    public var title: String?
    public var cellStyle = UITableViewCell.CellStyle.value1
    public var tag: String?
    public var baseCell: BaseCell! { return nil }
    public var baseValue: Any? {
        set {}
        get { return nil }
    }
    public var disabled : Condition? {
        willSet { removeFromDisabledRowObservers() }
        didSet  { addToDisabledRowObservers() }
    }
    public var hidden : Condition? {
        willSet { removeFromHiddenRowObservers() }
        didSet  { addToHiddenRowObservers() }
    }
    public var isDisabled : Bool { return disabledCache }
    public var isHidden : Bool { return hiddenCache }
    
    public weak var section: Section?

    public required init(tag: String? = nil){
        self.tag = tag
    }
    public func updateCell() {}
    public func didSelect() {}
    
    public func hightlightCell() {}
    public func unhighlightCell() {}
    
    public func prepareForSegue(segue: UIStoryboardSegue) {}
    
    public final func indexPath() -> NSIndexPath? {
        guard let sectionIndex = section?.index, let rowIndex = section?.firstIndex(of:self) else { return nil }
        return NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
    }
    
    private var hiddenCache = false
    private var disabledCache = false {
        willSet {
            if newValue == true && disabledCache == false  {
                baseCell.cellResignFirstResponder()
            }
        }
    }
}

extension BaseRow: Equatable, Hidable, Disableable {}

public func ==(lhs: BaseRow, rhs: BaseRow) -> Bool{
    return lhs === rhs
}

extension BaseRow {
    
    public final func evaluateHidden() {
        guard let h = hidden, let form = section?.form else { return }
        switch h {
            case .Function(_ , let callback):
                hiddenCache = callback(form)
            case .Predicate(let predicate):
                hiddenCache = predicate.evaluate(with: self, substitutionVariables: form.dictionaryValuesToEvaluatePredicate())
        }
        if hiddenCache {
            section?.hideRow(row: self)
        }
        else{
            section?.showRow(row: self)
        }
    }
    
    public final func evaluateDisabled() {
        guard let d = disabled, let form = section?.form else { return }
        switch d {
            case .Function(_ , let callback):
                disabledCache = callback(form)
            case .Predicate(let predicate):
                disabledCache = predicate.evaluate(with: self, substitutionVariables: form.dictionaryValuesToEvaluatePredicate())
        }
        updateCell()
    }
    
    private final func wasAddedToFormInSection(section: Section) {
        self.section = section
        if let t = tag {
            assert(section.form?.rowsByTag[t] == nil, "Duplicate tag \(t)")
            self.section?.form?.rowsByTag[t] = self
        }
        addToRowObservers()
        evaluateHidden()
        evaluateDisabled()
    }
    
    private final func addToHiddenRowObservers() {
        guard let h = hidden else { return }
        switch h {
            case .Function(let tags, _):
                section?.form?.addRowObservers(taggable: self, rowTags: tags, type: .Hidden)
            case .Predicate(let predicate):
                section?.form?.addRowObservers(taggable: self, rowTags: predicate.predicateVars, type: .Hidden)
        }
    }
    
    private final func addToDisabledRowObservers() {
        guard let d = disabled else { return }
        switch d {
            case .Function(let tags, _):
                section?.form?.addRowObservers(taggable: self, rowTags: tags, type: .Disabled)
            case .Predicate(let predicate):
                section?.form?.addRowObservers(taggable: self, rowTags: predicate.predicateVars, type: .Disabled)
        }
    }
    
    private final func addToRowObservers(){
        addToHiddenRowObservers()
        addToDisabledRowObservers()
    }
    
    public final func willBeRemovedFromForm(){
        (self as? BaseInlineRowType)?.collapseInlineRow()
        if let t = tag {
            section?.form?.rowsByTag[t] = nil
        }
        removeFromRowObservers()
    }
    
    
    private final func removeFromHiddenRowObservers() {
        guard let h = hidden else { return }
        switch h {
            case .Function(let tags, _):
                section?.form?.removeRowObservers(taggable: self, rows: tags, type: .Hidden)
            case .Predicate(let predicate):
                section?.form?.removeRowObservers(taggable: self, rows: predicate.predicateVars, type: .Hidden)
        }
    }
    
    private final func removeFromDisabledRowObservers() {
        guard let d = disabled else { return }
        switch d {
            case .Function(let tags, _):
                section?.form?.removeRowObservers(taggable: self, rows: tags, type: .Disabled)
            case .Predicate(let predicate):
                section?.form?.removeRowObservers(taggable: self, rows: predicate.predicateVars, type: .Disabled)
        }
    }
    
    
    private final func removeFromRowObservers(){
        removeFromHiddenRowObservers()
        removeFromDisabledRowObservers()
    }
}

public class RowOf<T: Equatable>: BaseRow {
    
    public var value : T?{
        didSet {
            guard value != oldValue else { return }
            guard let form = section?.form else { return }
            if let delegate = form.delegate {
                delegate.rowValueHasBeenChanged(row: self, oldValue: oldValue, newValue: value)
                callbackOnChange?()
            }
            guard let t = tag else { return }
            if let rowObservers = form.rowObservers[t]?[.Hidden]{
                for rowObserver in rowObservers {
                    (rowObserver as? Hidable)?.evaluateHidden()
                }
            }
            if let rowObservers = form.rowObservers[t]?[.Disabled]{
                for rowObserver in rowObservers {
                    (rowObserver as? Disableable)?.evaluateDisabled()
                }
            }
        }
    }
    
    public override var baseValue: Any? {
        get { return value }
        set { value = newValue as? T }
    }
    
    public var dataProvider: DataProvider<T>?
        
    public var displayValueFor : ((T?) -> String?)? = {
        if let t = $0 {
            return String(t)
        }
        return nil
    }
    
    public required init(tag: String?){
        super.init(tag: tag)
    }
    
}

public class Row<T: Equatable, Cell: CellType>: RowOf<T>,  TypedRowType where Cell: BaseCell, Cell.Value == T {
    
    public var cellProvider = CellProvider<Cell>()
    public let cellType: Cell.Type! = Cell.self
    
    private var _cell: Cell! {
        didSet {
            RowDefaults.cellSetup["\(type(of: self))"]?(_cell, self)
            (callbackCellSetup as? ((Cell) -> ()))?(_cell)
        }
    }
    
    public var cell : Cell! {
        guard _cell == nil else{
            return _cell
        }
        let result = cellProvider.createCell(cellStyle: self.cellStyle)
        result.row = self
        result.setup()
        _cell = result
        return _cell
    }
    
    public override var baseCell: BaseCell { return cell }

    public required init(tag: String?) {
        super.init(tag: tag)
    }

    override public func updateCell() {
        super.updateCell()
        cell.update()
        customUpdateCell()
        RowDefaults.cellUpdate["\(type(of: self))"]?(cell, self)
        callbackCellUpdate?()
        cell.setNeedsLayout()
        cell.setNeedsUpdateConstraints()
    }
    
    public override func didSelect() {
        super.didSelect()
        if !isDisabled {
            cell?.didSelect()
        }
        customDidSelect()
        callbackCellOnSelection?()
    }
    
    override public func hightlightCell() {
        super.hightlightCell()
        cell.highlight()
        RowDefaults.onCellHighlight["\(type(of: self))"]?(cell, self)
        callbackOnCellHighlight?()
    }
    
    public override func unhighlightCell() {
        super.unhighlightCell()
        cell.unhighlight()
        RowDefaults.onCellUnHighlight["\(type(of: self))"]?(cell, self)
        callbackOnCellUnHighlight?()
    }
    
    public func customDidSelect(){}
    
    public func customUpdateCell(){}
    
}

public class SelectorRow<T: Equatable, VCType: TypedRowControllerType>: OptionsRow<T, PushSelectorCell<T>> where VCType: UIViewController,  VCType.RowValue == T {
    
    public var presentationMode: PresentationMode<VCType>?
    public var onPresentCallback : ((FormViewController, VCType)->())?
    
    required public init(tag: String?) {
        super.init(tag: tag)
    }
    
    public required convenience init(_ tag: String, _ initializer: ((SelectorRow<T, VCType>) -> ()) = { _ in }) {
        self.init(tag:tag)
        RowDefaults.rowInitialization["\(type(of: self))"]?(self)
        initializer(self)
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            if let presentationMode = presentationMode {
                if let controller = presentationMode.createController(){
                    controller.row = self
                    if let title = selectorTitle {
                        controller.title = title
                    }
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
        if let title = selectorTitle {
            rowVC.title = title
        }
        if let callback = self.presentationMode?.completionHandler{
            rowVC.completionCallback = callback
        }
        onPresentCallback?(cell.formViewController()!, rowVC)
        rowVC.row = self
    }
}

public class GenericMultipleSelectorRow<T: Hashable, VCType: TypedRowControllerType>: Row<Set<T>, PushSelectorCell<Set<T>>> where VCType: UIViewController,  VCType.RowValue == Set<T> {
    
    public var presentationMode: PresentationMode<VCType>?
    public var onPresentCallback : ((FormViewController, VCType)->())?
    
    public var selectorTitle: String?
    
    public var options: [T] {
        get { return self.dataProvider?.arrayData?.map({ $0.first! }) ?? [] }
        set { self.dataProvider = DataProvider(arrayData: newValue.map({ Set<T>(arrayLiteral: $0) })) }
    }
    
    required public init(tag: String?) {
        super.init(tag: tag)
        presentationMode = .Show(controllerProvider: ControllerProvider.Callback { return VCType() }, completionCallback: { vc in vc.navigationController?.popViewController(animated: true) })
    }
    
    public required convenience init(_ tag: String, _ initializer: ((GenericMultipleSelectorRow<T, VCType>) -> ()) = { _ in }) {
        self.init(tag:tag)
        RowDefaults.rowInitialization["\(type(of: self))"]?(self)
        initializer(self)
    }
    
    public override func customDidSelect() {
        super.customDidSelect()
        if !isDisabled {
            if let presentationMode = presentationMode {
                if let controller = presentationMode.createController(){
                    controller.row = self
                    if let title = selectorTitle {
                        controller.title = title
                    }
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
        if let title = selectorTitle {
            rowVC.title = title
        }
        if let callback = self.presentationMode?.completionHandler{
            rowVC.completionCallback = callback
        }
        onPresentCallback?(cell.formViewController()!, rowVC)
        rowVC.row = self
        
    }
}

// MARK: Operators

infix operator +++{ associativity left precedence 95 }

public func +++(left: Form, right: Section) -> Form {
    left.append(formSection: right)
    return left
}

infix operator +++= { associativity left precedence 95 }

public func +++=( left: inout Form, right: Section){
    left = left +++ right
}

public func +++=( left: inout Form, right: BaseRow){
    left +++= Section() <<< right
}

public func +++(left: Section, right: Section) -> Form {
    let form = Form()
    form +++ left +++ right
    return form
}

public func +++(left: BaseRow, right: BaseRow) -> Form {
    let form = Section() <<< left +++ Section() <<< right
    return form
}

infix operator <<<{ associativity left precedence 100 }

public func <<<(left: Section, right: BaseRow) -> Section {
    left.append(formRow: right)
    return left
}

public func <<<(left: BaseRow, right: BaseRow) -> Section {
    let section = Section()
    section <<< left <<< right
    return section
}


public func +=< C : CollectionType>( lhs: inout Section, rhs: C) where C.Generator.Element == BaseRow{
    lhs.appendContentsOf(newElements: rhs)
}

public func +=< C : CollectionType>( lhs: inout Form, rhs: C) where C.Generator.Element == Section{
    lhs.appendContentsOf(newElements: rhs)
}

// MARK: FormCells

public protocol TextFieldCell {
    var textField : UITextField { get }
}

public protocol AreaCell {
    var textView: UITextView { get }
}

extension CellType where Self: UITableViewCell {
}

public class BaseCell : UITableViewCell, BaseCellType {
    
    public var baseRow: BaseRow! { return nil }
    
    public var height: (()->CGFloat)?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    public func formViewController () -> FormViewController? {
        var responder : AnyObject? = self
        while responder != nil {
            if responder! is FormViewController {
                return responder as? FormViewController
            }
            responder = responder?.nextResponder()
        }
        return nil
    }
    
    public func setup(){}
    public func update() {}
    
    public func didSelect() {}
    
    public func highlight() {}
    public func unhighlight() {}
    
    
    public func cellCanBecomeFirstResponder() -> Bool {
        return false
    }
    
    public func cellBecomeFirstResponder() -> Bool {
        return becomeFirstResponder()
    }
    
    public func cellResignFirstResponder() -> Bool {
        return resignFirstResponder()
    }
}


public class Cell<T: Equatable> : BaseCell, TypedCellType {
    
    public typealias Value = T
    
    public var row : RowOf<T>!
    
    override public var inputAccessoryView: UIView? {
        if let v = formViewController()?.inputAccessoryViewForRow(row: row){
            return v
        }
        return super.inputAccessoryView
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    public required override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        fatalError("init(style:reuseIdentifier:) has not been implemented")
    }
    
    public override func setup(){
        super.setup()
    }
    
    public override func update(){
        super.update()
        textLabel?.text = row.title
        textLabel?.textColor = row.isDisabled ? .gray : .black
        detailTextLabel?.text = row.displayValueFor?(row.value)
    }
    
    public override func didSelect() {}
    
    public override func canBecomeFirstResponder() -> Bool {
        return false
    }
    
    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            formViewController()?.beginEditing(cell: self)
        }
        return result
    }
    
    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            formViewController()?.endEditing(cell: self)
        }
        return result
    }
    
    public override var baseRow : BaseRow! { return row }
}

public struct CellProvider<Cell: BaseCell> where Cell: CellType {
    
    public private (set) var nibName: String?
    public private(set) var bundle: Bundle!

    
    public init(){}
    
    public init(nibName: String, bundle: Bundle? = nil){
        self.nibName = nibName
        self.bundle = bundle ?? Bundle(for: Cell.self)
    }
    
    func createCell(cellStyle: UITableViewCell.CellStyle) -> Cell {
        if let nibName = self.nibName {
            return bundle.loadNibNamed(nibName, owner: nil, options: nil)?.first as! Cell
        }
        return Cell.init(style: cellStyle, reuseIdentifier: nil)
    }
}

public enum ControllerProvider<VCType: UIViewController>{
    case Callback(builder: (() -> VCType))
    case NibFile(name: String, bundle: Bundle?)
    case StoryBoard(storyboardId: String, storyboardName: String, bundle: Bundle?)
    
    func createController() -> VCType {
        switch self {
            case .Callback(let builder):
                return builder()
            case .NibFile(let nibName, let bundle):
                return VCType.init(nibName: nibName, bundle:bundle ?? Bundle(for: VCType.self))
            case .StoryBoard(let storyboardId, let storyboardName, let bundle):
                let sb = UIStoryboard(name: storyboardName, bundle: bundle ?? Bundle(for: VCType.self))
                return sb.instantiateViewController(withIdentifier: storyboardId) as! VCType
        }
    }
}

public struct DataProvider<T: Equatable> {
    
    internal var arrayData: [T]?
    
    init(arrayData: [T]){
        self.arrayData = arrayData
    }
}

public enum PresentationMode<VCType: UIViewController> {
    
    case Show(controllerProvider: ControllerProvider<VCType>, completionCallback: ((UIViewController)->())?)
    case PresentModally(controllerProvider: ControllerProvider<VCType>, completionCallback: ((UIViewController)->())?)
    case SegueName(segueName: String, completionCallback: ((UIViewController)->())?)
    case SegueClass(segueClass: UIStoryboardSegue.Type, completionCallback: ((UIViewController)->())?)
    
    
    var completionHandler: ((UIViewController) ->())? {
        switch self{
            case .Show(_, let completionCallback):
                return completionCallback
            case .PresentModally(_, let completionCallback):
                return completionCallback
            case .SegueName(_, let completionCallback):
                return completionCallback
            case .SegueClass(_, let completionCallback):
                return completionCallback
        }
    }
    
    func presentViewController(viewController: VCType!, row: BaseRow, presentingViewController:FormViewController){
        switch self {
            case .Show(_, _):
                presentingViewController.show(viewController, sender: row)
            case .PresentModally:
                presentingViewController.present(viewController, animated: true, completion: nil)
            case .SegueName(let segueName, _):
                presentingViewController.performSegue(withIdentifier: segueName, sender: row)
            case .SegueClass(let segueClass, _):
                let segue = segueClass.init(identifier: row.tag, source: presentingViewController, destination: viewController)
                presentingViewController.prepare(for: segue, sender: row)
                segue.perform()
        }
        
    }
    
    func createController() -> VCType? {
        switch self {
            case .Show(let controllerProvider, let completionCallback):
                let controller = controllerProvider.createController()
                let completionController = controller as? RowControllerType
                if let callback = completionCallback {
                    completionController?.completionCallback = callback
                }
                return controller
            case .PresentModally(let controllerProvider, let completionCallback):
                let controller = controllerProvider.createController()
                let completionController = controller as? RowControllerType
                if let callback = completionCallback {
                    completionController?.completionCallback = callback
                }
                return controller
            default:
                return nil;
        }
    }
}

public protocol FormatterProtocol{
    func getNewPosition(forPosition forPosition: UITextPosition, inTextInput textInput: UITextInput, oldValue: String?, newValue: String?) -> UITextPosition
}

//MARK: Predicate Machine

internal enum ConditionType {
    case Hidden, Disabled
}

public enum Condition {
    case Function([String], (Form)->Bool)
    case Predicate(NSPredicate)
}

extension Condition : ExpressibleByBooleanLiteral {
    
    public init(booleanLiteral value: Bool){
        self = Condition.Function([]) { _ in return value }
    }
}

extension Condition : ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String){
        self = .Predicate(NSPredicate(format: value))
    }
    
    public init(unicodeScalarLiteral value: String) {
        self = .Predicate(NSPredicate(format: value))
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .Predicate(NSPredicate(format: value))
    }
}

//MARK: Errors

public enum EurekaError : ErrorType {
    case DuplicatedTag(tag: String)
}

//Mark: FormViewController

public protocol FormViewControllerProtocol {
    func beginEditing<T:Equatable>(cell: Cell<T>)
    func endEditing<T:Equatable>(cell: Cell<T>)
    
    func insertAnimationForRows(rows: [BaseRow]) -> UITableView.RowAnimation
    func deleteAnimationForRows(rows: [BaseRow]) -> UITableView.RowAnimation
    func reloadAnimationOldRows(oldRows: [BaseRow], newRows: [BaseRow]) -> UITableView.RowAnimation
    func insertAnimationForSections(sections : [Section]) -> UITableView.RowAnimation
    func deleteAnimationForSections(sections : [Section]) -> UITableView.RowAnimation
    func reloadAnimationOldSections(oldSections: [Section], newSections:[Section]) -> UITableView.RowAnimation
}

public struct RowNavigationOptions : OptionSetType {
    
    private enum NavigationOptions : Int {
        case Disabled = 0, Enabled = 1, StopDisabledRow = 2, SkipCanNotBecomeFirstResponderRow = 4
    }
    public let rawValue: Int
    public  init(rawValue: Int){ self.rawValue = rawValue}
    private init(_ options:NavigationOptions ){ self.rawValue = options.rawValue }
    @available(*, unavailable, renamed: "Disabled")
    public static let None = RowNavigationOptions(.Disabled)
    public static let Disabled = RowNavigationOptions(.Disabled)
    public static let Enabled = RowNavigationOptions(.Enabled)
    public static let StopDisabledRow = RowNavigationOptions(.StopDisabledRow)
    public static let SkipCanNotBecomeFirstResponderRow = RowNavigationOptions(.SkipCanNotBecomeFirstResponderRow)
}

public struct InlineRowHideOptions : OptionSetType {
    
    private enum _InlineRowHideOptions : Int {
        case Never = 0, AnotherInlineRowIsShown = 1, FirstResponderChanges = 2
    }
    public let rawValue: Int
    public init(rawValue: Int){ self.rawValue = rawValue}
    private init(_ options:_InlineRowHideOptions ){ self.rawValue = options.rawValue }
    
    public static let Never = InlineRowHideOptions(.Never)
    public static let AnotherInlineRowIsShown = InlineRowHideOptions(.AnotherInlineRowIsShown)
    public static let FirstResponderChanges = InlineRowHideOptions(.FirstResponderChanges)
}


public class FormViewController : UIViewController, FormViewControllerProtocol {
    
    @IBOutlet public var tableView: UITableView?
    
    private lazy var _form : Form = { [unowned self] in
        let form = Form()
        form.delegate = self
        return form
        }()
    public var form : Form {
        get { return _form }
        set {
            _form.delegate = nil
            tableView?.endEditing(false)
            _form = newValue
            _form.delegate = self;
            if isViewLoaded && tableView?.window != nil {
                tableView?.reloadData()
            }
        }
    }
    
    lazy public var navigationAccessoryView : NavigationAccessoryView = {
        [unowned self] in
        let naview = NavigationAccessoryView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44.0))
        naview.doneButton.target = self
        naview.doneButton.action = "navigationDone:"
        naview.previousButton.target = self
        naview.previousButton.action = "navigationAction:"
        naview.nextButton.target = self
        naview.nextButton.action = "navigationAction:"
        naview.tintColor = self.view.tintColor
        return naview
        }()
    
    public var navigationOptions : RowNavigationOptions?
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        if tableView == nil {
            tableView = UITableView(frame: view.bounds, style: .grouped)
            tableView?.autoresizingMask = UIView.AutoresizingMask.flexibleWidth.union(.flexibleHeight)
        }
        if tableView?.superview == nil {
            view.addSubview(tableView!)
        }
        if tableView?.delegate == nil {
            tableView?.delegate = self
        }
        if tableView?.dataSource == nil {
            tableView?.dataSource = self
        }
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = 44.0
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView?.indexPathForSelectedRow {
            tableView?.reloadRows(at: [selectedIndexPath], with: .none)
            tableView?.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
            tableView?.deselectRow(at: selectedIndexPath, animated: true)
        }
        NotificationCenter.default.addObserver(self, selector: "keyboardWillShow:", name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: "keyboardWillHide:", name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepare(for: segue, sender: sender)
        let baseRow = sender as? BaseRow
        baseRow?.prepareForSegue(segue: segue)
    }
    
    //MARK: FormDelegate
    
    public func rowValueHasBeenChanged(row: BaseRow, oldValue: Any, newValue: Any) {}
    
    //MARK: FormViewControllerProtocol
    
    public final func beginEditing<T:Equatable>(cell: Cell<T>) {
        cell.row.hightlightCell()
        guard let _ = tableView, (form.inlineRowHideOptions ?? Form.defaultInlineRowHideOptions).contains(.FirstResponderChanges) else { return }
        let row = cell.baseRow
        let inlineRow = row._inlineRow
        for row in form.allRows.filter({ $0 !== row && $0 !== inlineRow && $0._inlineRow != nil }) {
            if let inlineRow = row as? BaseInlineRowType {
                inlineRow.collapseInlineRow()
            }
        }
    }
    
    public final func endEditing<T:Equatable>(cell: Cell<T>) {
        cell.row.unhighlightCell()
    }
    
    public func insertAnimationForRows(rows: [BaseRow]) -> UITableView.RowAnimation {
        return .fade
    }
    
    public func deleteAnimationForRows(rows: [BaseRow]) -> UITableView.RowAnimation {
        return .fade
    }
    
    public func reloadAnimationOldRows(oldRows: [BaseRow], newRows: [BaseRow]) -> UITableView.RowAnimation {
        return .automatic
    }
    
    public func insertAnimationForSections(sections: [Section]) -> UITableView.RowAnimation {
        return .automatic
    }
    
    public func deleteAnimationForSections(sections: [Section]) -> UITableView.RowAnimation {
        return .automatic
    }
    
    public func reloadAnimationOldSections(oldSections: [Section], newSections: [Section]) -> UITableView.RowAnimation {
        return .automatic
    }
    
    //MARK: Private
    
    private var oldBottomInset : CGFloat = 0.0
}

extension FormViewController : UITableViewDelegate {
    
    //MARK: UITableViewDelegate
    
    public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard tableView == self.tableView else { return }
        form[indexPath].updateCell()
    }
    
    public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return indexPath
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard tableView == self.tableView else { return }
        if !form[indexPath].baseCell.cellCanBecomeFirstResponder() || !form[indexPath].baseCell.cellBecomeFirstResponder() {
            self.tableView?.endEditing(true)
        }
        form[indexPath].didSelect()
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard tableView == self.tableView else { return tableView.rowHeight }
        let row = form[indexPath.section][indexPath.row]
        return row.baseCell.height?() ?? tableView.rowHeight
    }
    
    public func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard tableView == self.tableView else { return tableView.rowHeight }
        let row = form[indexPath.section][indexPath.row]
        return row.baseCell.height?() ?? tableView.estimatedRowHeight
    }
    
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return form[section].header?.viewForSection(section: form[section], type: .Header, controller: self)
    }
    
    public func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return form[section].footer?.viewForSection(section: form[section], type:.Footer, controller: self)
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if let height = form[section].header?.height {
            return height()
        }
        guard let view = form[section].header?.viewForSection(section: form[section], type: .Header, controller: self) else{
            return UITableView.automaticDimension
        }
        guard view.bounds.height != 0 else {
            return UITableView.automaticDimension
        }
        return view.bounds.height
    }
    
    public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let height = form[section].footer?.height {
            return height()
        }
        guard let view = form[section].footer?.viewForSection(section: form[section], type: .Footer, controller: self) else{
            return UITableView.automaticDimension
        }
        guard view.bounds.height != 0 else {
            return UITableView.automaticDimension
        }
        return view.bounds.height
    }
}

extension FormViewController : UITableViewDataSource {
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    
    //MARK: UITableViewDataSource
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return form.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return form[section].count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return form[indexPath].baseCell
    }
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return form[section].header?.title
    }
    
    public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return form[section].footer?.title
    }
}

extension FormViewController : FormDelegate {
    
    //MARK: FormDelegate
    
    public func sectionsHaveBeenAdded(sections: [Section], atIndexes: NSIndexSet){
        tableView?.beginUpdates()
        tableView?.insertSections(atIndexes as IndexSet, with: insertAnimationForSections(sections: sections))
        tableView?.endUpdates()
    }
    
    public func sectionsHaveBeenRemoved(sections: [Section], atIndexes: NSIndexSet){
        tableView?.beginUpdates()
        tableView?.deleteSections(atIndexes as IndexSet, with: deleteAnimationForSections(sections: sections))
        tableView?.endUpdates()
    }
    
    public func sectionsHaveBeenReplaced(oldSections oldSections:[Section], newSections: [Section], atIndexes: NSIndexSet){
        tableView?.beginUpdates()
        tableView?.reloadSections(atIndexes as IndexSet, with: reloadAnimationOldSections(oldSections: oldSections, newSections: newSections))
        tableView?.endUpdates()
    }
    
    public func rowsHaveBeenAdded(rows: [BaseRow], atIndexPaths: [NSIndexPath]) {
        tableView?.beginUpdates()
        tableView?.insertRows(at: atIndexPaths as [IndexPath], with: insertAnimationForRows(rows: rows))
        tableView?.endUpdates()
    }
    
    public func rowsHaveBeenRemoved(rows: [BaseRow], atIndexPaths: [NSIndexPath]) {
        tableView?.beginUpdates()
        tableView?.deleteRows(at: atIndexPaths as [IndexPath], with: deleteAnimationForRows(rows: rows))
        tableView?.endUpdates()
    }

    public func rowsHaveBeenReplaced(oldRows oldRows:[BaseRow], newRows: [BaseRow], atIndexPaths: [NSIndexPath]){
        tableView?.beginUpdates()
        tableView?.reloadRows(at: atIndexPaths as [IndexPath], with: reloadAnimationOldRows(oldRows: oldRows, newRows: newRows))
        tableView?.endUpdates()
    }
}

extension FormViewController : UIScrollViewDelegate {
    
    //MARK: UIScrollViewDelegate
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        tableView?.endEditing(true)
    }
}

extension FormViewController {
    
    //MARK: KeyBoard Notifications
    
    public func keyboardWillShow(notification: NSNotification){
        guard let table = tableView, let cell = table.findFirstResponder()?.formCell() else { return }
        let keyBoardInfo = notification.userInfo!
        let keyBoardFrame = table.window!.convertRect((keyBoardInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue)!, toView: table.superview)
        let newBottomInset = table.frame.origin.y + table.frame.size.height - keyBoardFrame.origin.y
        var tableInsets = table.contentInset
        var scrollIndicatorInsets = table.scrollIndicatorInsets
        oldBottomInset = oldBottomInset != 0.0 ? oldBottomInset : tableInsets.bottom
        if newBottomInset > oldBottomInset {
            tableInsets.bottom = newBottomInset
            scrollIndicatorInsets.bottom = tableInsets.bottom
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey]! as AnyObject).doubleValue)
            UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey]! as AnyObject).integerValue)!)
            table.contentInset = tableInsets
            table.scrollIndicatorInsets = scrollIndicatorInsets
            if let selectedRow = table.indexPath(for: cell) {
                table.scrollToRow(at: selectedRow, at: .none, animated: false)
            }
            UIView.commitAnimations()
        }
    }
    
    public func keyboardWillHide(notification: NSNotification){
        guard let table = tableView,  let _ = table.findFirstResponder()?.formCell() else  { return }
        let keyBoardInfo = notification.userInfo!
        var tableInsets = table.contentInset
        var scrollIndicatorInsets = table.scrollIndicatorInsets
        tableInsets.bottom = oldBottomInset
        scrollIndicatorInsets.bottom = oldBottomInset
        oldBottomInset = 0.0
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey]! as AnyObject).doubleValue)
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey]! as AnyObject).integerValue)!)
        table.contentInset = tableInsets
        table.scrollIndicatorInsets = scrollIndicatorInsets
        UIView.commitAnimations()
    }
}

extension FormViewController {
    
    //MARK: Navigation Methods
    
    private enum Direction { case Up, Down }
    
    func navigationDone(sender: UIBarButtonItem) {
        tableView?.endEditing(true)
    }
    
    func navigationAction(sender: UIBarButtonItem) {
        navigateToDirection(direction: sender == navigationAccessoryView.previousButton ? .Up : .Down)
    }
    
    private func navigateToDirection(direction: Direction){
        guard let currentCell = tableView?.findFirstResponder()?.formCell() else { return }
        guard let currentIndexPath = tableView?.indexPath(for: currentCell) else { assertionFailure(); return }
        guard let nextRow = nextRowForRow(currentRow: form[currentIndexPath], withDirection: direction) else { return }
        if nextRow.baseCell.cellCanBecomeFirstResponder(){
            tableView?.scrollToRowAtIndexPath(nextRow.indexPath()!, atScrollPosition: .None, animated: false)
            nextRow.baseCell.cellBecomeFirstResponder()
        }
    }
    
    private func nextRowForRow(currentRow: BaseRow, withDirection direction: Direction) -> BaseRow? {
        
        let options = navigationOptions ?? Form.defaultNavigationOptions
        guard options.contains(.Enabled) else { return nil }
        guard let nextRow = direction == .Down ? form.nextRowForRow(currentRow: currentRow) : form.previousRowForRow(currentRow: currentRow) else { return nil }
        if nextRow.isDisabled && options.contains(.StopDisabledRow) {
            return nil
        }
        if !nextRow.baseCell.cellCanBecomeFirstResponder() && !nextRow.isDisabled && !options.contains(.SkipCanNotBecomeFirstResponderRow){
            return nil
        }
        if (!nextRow.isDisabled && nextRow.baseCell.cellCanBecomeFirstResponder()){
            return nextRow
        }
        return nextRowForRow(currentRow: nextRow, withDirection:direction)
    }
    
    public func inputAccessoryViewForRow(row: BaseRow) -> UIView? {
        let options = navigationOptions ?? Form.defaultNavigationOptions
        guard options.contains(.Enabled) else { return nil }
        guard row.baseCell.cellCanBecomeFirstResponder() else { return nil}
        navigationAccessoryView.previousButton.isEnabled = nextRowForRow(currentRow: row, withDirection: .Up) != nil
        navigationAccessoryView.nextButton.isEnabled = nextRowForRow(currentRow: row, withDirection: .Down) != nil
        return navigationAccessoryView
    }
}

public class NavigationAccessoryView : UIToolbar {
    
    public var previousButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem(rawValue: 105)!, target: nil, action: nil)
    public var nextButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem(rawValue: 106)!, target: nil, action: nil)
    public var doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
    private var fixedSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
    private var flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: 44.0))
        autoresizingMask = .flexibleWidth
        fixedSpace.width = 22.0
        setItems([previousButton, fixedSpace, nextButton, flexibleSpace, doneButton], animated: false)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {}
}

