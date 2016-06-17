//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Jonathan Grubb on 5/30/16.
//  Copyright © 2016 Jonathan Grubb. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class TravelLocationsMapViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    var selectedPin: Pin?
    
    // MARK:  - Properties
    var fetchedResultsController : NSFetchedResultsController? {
        didSet{
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            reloadMapData()
        }
    }
    
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add a gesture recognizer to the mapView for taps
        // http://stackoverflow.com/a/31304290
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation))
        uilgr.minimumPressDuration = 2.0
        mapView.addGestureRecognizer(uilgr)
        
        // Get the stack
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack
        
        // Create a fetchrequest
        let fr = NSFetchRequest(entityName: "Pin")
        fr.sortDescriptors = []
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr,
                                            managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        // see if we have any pins saved in CORE Data and load them onto the map as annotations
        print("Number of fetchedObjects: \(fetchedResultsController!.fetchedObjects!.count)")
    }
    
    // reload map with results from fetchedResultsController
    func reloadMapData() {
        
        if let fc = fetchedResultsController,
            let objs = fc.fetchedObjects {
            
            // make an array of annotations
            var annotations = [MKPointAnnotation]()
            
            for obj in objs {
                
                // downcast the object to a Pin
                if let pin = obj as? Pin,
                    let latitude = pin.latitude,
                    let longitude = pin.longitude {
                    
                    // Notice that the float values are being used to create CLLocationDegree values.
                    // This is a version of the Double type.
                    let lat = CLLocationDegrees(latitude)
                    let long = CLLocationDegrees(longitude)
                    
                    // The lat and long are used to create a CLLocationCoordinates2D instance.
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    
                    // Here we create the annotation and set its coordiates
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    
                    // Finally we place the annotation in an array of annotations.
                    annotations.append(annotation)
                }
            }
            
            let oldAnnotations = self.mapView.annotations
            self.mapView.addAnnotations(annotations)
            self.mapView.removeAnnotations(oldAnnotations)
        }
    }
    
    // handle the adding of a new pin
    // http://stackoverflow.com/a/31304290
    func addAnnotation(gestureRecognizer:UIGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)) { (placemarks, error) -> Void in
                
                if let error = error {
                    print("Reverse geocoder failed with error" + error.localizedDescription)
                    return
                }
                
                // add the annotation to the map
                self.mapView.addAnnotation(annotation)
                
                // ...and Core Data takes care of the rest!
                let pin = Pin(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: self.fetchedResultsController!.managedObjectContext)
                print("annotation \(pin) object added to CORE Data")
            }
        }

    }
}

// MARK:  - Fetches
extension TravelLocationsMapViewController {
    
    func executeSearch(){
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }catch let e as NSError{
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

// MARK:  - MKMapView delegate functions
extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    // rules for rendering the annotions on the map
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.animatesDrop = true
            pinView!.pinTintColor = UIColor.redColor()
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        if let annotation = view.annotation {
            
            let lat = annotation.coordinate.latitude
            let lon = annotation.coordinate.longitude
            
            print("annotation (\(lat),\(lon)) was selected")

            // create fetch request for the selected pin
            let fr = NSFetchRequest(entityName: "Pin")
            fr.sortDescriptors = []
            let pred = NSPredicate(format: "latitude = %@ AND longitude = %@", annotation.coordinate.latitude, annotation.coordinate.longitude)
            fr.predicate = pred
            executeSearch()
            if let pin = fetchedResultsController!.fetchedObjects?.first as? Pin {
                selectedPin = pin
                print("pin was fetched: \(pin)")
                // prepare to open the pictures associated with the place just clicked
                performSegueWithIdentifier("PhotosViewSegue", sender: nil)
            }
        
        } else {
            print("error clicking annotation")
        }
    }
    
}

extension TravelLocationsMapViewController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier! == "PhotosViewSegue" {
            
            if let photosVC = segue.destinationViewController as? PhotoAlbumViewController,
               let annotation = mapView.selectedAnnotations.first,
               let pin = selectedPin {
                
                // create fetch request for the selected photos for the pin
                let fr = NSFetchRequest(entityName: "Photo")
                fr.sortDescriptors = []
                let pred = NSPredicate(format: "pin = %@", pin)
                fr.predicate = pred
                
                let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: fetchedResultsController!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
                
                photosVC.selectedPin = pin
                photosVC.location = annotation
                photosVC.fetchedResultsController = fc
            }
            
        }
    }
}

// MARK:  - Delegate
extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate{
    
    /* if we ever need to update UI with changes that originate from CORE Data
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                    atIndexPath indexPath: NSIndexPath?,
                    forChangeType type: NSFetchedResultsChangeType,
                    newIndexPath: NSIndexPath?) {
        
        if let pin = anObject as? Pin,
           let latitude = pin.latitude,
           let longitude = pin.longitude {
    
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            let lat = CLLocationDegrees(latitude)
            let long = CLLocationDegrees(longitude)
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Here we create the annotation and set its coordiates
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            switch(type){
                
                case .Insert:
                    print("insert annotation")
                    mapView.addAnnotation(annotation)
                
                case .Delete:
                    print("delete annotation")
                    mapView.removeAnnotation(annotation)
                
                case .Update:
                    print("update annotation")
                
                case .Move:
                    print("move annotation")
            }
        }
    }
    */
    
}





