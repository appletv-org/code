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

class RemoteGroupInfo: NSObject, NSCoding {
    var url: String
    var hiddenGroup : GroupInfo
    var lastUpdate: Date?
    
    init(url: String, hiddenGroup:GroupInfo = GroupInfo(name:ChannelManager.groupNameHidden)) {
        self.url = url
        self.hiddenGroup = hiddenGroup
    }
    
    required convenience init?(coder decoder: NSCoder) {
        guard   let url = decoder.decodeObject(forKey: "url") as? String
        else { return nil }
        
        var hiddenGroup = decoder.decodeObject(forKey: "hidden") as? GroupInfo
        if hiddenGroup == nil {
            hiddenGroup = GroupInfo(name:ChannelManager.groupNameHidden)
        }

        self.init(
            url: url,
            hiddenGroup: hiddenGroup!
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.url, forKey: "url")
        if hiddenGroup.groups.count > 0 || hiddenGroup.channels.count > 0 {
            coder.encode(self.hiddenGroup, forKey:"hidden")
        }
    }

}


class GroupInfo : NSObject, NSCoding {
    var name: String
    var groups: [GroupInfo]
    var channels: [ChannelInfo]
    var remoteInfo : RemoteGroupInfo?
    
    
    init(name: String, groups:[GroupInfo] = [GroupInfo](), channels:[ChannelInfo] = [ChannelInfo]()) {
        self.name = name
        self.groups = groups
        self.channels = channels
    }

