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

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    
    var location: MKAnnotation?
    var selectedPin: Pin?
    
    // MARK:  - Properties
    var fetchedResultsController : NSFetchedResultsController? {
        didSet{
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            //performUIUpdatesOnMain {
            //    self.photosCollectionView.reloadData()
            //}
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
        
        if let loc = location {
            // display the current location
            let currentAnnotations = mapView.annotations
            mapView.removeAnnotations(currentAnnotations)
            mapView.addAnnotation(loc)
            
            let center = CLLocationCoordinate2D(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: false)
        } else {
            ControllerCommon.displayErrorDialog(self, message: "Could not display current location on map")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

// MARK:  - Fetches
extension PhotoAlbumViewController {
    
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

// MARK: - Delegates
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {

    // keep the collection view in three columns
    // http://stackoverflow.com/a/35826884
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let numberOfItemsPerRow = 3
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(numberOfItemsPerRow - 1))
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(numberOfItemsPerRow))
        return CGSize(width: size, height: size)
    }
    
    /* update UI with changes that originate from CORE Data (alternative to doing it in collectionView:cellForItemAtIndexPath
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                    atIndexPath indexPath: NSIndexPath?,
                    forChangeType type: NSFetchedResultsChangeType,
                    newIndexPath: NSIndexPath?) {
        
        let set = NSIndexSet(index: sectionIndex)
        
        switch(type) {
            
            case .Insert:
                print("insert photo")
            
            case .Delete:
                print("delete photo")
            
            case .Update:
                print("update photo")
            
            default:
                print("ignored photo change")
        }
    }
    */
}

// MARK: - Data Sources
extension PhotoAlbumViewController: UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var cellCount = 0
        // how many cells?
        if let objs = fetchedResultsController?.fetchedObjects {
            print("original cell count by fetch: \(objs.count)")
            cellCount = objs.count
        }
        
        if cellCount == 0 {
            
            print("no content")
            // initiate an album download from Flickr since there are no photos
            if let loc = location {
                print("initiate Flickr request")
                FlickrClient.sharedInstance().getLocationPhotos(loc.coordinate.latitude, longitude: loc.coordinate.longitude) { (success, error, results) in
                    
                    if success == false {
                        performUIUpdatesOnMain {
                            ControllerCommon.displayErrorDialog(self, message: "Error getting photo urls")
                        }
                        return
                    }
                    
                    // create photos for the pin in CORE Data
                    if let urls = results {
                        print("creating new Photos in CORE Data")
                        for url in urls {
                            let photo = Photo(url: url, context: self.fetchedResultsController!.managedObjectContext)
                            photo.pin = self.selectedPin
                        }
                        performUIUpdatesOnMain {
                            print("fetching new results from model")
                            self.executeSearch()
                            collectionView.reloadData()
                        }
                        print("new cell count provided by Flickr request for photos: \(urls.count)")
                    } else {
                        performUIUpdatesOnMain {
                            ControllerCommon.displayErrorDialog(self, message: "Error getting photos")
                        }
                    }
                }
            } else {
                ControllerCommon.displayErrorDialog(self, message: "Error: no location data to retrieve photos")
            }
        }
        
        print("returned row count: \(cellCount)")
        return cellCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // get the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Photo", forIndexPath: indexPath) as! PhotoViewCell
        
        // stop the circle of patience (if it was going)
        cell.activityIndicator.stopAnimating()
        
        // get the Photo (if available)
        if let photo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo {
            
            if let data = photo.data {
            
                // put it into the cell if we have it
                let image = UIImage(data: data)
                let imageView = UIImageView(image: image)
                cell.backgroundView = imageView
            
            } else {
            
                // get the picture data in the background
                // http://stackoverflow.com/a/27377744
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    if let imageURL = NSURL(string: photo.url!) {
                        let imageData = NSData(contentsOfURL: imageURL)
                        photo.setValue(imageData, forKey: "data")
                        performUIUpdatesOnMain {
                            collectionView.reloadData()
                        }
                    }
                }
                // haven't loaded the picture yet
                cell.activityIndicator.startAnimating()
            }
        }
        
        // return the cell
        return cell
    }
    
}







