//
//  RequestVC.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-10-21.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import UIKit
import Messages
import FirebaseAuth

class RequestVC: UIViewController {

    @IBOutlet weak var requestButton: UIButton!
    
    var conversation: MSConversation!
    
    var uid: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let uid = FIRAuth.auth()?.currentUser?.uid {
            self.uid = uid
        }
    }

    @IBAction func onRequestButtonPressed(sender: AnyObject) {
        if let uid = uid {
            if let image = createImageForMessage(), let conversation = conversation {
                let layout = MSMessageTemplateLayout()
                layout.image = image
                layout.caption = "Pic Requested!"
            
                let message = MSMessage()
                message.layout = layout
                message.URL = NSURLComponents(string: uid)?.URL
            
                self.sendRequest()
                conversation.insertMessage(message, completionHandler: {error in
                    if error != nil {
                        print(error)
                    }
                })
            }
        }
    }
    
    private func sendRequest(){
        var currentUid: String
        var otherUserUid: String
            
        if self.uid == EXTENSION_GORDON {
            currentUid = MAIN_GORDON
            otherUserUid = MAIN_ALIYA
        } else {
            currentUid = MAIN_ALIYA
            otherUserUid = MAIN_GORDON
        }
            
        let pictureRequest = PictureRequest(requesterUid: currentUid)
        pictureRequest.sendRequest()
        updateUsersNotifications(otherUserUid, type: "requests")
    }
    
    private func createImageForMessage() -> UIImage? {
        let background = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        background.backgroundColor = UIColor.blackColor()
        
        let picPleaseLogo = UIImage(named: "picpleaselogo")
        let imageView = UIImageView(frame: CGRect(x: 50, y: 50, width: 200, height: 200))
        imageView.image = picPleaseLogo
        
        background.addSubview(imageView)
        background.frame.origin = CGPoint(x: view.frame.size.width, y: view.frame.size.height)
        view.addSubview(background)
        
        UIGraphicsBeginImageContextWithOptions(background.frame.size, false, UIScreen.mainScreen().scale)
        background.drawViewHierarchyInRect(background.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        background.removeFromSuperview()
        
        return image
    }
}

