//
//  BatchClientPush.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-08-19.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import Foundation

// TODO: Document this
@objc
public class BatchClientPush: NSObject, NSURLSessionDelegate {
    private static let apiURLFormat = "https://api.batch.com/1.0/%@/transactional/send"
    private static let apiMaxRecipients = 10000
    private static let jsonContentType = "application/json"
    
    private let apiKey: String
    private let restKey: String
    
    private let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    
    // TODO: Document all this
    public private(set) var message = BatchClientPushMessage()
    public private(set) var recipients = BatchClientPushRecipients()
    public var sandbox = false
    public var customPayload: [String: AnyObject]? = nil
    public var groupId = "ios_push"
    public var deeplink: String? = nil
    
    init?(apiKey: String, restKey: String) {
        
        if apiKey.characters.count != 30 {
            return nil
        }
        
        if restKey.characters.count != 32 {
            return nil
        }
        
        self.apiKey = apiKey
        self.restKey = restKey
    }
    
    func send(completionHandler: (response: String?, error: NSError?) -> ()) {
        guard recipients.count > 0 else {
            completionHandler(response: nil, error: NSError(domain: "BatchClientPushErrorDomain",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Validation error: No recipients were specified"]))
            return
        }
        
        guard recipients.count <= BatchClientPush.apiMaxRecipients else {
            completionHandler(response: nil, error: NSError(domain: "BatchClientPushErrorDomain",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Validation error: Recipients count exceeds \(BatchClientPush.apiMaxRecipients)"]))
            return
        }
        
        var jsonPayload: NSData?
        
        if let customPayload = customPayload {
            do {
                jsonPayload = try NSJSONSerialization.dataWithJSONObject(customPayload, options: [])
            } catch let error as NSError {
                completionHandler(response: nil, error: NSError(domain: "BatchClientPushErrorDomain",
                    code: -3,
                    userInfo: [
                        NSUnderlyingErrorKey: error,
                        NSLocalizedDescriptionKey: "Validation error: An error occurred while serializing the custom payload to JSON. Make sure it's a dictionary only made of foundation objects compatible with NSJSONSerialization. (Additional info: \(error.localizedDescription)"
                    ]))
                return
            }
        }
        
        guard let request = buildRequest(jsonPayload) else {
            completionHandler(response: nil, error: NSError(domain: "BatchClientPushErrorDomain",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unknown error while building the HTTP request"]))
            return
        }
        
        let task = session.dataTaskWithRequest(request, completionHandler: {
            (data: NSData?, response: NSURLResponse?, error: NSError?) in
            
            var stringResponseData: String?
            if let data = data {
                stringResponseData = String(data: data, encoding: NSUTF8StringEncoding)
            }
            
            var userFacingError: NSError? = error
            
            if let response = response as? NSHTTPURLResponse
                where response.statusCode != 201 && error == nil {
                userFacingError = NSError(domain: "BatchClientPushErrorDomain",
                    code: -4,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Server error: Status code \(response.statusCode), please see the response string for more info."
                    ])
            }
            
            completionHandler(response: stringResponseData, error: userFacingError)
        })
        
        task.resume()
    }
    
    private func buildRequest(customPayload: NSData?) -> NSURLRequest? {
        guard let url = NSURL(string: String(format: BatchClientPush.apiURLFormat, apiKey)) else { return nil }
        
        guard let body = buildRequestBody(customPayload) else { return nil }
        
        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = body
        request.setValue(restKey, forHTTPHeaderField: "X-Authorization")
        request.setValue(BatchClientPush.jsonContentType, forHTTPHeaderField: "Accept")
        request.setValue(BatchClientPush.jsonContentType, forHTTPHeaderField: "Content-Type")
        
        return request
    }
    
    private func buildRequestBody(customPayload: NSData?) -> NSData? {
        var body: [String: AnyObject] = [:]
        body["group_id"] = groupId
        body["sandbox"] = sandbox
        body["recipients"] = [
            "custom_ids": recipients.customIds,
            "tokens": recipients.tokens,
            "install_ids": recipients.installIds
        ]
        
        body["message"] = message.dictionaryRepresentation()
        
        if let customPayload = customPayload {
            body["custom_payload"] = String(data: customPayload, encoding: NSUTF8StringEncoding)
        }
        
        if let deeplink = deeplink {
            body["deeplink"] = deeplink
        }
        
        do {
            return try NSJSONSerialization.dataWithJSONObject(body, options: [])
        } catch {
            return nil
        }
    }
    
}

@objc
public class BatchClientPushMessage: NSObject {
    var title: String?
    var body: String = ""
    
    public func dictionaryRepresentation() -> [String: AnyObject] {
        var res = ["body": body]
        if let title = title {
            res["title"] = title
        }
        
        return res
    }
    
}

@objc
public class BatchClientPushRecipients: NSObject {
    var customIds: [String] = []
    var installIds: [String] = []
    var tokens: [String] = []
    
    public var count: Int {
        get {
            return customIds.count + installIds.count + tokens.count
        }
    }
    
}