//
//  NotificationsVC.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-08-18.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import UIKit
import DKCamera

class NotificationsVC: UIViewController {

    @IBOutlet weak var requestLabel: UILabel!
    @IBOutlet weak var noRequestsLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    var cancelButton: UIButton!
    var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.scrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.delaysContentTouches = false
    }

    @IBAction func onCameraPressed(sender: AnyObject) {
        let camera = DKCamera()
        
        camera.didCancel = { () in
            print("didCancel")
            
            self.dismissViewControllerAnimated(true, completion: nil)
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
    
    func showImagePreview(image: UIImage){
        imageView.image = image
        imageView.hidden = false
        imageView.userInteractionEnabled = true
        self.tabBarController?.tabBar.hidden = true
        
        // cancel button
        cancelButton = UIButton()
        cancelButton.addTarget(self, action: #selector(cancelImagePreview), forControlEvents: .TouchUpInside)
        cancelButton.setImage(DKCameraResource.cameraCancelImage(), forState: .Normal)
        cancelButton.sizeToFit()
        cancelButton.frame.origin = CGPoint(x: 15, y: 25)
        cancelButton.autoresizingMask = [.FlexibleBottomMargin, .FlexibleLeftMargin]
        imageView.addSubview(cancelButton)
        
        sendButton = UIButton()
        sendButton.addTarget(self, action: #selector(sendImage), forControlEvents: .TouchUpInside)
        sendButton.setImage(UIImage(named:"camera"), forState: .Normal)
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
    }
    
    func cancelImagePreview(){
        let camera = DKCamera()
        
        camera.didCancel = { () in
            print("didCancel")
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        camera.didFinishCapturingImage = {(image: UIImage) in
            print("didFinishCapturingImage")
            print(image)
            self.showImagePreview(image)
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        self.presentViewController(camera, animated: false, completion: nil)
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
