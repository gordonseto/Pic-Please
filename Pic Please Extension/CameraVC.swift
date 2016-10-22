//
//  CameraVC.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-10-21.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import UIKit
import DKCamera
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Messages

protocol MessageVCDelegate {
    func finishedCreatingMessage()
}

class CameraVC: UIViewController {

    var imageView: UIImageView!
    var cancelButton: UIButton!
    var sendButton: UIButton!
    
    var capturedImage: UIImage!
    
    var isFront: Bool = false
    
    var firebase: FIRDatabaseReference!
    
    var uid: String!
    var otherUserUid: String!
    
    var conversation: MSConversation!
    
    var delegate: MessageVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let uid = FIRAuth.auth()?.currentUser?.uid {
            if uid == EXTENSION_GORDON {
                self.uid = MAIN_GORDON
                self.otherUserUid = MAIN_ALIYA
            } else {
                self.uid = MAIN_ALIYA
                self.otherUserUid = MAIN_GORDON
            }
            
            self.presentViewController(createDKCamera(), animated: false, completion: nil)
        }
    }
    
    func createDKCamera() -> DKCamera {
        let camera = DKCamera()
        camera.isMessageMode = true
        
        camera.didCancel = { () in
            print("didCancel")
            self.delegate?.finishedCreatingMessage()
        }
        
        camera.didFinishCapturingImage = {(image: UIImage) in
            self.imageCaptured(camera, image: image)
        }
        
        return camera
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
        imageView = UIImageView(frame: CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height))
        imageView.image = image
        imageView.hidden = false
        imageView.userInteractionEnabled = true
        self.view.addSubview(imageView)
        
        // cancel button
        cancelButton = UIButton()
        cancelButton.addTarget(self, action: #selector(cancelImagePreview), forControlEvents: .TouchUpInside)
        cancelButton.setImage(UIImage(named:"re_snap_btn"), forState: .Normal)
        cancelButton.frame.size = CGSizeMake(50, 50)
        //cancelButton.sizeToFit()
        cancelButton.frame.origin = CGPoint(x: 0, y: 15 + NAVIGATION_BAR_HEIGHT)
        cancelButton.autoresizingMask = [.FlexibleBottomMargin, .FlexibleLeftMargin]
        imageView.addSubview(cancelButton)
        
        sendButton = UIButton()
        sendButton.addTarget(self, action: #selector(sendImage), forControlEvents: .TouchUpInside)
        sendButton.setImage(UIImage(named:"sendbutton"), forState: .Normal)
        sendButton.frame.size = CGSizeMake(60, 60)
        sendButton.frame.origin = CGPoint(x: imageView.bounds.width - sendButton.bounds.width - 15, y: imageView.bounds.height - sendButton.bounds.height - 15 - MESSAGE_INPUT_HEIGHT)
        sendButton.autoresizingMask = [.FlexibleBottomMargin, .FlexibleLeftMargin]
        imageView.addSubview(sendButton)
        
    }
    
    func sendImage(){
//        cancelButton.removeFromSuperview()
//        sendButton.removeFromSuperview()
//        imageView.hidden = true
//        imageView.userInteractionEnabled = false
//        
//        firebase = FIRDatabase.database().reference()
//        let key = firebase.child("users").child(uid).child("images").childByAutoId().key
//        
//        let storage = FIRStorage.storage()
//        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
//        let imagesRef = storageRef.child("images")
//        let childRef = imagesRef.child(key)
//        var imgData: NSData!
//        
//        if isFront {
//            imgData = UIImageJPEGRepresentation(UIImage(CGImage: capturedImage.CGImage!, scale: 1.0, orientation: .LeftMirrored), 1.0)
//        } else {
//            imgData = UIImageJPEGRepresentation(capturedImage, 1.0)
//        }
//        
//        childRef.putData(imgData, metadata: nil) { metadata, error in
//            if (error != nil) {
//                print(error.debugDescription)
//                //show error
//            } else {
//                let timeSince1970 = NSDate().timeIntervalSince1970
//                self.firebase.child("users").child(self.uid).child("images").child(key).setValue(timeSince1970)
//                
//                self.sendPictureNotification()
//                self.removePictureRequest()
//                removeFromNotifications(self.uid, type: "requests"){}
//            }
//        }
        createMessage()
    }
    
    func createMessage(){
        print("hello")
        if let image = createImageForMessage(), let conversation = conversation {
            let layout = MSMessageTemplateLayout()
            layout.image = image
            
            let message = MSMessage()
            message.layout = layout
            message.URL = NSURLComponents(string: "\(self.uid) image")?.URL
            
            conversation.insertMessage(message, completionHandler: {error in
                if error != nil {
                    print(error)
                }
                print("yo")
                self.delegate?.finishedCreatingMessage()
            })
        }
    }
    
    func createImageForMessage() -> UIImage? {
        var image: UIImage
        if isFront {
            image = UIImage(CGImage: capturedImage.CGImage!, scale: 1.0, orientation: .RightMirrored)
        } else {
            image = capturedImage
        }
        return image
    }
    
    func removePictureRequest(){
        firebase = FIRDatabase.database().reference()
        firebase.child("requests").child(otherUserUid).setValue(nil)
    }
    
    func sendPictureNotification(){
        updateUsersNotifications(otherUserUid, type: "pictures")
    }
    
    func cancelImagePreview(){
        
        self.presentViewController(createDKCamera(), animated: false){
            self.cancelButton.removeFromSuperview()
            self.sendButton.removeFromSuperview()
            self.imageView.hidden = true
            self.imageView.userInteractionEnabled = false
        }
    }

}
