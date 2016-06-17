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
            //photosCollectionView.reloadData()
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
}

// MARK: - Data Sources
extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var cellCount = 0
        // how many cells?
        if let objs = fetchedResultsController?.fetchedObjects {
            cellCount = objs.count
        }
        
        if cellCount == 0 {
            // initiate an album download from Flickr since there are no photos
            if let loc = location {
                FlickrClient.sharedInstance().refreshAlbum(loc.coordinate.latitude, longitude: loc.coordinate.longitude) { (success, error, images) in
                    
                    if success == false {
                        performUIUpdatesOnMain {
                            ControllerCommon.displayErrorDialog(self, message: "Error getting photos")
                        }
                        return
                    }
                    
                    // create photos for the pin in CORE Data
                    if let images = images {
                        for image in images {
                            let photo = Photo(data: image, context: self.fetchedResultsController!.managedObjectContext)
                            photo.pin = self.selectedPin
                        }
                        cellCount = images.count
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
        
        return cellCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        // get the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Photo", forIndexPath: indexPath)
        
        // stop the circle of patience if it was going
        if let activityIndicator = cell.backgroundView as? UIActivityIndicatorView {
            activityIndicator.stopAnimating()
        }
        
        // get the Photo (if available)
        if let photo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo,
           let data = photo.data {
            
            // put it into the cell if we have it
            let image = UIImage(data: data)
            let imageView = UIImageView(image: image)
            cell.backgroundView = imageView
        
        } else {
        
            // programmatically adding UIActivityView and start its animation
            // http://sourcefreeze.com/uiactivityindicatorview-example-using-swift-in-ios/
            // http://stackoverflow.com/questions/7212859/how-to-set-an-uiactivityindicatorview-when-loading-a-uitableviewcell
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            activityIndicator.hidesWhenStopped = true;
            activityIndicator.center = view.center;
            activityIndicator.startAnimating()
            cell.backgroundView = activityIndicator
        }
        
        // return the cell
        return cell
    }
}
