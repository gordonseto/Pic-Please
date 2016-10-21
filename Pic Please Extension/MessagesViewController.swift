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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        firebaseSignIn(){
            
        }
    }
    
    func firebaseSignIn(completion:()->()){
        FIRApp.configure()
        
        FIRAuth.auth()?.signInAnonymouslyWithCompletion(){ (user, error) in
            
            print(user?.uid)
        }
    }

}
