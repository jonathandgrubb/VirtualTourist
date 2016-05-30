//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Jonathan Grubb on 5/30/16.
//  Copyright © 2016 Jonathan Grubb. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    func getLocationPhotos(latitude: Float, longitude: Float, completionHandlerForLocations: (success: Bool, error: Constants.Errors?) -> Void) {
        
        // specify params (if any)
        let parameters : [String:AnyObject] = [
            Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchByGeoMethod,
            Constants.FlickrParameterKeys.PerPage : "21"]
            // TODO: add lat/long to the parameters
            // TODO: add the lat/long 'box' to the parameters
        
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

}