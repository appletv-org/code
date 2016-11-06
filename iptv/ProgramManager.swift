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
    
    var name : String = ""
    var url:   String = ""
    var updateTime: Int = 0 //((24*day + hours)*60 + minuts)*60 + seconds, where  day:0-everyday, 1-monday,...,7-sunday
    var shiftTime: Int = 0//hours*60 + minuts)*60 + seconds
    
    override init() {
        super.init()
    }
    
    init(name: String, url:String, update:Int, shift:Int) {
        self.name = name
        self.url = url
        self.updateTime = update
        self.shiftTime = shift
    }
    
    
    // MARK: NSCoding
    
    required convenience init?(coder decoder: NSCoder) {
        guard let name = decoder.decodeObject(forKey: "name") as? String,
              let url = decoder.decodeObject(forKey: "url") as? String
        else { return nil }
        
        let update = decoder.decodeInteger(forKey: "update")
        let shift = decoder.decodeInteger(forKey: "shift")
        
        self.init(
            name: name,
            url: url,
            update: update,
            shift: shift
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name")
        coder.encode(self.url, forKey: "url")
        coder.encode(self.updateTime, forKey: "update")
        coder.encode(self.shiftTime, forKey: "shift")
    }
}


class ProgramManager {
    
    static let userDefaultKey = "epgProviders"
    
    static let instance = ProgramManager()
    private init() {}

    
    //var channels : [String: [Programm]] = [:]
    
    lazy var epgProviders : [EpgProviderInfo] = {
        
        var ret = [EpgProviderInfo]()
        if let data = UserDefaults.standard.object(forKey: ProgramManager.userDefaultKey) as? NSData {
            ret = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! [EpgProviderInfo]
        }
        
        return ret

    }()
    
    func save() {
        let data = NSKeyedArchiver.archivedData(withRootObject: epgProviders)
        UserDefaults.standard.set(data, forKey: ProgramManager.userDefaultKey)
    }

    func getProvider(_ name: String) -> EpgProviderInfo? {
        let provider = epgProviders.first(where: {$0.name == name})
        return provider
    }
    
    func updateProvider(_ provider:EpgProviderInfo) {
        //get file by link
        let url = URL(string: provider.url)
        
        let task = URLSession.shared.dataTask(with: url! as URL) { data, response, error in
            
            guard let data = data, error == nil
                else { return }
            
            
            //print(NSString(data: data, encoding: String.Encoding.utf8.rawValue))
            do {
                
                //parse xml
                var xml = data
                
                
                if data.isGzipped {
                    xml = try data.gunzipped()
                }
                
                
                let channels = try self._parseXml(xml)
                
                try self._saveProgramsToDB(provider, channels)
                
                try self._updateIcons(provider, channels)
                
            }
            catch {
                print("\(error)")
            }
        }
        
        task.resume()
        
        
        
        
    }
    
    func _parseXml(_ data:Data) throws -> [String: ParserChannelWithProgram] {
        
        let xmlDoc = try AEXMLDocument(xml: data)
        
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
        return channels
        
    }
    
    
    func _saveProgramsToDB(_ provider:EpgProviderInfo, _ channels:  [String: ParserChannelWithProgram]) {
        
        let moc = CoreDataManager.context()
        
        let dbcontext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        dbcontext.parent = moc
        
        dbcontext.perform {
        
            var dbProvider: EpgProvider? = nil
            
            let fetchRequest: NSFetchRequest<EpgProvider> = EpgProvider.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name=%@", provider.name)
            if let result = try? dbcontext.fetch(fetchRequest) {
                if result.count == 1 {
                   dbProvider = result[0]
                }
            }
            
            if dbProvider == nil {
                dbProvider = EpgProvider(context:dbcontext)
                dbProvider!.name = provider.name
                dbProvider!.url = provider.url
                dbProvider!.frequencyUpdate = Int64(provider.updateTime)
            }
            
            //soft change programs (change by channel)
            for (id, channelProg) in channels {
                //remove program for Provider
                if dbProvider != nil {
                    let fetchRequest: NSFetchRequest<EpgChannel> = EpgChannel.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "name==%@ AND provider.name == %@",
                                                         channelProg.channel.name,  provider.name)
                    if let result = try? dbcontext.fetch(fetchRequest) {
                        for dbchannel in result {
                            dbcontext.delete(dbchannel) //delete dbChannel and all program
                        }
                    }
                }
                
                let dbchannel = EpgChannel(context:dbcontext)
                dbchannel.id = id
                dbchannel.name = channelProg.channel.name
                dbchannel.icon = channelProg.channel.icon
                dbchannel.provider = dbProvider
                for program in channelProg.programs {
                    let dbprogram = EpgProgram(context:dbcontext)
                    dbprogram.title = program.title
                    dbprogram.desc = program.desc
                    dbprogram.start = program.start as NSDate?
                    dbprogram.stop = program.stop as NSDate?
                    dbprogram.channel = dbchannel
                }
                //print("save \(channelProg.programs.count) programs for '\(channelProg.programs)' channel")
            }
            
            do {
                try dbcontext.save()
                moc.performAndWait {
                    do {
                        try moc.save()
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
                }
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
        
    }
    
    func _updateIcons(_ provider:EpgProviderInfo, _ channels:  [String: ParserChannelWithProgram])  throws {
        //TODO: need realized
        print(" ProgramManager._updateIcons not realized")
    }
    
    func getPrograms(forChannel name: String)  -> [EpgProgram] {
        
        let dbcontext = CoreDataManager.context()
        
        for provider in epgProviders {
            let fetchRequest: NSFetchRequest<EpgChannel> = EpgChannel.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name==%@ AND provider.name == %@",
                                                 name.lowercased(),  provider.name)
            if let result = try? dbcontext.fetch(fetchRequest) {
                if result.count == 1 {
                    if let programs = result[0].programs?.allObjects as? [EpgProgram] {
                        return programs
                    }
                    
                }
            }
        }

        return []
    }
    
}
