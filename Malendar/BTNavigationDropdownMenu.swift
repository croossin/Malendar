//
//  BTConfiguration.swift
//  BTNavigationDropdownMenu
//
//  Created by Pham Ba Tho on 6/30/15.
//  Copyright (c) 2015 PHAM BA THO. All rights reserved.
//

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

// MARK: BTNavigationDropdownMenu
public class BTNavigationDropdownMenu: UIView {
    
    // The color of menu title. Default is darkGrayColor()
    public var menuTitleColor: UIColor! {
        get {
            return self.configuration.menuTitleColor
        }
        set(value) {
            self.configuration.menuTitleColor = value
        }
    }
    
    // The height of the cell. Default is 50
    public var cellHeight: CGFloat! {
        get {
            return self.configuration.cellHeight
        }
        set(value) {
            self.configuration.cellHeight = value
        }
    }
    
    // The color of the cell background. Default is whiteColor()
    public var cellBackgroundColor: UIColor! {
        get {
            return self.configuration.cellBackgroundColor
        }
        set(color) {
            self.configuration.cellBackgroundColor = color
        }
    }
    
    public var cellSeparatorColor: UIColor! {
        get {
            return self.configuration.cellSeparatorColor
        }
        set(value) {
            self.configuration.cellSeparatorColor = value
        }
    }
    
    // The color of the text inside cell. Default is darkGrayColor()
    public var cellTextLabelColor: UIColor! {
        get {
            return self.configuration.cellTextLabelColor
        }
        set(value) {
            self.configuration.cellTextLabelColor = value
        }
    }
    
    // The font of the text inside cell. Default is HelveticaNeue-Bold, size 19
    public var cellTextLabelFont: UIFont! {
        get {
            return self.configuration.cellTextLabelFont
        }
        set(value) {
            self.configuration.cellTextLabelFont = value
            self.menuTitle.font = self.configuration.cellTextLabelFont
        }
    }
    
    // The color of the cell when the cell is selected. Default is lightGrayColor()
    public var cellSelectionColor: UIColor! {
        get {
            return self.configuration.cellSelectionColor
        }
        set(value) {
            self.configuration.cellSelectionColor = value
        }
    }
    
    // The checkmark icon of the cell
    public var checkMarkImage: UIImage! {
        get {
            return self.configuration.checkMarkImage
        }
        set(value) {
            self.configuration.checkMarkImage = value
        }
    }
    
    // The animation duration of showing/hiding menu. Default is 0.3
    public var animationDuration: TimeInterval! {
        get {
            return self.configuration.animationDuration
        }
        set(value) {
            self.configuration.animationDuration = value
        }
    }

    // The arrow next to navigation title
    public var arrowImage: UIImage! {
        get {
            return self.configuration.arrowImage
        }
        set(value) {
            self.configuration.arrowImage = value
            self.menuArrow.image = self.configuration.arrowImage
        }
    }
    
    // The padding between navigation title and arrow
    public var arrowPadding: CGFloat! {
        get {
            return self.configuration.arrowPadding
        }
        set(value) {
            self.configuration.arrowPadding = value
        }
    }
    
    // The color of the mask layer. Default is blackColor()
    public var maskBackgroundColor: UIColor! {
        get {
            return self.configuration.maskBackgroundColor
        }
        set(value) {
            self.configuration.maskBackgroundColor = value
        }
    }
    
    // The opacity of the mask layer. Default is 0.3
    public var maskBackgroundOpacity: CGFloat! {
        get {
            return self.configuration.maskBackgroundOpacity
        }
        set(value) {
            self.configuration.maskBackgroundOpacity = value
        }
    }
    
    public var didSelectItemAtIndexHandler: ((_ indexPath: Int) -> ())?
    
