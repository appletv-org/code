
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




//--- Dictionary ------
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

//--- String
extension String
{
    var  isBlank:Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension String {
    func appendingPathComponent(_ string: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(string).path
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

//--- Date operators

extension Date {
    
    
    enum FixTimeInterval : Int {
        static let secondsInHour = 60*60
        
        case second = 1
        case minute = 60
        case hour = 3600
        case day = 86400
    }
    
    
}

func + (left: Date, right: TimeInterval)
    -> Date
{
    return left.addingTimeInterval(right)
}

func - (left: Date, right: TimeInterval)
    -> Date
{
    return left.addingTimeInterval(-right)
}

func += ( left: inout Date, right: TimeInterval) {
    left.addTimeInterval(right)
}

func -= ( left: inout Date, right: TimeInterval) {
    left.addTimeInterval(-right)
}

//--- Array



//Coping protocol and array realized
//Protocal that copyable class should conform
protocol Copying {
    init(copy: Self)
}

//Concrete class extension
extension Copying {
    func copy() -> Self {
        return Self.init(copy: self)
    }
}

//Array extension for elements conforms the Copying protocol
extension Array where Element: Copying {
    
    init(copy: Array<Element>) {
        self = Array<Element>();
        for element in copy {
            self.append(element.copy());
        }
    }
    
    func clone() -> Array {
        var copiedArray = Array<Element>()
        for element in self {
            copiedArray.append(element.copy())
        }
        return copiedArray
    }
}

func md5(_ inputString: String) -> String! {
    let str = inputString.cString(using: String.Encoding.utf8)
    let strLen = CC_LONG(inputString.lengthOfBytes(using: String.Encoding.utf8))
    let digestLen = Int(CC_MD5_DIGEST_LENGTH)
    let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
    
    CC_MD5(str!, strLen, result)
    
    let hash = NSMutableString()
    for i in 0..<digestLen {
        hash.appendFormat("%02x", result[i])
    }
    
    result.deallocate(capacity: digestLen)
    
    return String(format: hash as String)
}





