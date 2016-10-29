//
//  Utils.swift
//  iptv
//
//  Created by Александр Колганов on 20.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import Foundation

//error
enum CommonError : Error {
    case Message(String)
}

func Err(_ mess:String) -> Error {
    return CommonError.Message(mess)
}


//
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
