//
//  PeekViewController.swift
//  Malendar
//
//  Created by Chase Roossin on 10/21/15.
//  Copyright © 2015 Smart Drive LLC. All rights reserved.
//

import UIKit
import MapKit

class PeekViewController: UIViewController {
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var eventLocation: UILabel!
    @IBOutlet weak var eventNotes: UILabel!
    @IBOutlet weak var eventStart: UILabel!
    @IBOutlet weak var eventEnd: UILabel!
    @IBOutlet weak var eventMap: MKMapView!
    
    
    // MARK: - Preview action items.
    lazy var previewDetailsActions: [UIPreviewActionItem] = {
        func previewActionForTitle(title: String, style: UIPreviewActionStyle = .Default) -> UIPreviewAction {
            return UIPreviewAction(title: title, style: style) { previewAction, viewController in
                guard let PeekViewController = viewController as? PeekViewController,
                    item = PeekViewController.eventTitle else { return }
                
                print("\(previewAction.title) triggered from `DetailsViewController` for item: \(item)")
            }
        }
        
        let actionDefault = previewActionForTitle("Default Action")
        let actionDestructive = previewActionForTitle("Destructive Action", style: .Destructive)
        
        let subActionGoTo = previewActionForTitle("Go to coordinates")
        let subActionSave = previewActionForTitle("Save location")
        let groupedOptionsActions = UIPreviewActionGroup(title: "Options…", style: .Default, actions: [subActionGoTo, subActionSave] )
        
        return [actionDefault, actionDestructive, groupedOptionsActions]
        }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

//MARK: - PreviewActions -> DetailsViewController Extension
typealias PreviewActions = PeekViewController
extension PreviewActions  {
    
    /// User swipes upward on a 3D Touch preview
    override func previewActionItems() -> [UIPreviewActionItem] {
        return previewDetailsActions
    }
}
