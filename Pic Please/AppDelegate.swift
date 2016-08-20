//
//  AppDelegate.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-08-18.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import UIKit
import Firebase
import Batch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        FIRApp.configure()
        
        FIRAuth.auth()?.signInAnonymouslyWithCompletion(){ (user, error) in
            
            Batch.startWithAPIKey(BATCH_API_KEY)
            BatchPush.registerForRemoteNotifications()
            BatchPush.dismissNotifications()
            
            let editor = BatchUser.editor()
            editor.setIdentifier(user!.uid)
            editor.save() // Do not forget to save the changes!
            
            let firebase = FIRDatabase.database().reference()
            let time = NSDate().timeIntervalSince1970
            firebase.child("users").child(user!.uid).child("lastOnline").setValue(time)
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        BatchPush.dismissNotifications()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
        print(userInfo["com.batch"])
        print(userInfo["com.batch"]!["l"])
        
        if let tabBarController = self.window?.rootViewController as? UITabBarController {
            updateTabBarBadges(tabBarController)
        }
        
        completionHandler(UIBackgroundFetchResult.NewData)
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        let urlString = url.absoluteString
        let queryArray = urlString.componentsSeparatedByString("/")
        let queryType = queryArray[2]
        
        print(queryType)
        
        if let tabBarController = self.window?.rootViewController as? UITabBarController {
            updateTabBarBadges(tabBarController)
        }
        if queryType == "pictures" {
            goToGallery()
        } else if queryType == "requests"{
            goToNotifications()
        }
        
        return true
    }
    
    func goToNotifications(){
        if let tabBarController: UITabBarController = self.window?.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = NOTIFICATIONS_INDEX
            if let notificationsVC = tabBarController.viewControllers![NOTIFICATIONS_INDEX] as? NotificationsVC {
                notificationsVC.checkForRequests()
            }
        }
    }
    
    func goToGallery(){
        if let tabBarController: UITabBarController = self.window?.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = GALLERY_INDEX
            if let galleryVC = tabBarController.viewControllers![NOTIFICATIONS_INDEX] as? GalleryVC {
                galleryVC.getUsersImages()
            }
        }
    }

}