    required convenience init?(coder decoder: NSCoder) {
        guard   let name = decoder.decodeObject(forKey: "name") as? String
        else { return nil }
        
        var groups = decoder.decodeObject(forKey: "groups") as? [GroupInfo]
        if groups == nil {
            groups = [GroupInfo]()
        }
        var channels = decoder.decodeObject(forKey: "channels") as? [ChannelInfo]
        if channels == nil {
            channels = [ChannelInfo]()
        }
        
        self.init(
            name: name,
            groups: groups!,
            channels:channels!
        )
        if let remoteInfo = decoder.decodeObject(forKey: "remote") as? RemoteGroupInfo {
            self.remoteInfo = remoteInfo
        }
        

    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        
        if self.remoteInfo != nil {
            coder.encode(self.remoteInfo, forKey:"remote")
        }
        else {
            if groups.count > 0 {
                coder.encode(self.groups, forKey: "groups")
            }
            if channels.count > 0 {
                coder.encode(self.channels, forKey:"channels")
            }
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
    
    var url : String? {
        switch self {
        case .group(let group):
            if group.remoteInfo != nil {
                return group.remoteInfo!.url
            }
            else {
                return nil
            }
        case .channel(let channel):
            return channel.url
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
    
    static let reservedNames = [groupNameRoot, groupNameHidden, groupNameAll, groupNameFavorites]
    
    
    // Singleton
    static let instance = ChannelManager()
    private init() {}
    
    lazy var rootGroup : GroupInfo = {
        
        if let data = UserDefaults.standard.object(forKey: ChannelManager.userDefaultKey) as? NSData {
            var root = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! GroupInfo
            ChannelManager.instance.loadRemoteGroups(group:root)
            return root
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
    
        
    class func getPathElements(_ path: [String]) -> (groups:[GroupInfo]?, channel:ChannelInfo?) {
        var groups = [ChannelManager.instance.rootGroup]

        if path.count == 0 {
            return (groups, nil)
        }
        
        var currentGroup = ChannelManager.instance.rootGroup
        for ind in 0..<path.count {
            let name = path[ind]
            if let group = currentGroup.groups.first(where:{$0.name == name}) {
                groups.append(group)
                currentGroup = group
                continue
            }
            
            if ind == path.count-1 { //if not in group then check channel
                if let channel = currentGroup.channels.first(where:{$0.name == name}) {
                    return (groups, channel)
                }
            }
            else {
                return (nil, nil)
            }
        }
        return (groups, nil)
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
    
    class func findParentRemoteGroup(_ path: [String]) -> GroupInfo? {
        let ret = getPathElements(path)
        guard let groups = ret.groups
        else {
             return nil
        }
        for ind in (0..<groups.count).reversed() {
            if groups[ind].remoteInfo != nil {
                return groups[ind]
            }
        }
        return nil
    }
    
    func loadRemoteGroups(group:GroupInfo) {
        for group in group.groups {
            if group.remoteInfo != nil {
                try? ChannelManager.addM3uList(url: group.remoteInfo!.url, toGroup:group)
                removeHiddenElements(group)
            }
            else {
                loadRemoteGroups(group:group)
            }
        }
        
    }
    
    func removeHiddenElements(_ group:GroupInfo) {
        let hiddenGroup = group.remoteInfo!.hiddenGroup
        _removeHiddenElements(group: group, hiddenGroup: hiddenGroup)
        
    }
    
    func _removeHiddenElements(group:GroupInfo, hiddenGroup:GroupInfo) {
        //remove channels
        for hChannel in hiddenGroup.channels {
            if let index = group.channels.index(where: {$0.name == hChannel.name}) {
                group.channels.remove(at: index)
            }
        }
        
        //remove groups
        for hGroup in hiddenGroup.groups {
            if let index = group.groups.index(where: {$0.name == hGroup.name}) {
                if hGroup.channels.count > 0 || hGroup.groups.count > 0 {
                    _removeHiddenElements(group:group.groups[index], hiddenGroup:hGroup)
                }
                else {
                    group.groups.remove(at: index)
                }
            }
        }
    }

    class func save() {
        let data = NSKeyedArchiver.archivedData(withRootObject: ChannelManager.root)
        UserDefaults.standard.set(data, forKey: ChannelManager.userDefaultKey)
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
    
    class func changeChannel(_ path:[String], name newName:String, url newUrl:String) -> Error? {
        
        if let _ = ChannelManager.reservedNames.index(of:newName) {
            return Err("Reserved name")
        }
        
        let pathElements = ChannelManager.getPathElements(path)
        if let channel = pathElements.channel,
            let groups = pathElements.groups,
            let parentGroup = groups.last
        {
            if newName == channel.name && newUrl == channel.url {
                return nil
            }
            
            if newName != channel.name && parentGroup.findDirElement(newName) != nil {
                return Err("Duplicate name")
            }
            
            channel.name = newName
            channel.url = newUrl
            
            ChannelManager.save()
            return nil
            
        }
        else {
            return Err("Not found path:\(path.split(separator: "->"))")
        }
    }
    
    class func changeGroup(_ path:[String], name newName:String) -> Error? {
        
        if let _ = ChannelManager.reservedNames.index(of:newName) {
            return Err("Reserved name")
        }

        
        let pathElements = ChannelManager.getPathElements(path)
        if  let groups = pathElements.groups,
            groups.count > 1
        {
            let group = groups.last!
            if newName == group.name {
                return nil
            }

            let parentGroup = groups[groups.count - 2]
            
            if parentGroup.findDirElement(newName) != nil {
                return Err("Duplicate name")
            }
            group.name = newName
            ChannelManager.save()
            return nil
            
        }
        else {
            return Err("Not found path:\(path.split(separator: "->"))")
        }
    }
    
    class func addGroup(_ path:[String], name:String) -> Error? {
        
        if let _ = ChannelManager.reservedNames.index(of:name) {
            return Err("Reserved name")
        }
        
        let pathElements = ChannelManager.getPathElements(path)
        
        if  let groups = pathElements.groups,
            groups.count > 0
        {
            let parentGroup = groups.last!
            
            if parentGroup.findDirElement(name) != nil {
                return Err("Duplicate name")
            }
            
            
            parentGroup.groups.append( GroupInfo(name:name) )
            ChannelManager.save()
            return nil
            
        }
        else {
            return Err("Not found path:\(path.split(separator: "->"))")
        }
        
    }

    class func addChannel(_ path:[String], name:String, url:String) -> Error? {
        
        if let _ = ChannelManager.reservedNames.index(of:name) {
            return Err("Reserved name")
        }
        
        let pathElements = ChannelManager.getPathElements(path)
        
        if  let groups = pathElements.groups,
            groups.count > 0
        {
            let parentGroup = groups.last!
            
            if parentGroup.findDirElement(name) != nil {
                return Err("Duplicate name")
            }
            
            parentGroup.channels.append( ChannelInfo(name:name, url:url) )
            ChannelManager.save()
            return nil
            
        }
        else {
            return Err("Not found path:\(path.split(separator: "->"))")
        }
        
    }
    
    class func addRemoteGroup(_ path:[String], name newName:String, url newUrl:String) -> Error? {
        //check url
        let group = GroupInfo(name:newName)
        do {
            try ChannelManager.addM3uList(url: newUrl, toGroup: group)
        }
        catch {
            return error
        }
        if group.groups.count == 0 && group.channels.count == 0 {
            return Err("Not found groups or channels for:\(newUrl)")
        }
        group.remoteInfo = RemoteGroupInfo(url: newUrl)
        
        let pathElements = ChannelManager.getPathElements(path)
        if pathElements.groups == nil {
            return Err("Not found path:\(path.split(separator: "->"))")
        }
        
        
        let parentGroup = pathElements.groups!.last!
        parentGroup.groups.append(group)
        
        return nil
    }
    
    
    
}


    
extension  ChannelManager { //parsing m3u list
    class func addM3uList(url:String, toGroup:GroupInfo) throws -> Void {
    
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
            
        
            //clear groups and channels (if exist)
            toGroup.groups = [GroupInfo]()
            toGroup.channels = [ChannelInfo]()
            
            //add groups
            for (nameGroup,itemList) in groupsList {
                let group = GroupInfo(name:nameGroup, groups:[], channels:[])
                toGroup.groups.append(group)
                
                for item in itemList {
                    let channel = ChannelInfo(name:item.name!, url:item.url!)
                    group.channels.append(channel)
                    //print("add channel:\(channel.name) to group:\(group.name)")
                }
            }
            
            //add items without groups
            for item in channelList {
                let channel = ChannelInfo(name:item.name!, url:item.url!)
                toGroup.channels.append(channel)
            }
            
            //sort groups by count channels
            if toGroup.groups.count > 0 {
                toGroup.groups.sort(by: {$0.channels.count > $1.channels.count})
            }
            
        }
    }

}
