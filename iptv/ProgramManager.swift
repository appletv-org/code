//
//  ProgramManager.swift
//  iptv
//
//  Created by Alexandr Kolganov on 19.10.16.
//  Copyright © 2016 Home. All rights reserved.
//

import Foundation
import CoreData


class EpgProviderInfo : NSObject, NSCoding {
    
    enum ProcessStatus {
        case idle, waiting, processing
    }
    
    
    var name : String = ""
    var url:   String = ""
    var updateTime: Int = 0 //((24*day + hours)*60 + minuts)*60 + seconds, where  day:0-everyday, 1-sunday,...,7-monday
    var shiftTime: Int = 0//hours*60 + minuts)*60 + seconds
    var parseProgram = true
    var parseIcons = true
    
    
    //not store values
    var status : ProcessStatus = .idle
    
    
    //---
    
    override init() {
        super.init()
    }
    
    init(name: String, url:String) {
        self.name = name
        self.url = url
    }
    
    
    func codeParseProperties() -> Int {
        if parseProgram && parseIcons {
            return 0
        }
        else if parseProgram {
            return 1
        }
        else {
            return 2
        }
    }
    
    func decodeParseProperties(_ prop: Int) {
        switch(prop) {
        case 1:
            parseProgram = true
            parseIcons   = false
        case 2:
            parseProgram = false
            parseIcons   = true
        default:
            parseIcons   = true
            parseProgram = true
        }
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
        
        self.updateTime =  decoder.decodeInteger(forKey: "update")
        self.shiftTime = decoder.decodeInteger(forKey: "shift")
        decodeParseProperties( decoder.decodeInteger(forKey: "use") )
        
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.url, forKey: "url")
        coder.encode(self.updateTime, forKey: "update")
        coder.encode(self.shiftTime, forKey: "shift")
        coder.encode(codeParseProperties(), forKey:"use")
    }
}


class ProgramManager : NSObject {
    
    static let providerUserDefaultKey = "epgProviders"
    static let linkUserDefaultKey = "epgLinks"
    
    
    static let epgNotification = Notification.Name("EpgNotification")
    
    static let userInfoStatus = "status"
    static let userInfoProvider = "provider"
    static let errorMsg = "errorMsg"
    
    let serialQueue = DispatchQueue(label: "ProgramManagerQueue", qos: .background)
    
    var iconCache =  NSCache<NSString,NSData>()
    
    var timerUpdate : Timer?
    
    var _epgProviders : [EpgProviderInfo]?
    var epgProviders :  [EpgProviderInfo] {
        get {
            if(_epgProviders == nil) {
                _epgProviders = [EpgProviderInfo]()
                if let data = UserDefaults.standard.object(forKey: ProgramManager.providerUserDefaultKey) as? NSData {
                    if let providers = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? [EpgProviderInfo] {
                        _epgProviders = providers
                    }
                }
            }
            return _epgProviders!
        }
    }
    
    
    lazy var channelLinks : [String:String] = {
        if let links = UserDefaults.standard.dictionary(forKey: ProgramManager.linkUserDefaultKey) as? [String:String] {
            return links
        }
        return [:]
    }()
    
    
    
    static let instance = ProgramManager()
    private override init() {
    }

    
    func save() {
        let data = NSKeyedArchiver.archivedData(withRootObject: _epgProviders!)
        UserDefaults.standard.set(data, forKey: ProgramManager.providerUserDefaultKey)
    }

    func getProvider(_ name: String) -> EpgProviderInfo? {
        let provider = epgProviders.first(where: {$0.name == name})
        return provider
    }
    
    func getDbProvider(_ name:String) -> EpgProvider? {
        let providers : [EpgProvider] = CoreDataManager.simpleRequest(NSPredicate(format:"name==%@", name))
        if providers.count > 0 {
            return providers[0]
        }
        return nil
    }
    
