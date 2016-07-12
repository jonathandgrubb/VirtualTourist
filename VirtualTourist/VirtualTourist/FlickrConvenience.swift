//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Jonathan Grubb on 5/30/16.
//  Copyright © 2016 Jonathan Grubb. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    func getLocationPhotosNumberOfPages(latitude: Double, longitude: Double, completionHandlerForLocationPages: (success: Bool, error: Constants.Errors?, pages: Int?) -> Void) {
        
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
                completionHandlerForLocationPages(success: false, error: Constants.Errors.NetworkError, pages: nil)
            } else {
                
                // get the photo urls
                if let results = result[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject],
                   let pages = results[Constants.FlickrResponseKeys.Pages] as? Int {
                    
                    // success
                    completionHandlerForLocationPages(success: true, error: nil, pages: pages)
                    
                } else {
                    // couldn't find the photos in the result
                    if result["message"] != nil {
                        print("Error from Flickr in \(result)")
                        completionHandlerForLocationPages(success: false, error: Constants.Errors.InputError, pages: nil)
                    } else {
                        completionHandlerForLocationPages(success: false, error: Constants.Errors.NetworkError, pages: nil)
                    }
                }
            }
        }
        
    }

    func getLocationPhotos(latitude: Double, longitude: Double, completionHandlerForLocations: (success: Bool, error: Constants.Errors?, results: [String]?) -> Void) {
        
        // get the number of photo "pages" available for this location
        getLocationPhotosNumberOfPages(latitude, longitude: longitude) { (success, error, pages) in
            
            if let error = error {
                print(error)
                completionHandlerForLocations(success: false, error: error, results: nil)
            
            } else {
                
                if let numPages = pages {
                    print("total pages: \(numPages)")
                    
                    // 4,000 results is the most that Flickr will return
                    // 4000 / 21 per page = 190 max pages
                    let maxPages = min(numPages, 190)
                    print("min of \(numPages) and 190 is \(maxPages)")
                    
                    // convert to a random page number for our photos
                    let page = arc4random_uniform(UInt32(maxPages)) + 1
                    print("random page: \(page)")
                    
                    // specify params to get the photos on the random page
                    let parameters : [String:AnyObject] = [
                        Constants.FlickrParameterKeys.Method : Constants.FlickrParameterValues.SearchMethod,
                        Constants.FlickrParameterKeys.Page : String(page),
                        Constants.FlickrParameterKeys.PerPage : "21",
                        Constants.FlickrParameterKeys.Media : Constants.FlickrParameterValues.MediaPhotosOnly,
                        Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.SmallSquareURL,
                        Constants.FlickrParameterKeys.BoundingBox : FlickrClient.bboxString(String(latitude), longitude: String(longitude))
                    ]
                    
                    // get the photos on the random page
                    self.taskForGETMethod(parameters) { (result, error) in
                        
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

                    
                } else {
                    print("getLocationPhotosNumberOfPages indicates success but did not return total pages")
                    completionHandlerForLocations(success: false, error: Constants.Errors.UnknownError, results: nil)
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