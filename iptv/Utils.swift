//
//  Utils.swift
//  iptv
//
//  Created by Александр Колганов on 20.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import Foundation

//--- error -----
enum SimpleError : Error {
    case message(String)
}

func Err(_ mess:String) -> Error {
    return SimpleError.message(mess)
}

func errMsg(_ err:Error) -> String {
    var mess = err.localizedDescription
    
    if let simpleErr = err as? SimpleError {
        switch(simpleErr) {
        case SimpleError.message(let str):
            mess = str
        }
    }
    return mess
}




//--- directory ------
func + <K,V>(left: Dictionary<K,V>, right: Dictionary<K,V>)
    -> Dictionary<K,V>
{
    var map = Dictionary<K,V>()
    for (k, v) in left {
        map[k] = v
    }
    for (k, v) in right {
        map[k] = v
    }
    return map
}

func += <K, V> ( left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}


//Date to string and vice versa
extension Date {
    func toFormatString(_ format:String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return  formatter.string(from: self)
    }
}

extension String {
    func toFormatDate(_ format:String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self)
    }
}


