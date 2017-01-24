//
//  HttpServer.swift
//  iptv
//
//  Created by Alexandr Kolganov on 17.01.17.
//  Copyright © 2017 Home. All rights reserved.
//

import Foundation


class HttpServer: GCDWebServer {
    
    static let operationFail = "Operation failed"
    static let operationSuccess = "Operation completed succesfully"
    
    
    override init() {
        super.init()
        
        let webPath = Bundle.main.bundlePath + "/WebContent"
        self.addGETHandler(forBasePath: "/", directoryPath: webPath, indexFilename: nil, cacheAge: 0, allowRangeRequests: true)
        
        
        self.addHandler(forMethod: "GET", path: "/", request: GCDWebServerRequest.self, processBlock: { (request) -> GCDWebServerResponse? in
            return GCDWebServerResponse(redirect: URL(string:"/index.html")!, permanent: false)
        })


        self.addHandler(forMethod: "POST", path: "/add_channel", request: GCDWebServerURLEncodedFormRequest.self, processBlock: { (request) -> GCDWebServerResponse? in
            var ret = HttpServer.operationSuccess
            if  let formRequest = request as? GCDWebServerURLEncodedFormRequest,
                let name = formRequest.arguments["name"] as? String,
                let url = formRequest.arguments["url"] as? String,
                let isPublic = formRequest.arguments["public"] as? String
            {
                let err = ChannelManager.addChannel([], name: name, url: url, isPublic: isPublic == "on")
                if err != nil {
                    ret = "\(HttpServer.operationFail): " + errMsg(err!)
                }
                
            }
            return GCDWebServerDataResponse(html:"<html><body><p>\(ret)</p></body></html>")
        })
        
        self.addHandler(forMethod: "POST", path: "/add_remote_group", request: GCDWebServerURLEncodedFormRequest.self, processBlock: { (request) -> GCDWebServerResponse? in
            var ret = HttpServer.operationSuccess
            if  let formRequest = request as? GCDWebServerURLEncodedFormRequest,
                let name = formRequest.arguments["name"] as? String,
                let url = formRequest.arguments["url"] as? String,
                let isPublic = formRequest.arguments["public"] as? String
            {
                let err = ChannelManager.addRemoteGroup([], name: name, url: url, isPublic: isPublic == "on")
                if err != nil {
                    ret = "\(HttpServer.operationFail): " + errMsg(err!)
                }
                
            }
            return GCDWebServerDataResponse(html:"<html><body><p>\(ret)</p></body></html>")
        })
        
        self.addHandler(forMethod: "POST", path: "/upload_m3u", request: GCDWebServerMultiPartFormRequest.self, processBlock: { (request) -> GCDWebServerResponse? in
            return self.uploadFile(request)
        })
        
        self.addHandler(forMethod: "POST", path: "/add_epg", request: GCDWebServerURLEncodedFormRequest.self, processBlock: { (request) -> GCDWebServerResponse? in
            var ret = HttpServer.operationSuccess
            if  let formRequest = request as? GCDWebServerURLEncodedFormRequest,
                let name = formRequest.arguments["name"] as? String,
                let url = formRequest.arguments["url"] as? String
            {
                let epgInfo = EpgProviderInfo(name: name, url: url)
                let err = ProgramManager.instance.addProvider(epgInfo)
                if err != nil {
                    ret = "\(HttpServer.operationFail): " + errMsg(err!)
                }
                
            }
            return GCDWebServerDataResponse(html:"<html><body><p>\(ret)</p></body></html>")
        })


        
        self.addHandler(forMethod: "POST", path: "/add_m3u_text", request: GCDWebServerURLEncodedFormRequest.self, processBlock: { (request) -> GCDWebServerResponse? in

            if  let formRequest = request as? GCDWebServerURLEncodedFormRequest,
                let name = formRequest.arguments["name"] as? String,
                let content = formRequest.arguments["context"] as? String
            {
                
                let group = GroupInfo(name: name)
                ChannelManager.addM3uList(content:content, toGroup:group)
                ChannelManager.root.groups.append(group)
                return GCDWebServerDataResponse(html:"<html><body><p>\(HttpServer.operationSuccess)</p></body></html>")
            }
            
            return GCDWebServerDataResponse(html:"<html><body><p>\(HttpServer.operationFail)</p></body></html>")
        })


        
    }

    static func instance() -> HttpServer {
        return (UIApplication.shared.delegate as! AppDelegate).webServer!
    }

        
    func uploadFile(_ multiPartRequest:GCDWebServerRequest?) -> GCDWebServerResponse? {
        
        print ("temp dir:\(NSTemporaryDirectory())")
        
        if  let request = multiPartRequest as? GCDWebServerMultiPartFormRequest,
            let file = request.firstFile(forControlName: "file"),
            let name = request.firstArgument(forControlName: "name")?.string
        {
            let url = URL(fileURLWithPath:file.temporaryPath)
            let group = GroupInfo(name: name)
            
            do {
                try ChannelManager.addM3uList(url:url, toGroup:group)
                ChannelManager.root.groups.append(group)
            }
            catch {
                return GCDWebServerDataResponse(html:"<html><body><p>Failure operation: \(errMsg(error))</p></body></html>")
            }
            return GCDWebServerDataResponse(html:"<html><body><p>Success operation</p></body></html>")
        }
        
        return GCDWebServerDataResponse(html:"<html><body><p>Failure operation</p></body></html>")

    }
        
    

        
    
    
}
