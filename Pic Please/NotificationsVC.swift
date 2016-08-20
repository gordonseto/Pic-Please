//
//  NotificationsVC.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-08-18.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import UIKit
import DKCamera
import FirebaseStorage
import FirebaseDatabase
import FirebaseAuth

class NotificationsVC: UIViewController {

    @IBOutlet weak var requestLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIButton!
    
    var cancelButton: UIButton!
    var sendButton: UIButton!
    var refreshControl: UIRefreshControl!
    
    var firebase: FIRDatabaseReference!
    
    var uid: String!
    var otherUserUid: String!
    
    var requestActive = false
    var capturedImage: UIImage!
    var isFront: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.scrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.delaysContentTouches = false
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents:  UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        scrollView.addSubview(refreshControl)
        
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            self.uid = uid
            requestLabel.textColor = UIColor.darkGrayColor()
            cameraButton.setImage(UIImage(named:"bigcameradark"), forState: .Normal)
            requestLabel.text = "Checking for requests..."
            checkForRequests()
        }
    }
    
    func checkForRequests(){
        if let uid = uid {
            firebase = FIRDatabase.database().reference()
            firebase.child("requests").observeSingleEventOfType(.Value, withBlock: {(snapshot) in
                print(snapshot)
                self.requestActive = false
                for child in snapshot.children {
                    if child.key != uid {
                        self.requestActive = true
                    }
                }
                self.updateRequestLabel()
            }) { (error) in
                print(error.debugDescription)
            }
        }
    }
    
    func updateRequestLabel(){
        if requestActive {
            requestLabel.textColor = UIColor.whiteColor()
            cameraButton.setImage(UIImage(named:"bigcamera"), forState: .Normal)
            if uid == "U9LsPZ6PYjOl81cuyQyQqD552FH3" {
                requestLabel.text = "Aliya has requested a picture!"
            } else {
                requestLabel.text = "Gordon has requested a picture!"
            }
        } else {
            cameraButton.setImage(UIImage(named:"bigcameradark"), forState: .Normal)
            requestLabel.textColor = UIColor.darkGrayColor()
            requestLabel.text = "No recent requests!"
        }
    }

    @IBAction func onCameraPressed(sender: AnyObject) {
        if let _ = uid {
            let camera = DKCamera()
        
            camera.didCancel = { () in
                print("didCancel")
            
                self.dismissViewControllerAnimated(true){
                    self.tabBarController?.tabBar.hidden = false
                }
            }
        
            camera.didFinishCapturingImage = {(image: UIImage) in
                self.imageCaptured(camera, image: image)
            }
            self.presentViewController(camera, animated: true, completion: nil)
        }
    }
    
    func imageCaptured(camera: DKCamera, image: UIImage){
        print("didFinishCapturingImage")
        print(image)
        self.capturedImage = image
        if let _ = self.capturedImage {
            if camera.currentDevice == camera.captureDeviceFront {
                isFront = true
                let flippedimage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .LeftMirrored)
                self.showImagePreview(flippedimage)
            } else {
                isFront = false
                self.showImagePreview(image)
            }
            self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    func showImagePreview(image: UIImage){
        imageView.image = image
        imageView.hidden = false
        imageView.userInteractionEnabled = true
        self.tabBarController?.tabBar.hidden = true
        
        // cancel button
        cancelButton = UIButton()
        cancelButton.addTarget(self, action: #selector(cancelImagePreview), forControlEvents: .TouchUpInside)
        cancelButton.setImage(UIImage(named:"re_snap_btn"), forState: .Normal)
        cancelButton.frame.size = CGSizeMake(50, 50)
        //cancelButton.sizeToFit()
        cancelButton.frame.origin = CGPoint(x: 0, y: 15)
        cancelButton.autoresizingMask = [.FlexibleBottomMargin, .FlexibleLeftMargin]
        imageView.addSubview(cancelButton)
        
        sendButton = UIButton()
        sendButton.addTarget(self, action: #selector(sendImage), forControlEvents: .TouchUpInside)
        sendButton.setImage(UIImage(named:"sendbutton"), forState: .Normal)
        sendButton.frame.size = CGSizeMake(60, 60)
        sendButton.frame.origin = CGPoint(x: imageView.bounds.width - sendButton.bounds.width - 15, y: imageView.bounds.height - sendButton.bounds.height - 15)
        sendButton.autoresizingMask = [.FlexibleBottomMargin, .FlexibleLeftMargin]
        imageView.addSubview(sendButton)
        
    }
    
    func sendImage(){
        cancelButton.removeFromSuperview()
        sendButton.removeFromSuperview()
        imageView.hidden = true
        imageView.userInteractionEnabled = false
        self.tabBarController?.tabBar.hidden = false
        
        firebase = FIRDatabase.database().reference()
        let key = firebase.child("users").child(uid).child("images").childByAutoId().key
        
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        let imagesRef = storageRef.child("images")
        let childRef = imagesRef.child(key)
        var imgData: NSData!
    
        if isFront {
            imgData = UIImageJPEGRepresentation(UIImage(CGImage: capturedImage.CGImage!, scale: 1.0, orientation: .LeftMirrored), 1.0)
        } else {
            imgData = UIImageJPEGRepresentation(capturedImage, 1.0)
        }
        
        let uploadTask = childRef.putData(imgData, metadata: nil) { metadata, error in
            if (error != nil) {
                print(error.debugDescription)
                //show error
            } else {
                let timeSince1970 = NSDate().timeIntervalSince1970
                self.firebase.child("users").child(self.uid).child("images").child(key).setValue(timeSince1970)
                
                self.requestLabel.text = "Pic sent!"
                self.sendPictureNotification()
                self.removePictureRequest()
                removeFromNotifications(self.uid, type: "requests"){
                    updateTabBarBadges(self.tabBarController!)
                }
            }
        }
        
        uploadTask.observeStatus(.Progress) { snapshot in
            if let progress = snapshot.progress {
                self.requestLabel.text = "Sending..."
                let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                print(progress)
            }
        }
 
    }
    
    func removePictureRequest(){
        if otherUserUid == nil {
            findOtherUser(){(otherUserUid) in
                if let otherUserUid = otherUserUid {
                    self.otherUserUid = otherUserUid
                    self.firebase = FIRDatabase.database().reference()
                    self.firebase.child("requests").child(otherUserUid).setValue(nil)
                }
            }
        } else {
            firebase = FIRDatabase.database().reference()
            firebase.child("requests").child(otherUserUid).setValue(nil)
        }
    }
    
    func sendPictureNotification(){
        var message: String = ""
        if uid == "U9LsPZ6PYjOl81cuyQyQqD552FH3" {
            message = "Gordon has sent you a picture"
        } else {
            message = "Aliya has sent you a picture"
        }
        if otherUserUid == nil {
            findOtherUser(){(otherUserUid) in
                if let otherUserUid = otherUserUid {
                    self.otherUserUid = otherUserUid
                    updateUsersNotifications(otherUserUid, type: "pictures")
                    sendNotification(otherUserUid, hasSound: true, groupId: "pictures", message: message, deeplink: "pic-please://pictures/\(self.uid)")
                }
            }
        } else {
            updateUsersNotifications(otherUserUid, type: "pictures")
            sendNotification(otherUserUid, hasSound: true, groupId: "pictures", message: message, deeplink: "pic-please://pictures/\(self.uid)")
        }
    }
    
    func cancelImagePreview(){
        let camera = DKCamera()
        
        camera.didCancel = { () in
            print("didCancel")
            
            self.dismissViewControllerAnimated(true){
                self.tabBarController?.tabBar.hidden = false
            }
        }
        
        camera.didFinishCapturingImage = {(image: UIImage) in
            self.imageCaptured(camera, image: image)
        }
        self.presentViewController(camera, animated: false){
            self.cancelButton.removeFromSuperview()
            self.sendButton.removeFromSuperview()
            self.imageView.hidden = true
            self.imageView.userInteractionEnabled = false
        }
    }
    
    func refreshView(sender: AnyObject){
        if let uid = uid {
            checkForRequests()
        }
        self.refreshControl.endRefreshing()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

func findOtherUser(completion:(String!)->()) {
    if let uid = FIRAuth.auth()?.currentUser!.uid {
        let firebase = FIRDatabase.database().reference()
        firebase.child("users").observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            var otherUserUid: String!
            for child in snapshot.children {
                if child.key != uid {
                    otherUserUid = child.key
                }
            }
            completion(otherUserUid)
        }) { (error) in
            print(error.debugDescription)
        }
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
                print(toUserUid)
                print("Push sent \(response)")
            }
        }
        
    } else {
        print("Error while initializing BatchClientPush")
    }
}

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

func updateTabBarBadges(tabBarController: UITabBarController){
    if let uid = FIRAuth.auth()?.currentUser?.uid {
        let firebase = FIRDatabase.database().reference()
        firebase.child("notifications").child(uid).observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            
            tabBarController.tabBar.items?[GALLERY_INDEX].badgeValue = nil
            tabBarController.tabBar.items?[NOTIFICATIONS_INDEX].badgeValue = nil
            for child in snapshot.children {
                if child.key == "pictures" {
                    tabBarController.tabBar.items?[GALLERY_INDEX].badgeValue = "1"
                }
                if child.key == "requests" {
                    tabBarController.tabBar.items?[NOTIFICATIONS_INDEX].badgeValue = "1"
                }
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
}