    private var navigationController: UINavigationController?
    private var configuration = BTConfiguration()
    private var topSeparator: UIView!
    private var menuButton: UIButton!
    private var menuTitle: UILabel!
    private var menuArrow: UIImageView!
    private var backgroundView: UIView!
    private var tableView: BTTableView!
    private var items: [AnyObject]!
    private var isShown: Bool!
    private var menuWrapper: UIView!
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(title: String, items: [AnyObject]) {
        
        // Navigation controller
        self.navigationController = UIApplication.shared.keyWindow?.rootViewController?.topMostViewController?.navigationController
        
        // Get titleSize
        let titleSize = (title as NSString).size(withAttributes: [NSAttributedString.Key.font:self.configuration.cellTextLabelFont])
        
        // Set frame
        let frame = CGRectMake(0, 0, titleSize.width + (self.configuration.arrowPadding + self.configuration.arrowImage.size.width)*2, self.navigationController!.navigationBar.frame.height)
        
        super.init(frame:frame)
        
        self.navigationController?.view.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
        
        self.isShown = false
        self.items = items
        
        // Init properties
        self.setupDefaultConfiguration()

        // Init button as navigation title
        self.menuButton = UIButton(frame: frame)
        self.menuButton.addTarget(self, action: "menuButtonTapped:", for: UIControl.Event.touchUpInside)
        self.addSubview(self.menuButton)
        
        self.menuTitle = UILabel(frame: frame)
        self.menuTitle.text = title
        self.menuTitle.textColor = self.menuTitleColor
        self.menuTitle.textAlignment = NSTextAlignment.center
        self.menuTitle.font = self.configuration.cellTextLabelFont
        self.menuButton.addSubview(self.menuTitle)
        
        self.menuArrow = UIImageView(image: self.configuration.arrowImage)
        self.menuButton.addSubview(self.menuArrow)
        
        let window = UIApplication.shared.keyWindow!
        let menuWrapperBounds = window.bounds
        
        // Set up DropdownMenu
        self.menuWrapper = UIView(frame: CGRectMake(menuWrapperBounds.origin.x, 0, menuWrapperBounds.width, menuWrapperBounds.height))
        self.menuWrapper.clipsToBounds = true
        self.menuWrapper.autoresizingMask = UIView.AutoresizingMask.flexibleWidth.union(UIView.AutoresizingMask.flexibleHeight)
        
        // Init background view (under table view)
        self.backgroundView = UIView(frame: menuWrapperBounds)
        self.backgroundView.backgroundColor = self.configuration.maskBackgroundColor
        self.backgroundView.autoresizingMask = UIView.AutoresizingMask.flexibleWidth.union(UIView.AutoresizingMask.flexibleHeight)
        
        // Init table view
        self.tableView = BTTableView(frame: CGRectMake(menuWrapperBounds.origin.x, menuWrapperBounds.origin.y + 0.5, menuWrapperBounds.width, menuWrapperBounds.height + 300), items: items, configuration: self.configuration)
        
        self.tableView.selectRowAtIndexPathHandler = { (indexPath: Int) -> () in
            self.didSelectItemAtIndexHandler!(indexPath)
            self.setMenuTitle(title: "\(items[indexPath])")
            self.hideMenu()
            self.isShown = false
            self.layoutSubviews()
        }
        
        // Add background view & table view to container view
        self.menuWrapper.addSubview(self.backgroundView)
        self.menuWrapper.addSubview(self.tableView)
        
        // Add Line on top
        self.topSeparator = UIView(frame: CGRectMake(0, 0, menuWrapperBounds.size.width, 0.5))
        self.topSeparator.autoresizingMask = UIView.AutoresizingMask.FlexibleWidth
        self.menuWrapper.addSubview(self.topSeparator)
        
        // Add Menu View to container view
        window.addSubview(self.menuWrapper)
        
        // By default, hide menu view
        self.menuWrapper.isHidden = true
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "frame" {
            // Set up DropdownMenu
            self.menuWrapper.frame.origin.y = self.navigationController!.navigationBar.frame.maxY
            self.tableView.reloadData()
        }
    }
    
