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

class MessagesViewController: MSMessagesAppViewController {
    

    override func willBecomeActiveWithConversation(conversation: MSConversation) {
        super.willBecomeActiveWithConversation(conversation)
        
        firebaseSignIn(){
            self.presentViewController(for: conversation, with: self.presentationStyle)
        }
    }
    

    
    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle){
        
        let controller = UIStoryboard(name: "MainInterface", bundle: nil).instantiateViewControllerWithIdentifier("RequestVC") as! RequestVC
        controller.conversation = conversation
        
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
            
                print(user?.uid)
                completion()
            }
        }
    }

}