    class func startStopTime(_ program:EpgProgram) -> (start:Date?, stop:Date?) {
        return ProgramManager.instance._startStopTime(program)
    }
    
    
    //start & stop time with timeshift
    func _startStopTime(_ program:EpgProgram) -> (start:Date?, stop:Date?) {
        var start = program.start as Date?
        var stop = program.stop as Date?
        guard   let dbProvider = program.channel?.provider,
                let provider = getProvider(dbProvider.name!),
                provider.shiftTime != 0
        else {
            return (start, stop)
        }
        
        if start != nil {
            start!.addTimeInterval(TimeInterval(provider.shiftTime))
        }
        if stop != nil {
            stop!.addTimeInterval(TimeInterval(provider.shiftTime))
        }
        return (start, stop)
        
    }
    
    func epgName(_ name:String) -> String {
        var nameForEpg = componentName(name).name
        if let linkName = channelLinks[nameForEpg] {
            nameForEpg = linkName
        }
        return nameForEpg
    }
    
    func componentName(_ name:String) -> (name:String, shiftTime:Int) { //name withoup hour zone and version, example: BBC +2 .3 -> +2:shifttime, .3:version
        
        var shiftTime = 0
        
        var components = name.components(separatedBy: " ")
        if components.count != 1 {
        
            //remove version ( <space>.<number>)
            var lastComp = components.last!
            if  lastComp.count >= 2,
                lastComp[lastComp.startIndex] == "."
            {
                let ver = String(lastComp.dropFirst())
                if Int(ver) != nil {
                    let _ = components.popLast()
                }
            }
            
            //remove timeShift ( <space><+/-><number>)
            if components.count != 1 {
                lastComp = components.last!
                if  lastComp.characters.count >= 2 {
                    let firstSymbol = lastComp[lastComp.startIndex]
                    if  firstSymbol == "+" ||  firstSymbol == "-",
                        let timeShift = Int(lastComp)
                    {
                        shiftTime = timeShift
                        let _ = components.popLast()
                    }
                }
            }
        }
        
        return (components.joined(separator:" "), shiftTime)
    }
    
    func getPrograms(channel: String, from:Date?=nil, to:Date?=nil )  -> [EpgProgram] {
        
        for provider in epgProviders  where provider.parseProgram {
            let programs = getProviderPrograms(provider: provider, channel:channel, from:from, to:to)
            if programs.count > 0 {
                return programs
            }            
        }

        return []
    }
    
