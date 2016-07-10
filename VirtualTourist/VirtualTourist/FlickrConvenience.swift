//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Jonathan Grubb on 5/30/16.
//  Copyright © 2016 Jonathan Grubb. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    func getLocationPhotos(latitude: Double, longitude: Double, completionHandlerForLocations: (success: Bool, error: Constants.Errors?, results: [String]?) -> Void) {
        
        // specify params (if any)
        let parameters : [String:AnyObject] = [
            Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.PerPage : "21",
            Constants.FlickrParameterKeys.Media : Constants.FlickrParameterValues.MediaPhotosOnly,
            Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.SmallSquareURL,
            Constants.FlickrParameterKeys.BoundingBox : FlickrClient.bboxString(String(latitude), longitude: String(longitude))
        ]
        
        taskForGETMethod(parameters) { (result, error) in
            
            // 3. Send the desired value(s) to completion handler */
            if let error = error {
                print(error)
                completionHandlerForLocations(success: false, error: Constants.Errors.NetworkError, results: nil)
            } else {
                
                // get the photo urls
                if let results = result[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject],
                    let photos = results[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] {
                    
                    // put the urls into an array
                    var photosArray = [String]()
                    for pic in photos {
                        if let url = pic[Constants.FlickrResponseKeys.SmallSquareURL] as? String {
                            photosArray.append(url)
                        }
                    }
                    
                    // success
                    completionHandlerForLocations(success: true, error: nil, results: photosArray)
                    
                } else {
                    // couldn't find the photos in the result
                    if result["message"] != nil {
                        print("Error from Flickr in \(result)")
                        completionHandlerForLocations(success: false, error: Constants.Errors.InputError, results: nil)
                    } else {
                        completionHandlerForLocations(success: false, error: Constants.Errors.NetworkError, results: nil)
                    }
                }
            }
        }
        
    }

    // Jarrod Parkes - create a box of tolerance around our coordinates
    private static func bboxString(latitude: String, longitude: String) -> String {
        if let lat = Double(latitude), lon = Double(longitude) {
            let minLatitude = max(lat - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maxLatitude = min(lat + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            let minLongitude = max(lon - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let maxLongitude = min(lon + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            return "\(minLongitude),\(minLatitude),\(maxLongitude),\(maxLatitude)"
        } else {
            return "0,0,0,0"
        }
    }
    
}