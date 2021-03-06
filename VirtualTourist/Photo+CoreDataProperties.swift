//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Jonathan Grubb on 7/9/16.
//  Copyright © 2016 Jonathan Grubb. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var data: NSData?
    @NSManaged var url: String?
    @NSManaged var pin: Pin?

}
