//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jonathan Grubb on 5/30/16.
//  Copyright © 2016 Jonathan Grubb. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var location: MKAnnotation?
    
    // MARK:  - Properties
    var fetchedResultsController : NSFetchedResultsController? {
        didSet{
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            //executeSearch()
            //reloadMapData()
        }
    }
    
    /*
    init(fetchedResultsController fc : NSFetchedResultsController) {
        fetchedResultsController = fc
        super.init(nibName: nil, bundle: nil)
    }
    
    // Do not worry about this initializer. I has to be implemented
    // because of the way Swift interfaces with an Objective C
    // protocol called NSArchiving. It's not relevant.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}