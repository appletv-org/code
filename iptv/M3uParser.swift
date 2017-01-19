//
//  M3uParser.swift
//  iptv
//
//  Created by Александр Колганов on 19.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import Foundation
import AVFoundation

struct M3uItem {
    var name  : String?
    var url   : String?
    var group : String?
    
    init() {
        
    }
    
    init(name : String, url : String, group : String) {
        self.name = name
        self.url = url
        self.group = group
    }
}

enum M3uError : Error {
    case urlError(String)
    case loadingError(String)
    case codingError(String)
}

func parseM3u(urlString: String) throws -> [M3uItem] {
    guard let url = URL(string:urlString) else {
        throw M3uError.urlError("Incorrect url:\(urlString)")
    }
    return try parseM3u(url:url)
}

func parseM3u(url: URL) throws -> [M3uItem] {
    var content : String? = nil
    
    let data = try Data(contentsOf: url)

    for code in [String.Encoding.utf8, String.Encoding.windowsCP1252] {
        content = String(data:data, encoding: code)
        if(content != nil) {
            break
        }

    }
    
    if(content == nil) {
        throw M3uError.loadingError("incorrect code of file")
    }
    return parseM3u(content: content!)
    
}

func parseM3u(content: String) -> [M3uItem] {
    let lines = content.components(separatedBy: .newlines)
    
    var item : M3uItem? = nil
    var items : [M3uItem] = []
    for line in lines {
        let str = line.trimmingCharacters(in: .whitespaces)
        if str.hasPrefix("#EXTINF:") {
            let props = str.components(separatedBy: ",")
            let name = props.last
            if props.count > 1 && props.last!.characters.count > 0 {
                //save previous item
                if item != nil && item!.name != nil && item!.url != nil {
                    items.append(item!)
                }
                item = M3uItem()
                item!.name = name
            }
        }
        else if str.hasPrefix("http") || str.hasPrefix("udp") {
            if item != nil {
                item!.url = str
            }
        }
        else if str.hasPrefix("#EXTGRP:") {
            guard  item != nil, let group = str.components(separatedBy: ":").last else {
                continue
            }
            item!.group = group
        }
    }
    if item != nil && item!.name != nil && item!.url != nil {
        items.append(item!)
    }
    
    return items
    
}
    

