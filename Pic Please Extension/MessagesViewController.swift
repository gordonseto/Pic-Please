//
//  MessagesViewController.swift
//  Pic Please Extension
//
//  Created by Gordon Seto on 2016-10-21.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import UIKit
import Messages
import Firebase
import FirebaseAuth

class MessagesViewController: MSMessagesAppViewController, CameraVCDelegate {
    
    var uid: String!
    
    override func willBecomeActiveWithConversation(conversation: MSConversation) {
        super.willBecomeActiveWithConversation(conversation)
        
        firebaseSignIn(){
            self.presentViewController(for: conversation, with: self.presentationStyle)
        }
    }
    
    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle){
        
        if let url = conversation.selectedMessage?.URL {
            //this is a selected message
            print(url)
            
            let controller = CameraVC()
            controller.delegate = self
            controller.conversation = conversation
            initializeViewController(controller)
        } else {
            //this is not a selected message, show RequestVC
            let controller = UIStoryboard(name: "MainInterface", bundle: nil).instantiateViewControllerWithIdentifier("RequestVC") as! RequestVC
            controller.conversation = conversation
            
            initializeViewController(controller)
        }
    }
    
    func finishedCreatingMessage() {
        print("wat")
        self.dismiss()
    }
    
    func initializeViewController(controller: UIViewController){
        for child in childViewControllers {
            child.willMoveToParentViewController(nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }
        
        addChildViewController(controller)
        
        controller.view.frame = view.bounds
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        
        controller.view.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        controller.view.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        controller.view.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        controller.view.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        
        controller.didMoveToParentViewController(self)
    }
    
    func firebaseSignIn(completion:()->()){
        if let _ = FIRAuth.auth()?.currentUser {
            completion()
        } else {
            FIRApp.configure()
        
            FIRAuth.auth()?.signInAnonymouslyWithCompletion(){ (user, error) in
                self.uid = user?.uid
                print(user?.uid)
                completion()
            }
        }
    }

}
