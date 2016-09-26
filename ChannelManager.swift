//
//  ChannelManager.swift
//  iptv
//
//  Created by Александр Колганов on 26.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import UIKit

class ChannelInfo : NSObject, NSCoding {
    
    var name : String
    var url: String
    
    init(name: String, url:String) {
        self.name = name
        self.url = url
    }
    
    // MARK: NSCoding
    
    required convenience init?(coder decoder: NSCoder) {
        guard let name = decoder.decodeObject(forKey: "name") as? String,
            let url = decoder.decodeObject(forKey: "url") as? String
        else { return nil }
        
        self.init(
            name: name,
            url: url
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.url, forKey: "url")
    }
}

class GroupInfo : NSObject, NSCoding {
    var name: String
    var groups: [GroupInfo]
    var channels: [ChannelInfo]
    
    init(name: String, groups:[GroupInfo], channels:[ChannelInfo]) {
        self.name = name
        self.groups = groups
        self.channels = channels
    }

    required convenience init?(coder decoder: NSCoder) {
        guard let name = decoder.decodeObject(forKey: "name") as? String,
            let groups = decoder.decodeObject(forKey: "groups") as? [GroupInfo],
            let channels = decoder.decodeObject(forKey: "channels") as? [ChannelInfo]
            else { return nil }
        
        self.init(
            name: name,
            groups: groups,
            channels:channels
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.groups, forKey: "groups")
        coder.encode(self.channels, forKey:"channels")
    }



}


class ChannelManager {
    
    static let channelsPropertyName = "Channels"
    
    // Singleton
    static let instance = ChannelManager()
    
    lazy var rootGroup : GroupInfo = {
        
        var ret = GroupInfo( name:"Channels", groups: [], channels: [])
        
        if let data = UserDefaults.standard.object(forKey: "channels") as? NSData {
            ret = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! GroupInfo
        }
        
        return ret
    }()
    
    
    class var root : GroupInfo {
        get {
            return ChannelManager.instance.rootGroup
        }
    }
    
    class func save() {
        let data = NSKeyedArchiver.archivedData(withRootObject: ChannelManager.root)
        UserDefaults.standard.set(data, forKey: "channels")
    }
    
    


}
