//
//  ViewController.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-08-18.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    
    @IBOutlet weak var picRequestedLabel: UILabel!
    
    let MIN_TIME_BETWEEN_NOTIFICATIONS: Double = 60 * 2
    
    var uid: String!
    var otherUserUid: String!
    
    var lastRequest: NSTimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let tbc = self.tabBarController
        tbc?.tabBar.barStyle = UIBarStyle.Black
        tbc?.tabBar.selectedImageTintColor = UIColor.whiteColor()
        
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            self.uid = uid
        }
    }


    @IBAction func onRequestButtonPressed(sender: AnyObject) {
        if let uid = uid {
            animatePicRequestedLabel()
            let picrequest = PictureRequest(requesterUid: uid)
            picrequest.sendRequest()
            sendRequestNotification()
        }
    }
    
    func sendRequestNotification(){
        if NSDate().timeIntervalSince1970 -  lastRequest > MIN_TIME_BETWEEN_NOTIFICATIONS {
            lastRequest = NSDate().timeIntervalSince1970
            var message: String = ""
            if uid == "U9LsPZ6PYjOl81cuyQyQqD552FH3" {
                message = "Gordon has requested a picture!"
            } else {
                message = "Aliya has requested a picture!"
            }
            if otherUserUid == nil {
                findOtherUser(){(otherUserUid) in
                    if let otherUserUid = otherUserUid {
                        self.otherUserUid = otherUserUid
                        sendNotification(otherUserUid, hasSound: true, groupId: "requests", message: message, deeplink: "pic-please://requests/\(self.uid)")
                    }
                }
            } else {
                sendNotification(otherUserUid, hasSound: true, groupId: "requests", message: message, deeplink: "pic-please://requests/\(self.uid)")
            }
        }
    }
    
    func animatePicRequestedLabel(){
        picRequestedLabel.alpha = 0.0
        picRequestedLabel.center.y += 40
        UIView.animateWithDuration(0.5, delay: 0.0, options: [UIViewAnimationOptions.CurveLinear], animations: {
            self.picRequestedLabel.alpha = 1.0
            self.picRequestedLabel.center.y -= 20
            }, completion: {completion in
                UIView.animateWithDuration(0.5, delay: 0.0, options: [UIViewAnimationOptions.CurveLinear], animations: {
                        self.picRequestedLabel.alpha = 0.0
                        self.picRequestedLabel.center.y -= 20
                    }, completion: {completion in })
        })
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
}

