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
    
    var uid: String!
    
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
        }
    }
    
    func animatePicRequestedLabel(){
        picRequestedLabel.alpha = 0.0
        picRequestedLabel.center.y += 20
        UIView.animateWithDuration(1.0, delay: 0.0, options: [UIViewAnimationOptions.CurveEaseInOut], animations: {
            self.picRequestedLabel.alpha = 1.0
            self.picRequestedLabel.center.y -= 20
            }, completion: {completion in })
    }
    
}

