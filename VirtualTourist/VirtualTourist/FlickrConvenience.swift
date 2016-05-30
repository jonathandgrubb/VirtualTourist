//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Jonathan Grubb on 5/30/16.
//  Copyright © 2016 Jonathan Grubb. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    func getLocationPhotos(latitude: String, longitude: String, completionHandlerForLocations: (success: Bool, error: Constants.Errors?) -> Void) {
        
        // specify params (if any)
        let parameters : [String:AnyObject] = [
            Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchByGeoMethod,
            Constants.FlickrParameterKeys.PerPage : "21",
            Constants.FlickrParameterKeys.Latitude : latitude,
            Constants.FlickrParameterKeys.Longitude : longitude,
            Constants.FlickrParameterKeys.BoundingBox : FlickrClient.bboxString(latitude, longitude: longitude)
        ]
        
        taskForGETMethod(parameters) { (result, error) in
            // 3. Send the desired value(s) to completion handler */
            if let error = error {
                print(error)
                completionHandlerForLocations(success: false, error: Constants.Errors.NetworkError)
            } else {
                print(result)
                // get the students' locations
                if let results = result["photos"] as? [[String:AnyObject]] {
                    // TODO: put it in the database
                } else {
                    if result["message"] != nil {
                        print("Error from Flickr in \(result)")
                        completionHandlerForLocations(success: false, error: Constants.Errors.InputError)
                    } else {
                        completionHandlerForLocations(success: false, error: Constants.Errors.NetworkError)
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