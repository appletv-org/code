//
//  ProgramManager.swift
//  iptv
//
//  Created by Alexandr Kolganov on 19.10.16.
//  Copyright © 2016 Home. All rights reserved.
//

import Foundation
import CoreData

struct ParserChannel {
    var name : String
    var icon : String?
    
    init(_ name:String) {
        self.name = name
    }
}

struct ParserProgram {
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

struct ParserChannelWithProgram {
    var channel : ParserChannel
    var programs: [ParserProgram]
    
    init(_ channel:ParserChannel) {
        self.channel = channel
        self.programs = [ParserProgram]()
    }
    
}

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


class ProgramManager {
    
    static let userDefaultKey = "epgProviders"
    
    static let epgNotification = Notification.Name("EpgNotification")
    
    static let userInfoStatus = "status"
    static let userInfoProvider = "provider"
    static let errorMsg = "errorMsg"
    
    
    
    
    let serialQueue = DispatchQueue(label: "ProgramManagerQueue")
    
    var iconCache =  NSCache<NSString,NSData>()
    
    var timerUpdate : Timer?
    
    var _epgProviders : [EpgProviderInfo]?
    var epgProviders :  [EpgProviderInfo] {
        get {
            if(_epgProviders == nil) {
                _epgProviders = [EpgProviderInfo]()
                if let data = UserDefaults.standard.object(forKey: ProgramManager.userDefaultKey) as? NSData {
                    if let providers = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as? [EpgProviderInfo] {
                        _epgProviders = providers
                    }
                }
            }
            return _epgProviders!
        }
    }
    
    
    static let instance = ProgramManager()
    private init() {
    }

    
    func save() {
        let data = NSKeyedArchiver.archivedData(withRootObject: _epgProviders!)
        UserDefaults.standard.set(data, forKey: ProgramManager.userDefaultKey)
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
        var start = program.start as? Date
        var stop = program.stop as? Date
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
    
    func getPrograms(channel: String, from:Date?=nil, to:Date?=nil )  -> [EpgProgram] {
        
        let dbcontext = CoreDataManager.context()
        
        for provider in epgProviders  where provider.parseProgram {
            let programs = getProviderPrograms(provider:provider.name, channel:channel, from:from, to:to)
            if programs.count > 0 {
                return programs
            }            
        }

        return []
    }
    
    func getProviderPrograms(provider:String, channel: String, from:Date?=nil, to:Date?=nil )  -> [EpgProgram] {
        
        guard let dbChannel : EpgChannel = CoreDataManager.requestFirstElement(
                        NSPredicate(format: "name == %@ AND provider.name == %@",channel.lowercased(),  provider)),
              let programs = dbChannel.programs?.allObjects as? [EpgProgram]
        else {
             return []
        }
        
        
        if from == nil && to == nil {
            return programs
        }
        
        let filterPrograms = programs.filter {
            (from == nil || ($0.stop as! Date) > from!) && (to == nil || ($0.start as! Date) < to!)
        }
        
        return filterPrograms
        
    }
    
    
    func getIcon(channel: String, completion:@escaping (Data?) -> Swift.Void )  {
        
        if let nsData = iconCache.object(forKey: channel as NSString) {
            completion(nsData as Data)
        }
        
        DispatchQueue.global().async {
            
            var data : Data? = nil
            for provider in self.epgProviders where provider.parseIcons {
                data = self.getProviderIcon(channel: channel, provider: provider.name)
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
    
    func getProviderIcon(channel: String, provider: String) -> Data? {
        
        guard let dbChannel : EpgChannel = CoreDataManager.requestFirstElement(NSPredicate(format: "name==%@ AND provider.name == %@",
                                                                                          channel.lowercased(),  provider) ),
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
                    let lastUpdate = dbProvider.lastUpdate as? Date,
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
            let data = try Data(contentsOf: url!)
    
            //parse xml
            var xml = data
            
            
            if data.isGzipped {
                xml = try data.gunzipped()
            }
            
            let channels = try self._parseXml(xml)
            
            self._saveProgramsToDB(provider, channels)
            
            
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
                    print("channel have not required fields: id \(id) or name \(name)")
                    continue
                }
                
                var channel = ParserChannel(name!)
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
                    print("programme have not required fields: id \(id) or start \(start) or stop \(stop) or title \(title)")
                    continue
                }
                
                var channel = channels[id!]
                if(channel == nil) {
                    print("channel id  \(id) not exist for programme")
                    continue
                }
                
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMddHHmmss Z"
                let startDate = formatter.date(from: start!)
                let stopDate = formatter.date(from: stop!)
                if(startDate == nil || stopDate == nil) {
                    print("cann't parse data \(start) or \(stop)")
                    continue
                }
                
                var program = ParserProgram(title:title!, start:startDate!, stop:stopDate!)
                
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
    
    
    func _saveProgramsToDB(_ provider:EpgProviderInfo, _ channels:  [String: ParserChannelWithProgram]) {
        
        let moc = CoreDataManager.context()
        let dbcontext = CoreDataManager.concurrentContext()
        
        
        //dbcontext.perform {
            
            var dbProvider : EpgProvider?  = CoreDataManager.requestFirstElement(NSPredicate(format:"name==%@", provider.name), context:dbcontext)
            if dbProvider == nil {
                dbProvider = EpgProvider(context:dbcontext)
                dbProvider!.name = provider.name
            }
            
            //soft change programs (change by channel)
            for (id, channelProg) in channels {
                
                
                //sort programs by start time
                var programs = channelProg.programs.sorted(by: { $0.start.timeIntervalSince1970 < $1.start.timeIntervalSince1970 })

                
                var dbChannel : EpgChannel? = CoreDataManager.requestFirstElement(NSPredicate(format: "name==%@ AND provider.name == %@", channelProg.channel.name,  provider.name), context:dbcontext)
                
                if dbChannel == nil {
                    dbChannel = EpgChannel(context:dbcontext)
                    dbChannel!.id = id
                    dbChannel!.name = channelProg.channel.name
                    dbChannel!.icon = channelProg.channel.icon
                    dbChannel!.provider = dbProvider
                }
                else {
                    
                    if programs.count > 0 {
                        //delete programs, exist in new programs list                        
                        let fetchRequest: NSFetchRequest<EpgProgram> = EpgProgram.fetchRequest()
                        fetchRequest.predicate = NSPredicate(
                            format: "channel.name==%@ AND channel.provider.name == %@ AND start >= %@",
                            channelProg.channel.name,  provider.name, programs[0].start as NSDate)
                        
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
                    dbprogram.start = program.start as NSDate?
                    dbprogram.stop = program.stop as NSDate?
                    dbprogram.channel = dbChannel!
                    
                }
                //print("save \(channelProg.programs.count) programs for '\(channelProg.programs)' channel")
            }
        
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
            if let result = try? dbcontext.fetch(fetchRequestDate) {
                minDate = result[0].start as Date?
            }
            fetchRequestDate.sortDescriptors = [NSSortDescriptor(key: "stop", ascending: false)]
            if let result = try? dbcontext.fetch(fetchRequestDate) {
                maxDate = result[0].stop as Date?
            }
        
            dbProvider!.startDate = minDate as NSDate?
            dbProvider!.finishDate = maxDate as NSDate?
            dbProvider!.channelCount = Int64(channels.count)
            dbProvider!.lastUpdate = Date() as NSDate?
            
            CoreDataManager.saveConcurrentContext(dbcontext)
        
        //}

    }

}
