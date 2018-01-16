//
//  Aya+CoreDataProperties.swift
//  quran_hafiz
//
//  Created by Ramy Eldesoky on 1/11/18.
//  Copyright © 2018 Ramy Eldesoky. All rights reserved.
//
//

import Foundation
import CoreData


extension Aya {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Aya> {
        return NSFetchRequest<Aya>(entityName: "Aya")
    }

    @NSManaged public var aya: Int16
    @NSManaged public var page: Int16
    @NSManaged public var stext: String?
    @NSManaged public var sura: Int16
    @NSManaged public var text: String?
    @NSManaged public var index: Int16

}