    func getProviderPrograms(provider:EpgProviderInfo, channel: String, from:Date?=nil, to:Date?=nil )  -> [EpgProgram] {
        
        
        let nameEpg = epgName(channel)
        
        guard let dbChannel : EpgChannel = CoreDataManager.requestFirstElement(
                        NSPredicate(format: "name == %@ AND provider.name == %@", nameEpg.lowercased(),  provider.name)),
              var programs = dbChannel.programs?.allObjects as? [EpgProgram]
        else {
             return []
        }
        
        
        if from != nil || to != nil {
            var fromDate = "01.01.2000".toFormatDate("dd.mm.YYYY")!
            if from != nil {
                fromDate = from!.addingTimeInterval(-TimeInterval(provider.shiftTime))
            }
            
            var toDate = "01.01.2100".toFormatDate("dd.mm.YYYY")!
            if to != nil {
                toDate = to!.addingTimeInterval(-TimeInterval(provider.shiftTime))
            }
            
            let filterPrograms = programs.filter {
                ($0.stop! as Date) > fromDate && ($0.start! as Date) <= toDate
            }
            programs = filterPrograms
        }
        
        //sort programs by start time
        programs.sort(by: { $0.start!.timeIntervalSince1970 < $1.start!.timeIntervalSince1970 })

        
        return programs
    }
    
    
    func getIcon(channel: String, completion:@escaping (Data?) -> Swift.Void )  {
        
        if let nsData = iconCache.object(forKey: channel as NSString) {
            if(Thread.isMainThread) {
                completion(nsData as Data)
            }
            else {
                DispatchQueue.main.async {
                    completion(nsData as Data)
                }
            }
        }
        
        DispatchQueue.global().async {
            
            var data : Data? = nil
            for provider in self.epgProviders where provider.parseIcons {
                data = self._getProviderIcon(channel: channel, provider: provider.name)
                if data != nil {
                    self.iconCache.setObject(data! as NSData, forKey: channel as NSString)
                    break
                }
            }
                    
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
    
    func getProviderIcon(channel: String, provider: String, completion:@escaping (Data?) -> Swift.Void )  {
        DispatchQueue.global().async {
            
            let data = self._getProviderIcon(channel: channel, provider: provider)
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }

    private func _getProviderIcon(channel: String, provider: String) -> Data? {
        
        let nameEpg = self.epgName(channel)

        guard let dbChannel : EpgChannel = CoreDataManager.requestFirstElement(NSPredicate(format: "name==%@ AND provider.name == %@",
                                                                                          nameEpg.lowercased(),  provider) ),
              let strUrl = dbChannel.icon,
              let url = URL(string:strUrl),
              let data = try? Data(contentsOf: url)
        
        else {
            return nil
        }
        return data
    }
    
    
    
    
    func addProvider(_ provider:EpgProviderInfo) -> Error? {
        if let error = checkProviderFields(name:nil, provider:provider) {
            return error
        }
        
        //save providers in UserDefault
        _epgProviders!.append(provider)
        save()
        
        Analytics.logCountry("addEPGProvider", params:["url":provider.url, "name":provider.name, "updateTime": String(provider.updateTime)])
        
        //update programs and icons in DB
        updateData(provider, isNew:true)

        return nil
    }
        

    
    
    func updateProvider(name:String, provider:EpgProviderInfo) -> Error? {
        if let error = checkProviderFields(name:name, provider:provider) {
            return error
        }
        
        if let ind = epgProviders.index(where: {$0.name == name}) { //previous providerInfo
            let prevProvider = _epgProviders![ind]
            _epgProviders![ind] = provider
            save()
        
            if name != provider.name {
                //change name of DB provider
                if let prevDBProvider = getDbProvider(name) {
                    prevDBProvider.name = provider.name
                    CoreDataManager.instance.saveContext()
                }
            }
            
            if prevProvider.url != provider.url {
                updateData(provider)
            }
            else {
                NotificationCenter.default.post(name: ProgramManager.epgNotification, object:nil,
                                                userInfo: [ ProgramManager.userInfoStatus:"update", ProgramManager.userInfoProvider: provider] )
            }
            
            if prevProvider.updateTime != provider.updateTime {
                self.checkUpdateTimer()
            }
            
            
            
        }
        else {
            return Err("Unexpeсted error: Not found provider for update")
        }
        
        return nil        
    }
    
    func delProvider(_ name:String) -> Error? {
        if let ind = _epgProviders!.index(where: {$0.name == name}) {
        
            let provider = _epgProviders![ind]
            _epgProviders!.remove(at: ind)
            save()
            
            NotificationCenter.default.post(name: ProgramManager.epgNotification, object:nil,
                                            userInfo: [ ProgramManager.userInfoStatus:"delete", ProgramManager.userInfoProvider: provider] )

            clearData(provider)
            
            return nil
        }
        else {
            
            return Err("Unexpeсted error: Not found provider for delete")

        }
        
    }

    
    func checkProviderFields(name:String?, provider:EpgProviderInfo) -> Error? {
        
        if provider.name.isEmpty {
            return Err("Empty field: \"Name\"")
        }
        
        if provider.name != name {
            if getProvider(provider.name) != nil {
                return Err("Provider with Name: \"\(provider.name)\" is existed. Please enter unique name.")
                
            }
        }
        
        if provider.url.isEmpty {
            return Err("Empty field: \"Url\"")
        }
        
        return nil
        
    }
    
    func replaceProviders(from:Int, to:Int) {
        
        if from != to && from >= 0 && to >= 0 && from < _epgProviders!.count && to < _epgProviders!.count {
            swap(&_epgProviders![from], &_epgProviders![to])
            save()
        }
        
    }
    
    func existChannelLink(_ channel:String) -> Bool {
        let nameShift = componentName( channel )
        return (channelLinks[nameShift.name] != nil)
    }

    func addChannelLink(channel:String, epg:String) {
        let nameShift = componentName( channel )
        channelLinks[nameShift.name] = epg
        UserDefaults.standard.setValue(channelLinks, forKey: ProgramManager.linkUserDefaultKey)
    }
    func delChannelLink(_ channel:String) {
        let nameShift = componentName( channel )
        channelLinks.removeValue(forKey: nameShift.name)
        UserDefaults.standard.setValue(channelLinks, forKey: ProgramManager.linkUserDefaultKey)
    }
    
    

}


class ParserChannel {
    var name : String
    var icon : String?
    
    init(_ name:String) {
        self.name = name
    }
}

class ParserProgram {
    var start : Date
    var stop  : Date
    var title : String
    var desc  : String?
    var category: String?
    
    init(title:String, start:Date, stop:Date) {
        self.title = title
        self.start = start
        self.stop = stop
    }
}

class ParserChannelWithProgram {
    var channel : ParserChannel
    var programs: [ParserProgram]
    
    init(_ channel:ParserChannel) {
        self.channel = channel
        self.programs = [ParserProgram]()
    }
    
}






extension ProgramManager { //upload data (programs, icons) by url
    
    func checkUpdateTimer() {
        serialQueue.async {
            self._checkUpdateTimer()
        }
    }
    
    func _checkUpdateTimer() {
        
        var nextUpdateTime : Date?
        
        if timerUpdate != nil {
            timerUpdate!.invalidate()
            timerUpdate =  nil
        }
        
        
        
        for provider in epgProviders {
            
            if provider.updateTime < 0 {
                continue
            }

            //calc prev/next update time
            let updateDayofWeek = provider.updateTime / (24*60*60)
            let updateSeconds = provider.updateTime % (24*60*60)
            
            var dateComponent = DateComponents(hour:updateSeconds/(60*60), minute:updateSeconds/60%60, second:updateSeconds%60)
            if(updateDayofWeek != 0) { //everyday
                dateComponent.weekday = updateDayofWeek
            }
            guard let  prevUpdateDate = Calendar.current.nextDate(after: Date(), matching: dateComponent, matchingPolicy: .nextTime, direction:.backward),
                  let nextUpdateDate = Calendar.current.nextDate(after: Date(), matching: dateComponent, matchingPolicy: .nextTime, direction:.forward)
            else {
                continue
            }
            print("provider \(provider.name)")
            print("prevUpdateDate: \(prevUpdateDate.description(with: Locale.current)) ")
            print("nextUpdateDate: \(nextUpdateDate.description(with: Locale.current)) ")
            
            if nextUpdateTime == nil || nextUpdateTime! > nextUpdateDate {
                nextUpdateTime = nextUpdateDate
            }
            
            if provider.status != .idle {
                continue
            }
            
            if      let dbProvider = getDbProvider(provider.name),
                    let lastUpdate = dbProvider.lastUpdate as Date?,
                    lastUpdate > prevUpdateDate
            {
               continue
                
            }
            updateData(provider)

        }
        
        if nextUpdateTime !=  nil {
            let timeInterval = nextUpdateTime!.timeIntervalSinceNow + 1
            print("timeInterval: \(timeInterval)")
            DispatchQueue.main.async {
            self.timerUpdate = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { (_) in
                self.checkUpdateTimer()
            })
            }
        }
        
    }

    
    func updateData(_ provider:EpgProviderInfo, isNew:Bool = false) {
        
        if(provider.status != .idle) {
            return
        }
        
        provider.status = .waiting
        NotificationCenter.default.post(name: ProgramManager.epgNotification, object:nil,
                                        userInfo: [ ProgramManager.userInfoStatus:"waiting", ProgramManager.userInfoProvider: provider] )

        
        serialQueue.async {
            self._updateData(provider, isNew: isNew)
        }
    }
 
    func clearData(_ provider:EpgProviderInfo) {

        if(provider.status != .idle) {
            return
        }
        provider.status = .waiting
        NotificationCenter.default.post(name: ProgramManager.epgNotification, object:nil,
                                        userInfo: [ ProgramManager.userInfoStatus:"waiting", ProgramManager.userInfoProvider: provider] )

        serialQueue.async {
            self._clearData(provider)
        }
    }

    func _clearData(_ provider:EpgProviderInfo) {
        
        if let dbProvider = getDbProvider(provider.name) {
            
            provider.status = .processing
            NotificationCenter.default.post(name: ProgramManager.epgNotification, object:nil,
                                            userInfo: [ ProgramManager.userInfoStatus:"processing", ProgramManager.userInfoProvider: provider] )

            
            CoreDataManager.context().delete(dbProvider)
            try? CoreDataManager.context().save()
            
            provider.status = .idle
            NotificationCenter.default.post(name: ProgramManager.epgNotification, object:nil,
                                            userInfo: [ ProgramManager.userInfoStatus:"processed", ProgramManager.userInfoProvider: provider] )

        }
    }
    
    
    func _updateData(_ provider:EpgProviderInfo, isNew:Bool) {
        
        
        var dbProvider = getDbProvider(provider.name)
        if dbProvider == nil {
            if !isNew {
                print("warning: absent db provider for update: \(provider.name)")
            }
            
            dbProvider = EpgProvider(context:CoreDataManager.context())
            dbProvider!.name = provider.name
        }

        provider.status = .processing
        NotificationCenter.default.post(name: ProgramManager.epgNotification, object:nil,
                                        userInfo: [ ProgramManager.userInfoStatus:"processing", ProgramManager.userInfoProvider: provider] )
        
        
         //get file by link
        let url = URL(string: provider.url)
        if url == nil {
            
            provider.status = .idle
            dbProvider!.error = "wrong url"
            NotificationCenter.default.post(name: ProgramManager.epgNotification, object:nil,
                                            userInfo: [ ProgramManager.userInfoStatus:"error", ProgramManager.userInfoProvider: provider] )

            return
        }
        
        do {

            let tempPath = NSTemporaryDirectory().appendingPathComponent("program.xml")
            let tempFileUrl = URL(fileURLWithPath:  tempPath)
                
            //data to temporary file
            try autoreleasepool {
            
                //data to temporary file
                 var xml = try Data(contentsOf: url!)
                
                if xml.isGzipped {
                    let xmlnew = try xml.gunzipped()
                    xml = xmlnew
                }
                
                
                
                FileManager.default.createFile(atPath: tempFileUrl.path, contents: xml, attributes: nil)
                
                /*
                //let file = try FileHandle(forWritingTo: url)
                let file = try FileHandle(forWritingAtPath: tempFileUrl.path)
                file?.write(xml)
                file?.closeFile()
                 */
                
                
                //try xml.write(to: url)
                xml.removeAll(keepingCapacity: false)
                xml = Data() //release xml data
        
            }
            
            try parseFileAndSaveDb(tempFileUrl, provider)
            
            //parse xml and save to db
            //try parseXmlAndSaveDb2(xml, provider)
            
            
            dbProvider!.error = nil
            
        }
        
        catch {
            dbProvider!.error = error.localizedDescription
            
            print("processing error:\(error) for provider:\(provider.name)")
        }
        provider.status = .idle
        NotificationCenter.default.post(name: ProgramManager.epgNotification, object:nil,
                                        userInfo: [ ProgramManager.userInfoStatus:"processed", ProgramManager.userInfoProvider: provider] )
        
        //task.resume()
        
    }
    
    /*
    func parseXmlAndSaveDb(_ xml:Data, _ provider:EpgProviderInfo)  throws {
        let channels = try self._parseXml2(xml)
        self._saveProgramsToDB(provider, channels)
    }
 */
    
    /*
    func parseXmlAndSaveDb2(_ xml:Data, _ provider:EpgProviderInfo)  throws {
        let epgParser = EpgxmlToParseChannels()
        let dbReplaceChannels = DbReplaceChannel(provider)
        
        epgParser.delegate = dbReplaceChannels
        let ret = epgParser.parseData(xml)
        if ret.err != nil {
            throw ret.err!
        }
        dbReplaceChannels.finish()
    }
 */
    
    func parseFileAndSaveDb(_ url:URL, _ provider:EpgProviderInfo)  throws {
        let epgParser = EpgxmlToParseChannels()
        let dbReplaceChannels = DbReplaceChannel(provider)
        epgParser.delegate = dbReplaceChannels
        
        epgParser.parseFile(url)
        dbReplaceChannels.finish()
    }

    


    
    
    
    func _parseXml(_ data:Data) throws -> [String: ParserChannelWithProgram] {
        
        
        print("start parse xml")
        let xmlDoc = try AEXMLDocument(xml: data)
        print("start parse content xml")
        
        //save by id
        var channels = [String: ParserChannelWithProgram]()
        for child in xmlDoc.root.children {
            if(child.name == "channel") {
                let id = child.attributes["id"]
                var name = child["display-name"].value
                if(name != nil) {
                    name = name!.lowercased()
                }
                if(id == nil || name == nil) {
                    print("channel have not required fields: id \(String(describing: id)) or name \(String(describing: name))")
                    continue
                }
                
                let channel = ParserChannel(name!)
                if let icon = child["icon"].attributes["src"] {
                    channel.icon = icon
                }
                channels[id!] = ParserChannelWithProgram(channel)
            }
            else if(child.name == "programme") {
                let id = child.attributes["channel"]
                let start = child.attributes["start"]
                let stop = child.attributes["stop"]
                let title = child["title"].value
                
                
                if(id == nil || start == nil || stop == nil || title == nil) {
                    print("programme have not required fields: id \(String(describing: id)) or start \(String(describing: start)) or stop \(String(describing: stop)) or title \(String(describing: title))")
                    continue
                }
                
                let channel = channels[id!]
                if(channel == nil) {
                    print("channel id  \(String(describing: id)) not exist for programme")
                    continue
                }
                
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMddHHmmss Z"
                let startDate = formatter.date(from: start!)
                let stopDate = formatter.date(from: stop!)
                if(startDate == nil || stopDate == nil) {
                    print("cann't parse data \(String(describing: start)) or \(String(describing: stop))")
                    continue
                }
                
                let program = ParserProgram(title:title!, start:startDate!, stop:stopDate!)
                
                if let category = child["category"].value {
                    program.category = category
                }
                if let desc = child["desc"].value {
                    program.desc = desc
                }
                
                channels[id!]!.programs.append(program)
                
                //print("channel!.programs.count \(channels[id!]!.programs.count)")
                
                //print("channel: \(channel?.channel.name) title : \(program.title) start:\(program.start)")
                
            }
        }
        
        print("ProgramManager:_parseXml: parse \(channels.count) channels")
        return channels
        
    }

    /*
    func _parseXml2(_ data:Data) throws -> [String: ParserChannelWithProgram] {
        let epgParser = EpgxmlToParseChannels()
        let ret = epgParser.parseData(data)
        if ret.err != nil {
            throw ret.err!
        }
        return ret.channels
    }
 */
    
    /*
    func _saveProgramsToDB(_ provider:EpgProviderInfo, _ channels:  [String: ParserChannelWithProgram]) {
        
        let dbReplaceChannels = DbReplaceChannel(provider)
        for (id, channelProg) in channels {
            dbReplaceChannels.saveChannel(id: id, channelProg: channelProg)
        }
        dbReplaceChannels.finish()
    }
 */

}


protocol EpgxmlToParseChannelsDelegate: class {
    func saveChannel(id:String, channel:ParserChannel, programs:[ParserProgram] )
}

class EpgxmlToParseChannels : NSObject, XMLParserDelegate {
    
    weak var delegate : EpgxmlToParseChannelsDelegate?
    
    let formatter = DateFormatter()
    
    var channels = [String: ParserChannel]()
    var xmlParser = XMLParser()
    
    var channelId : String?
    var currentChannel : ParserChannel?
    var currentProgram : ParserProgram?
    var currentValue = ""
    //var lastChannelWithProgram : ParserChannelWithProgram?
    var lastChannel : ParserChannel?
    var lastChannelId = ""
    var programsForLastChannel: [ParserProgram] = []
    var err : Error?
    
    var channelCounter = 0

    
    override init() {
        self.formatter.dateFormat = "yyyyMMddHHmmss Z"
        super.init()
    }
    
    func parseFile(_ url:URL) {
        xmlParser = XMLParser(contentsOf: url)!
        xmlParser.delegate = self
        xmlParser.parse()
        
        //return (channels, err)
    }

    
/*
    func parseData(_ data:Data) -> (channels:[String: ParserChannelWithProgram], err:Error?) {
        xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
        
        return (channels, err)
    }
 */
    
    func parserDidStartDocument(_ parser: XMLParser) {
        channels = [:]
    }
    
    
    func parserDidEndDocument(_ parser: XMLParser) {
        if lastChannelId != "" && lastChannel != nil && delegate != nil && programsForLastChannel.count > 0 {
            delegate!.saveChannel(id: lastChannelId, channel: lastChannel!, programs:programsForLastChannel )
        }
    }
    
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        err = parseError
    }

    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        switch(elementName) {
        
        case "channel":
            
            channelId = attributeDict["id"]
            if channelId == nil {
                print ("channel have not attribute id")
                currentChannel = nil
            }
            else {
                currentChannel = ParserChannel("")
            }
            
        case "programme":
            channelId = attributeDict["channel"]
            let start = attributeDict["start"]
            let stop = attributeDict["stop"]
            
            if  channelId != nil, start != nil, stop != nil,
                let startDate = formatter.date(from: start!),
                let stopDate = formatter.date(from: stop!)
            {
                currentProgram = ParserProgram(title: "", start: startDate, stop: stopDate)
            }
            else {
                currentProgram = nil
            }
            

        
        case "icon":
            if  currentChannel != nil,
                let src = attributeDict["src"]
            {
                currentChannel!.icon = src
            }
            
        default:
            break

        }
        
    }
    
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        switch(elementName) {
            
        case "channel":
            if currentChannel != nil, currentChannel!.name != "", channelId != nil  {
                channels[channelId!] = currentChannel!
                currentChannel = nil
                channelId = nil
            }
            else {
                print("cann't parse channel: \(String(describing: currentChannel?.name)) \(String(describing: channelId))")
            }
    
        case "programme":
            if currentProgram != nil, currentProgram!.title != "", channelId != nil
            {
                if lastChannelId != channelId! { //save lastChannel with programs to db
                    if lastChannel != nil && programsForLastChannel.count > 0 && delegate != nil {
                        delegate!.saveChannel(id: lastChannelId, channel: lastChannel!, programs:programsForLastChannel)
                        channelCounter += 1
                        //print("count channels: \(channels.count) channelCounter: \(channelCounter) name: \(lastChannel?.name) programs:\(programsForLastChannel.count)")
                    }
                    else {
                        print("not saved programs for channel: \(String(describing: lastChannel?.name))")
                    }
                    
                    lastChannelId = channelId!
                    lastChannel = channels[channelId!]
                    programsForLastChannel = []
                    
                }
                if lastChannel != nil  {
                    programsForLastChannel.append(currentProgram!)
                }
                else {
                     print("not found channel for program: \(String(describing: currentProgram?.title)) \(String(describing: channelId))")
                }
            }
            else {
                print("cann't parse program: \(String(describing: currentProgram?.title)) \(String(describing: channelId))")
            }
            currentProgram = nil
            channelId = nil

        
        //channel values
        case "display-name":
            if currentChannel != nil, currentValue != "" {
                currentChannel!.name = currentValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
            }

        //programme values
        case "title":
            if currentProgram != nil, currentValue != "" {
                currentProgram!.title = currentValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }

            
        case "category":
            if currentProgram != nil, currentValue != "" {
                currentProgram!.category = currentValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            
        case "desc":
            if currentProgram != nil, currentValue != "" {
                currentProgram!.desc = currentValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            
        default:
            break
   
        }
        
        currentValue = ""
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.currentValue += string
    }
    
}


class DbReplaceChannel : EpgxmlToParseChannelsDelegate {
    
