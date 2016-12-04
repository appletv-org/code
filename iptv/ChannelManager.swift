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
    var url: String?
    
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
        if let url = decoder.decodeObject(forKey: "url") as? String {
            self.url = url
        }
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.groups, forKey: "groups")
        coder.encode(self.channels, forKey:"channels")
        if self.url != nil {
            coder.encode(self.url, forKey:"url")
        }
    }
    
    func findDirElement(_ name:String) -> DirElement? {
        
        if let findgroup = groups.first(where: {$0.name == name}) {
            return DirElement.group(findgroup)
        }
        if let findchannel = channels.first(where: {$0.name == name}) {
            return DirElement.channel(findchannel)
        }
        
        return nil
    }

    func findDirIndex(_ name:String) -> Int {
        for i in 0..<groups.count {
            if(groups[i].name == name) {
                return i
            }
        }
        for i in 0..<channels.count {
            if(channels[i].name == name) {
                return i + groups.count
            }
        }
        return -1
    }
    
    func findDirElement(index:Int)  -> DirElement? {
        if index < 0 || index >= countDirElements() {
            return nil
        }
        if index < groups.count {
            return DirElement.group(groups[index])
        }
        else {
            return DirElement.channel(channels[index - groups.count])
        }
    }
    
    func countDirElements() -> Int {
        return groups.count + channels.count
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


//path begin from "/": 
//path example:
//  path to group: ["/", "edem"]
//  path to channel:  ["/", "edem", "взрослые", "egoist.tv"]

class ChannelManager {
    
    static let userDefaultKey = "channels"
    
    static let groupNameRoot = "Channels"
    static let groupNameHidden = "Hidden"
    static let groupNameAll = "All"
    static let groupNameFavorites = "Favorites"
    
    
    // Singleton
    static let instance = ChannelManager()
    private init() {}
    
    lazy var rootGroup : GroupInfo = {
        
        if let data = UserDefaults.standard.object(forKey: ChannelManager.userDefaultKey) as? NSData {
            return NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! GroupInfo
        }
        else {
            var root = GroupInfo( name:ChannelManager.groupNameRoot, groups: [], channels: [])
            root.groups.append( GroupInfo(name: ChannelManager.groupNameFavorites, groups: [], channels: []) )
            return root
        }
        
        
    }()
    
    
    class var root : GroupInfo {
        get {
            return ChannelManager.instance.rootGroup
        }
    }
    
    
    class func findDirElement(_ path: [String]) -> DirElement? {
        
        if path.count == 0 {
            return DirElement.group(root)
        }
        
        if let parentGroup = findParentGroup(path) {
            return parentGroup.findDirElement(path.last!)
        }
        return nil
    }

    class func findParentGroup(_ path: [String]) -> GroupInfo? {
        if path.count > 0 {
            return findGroup(Array(path[0..<path.count-1]))
        }
        return nil
    }

    
    
    class func findGroup(_ path: [String], group:GroupInfo = root) -> GroupInfo? {
        
        if path.count == 0 {
            return group
        }
        
        if path.count == 1 && path[0] == ChannelManager.groupNameAll  {
            let channels = ChannelManager.allChannels(group)
            return GroupInfo(name: ChannelManager.groupNameAll, groups: [GroupInfo](), channels: channels)
        }
        
        if let findedGroup = group.groups.first(where: {$0.name == path[0]}) {
            return findGroup( Array(path[1..<path.count]), group:findedGroup )
        }
        return nil
    
    }
        
    class func delPath(_ path: [String]) -> Bool {
        let group = findParentGroup(path)
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
        UserDefaults.standard.set(data, forKey: ChannelManager.userDefaultKey)
    }
    
    
    class func _addChannels(_ group:GroupInfo, setLink: inout Set<String>, channels: inout [ChannelInfo]) {
        for channel in group.channels {
            if !setLink.contains(channel.url) {
                setLink.insert(channel.url)
                channels.append(channel)
            }
        }
        for group in group.groups {
            if group.name == groupNameHidden {
                continue
            }
            self._addChannels(group, setLink: &setLink, channels: &channels)
        }
    }
        
    class func allChannels(_ group:GroupInfo) -> [ChannelInfo] {
        var setLink = Set<String>()
        var channels = [ChannelInfo]()
        self._addChannels(group, setLink: &setLink, channels: &channels)
        return channels
    }
}
    
extension  ChannelManager { //parsing m3u list
    class func addM3uList(name:String, url:String) throws -> Void {
    
        let items = try parseM3u(string:url)
        if items.count > 0  {
            
            //set items by groups
            var groupsList = [String:[M3uItem]]()
            var channelList = [M3uItem]()
            for item in items {
                if let groupName = item.group {
                    if groupsList[groupName] == nil {
                        groupsList[groupName] = []
                    }
                    groupsList[groupName]!.append(item)
                }
                else {
                    channelList.append(item)
                }
            }
            
        
        
            //add new group to root
            let parentGroup = GroupInfo(name:name, groups:[], channels:[])
            ChannelManager.root.groups.append(parentGroup)
            
            //add groups
            for (nameGroup,itemList) in groupsList {
                let group = GroupInfo(name:nameGroup, groups:[], channels:[])
                parentGroup.groups.append(group)
                
                for item in itemList {
                    let channel = ChannelInfo(name:item.name!, url:item.url!)
                    group.channels.append(channel)
                    //print("add channel:\(channel.name) to group:\(group.name)")
                }
            }
            
            //add items without groups
            for item in channelList {
                let channel = ChannelInfo(name:item.name!, url:item.url!)
                parentGroup.channels.append(channel)
            }
            
            //sort groups by count channels
            if parentGroup.groups.count > 0 {
                parentGroup.groups.sort(by: {$0.channels.count > $1.channels.count})
            }
        }
    }

}
