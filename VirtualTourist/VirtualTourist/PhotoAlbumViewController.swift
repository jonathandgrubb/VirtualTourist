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
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var location: MKAnnotation?
    var selectedPin: Pin?
    var selectedPhotos = [NSIndexPath]()
    var deleteQueue = [NSIndexPath]()
    
    // MARK:  - Properties
    var fetchedResultsController : NSFetchedResultsController? {
        didSet{
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            performUIUpdatesOnMain {
                self.photosCollectionView.reloadData()
            }
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
        
        // mapView
        if let loc = location {
            // map - display the current location
            let currentAnnotations = mapView.annotations
            mapView.removeAnnotations(currentAnnotations)
            mapView.addAnnotation(loc)
            
            // map - disable user interaction
            // http://stackoverflow.com/a/15419639
            mapView.zoomEnabled = false;
            mapView.scrollEnabled = false;
            mapView.userInteractionEnabled = false;
            
            // map - set how much to zoom on the pin
            let center = CLLocationCoordinate2D(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: false)
            
        } else {
            ControllerCommon.displayErrorDialog(self, message: "Could not display current location on map")
        }
        
        // photosCollectionView
        photosCollectionView.allowsMultipleSelection = true
        if fetchedResultsController!.fetchedObjects?.count == 0 {
            print("no content for this location... get photos")
            
            // initiate an album download from Flickr since there are no photos
            if let pin = selectedPin {
                
                // disable the 'New Collection' button
                newCollectionButton.enabled = false
                
                refreshPhotos(pin) { (success, errorMessage) in
                    if success == false {
                        performUIUpdatesOnMain {
                            self.newCollectionButton.enabled = true
                            ControllerCommon.displayErrorDialog(self, message: "Error getting photo urls")
                        }
                    }
                    
                    // reenable the 'New Collection' button
                    performUIUpdatesOnMain {
                        self.newCollectionButton.enabled = true
                    }
                    
                }
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func newCollectionSelected(sender: AnyObject) {
        print("newCollectionButton titleLabel is: \(newCollectionButton.titleLabel!.text!)")
        if newCollectionButton.titleLabel!.text! == "New Collection" {
            // let's refresh the photos
            if let pin = selectedPin {
                
                // disable the 'New Collection' button
                newCollectionButton.enabled = false
                
                clearPhotos(pin)
                
                refreshPhotos(pin) { (success, errorMessage) in
                    if success == false {
                        performUIUpdatesOnMain {
                            self.newCollectionButton.enabled = true
                            ControllerCommon.displayErrorDialog(self, message: "Error getting photo urls")
                        }
                     }
                    
                    // reenable the 'New Collection' button
                    performUIUpdatesOnMain {
                        self.newCollectionButton.enabled = true
                    }
                }
                
            }
        } else {
            // let's delete the selected photos
            print("delete number of selected items: \(photosCollectionView.indexPathsForSelectedItems()!.count)")
            if let indexPaths = photosCollectionView.indexPathsForSelectedItems() {
                for index in indexPaths {
                    let photo = fetchedResultsController!.objectAtIndexPath(index) as! Photo
                    fetchedResultsController!.managedObjectContext.deleteObject(photo)
                }
            }
            newCollectionButton.setTitle("New Collection", forState: .Normal)
        }
        
    }
    
    func clearPhotos(pin: Pin) {
        print("remove existing Photos from CORE Data")
        if let pinPhotos = pin.photo?.allObjects as? [Photo] {
            for photo in pinPhotos {
                self.fetchedResultsController!.managedObjectContext.deleteObject(photo)
            }
        }
    }

    func refreshPhotos(pin: Pin, completionHandler: (success: Bool, errorMessage: String?) -> Void) {
        
        guard let latitude = pin.latitude as? Double, longitude = pin.longitude as? Double else {
            completionHandler(success: false, errorMessage: "Input error")
            return
        }
        
        print("initiate Flickr request")
        FlickrClient.sharedInstance().getLocationPhotos(latitude, longitude: longitude) { (success, error, results) in
            
            if success == false {
                completionHandler(success: false, errorMessage: "Error getting photo urls")
                return
            }
            
            if let urls = results {
                
                print("creating new Photos in CORE Data")
                for url in urls {
                    let photo = Photo(url: url, context: self.fetchedResultsController!.managedObjectContext)
                    photo.pin = self.selectedPin
                }
                
                // needed because 'insert' event never fires for the frc
                performUIUpdatesOnMain {
                    self.executeSearch()
                    self.photosCollectionView.reloadData()
                }
                
                print("new cell count provided by Flickr request for photos: \(urls.count)")
                completionHandler(success: true, errorMessage: nil)
            
            } else {
                completionHandler(success: false, errorMessage: "Error getting photo urls")
            }
        }
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
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
            cell.highlighted = true
            print("select: \(cell.highlighted)")
            cell.backgroundView!.alpha = 0.1
            newCollectionButton.setTitle("Remove Selected Pictures", forState: .Normal)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) {
            cell.highlighted = false
            print("deselect: \(cell.highlighted)")
            cell.backgroundView!.alpha = 1.0
        }
        if photosCollectionView.indexPathsForSelectedItems() == nil {
            newCollectionButton.setTitle("New Collection", forState: .Normal)
        }
    }
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    // update UI with changes that originate from CORE Data (alternative to doing it in collectionView:cellForItemAtIndexPath
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                    atIndexPath indexPath: NSIndexPath?,
                    forChangeType type: NSFetchedResultsChangeType,
                    newIndexPath: NSIndexPath?) {
        
        if let ind = indexPath {
        
            switch(type) {
                
                case .Insert:
                    // this event never fires
                    print("insert photo: \(ind)")
                    photosCollectionView.insertItemsAtIndexPaths([ind])
         
                case .Delete:
                    print("delete photo: \(ind)")
                    // queued approach to delete
                    //https://github.com/AshFurrow/UICollectionView-NSFetchedResultsController
                    deleteQueue.append(ind)
                
                case .Update:
                    print("update photo: \(ind)")
                    photosCollectionView.reloadItemsAtIndexPaths([ind])
                
                default:
                    print("ignored photo change: \(ind)")
            }
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("controllerDidChangeContent")
        // queued approach to delete
        //https://github.com/AshFurrow/UICollectionView-NSFetchedResultsController
        if deleteQueue.count > 0 {
            photosCollectionView.deleteItemsAtIndexPaths(deleteQueue)
            deleteQueue.removeAll()
        }
    }
    
}

// MARK: - Data Sources
extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var cellCount = 0
        // how many cells?
        if let objs = fetchedResultsController?.fetchedObjects {
            cellCount = objs.count
        }
        print("cell count: \(cellCount)")
        return cellCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // get the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Photo", forIndexPath: indexPath) as! PhotoViewCell
        
        // stop the circle of patience (if it was going)
        cell.activityIndicator.stopAnimating()
        
        // enable user interaction
        cell.userInteractionEnabled = true
        
        // get the Photo (if available)
        if let photo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo {
            
            if let data = photo.data {
            
                // put it into the cell if we have it
                let image = UIImage(data: data)
                let imageView = UIImageView(image: image)
                cell.backgroundView = imageView
                if cell.selected == true {
                    cell.backgroundView!.alpha = 0.1
                } else {
                    cell.backgroundView!.alpha = 1.0
                }
            
            } else {
            
                // get the picture data in the background
                // http://stackoverflow.com/a/27377744
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    if let imageURL = NSURL(string: photo.url!),
                       let imageData = NSData(contentsOfURL: imageURL) {
                        photo.setValue(imageData, forKey: "data")
                    }
                }
                // haven't loaded the picture yet
                cell.backgroundView = nil
                cell.activityIndicator.startAnimating()
            }
        }
        
        // return the cell
        return cell
    }
    
}