    let dbcontext = CoreDataManager.concurrentContext()
    var provider : EpgProviderInfo!
    var dbProvider : EpgProvider?
    var channelCount: Int64
    
    init(_ provider:EpgProviderInfo) {
        //let moc = CoreDataManager.context()
        
        //dbcontext.perform {
        self.provider = provider
        
        dbProvider = CoreDataManager.requestFirstElement(NSPredicate(format:"name==%@", provider.name), context:dbcontext)
        if dbProvider == nil {
            dbProvider = EpgProvider(context:dbcontext)
            dbProvider!.name = provider.name
        }
        channelCount = 0
    }
    
    func saveChannel(id:String, channel:ParserChannel, programs channelPrograms:[ParserProgram]) {
        
        if channelPrograms.count == 0 {
            return
        }
        
        channelCount += 1
        
        //sort programs by start time
        var programs = channelPrograms.sorted(by: { $0.start.timeIntervalSince1970 < $1.start.timeIntervalSince1970 })
        
        
        var dbChannel : EpgChannel? = CoreDataManager.requestFirstElement(NSPredicate(format: "name==%@ AND provider.name == %@", channel.name,  provider.name), context:dbcontext)
        
        if dbChannel == nil {
            dbChannel = EpgChannel(context:dbcontext)
            dbChannel!.id = id
            dbChannel!.name = channel.name
            dbChannel!.icon = channel.icon
            dbChannel!.provider = dbProvider
        }
        else {
            
            if programs.count > 0 {
                //delete programs, exist in new programs list
                let fetchRequest: NSFetchRequest<EpgProgram> = EpgProgram.fetchRequest()
                fetchRequest.predicate = NSPredicate(
                    format: "channel.name==%@ AND channel.provider.name == %@ AND start >= %@",
                    channel.name,  provider.name, programs[0].start as NSDate)
                
                if let result = try? dbcontext.fetch(fetchRequest) {
                    for dbprogram in result {
                        dbcontext.delete(dbprogram) //delete programs exists in new list
                    }
                }
            }
        }
        
        //add programs
        for program in programs {
            let dbprogram = EpgProgram(context:dbcontext)
            dbprogram.title = program.title
            dbprogram.desc = program.desc
            dbprogram.start = program.start // as NSDate?
            dbprogram.stop = program.stop // as NSDate?
            dbprogram.channel = dbChannel!
        }
        
    }
    