    override public func layoutSubviews() {
        self.menuTitle.sizeToFit()
        self.menuTitle.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2)
        self.menuArrow.sizeToFit()
        self.menuArrow.center = CGPointMake(CGRectGetMaxX(self.menuTitle.frame) + self.configuration.arrowPadding, self.frame.size.height/2)
    }
    
    func setupDefaultConfiguration() {
        self.menuTitleColor = self.navigationController?.navigationBar.titleTextAttributes?[NSAttributedString.Key.foregroundColor] as? UIColor // Setter
        self.cellBackgroundColor = self.navigationController?.navigationBar.barTintColor
        self.cellSeparatorColor = self.navigationController?.navigationBar.titleTextAttributes?[NSAttributedString.Key.foregroundColor] as? UIColor
        self.cellTextLabelColor = self.navigationController?.navigationBar.titleTextAttributes?[NSAttributedString.Key.foregroundColor] as? UIColor
    }
    
    func showMenu() {
        self.menuWrapper.frame.origin.y = self.navigationController!.navigationBar.frame.maxY
        
        // Table view header
        let headerView = UIView(frame: CGRectMake(0, 0, self.frame.width, 300))
        headerView.backgroundColor = self.configuration.cellBackgroundColor
        self.tableView.tableHeaderView = headerView
        
        self.topSeparator.backgroundColor = self.configuration.cellSeparatorColor
        
        // Rotate arrow
        self.rotateArrow()
        
        // Visible menu view
        self.menuWrapper.isHidden = false
        
        // Change background alpha
        self.backgroundView.alpha = 0
        
        // Animation
        self.tableView.frame.origin.y = -CGFloat(self.items.count) * self.configuration.cellHeight - 300
        
        // Reload data to dismiss highlight color of selected cell
        self.tableView.reloadData()
        
        UIView.animateWithDuration(
            self.configuration.animationDuration * 1.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [],
            animations: {
                self.tableView.frame.origin.y = CGFloat(-300)
                self.backgroundView.alpha = self.configuration.maskBackgroundOpacity
            }, completion: nil
        )
    }
    
    func hideMenu() {
        // Rotate arrow
        self.rotateArrow()
        
        // Change background alpha
        self.backgroundView.alpha = self.configuration.maskBackgroundOpacity
        
        UIView.animateWithDuration(
            self.configuration.animationDuration * 1.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [],
            animations: {
                self.tableView.frame.origin.y = CGFloat(-200)
            }, completion: nil
        )
        
        // Animation
        UIView.animateWithDuration(self.configuration.animationDuration, delay: 0, options: UIView.AnimationOptions.TransitionNone, animations: {
            self.tableView.frame.origin.y = -CGFloat(self.items.count) * self.configuration.cellHeight - 300
            self.backgroundView.alpha = 0
        }, completion: { _ in
            self.menuWrapper.hidden = true
        })
    }
    
    func rotateArrow() {
        UIView.animateWithDuration(self.configuration.animationDuration, animations: {[weak self] () -> () in
            if let selfie = self {
                selfie.menuArrow.transform = CGAffineTransformRotate(selfie.menuArrow.transform, 180 * CGFloat(M_PI/180))
            }
        })
    }
    
    func setMenuTitle(title: String) {
        self.menuTitle.text = title
    }
    
    func menuButtonTapped(sender: UIButton) {
        self.isShown = !self.isShown
        if self.isShown == true {
            self.showMenu()
        } else {
            self.hideMenu()
        }
    }
}

// MARK: BTConfiguration
class BTConfiguration {
    var menuTitleColor: UIColor?
    var cellHeight: CGFloat!
    var cellBackgroundColor: UIColor?
    var cellSeparatorColor: UIColor?
    var cellTextLabelColor: UIColor?
    var cellTextLabelFont: UIFont!
    var cellSelectionColor: UIColor?
    var checkMarkImage: UIImage!
    var arrowImage: UIImage!
    var arrowPadding: CGFloat!
    var animationDuration: TimeInterval!
    var maskBackgroundColor: UIColor!
    var maskBackgroundOpacity: CGFloat!
    
    init() {
        self.defaultValue()
    }
    
    func defaultValue() {
        // Path for image
        let bundle = Bundle(for: BTConfiguration.self)
        let url = bundle.url(forResource: "BTNavigationDropdownMenu", withExtension: "bundle")
        let imageBundle = Bundle(url: url!)
        let checkMarkImagePath = imageBundle?.path(forResource: "checkmark_icon", ofType: "png")
        let arrowImagePath = imageBundle?.path(forResource: "arrow_down_icon", ofType: "png")

        // Default values
        self.menuTitleColor = UIColor.darkGray
        self.cellHeight = 50
        self.cellBackgroundColor = UIColor.white
        self.cellSeparatorColor = UIColor.darkGray
        self.cellTextLabelColor = UIColor.darkGray
        self.cellTextLabelFont = UIFont(name: "HelveticaNeue-Bold", size: 17)
        self.cellSelectionColor = UIColor.lightGray
        self.checkMarkImage = UIImage(contentsOfFile: checkMarkImagePath!)
        self.animationDuration = 0.5
        self.arrowImage = UIImage(contentsOfFile: arrowImagePath!)
        self.arrowPadding = 15
        self.maskBackgroundColor = UIColor.black
        self.maskBackgroundOpacity = 0.3
    }
}

