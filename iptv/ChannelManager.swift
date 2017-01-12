//
//  ChannelManager.swift
//  iptv
//
//  Created by Александр Колганов on 26.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import Foundation

class ChannelInfo : NSObject, NSCoding, NSCopying {
    
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
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = ChannelInfo(name: name, url:url)
        return copy
    }

}

class RemoteGroupInfo: NSObject, NSCoding, NSCopying {
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
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = RemoteGroupInfo(url: url, hiddenGroup: hiddenGroup.copy() as! GroupInfo)
        return copy
    }


}


class GroupInfo : NSObject, NSCoding, NSCopying {
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
    
    required init(original:GroupInfo) {
        name = original.name
        channels = original.channels
        groups = original.groups
        remoteInfo = original.remoteInfo
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
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = GroupInfo(name: name)
        for channel in channels {
            copy.channels.append(channel.copy() as! ChannelInfo)
        }
        for group in groups {
            copy.groups.append(group.copy() as! GroupInfo)
        }
        if remoteInfo != nil {
            copy.remoteInfo = remoteInfo!.copy() as? RemoteGroupInfo
        }
        
        return copy
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
    
    
    var saveTimer : Timer?
    
    // Singleton
    static let instance = ChannelManager()
    private init() {}
    
    lazy var rootGroup : GroupInfo = {
        
        if let data = UserDefaults.standard.object(forKey: ChannelManager.userDefaultKey) as? NSData {
            var root = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! GroupInfo
            ChannelManager.instance.loadRemoteGroups(group:root)
            
            if root.groups.index(where:{$0.name == ChannelManager.groupNameFavorites}) == nil {
                root.groups.append( GroupInfo(name: ChannelManager.groupNameFavorites) )
            }
            return root
        }
        else {
            var root = GroupInfo( name:ChannelManager.groupNameRoot, groups: [], channels: [])
            root.groups.append( GroupInfo(name: ChannelManager.groupNameFavorites) )
            
            var demo = GroupInfo(name: "Demo")
            demo.remoteInfo = RemoteGroupInfo(url: "http://tvorg.alevko.com/playlists/demo.m3u")
            root.groups.append(demo)
            ChannelManager.instance.loadRemoteGroups(group:root)
            return root
        }
        
        
    }()
    
    
    
    class var root : GroupInfo {
        get {
            return ChannelManager.instance.rootGroup
        }
    }
    
    lazy var favoriteGroup : GroupInfo = {
        var favorite = ChannelManager.root.groups.first(where:{$0.name == ChannelManager.groupNameFavorites})
        return favorite!
    }()

    
    class func favoriteIndex(_ channel:ChannelInfo) -> Int? {
        return ChannelManager.instance.favoriteGroup.channels.index(where:{$0.name == channel.name})
    }
    
    
    class func changeFavoriteChannel(_ channel:ChannelInfo) {
        
        let favGroup = ChannelManager.instance.favoriteGroup
        let ind = ChannelManager.favoriteIndex(channel)
        if ind != nil {
            favGroup.channels.remove(at:ind!)
        }
        else {
            favGroup.channels.append(channel)
        }
    }
    
    class func lastName(_ path : [String]) -> String {
        if path.count > 0 {
            return path.last!
        }
        else {
            return ChannelManager.groupNameRoot
        }
        
    }
    
    
    class func findDirElement(_ path: [String]) -> DirElement? {
        
        if path.count == 0 {
            return DirElement.group(root)
        }
        
        if let parentGroup = findParentGroup(path) {
            let name = path.last!
            if name == ChannelManager.groupNameHidden && parentGroup.remoteInfo != nil {
                return DirElement.group(parentGroup.remoteInfo!.hiddenGroup)
            }
            return parentGroup.findDirElement(name)
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
        
        if path[0] == ChannelManager.groupNameHidden,
           let hiddenGroup = group.remoteInfo?.hiddenGroup
        {
            return findGroup( Array(path[1..<path.count]), group:hiddenGroup )
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
            
            var group : GroupInfo? = nil
            if name == ChannelManager.groupNameHidden && currentGroup.remoteInfo != nil {
                group = currentGroup.remoteInfo?.hiddenGroup
            }
            else {
                group = currentGroup.groups.first(where:{$0.name == name})
            }
            if group != nil {
                groups.append(group!)
                currentGroup = group!
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
        let elements = getPathElements(path)
        guard let groups = elements.groups
        else {
             return nil
        }
        var lastInd = groups.count-1
        if elements.channel == nil {
           lastInd -= 1
        }
        
        if lastInd < 1 {
            return nil
        }
        
        for ind in (1...lastInd).reversed() {
            if groups[ind].remoteInfo != nil {
                return groups[ind]
            }
        }
        return nil
    }
    
    func loadRemoteGroups(group parentGroup:GroupInfo) {
        for group in parentGroup.groups {
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
        
        //remove empty groups
        for ind in (0..<group.groups.count).reversed() {
            if group.groups[ind].countDirElements() == 0 {
                group.groups.remove(at: ind)
            }
        }
        
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
        let man = ChannelManager.instance
        if man.saveTimer != nil {
            man.saveTimer!.invalidate()
        }
        man.saveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { (timer) in
            let data = NSKeyedArchiver.archivedData(withRootObject: ChannelManager.root)
            UserDefaults.standard.set(data, forKey: ChannelManager.userDefaultKey)
            print("saved channels")
            man.saveTimer = nil
        })
    }
    

    class func delPathElement(_ path: [String]) -> Error? {
        
        let pathElements = ChannelManager.getPathElements(path)
        guard let groups = pathElements.groups
        else {
            return Err("Not found path:\(path.joined(separator: "->"))")
        }
        
        //check reserved name
        if  pathElements.channel == nil,
            let _ = ChannelManager.reservedNames.index(of:pathElements.groups!.last!.name)
        {
            return Err("You can't delete reserved group:\"\(pathElements.groups!.last!.name)\"")
        }

        
        var delGroup : GroupInfo? = nil
        var remoteGroup : GroupInfo? = nil
        var addHiddenGroup : GroupInfo? = nil

        var delChannel = pathElements.channel
        var parentGroup = groups.last!
        if delChannel == nil {
            delGroup = parentGroup
            parentGroup = groups[groups.count - 2]
        }
        
        
        if parentGroup.remoteInfo != nil { //add group/channel in hidden group
            remoteGroup = parentGroup
            addHiddenGroup = parentGroup.remoteInfo!.hiddenGroup
        }
        else if delChannel != nil && groups.count > 1 && groups[groups.count - 2].remoteInfo != nil { //add channel in group into hidden group
            remoteGroup = groups[groups.count - 2]
            let hiddenGroup = remoteGroup!.remoteInfo!.hiddenGroup
            addHiddenGroup = hiddenGroup.groups.first(where:{$0.name == parentGroup.name})
            if addHiddenGroup == nil {
                addHiddenGroup = GroupInfo(name:parentGroup.name)
                hiddenGroup.groups.append(addHiddenGroup!)
            }
        }
        
        
        if delChannel != nil { //delete channel
            if addHiddenGroup != nil {
                addHiddenGroup!.channels.append(delChannel!)
            }
            
            if let index = parentGroup.channels.index(where: {$0.name == path.last})  {
                parentGroup.channels.remove(at: index)
                ChannelManager.save()
                return nil
            }
        }
        else { //delete group
            if addHiddenGroup != nil {
                if let group =  addHiddenGroup!.groups.first(where:{$0.name == delGroup!.name}) {
                    //copy rest channels from delGroup to group
                    for channel in delGroup!.channels {
                        group.channels.append(channel)
                    }
                }
                else {
                    addHiddenGroup!.groups.append(delGroup!)
                }
            }
            
            if let index = parentGroup.groups.index(where: {$0.name == path.last})  {
                parentGroup.groups.remove(at: index)
                ChannelManager.save()
                return nil
            }
        }
        
        
        return Err("Not found path element:\(path.joined(separator:"->"))")
    }
    
    class func unhidePath(_ path: [String]) -> Error? {
        let pathElements = ChannelManager.getPathElements(path)
        guard let groups = pathElements.groups
            else {
                return Err("Not found path:\(path.joined(separator: "->"))")
        }
        
        if pathElements.channel != nil { //unhide channel

            let groupFrom = groups.last!
            var groupTo : GroupInfo? = nil
            
            if groupFrom.name == ChannelManager.groupNameHidden {
                groupTo = groups[groups.count-2] //remoteGroup
            }
            else if groups[groups.count-2].name == ChannelManager.groupNameHidden {
                let remoteGroup = groups[groups.count-3]
                groupTo = remoteGroup.groups.first(where:{$0.name == groupFrom.name})
                if groupTo == nil {
                    return Err("not found group \(groupFrom.name) in hidden group")
                }
            }
            else {
                return Err("not found hidden group")
            }
            let index = groupFrom.channels.index(where:{$0.name == pathElements.channel!.name})
            if index == nil {
                return Err("not found \"\(pathElements.channel!.name)\" in hidden group")
            }
            groupFrom.channels.remove(at: index!)
            groupTo!.channels.append(pathElements.channel!)
            
        }
        else {
            //restore group
            if groups.count < 3 {
                return Err("not found remote group")
            }
            let group = groups[groups.count-1]
            let hiddenGroup = groups[groups.count-2]
            if hiddenGroup.name != ChannelManager.groupNameHidden {
                return Err("not found hidden group")
            }
            let remoteGroup = groups[groups.count-3]
            var groupTo = remoteGroup.groups.first(where:{$0.name == group.name})
            
            //find or add new group in remote group
            if groupTo == nil {
                groupTo = GroupInfo(name:group.name)
                remoteGroup.groups.append(groupTo!)
            }
            
            //add channels from hidden group to remote group
            for channel in group.channels {
                groupTo!.channels.append(channel)
            }
            
            //delete group from hidden
            if let index = hiddenGroup.groups.index(of:group) {
                hiddenGroup.groups.remove(at:index)
            }
            
        }
        return nil
    }
    
    
    class func checkCorrectName(_ name:String, _ parentGroup:GroupInfo) -> Error? {
        if name.isBlank {
            return Err("You cann't use blank string")
        }
        
        if let _ = ChannelManager.reservedNames.index(of:name) {
            return Err("You cann't use reserved name: \"\(name)\"")
        }
        
        if parentGroup.findDirElement(name) != nil {
            return Err("Name \"\(name)\" is already in use, please choose another name")
        }
        
        return nil
        
    }
    
    class func changeChannel(_ path:[String], name newName:String, url newUrl:String) -> Error? {
        
        let pathElements = ChannelManager.getPathElements(path)
        if let channel = pathElements.channel,
            let groups = pathElements.groups,
            let parentGroup = groups.last
        {
            if newName == channel.name && newUrl == channel.url {
                return nil
            }
            
            if newName != channel.name {
                if let err = checkCorrectName(newName, parentGroup) {
                    return err
                }
            }
            
            channel.name = newName
            channel.url = newUrl
            
            ChannelManager.save()
            return nil
            
        }
        else {
            return Err("Not found path:\(path.joined(separator: "->"))")
        }
    }
    
    class func changeGroup(_ path:[String], name newName:String) -> Error? {

        
        let pathElements = ChannelManager.getPathElements(path)
        if  pathElements.channel == nil,
            let groups = pathElements.groups,
            groups.count > 1
        {
            let group = groups.last!
            let parentGroup = groups[groups.count - 2]

            if newName == group.name {
                return nil
            }
            
            if let err = ChannelManager.checkCorrectName(newName, parentGroup) {
                return err
            }
            group.name = newName
            ChannelManager.save()
            return nil
            
        }
        else {
            return Err("Not found path:\(path.joined(separator: "->"))")
        }
    }
    
    class func addGroup(_ path:[String], name:String) -> Error? {
        
        let pathElements = ChannelManager.getPathElements(path)
        
        if  pathElements.channel == nil,
            let groups = pathElements.groups,
            groups.count > 0
        {
            let parentGroup = groups.last!
            
            if let err = ChannelManager.checkCorrectName(name, parentGroup) {
                return err
            }
            
            parentGroup.groups.append( GroupInfo(name:name) )
            ChannelManager.save()
            return nil
            
        }
        else {
            return Err("Not found path:\(path.joined(separator: "->"))")
        }
        
    }

    class func addChannel(_ path:[String], name:String, url:String) -> Error? {
        
        let pathElements = ChannelManager.getPathElements(path)
        
        if  pathElements.channel == nil,
            let groups = pathElements.groups,
            groups.count > 0
        {
            let parentGroup = groups.last!
            
            if let err = ChannelManager.checkCorrectName(name, parentGroup) {
                return err
            }
            
            parentGroup.channels.append( ChannelInfo(name:name, url:url) )
            ChannelManager.save()
            return nil
            
        }
        else {
            return Err("Not found path:\(path.joined(separator: "->"))")
        }
        
    }
    
    class func addRemoteGroup(_ path:[String], name newName:String, url newUrl:String) -> Error? {
        
        
        let pathElements = ChannelManager.getPathElements(path)
        
        if  pathElements.channel == nil,
            let groups = pathElements.groups,
            groups.count > 0
        {
            let parentGroup = groups.last!
            
            if let err = ChannelManager.checkCorrectName(newName, parentGroup) {
                return err
            }
        
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
            parentGroup.groups.append(group)
            ChannelManager.save()
            return nil
        }
        else {
            return Err("Not found path:\(path.joined(separator: "->"))")
        }
    }
    
    class func reorderPath(_ path: [String], shift: Int) -> Error?
    {
        let pathElements = ChannelManager.getPathElements(path)
        if pathElements.groups == nil {
            return Err("Not found source path:\(path.joined(separator: "->"))")
        }

        if pathElements.channel != nil {
            let group = pathElements.groups!.last!
            if let ind = group.channels.index(of:pathElements.channel!) {
                var newInd = ind + shift
                if newInd < 0 {
                    newInd = 0
                }
                if newInd >= group.channels.count {
                    newInd = group.channels.count - 1
                }
                if ind != newInd {
                    group.channels.remove(at: ind)
                    group.channels.insert(pathElements.channel!, at:newInd)
                    ChannelManager.save()
                }
            }
        }
        else {
            if pathElements.groups!.count > 1 {
                let group = pathElements.groups![pathElements.groups!.count-2]
                let movingGroup = pathElements.groups!.last!
                
                if let ind = group.groups.index(of:movingGroup) {
                    var newInd = ind + shift
                    if newInd < 0 {
                        newInd = 0
                    }
                    if newInd >= group.groups.count {
                        newInd = group.groups.count - 1
                    }
                    
                    if ind != newInd {
                        group.groups.remove(at: ind)
                        group.groups.insert(movingGroup, at:newInd)
                        ChannelManager.save()
                    }
                }

            }
        }
        return nil        
    }
    
    
    class func isAvailableMoveCopy(_ path: [String], to:[String]) -> Error? {

        let pathElements = ChannelManager.getPathElements(path)
        if pathElements.groups == nil {
            return Err("Not found source path:\(path.joined(separator: "->"))")
        }
        
        let pathToElements = ChannelManager.getPathElements(to)
        if pathToElements.groups == nil {
            return Err("Not found destination path:\(to.joined(separator: "->"))")
        }
        
        
        //check pathTo is group (not channel)
        if pathToElements.channel != nil {
            return Err("You can't copy/move to channel")
        }
        
        //check duplicate name
        let sourceName = pathElements.channel != nil ? pathElements.channel!.name : pathElements.groups!.last!.name
        if let dirElement = pathToElements.groups!.last!.findDirElement(sourceName) {
            return Err("Group has item with the same name")
        }
        
        //check copy/move to Remote group
        if let remoteGroup = pathToElements.groups!.first(where: {$0.remoteInfo != nil }) {
            return Err("You can't cope/move to Remote group:\"\(remoteGroup.name)\"")
        }
        
        //check favorite
        //      to favorite
        if  pathToElements.groups!.last!.name == ChannelManager.groupNameFavorites,
            pathElements.channel == nil
        {
            return Err("You can't copy/move group to Favorite")
        }
        
        //check copy/move reserved group
        if let _ = ChannelManager.reservedNames.index(of:pathElements.groups!.last!.name) {
            return Err("You can't copy/move reserved group:\"\(pathElements.groups!.last!.name)\"")
        }
        
        
        
        //check recursion (copy from parent group to child group)
        var isRecursion = false
        if  pathElements.channel == nil,
            pathElements.groups!.count <= pathToElements.groups!.count
        {
            isRecursion = true
            for ind in (0..<pathElements.groups!.count) {
                if pathElements.groups![ind] !=  pathToElements.groups![ind] {
                    isRecursion = false
                    break
                }
            }
        }
        
        if isRecursion {
            return Err("You can't copy/move parent group to child group")
        }
        
        return nil
        
    }
    
    class func movePath(_ path: [String], to:[String], index:Int? = nil) -> Error?  { // if index == 0 to last group/channel
        
        if let err = ChannelManager.isAvailableMoveCopy(path, to:to) {
            return err
        }
        
        let pathElements = ChannelManager.getPathElements(path)
        let pathToElements = ChannelManager.getPathElements(to)

        //check move from remote group
        var lastIndex = pathElements.groups!.count - 1
        if pathElements.channel == nil {
            lastIndex -= 1
        }
        
        if lastIndex >= 1 {
            for ind in 1...lastIndex {
                if pathElements.groups![ind].remoteInfo != nil {
                    return Err("You can't move from remote group:\"\(pathElements.groups![ind].name)\"")
                }
            }
        }
        
        //move channel
        let groupTo = pathToElements.groups!.last!
        if let channel = pathElements.channel {
            let group = pathElements.groups!.last!
            if let ind = group.channels.index(of: channel) {
                group.channels.remove(at: ind)
                if index == nil || index! >= groupTo.channels.count-1 {
                    groupTo.channels.append(channel)
                }
                else {
                    groupTo.channels.insert(channel, at: index!)
                }
            }
        }
        else {
            if pathElements.groups!.count > 1 {
                let group = pathElements.groups![pathElements.groups!.count-2]
                let copingGroup = pathElements.groups!.last!
                if let ind = group.groups.index(of: copingGroup) {
                    group.groups.remove(at: ind)
                }
                if index == nil || index! >= groupTo.channels.count-1 {
                    groupTo.groups.append(copingGroup)
                }
                else {
                    groupTo.groups.insert(copingGroup, at: index!)
                }
                
            }
        }
        ChannelManager.save()
        
        return nil
    }
    
    class func copyPath(_ path: [String], to:[String], index:Int? = nil) -> Error?  { // if index == 0 to last group/channel
        
        if let err = ChannelManager.isAvailableMoveCopy(path, to:to) {
            return err
        }
        
        let pathElements = ChannelManager.getPathElements(path)
        let pathToElements = ChannelManager.getPathElements(to)
        
        
        //copy channel
        let groupTo = pathToElements.groups!.last!
        if let channel = pathElements.channel {
            if index == nil || index! >= groupTo.channels.count-1 {
                groupTo.channels.append(channel.copy() as! ChannelInfo)
            }
            else {
                groupTo.channels.insert(channel.copy() as! ChannelInfo, at: index!)
            }
        }
        else {
            if pathElements.groups!.count > 1 {
                let copingGroup = pathElements.groups!.last!.copy() as! GroupInfo
                if index == nil || index! >= groupTo.channels.count-1 {
                    groupTo.groups.append(copingGroup)
                }
                else {
                    groupTo.groups.insert(copingGroup, at: index!)
                }
            }
        }
        ChannelManager.save()
        
        return nil
    }

    
/*
    class func movePath(_ path: [String], after:[String])
    
    class func movePath(_ path: [String], before:[String])
*/
    
}


    
extension  ChannelManager { //parsing m3u list
    
    
    class func nameWithVersion(_ name:String, _ duplicateNames:inout [String:Int]) -> String {
        let ver = duplicateNames[name]
        if ver != nil {
            duplicateNames[name] = ver! + 1
            return "\(name) .\(ver!)"
        }
        else {
            duplicateNames[name] = 1
            return name
        }
    }
    
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
                
                var duplicateNames = [String: Int]()
                for item in itemList {
                    let name = ChannelManager.nameWithVersion(item.name!, &duplicateNames)
                    let channel = ChannelInfo(name:name, url:item.url!)
                    group.channels.append(channel)
                    //print("add channel:\(channel.name) to group:\(group.name)")
                }
            }
            
            //add items without groups
            var duplicateNames = [String: Int]()
            for item in channelList {                
                let name = ChannelManager.nameWithVersion(item.name!, &duplicateNames)
                let channel = ChannelInfo(name:name, url:item.url!)
                toGroup.channels.append(channel)
            }
            
            //sort groups by count channels
            if toGroup.groups.count > 0 {
                toGroup.groups.sort(by: {$0.channels.count > $1.channels.count})
            }
            
        }
    }

}
