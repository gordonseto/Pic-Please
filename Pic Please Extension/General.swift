//
//  General.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-10-21.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import Foundation
import FirebaseDatabase
import UIKit

let MESSAGE_INPUT_HEIGHT: CGFloat = 45
let NAVIGATION_BAR_HEIGHT: CGFloat = 70

func updateUsersNotifications(uid: String, type: String){
    let firebase = FIRDatabase.database().reference()
    let time = NSDate().timeIntervalSince1970
    firebase.child("notifications").child(uid).child(type).setValue(time)
}

func removeFromNotifications(uid: String, type: String, completion: ()->()){
    let firebase = FIRDatabase.database().reference()
    firebase.child("notifications").child(uid).child(type).setValue(nil) { (
        error, reference) in
        completion()
    }
}