    func finish() {
        
        //delete programs more them 7-day old
        let oldDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(-7*24*60*60)
        let fetchRequest: NSFetchRequest<EpgProgram> = EpgProgram.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "channel.provider.name == %@ AND start < %@",
            provider.name, oldDate as NSDate)
        
        if let result = try? dbcontext.fetch(fetchRequest) {
            for dbprogram in result {
                dbcontext.delete(dbprogram) //delete old programs
            }
        }
        
        //get min max date
        
        var minDate : Date? = nil
        var maxDate : Date? = nil
        
        let fetchRequestDate: NSFetchRequest<EpgProgram> = EpgProgram.fetchRequest()
        fetchRequestDate.predicate = NSPredicate(format:"channel.provider.name == %@", provider.name)
        fetchRequestDate.fetchLimit = 1
        fetchRequestDate.sortDescriptors = [NSSortDescriptor(key: "start", ascending: true)]
        if  let result = try? dbcontext.fetch(fetchRequestDate),
            result.count > 0
        {
            minDate = result[0].start as Date?
        }
        fetchRequestDate.sortDescriptors = [NSSortDescriptor(key: "stop", ascending: false)]
        if  let result = try? dbcontext.fetch(fetchRequestDate),
            result.count > 0
        {
            maxDate = result[0].stop as Date?
        }
        
        if dbProvider != nil {
            dbProvider!.startDate = minDate // as NSDate?
            dbProvider!.finishDate = maxDate // as NSDate?
            dbProvider!.channelCount = channelCount
            dbProvider!.lastUpdate = Date() // as NSDate?
            
            CoreDataManager.saveConcurrentContext(dbcontext)
        }
    }
}