// MARK: Table View
class BTTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    
    // Public properties
    var configuration: BTConfiguration!
    var selectRowAtIndexPathHandler: ((_ indexPath: Int) -> ())?
    
    // Private properties
    private var items: [AnyObject]!
    private var selectedIndexPath: Int!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, items: [AnyObject], configuration: BTConfiguration) {
        super.init(frame: frame, style: UITableView.Style.Plain)
        
        self.items = items
        self.selectedIndexPath = 0
        self.configuration = configuration
        
        // Setup table view
        self.delegate = self
        self.dataSource = self
        self.backgroundColor = UIColor.clear
        self.separatorStyle = UITableViewCell.SeparatorStyle.none
        self.autoresizingMask = UIView.AutoresizingMask.flexibleWidth
        self.tableFooterView = UIView(frame: CGRectZero)
    }
    
    // Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.configuration.cellHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = BTTableViewCell(style: default.CellStyle.Default, reuseIdentifier: "Cell", configuration: self.configuration)
        cell.textLabel?.text = self.items[indexPath.row] as? String
        cell.checkmarkIcon.hidden = (indexPath.row == selectedIndexPath) ? false : true
        
        return cell
    }
    
    // Table view delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndexPath = indexPath.row
        self.selectRowAtIndexPathHandler!(indexPath.row)
        self.reloadData()
        let cell = tableView.cellForRow(at: indexPath as IndexPath) as? BTTableViewCell
        cell?.contentView.backgroundColor = self.configuration.cellSelectionColor
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRow(at: indexPath as IndexPath) as? BTTableViewCell
        cell?.checkmarkIcon.isHidden = true
        cell?.contentView.backgroundColor = self.configuration.cellBackgroundColor
    }
}

// MARK: Table view cell
class BTTableViewCell: UITableViewCell {
    
    var checkmarkIcon: UIImageView!
    var cellContentFrame: CGRect!
    var configuration: BTConfiguration!
    
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, configuration: BTConfiguration) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.configuration = configuration
        
        // Setup cell
        cellContentFrame = CGRectMake(0, 0, (UIApplication.shared.keyWindow?.frame.width)!, self.configuration.cellHeight)
        self.contentView.backgroundColor = self.configuration.cellBackgroundColor
        self.selectionStyle = UITableViewCell.SelectionStyle.none
        self.textLabel!.textAlignment = NSTextAlignment.left
        self.textLabel!.textColor = self.configuration.cellTextLabelColor
        self.textLabel!.font = self.configuration.cellTextLabelFont
        self.textLabel!.frame = CGRectMake(20, 0, cellContentFrame.width, cellContentFrame.height)
        
        
        // Checkmark icon
        self.checkmarkIcon = UIImageView(frame: CGRectMake(cellContentFrame.width - 50, (cellContentFrame.height - 30)/2, 30, 30))
        self.checkmarkIcon.isHidden = true
        self.checkmarkIcon.image = self.configuration.checkMarkImage
        self.checkmarkIcon.contentMode = UIView.ContentMode.scaleAspectFill
        self.contentView.addSubview(self.checkmarkIcon)
        
        // Separator for cell
        let separator = BTTableCellContentView(frame: cellContentFrame)
        if let cellSeparatorColor = self.configuration.cellSeparatorColor {
            separator.separatorColor = cellSeparatorColor
        }
        self.contentView.addSubview(separator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        self.bounds = cellContentFrame
        self.contentView.frame = self.bounds
    }
}

// Content view of table view cell
class BTTableCellContentView: UIView {
    var separatorColor: UIColor = UIColor.black
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    func initialize() {
        self.backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        
        // Set separator color of dropdown menu based on barStyle
        (context ?? <#default value#>).setStrokeColor(self.separatorColor.cgColor)
        (context ?? <#default value#>).setLineWidth(1)
        CGContextMoveToPoint(context, 0, self.bounds.size.height)
        CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.size.height)
        (context ?? <#default value#>).strokePath()
    }
}

extension UIViewController {
    // Get ViewController in top present level
    var topPresentedViewController: UIViewController? {
            var target: UIViewController? = self
            while (target?.presentedViewController != nil) {
                target = target?.presentedViewController
        }
        return target
    }
    
    // Get top VisibleViewController from ViewController stack in same present level.
    // It should be visibleViewController if self is a UINavigationController instance
    // It should be selectedViewController if self is a UITabBarController instance
    var topVisibleViewController: UIViewController? {
        if let navigation = self as? UINavigationController {
            if let visibleViewController = navigation.visibleViewController {
                return visibleViewController.topVisibleViewController
            }
        }
        if let tab = self as? UITabBarController {
            if let selectedViewController = tab.selectedViewController {
                return selectedViewController.topVisibleViewController
            }
        }
        return self
    }
    
    // Combine both topPresentedViewController and topVisibleViewController methods, to get top visible viewcontroller in top present level
    var topMostViewController: UIViewController? {
        return self.topPresentedViewController?.topVisibleViewController
    }
}
