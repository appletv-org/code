//
//  ChannelManager.swift
//  iptv
//
//  Created by Александр Колганов on 26.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import Foundation

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

enum DirElement {
    case group(GroupInfo)
    case channel(ChannelInfo)
    
    var name : String {
        get {
            switch self {
            case .group(let group):
                return group.name
            case .channel(let channel):
                return channel.name
            }
        }
    }
}


class ChannelManager {
    
    static let channelsPropertyName = "Channels"
    
    // Singleton
    static let instance = ChannelManager()
    private init() {}
    
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
    
    class func findGroupList(_ path: [String]) -> [GroupInfo]? {        
        var group : GroupInfo? = root
        var groupList : [GroupInfo] = [root]
        for name in path {
            group = group?.groups.first(where: {$0.name == name})
            if(group == nil) {
                return nil
            }
            groupList.append(group!)
        }
        return groupList
    }
    
    class func findDirElement(_ path: [String]) -> DirElement? {
        var group : GroupInfo? = root
        
        //find prev last groupInfo
        if(path.count > 1) {
            let pathGroup = Array(path[0..<path.count-1])
            group = findGroup(pathGroup)
        }
        
        
        if(group != nil) {
            if let findgroup = group!.groups.first(where: {$0.name == path.last}) {
                return DirElement.group(findgroup)
            }
            if let findchannel = group!.channels.first(where: {$0.name == path.last}) {
                return DirElement.channel(findchannel)
            }
        }
        return nil
    }

    
    class func findGroup(_ path: [String]) -> GroupInfo? {
        var group : GroupInfo? = root
        var startIndex = 0
        if path[0] == root.name {
            startIndex = 1
            if path.count == 1 {
                return group
            }
        }
        
        for ind in startIndex...path.count-1 {
            group = group?.groups.first(where: {$0.name == path[ind]})
            if(group == nil) {
                return nil
            }
        }
        return group
    }
        
    class func delPath(_ path: [String]) -> Bool {
        if path.count == 0 {
            return false
        }
        let parentPath = Array(path[0..<path.count-1])
        let group = findGroup(parentPath)
        if(group == nil) {
            return false
        }
        if let index = group!.groups.index(where: {$0.name == path.last})  {
            group!.groups.remove(at: index)
            return true
        }
        if let index = group!.channels.index(where: {$0.name == path.last})  {
            group!.channels.remove(at: index)
            return true
        }
        return false
    }
    
    
    class func save() {
        let data = NSKeyedArchiver.archivedData(withRootObject: ChannelManager.root)
        UserDefaults.standard.set(data, forKey: "channels")
    }
    
    class func addM3uList(name:String, url:String) throws -> Void {
    
        let items = try parseM3u(string:url)
        if items.count > 0  {
            var groupsList : [String:[M3uItem]] = ["All":[]]
            for item in items {
                groupsList["All"]!.append(item)
                if let groupName = item.group {
                    if groupsList[groupName] == nil {
                        groupsList[groupName] = []
                    }
                    groupsList[groupName]!.append(item)
                }
            }
        
        
            //add new list to root
            let parentGroup = GroupInfo(name:name, groups:[], channels:[])
            ChannelManager.root.groups.append(parentGroup)
            
            for (nameGroup,groupList) in groupsList {
            
                var group = parentGroup
                if groupsList.count > 1 { //not only all
                    group = GroupInfo(name:nameGroup, groups:[], channels:[])
                    parentGroup.groups.append(group)
                    //print("add group:\(group.name) to parent:\(parentGroup.name)")
                }
                
                for item in groupList {
                    let channel = ChannelInfo(name:item.name!, url:item.url!)
                    group.channels.append(channel)
                    //print("add channel:\(channel.name) to group:\(group.name)")
                }
            
            }
        }
    }


}
