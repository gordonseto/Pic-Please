//
//  PictureRequest.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-08-18.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import Foundation
import FirebaseDatabase

class PictureRequest {
    
    private var _requesterUid: String!
    private var _time: NSTimeInterval!
    
    var firebase: FIRDatabaseReference!
    
    var requesterUid: String! {
        return _requesterUid
    }
    
    var time: NSTimeInterval! {
        return _time
    }
    
    init(requesterUid: String){
        _requesterUid = requesterUid
        _time = NSDate().timeIntervalSince1970
    }
    
    func sendRequest(){
        firebase = FIRDatabase.database().reference()
        firebase.child("requests").child(_requesterUid).setValue(time)
    }
}

func sendNotification(toUserUid: String, hasSound: Bool, groupId: String, message: String, deeplink: String){
    if let pushClient = BatchClientPush(apiKey: BATCH_API_KEY, restKey: BATCH_REST_KEY) {
        
        pushClient.sandbox = false
        if hasSound {
            pushClient.customPayload = ["aps": ["badge": 1, "content-available": 1]]
        } else {
            pushClient.customPayload = ["aps": ["badge": 1, "sound": NSNull(), "content-available": 1]]
        }
        pushClient.groupId = groupId
        pushClient.message.title = "Pic Please"
        pushClient.message.body = message
        pushClient.recipients.customIds = [toUserUid]
        pushClient.deeplink = deeplink
            
        pushClient.send { (response, error) in
            if let error = error {
                print("Something happened while sending the push: \(response) \(error.localizedDescription)")
            } else {
                print("Push sent \(response)")
            }
        }
        
    } else {
        print("Error while initializing BatchClientPush")
    }
}