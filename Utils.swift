//
//  Utils.swift
//  iptv
//
//  Created by Александр Колганов on 20.09.16.
//  Copyright © 2016 Home. All rights reserved.
//

import Foundation


enum CommonError : Error {
    case Message(String)
}

func Err(_ mess:String) -> Error {
    return CommonError.Message(mess)
}



