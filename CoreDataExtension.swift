//
//  CoreDataExtension.swift
//  iptv
//
//  Created by Александр Колганов on 21.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import Foundation

extension Group {
    public class func Insert() -> Group {
        return Group(entity: CoreDataManager.instance.entityForName(entityName: "Group"), insertInto: CoreDataManager.instance.managedObjectContext)
    }
}

extension Channel {
    public class func Insert() -> Channel {
        return Channel(entity: CoreDataManager.instance.entityForName(entityName: "Channel"), insertInto: CoreDataManager.instance.managedObjectContext)
    }
}
