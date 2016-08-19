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
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var cameraButton: UIButton!
    
    var cancelButton: UIButton!
    var sendButton: UIButton!
    var refreshControl: UIRefreshControl!
    
    var firebase: FIRDatabaseReference!
    
    var uid: String!
    
    var requestActive = false
    
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
                print("didFinishCapturingImage")
                print(image)
                if camera.currentDevice == camera.captureDeviceFront {
                    let flippedimage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .LeftMirrored)
                    self.showImagePreview(flippedimage)
                } else {
                    self.showImagePreview(image)
                }
                self.dismissViewControllerAnimated(false, completion: nil)
            }
            self.presentViewController(camera, animated: true, completion: nil)
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
        sendButton.setImage(UIImage(named:"send_btn"), forState: .Normal)
        sendButton.sizeToFit()
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
        
        progressBar.hidden = false
        
        firebase = FIRDatabase.database().reference()
        let key = firebase.child("users").child(uid).child("images").childByAutoId().key
        
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        let imagesRef = storageRef.child("images")
        let childRef = imagesRef.child(key)
        var imgData: NSData!
        imgData = UIImagePNGRepresentation(imageView.image!)
        
        let uploadTask = childRef.putData(imgData, metadata: nil) { metadata, error in
            if (error != nil) {
                print(error.debugDescription)
                //show error
            } else {
                let timeSince1970 = NSDate().timeIntervalSince1970
                self.firebase.child("users").child(self.uid).child("images").child(key).setValue(timeSince1970)
                
                let delay = 1.0 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue()){
                    self.progressBar.hidden = true
                    self.progressBar.setProgress(0, animated: false)
                    self.requestLabel.text = "Pic sent!"
                }
            }
        }
        
        uploadTask.observeStatus(.Progress) { snapshot in
            if let progress = snapshot.progress {
                self.requestLabel.text = "Sending..."
                let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                self.progressBar.setProgress(Float(percentComplete), animated: true)
            }
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
            print("didFinishCapturingImage")
            print(image)
            if camera.currentDevice == camera.captureDeviceFront {
                let flippedimage = UIImage(CGImage: image.CGImage!, scale: 1.0, orientation: .LeftMirrored)
                self.showImagePreview(flippedimage)
            } else {
                self.showImagePreview(image)
            }
            self.dismissViewControllerAnimated(false, completion: nil)
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

public class DKCameraResource {
    
    public class func imageForResource(name: String) -> UIImage {
        let bundle = NSBundle.cameraBundle()
        let imagePath = bundle.pathForResource(name, ofType: "png", inDirectory: "Images")
        let image = UIImage(contentsOfFile: imagePath!)
        return image!
    }
    
    class func cameraCancelImage() -> UIImage {
        return imageForResource("camera_cancel")
    }
    
    class func cameraFlashOnImage() -> UIImage {
        return imageForResource("camera_flash_on")
    }
    
    class func cameraFlashAutoImage() -> UIImage {
        return imageForResource("camera_flash_auto")
    }
    
    class func cameraFlashOffImage() -> UIImage {
        return imageForResource("camera_flash_off")
    }
    
    class func cameraSwitchImage() -> UIImage {
        return imageForResource("camera_switch")
    }
    
}
