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