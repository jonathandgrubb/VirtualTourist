//
//  PhotoManager.swift
//  VirtualTourist
//
//  Created by Jonathan Grubb on 6/14/16.
//  Copyright © 2016 Jonathan Grubb. All rights reserved.
//

import Foundation

public class PhotoManager {
    
    public static func RefreshAlbum(pin: Pin) {
        
        if let lat = pin.latitude as? Double, let lon = pin.longitude as? Double {
        
            FlickrClient.sharedInstance().getLocationPhotos(lat, longitude: lon) { (success, error, results) in
                if success == false {
                    // call the completion handler
                    return
                }
                
                if let urls = results {
                    // turn the urls into images
                    var images = [NSData]()
                    for url in urls {
                        let imageURL = NSURL(string: url)
                        if let imageData = NSData(contentsOfURL: imageURL!) {
                            images.append(imageData)
                        }
                    }
                    
                    // load the images into CORE Data
                }
            }
        }
    }
}