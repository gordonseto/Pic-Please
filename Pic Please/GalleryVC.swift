//
//  GalleryVC.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-08-19.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import UIKit
import INSPhotoGallery
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class GalleryVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var refreshControl: UIRefreshControl!
    
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    
    var firebase: FIRDatabaseReference!
    
    var uid: String!
    
    var photos: [CustomPhotoModel] = {
        return [
            CustomPhotoModel(imageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/13-3f15416ddd11d38619289335fafd498d.jpg"), thumbnailImage: UIImage(named: "testProfileImage")!),
            CustomPhotoModel(imageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/13-3f15416ddd11d38619289335fafd498d.jpg"), thumbnailImage: UIImage(named: "testProfileImage")!),
            CustomPhotoModel(image: UIImage(named: "testProfileImage")!, thumbnailImage: UIImage(named: "testProfileImage")!),
            CustomPhotoModel(imageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/6-d793b947f57cc3df688eeb1d36b04ddb.jpg"), thumbnailImageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/6-d793b947f57cc3df688eeb1d36b04ddb.jpg")),
            CustomPhotoModel(imageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/6-d793b947f57cc3df688eeb1d36b04ddb.jpg"), thumbnailImageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/6-d793b947f57cc3df688eeb1d36b04ddb.jpg")),
            CustomPhotoModel(imageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/6-d793b947f57cc3df688eeb1d36b04ddb.jpg"), thumbnailImageURL: NSURL(string: "http://inspace.io/assets/portfolio/thumb/6-d793b947f57cc3df688eeb1d36b04ddb.jpg"))
        ]
    }()
    
    var usersPhotos: [CustomPhotoModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refreshView:"), forControlEvents:  UIControlEvents.ValueChanged)
        refreshControl.tintColor = UIColor.lightGrayColor()
        collectionView.addSubview(refreshControl)
        collectionView.scrollEnabled = true
        collectionView.alwaysBounceVertical = true
        
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            self.uid = uid
            getUsersImages()
        }
    }
    
    func getUsersImages(){
        firebase = FIRDatabase.database().reference()
        firebase.child("users").child(uid).child("images").queryOrderedByValue().observeSingleEventOfType(.Value, withBlock: {(snapshot) in
            print(snapshot)
            var imageKeys: [String] = []
            for child in snapshot.children {
                imageKeys.append(child.key)
            }
            imageKeys = imageKeys.reverse()
            self.downloadUrlsFromKeys(imageKeys)
        }) { (error) in
            print(error.debugDescription)
        }
    }
    
    func downloadUrlsFromKeys(imageKeys: [String]){
        let storage = FIRStorage.storage()
        let storageRef = storage.referenceForURL(FIREBASE_STORAGE)
        let imagesRef = storageRef.child("images")
        
        var imageUrls: [String: NSURL] = [:]
        var keysDownloaded = 0
        
        usersPhotos = []
        
        for key in imageKeys {
            let childRef = imagesRef.child(key)
            childRef.downloadURLWithCompletion {(URL, error) -> Void in
                if (error != nil) {
                    print(error.debugDescription)
                } else {
                    if let URL = URL {
                        keysDownloaded++
                        
                        imageUrls[key] = URL
                        
                        if keysDownloaded == imageKeys.count {
                            self.doneGettingUrls(imageKeys, imageUrls: imageUrls)
                        }
                    }
                }
            }
        }
        if imageKeys.count == 0 {
            doneGettingUrls(imageKeys, imageUrls: [:])
        }
    }
    
    func appendUrl(URL: NSURL){
        let customPhotoModel = CustomPhotoModel(imageURL: URL, thumbnailImageURL: URL)
        usersPhotos.append(customPhotoModel)
    }
    
    func doneGettingUrls(imageKeys: [String], imageUrls: [String: NSURL]){
        for key in imageKeys {
            if let url = imageUrls[key] {
                appendUrl(url)
            }
        }
        removeFromNotifications(uid, type: "pictures")
        collectionView.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        cell.populateWithPhoto(usersPhotos[indexPath.row])
        
        return cell
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return usersPhotos.count
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        let currentPhoto = usersPhotos[indexPath.row]
        let galleryPreview = INSPhotosViewController(photos: usersPhotos, initialPhoto: currentPhoto, referenceView: cell)
        
        galleryPreview.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
            if let index = self?.usersPhotos.indexOf({$0 === photo}) {
                let indexPath = NSIndexPath(forItem: index, inSection: 0)
                let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PhotoCell
                return cell
            }
            return nil
        }
        presentViewController(galleryPreview, animated: true, completion: nil)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake((screenWidth - 2) / CGFloat(3.0), (screenWidth - 2) / CGFloat(3.0))
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func refreshView(sender: AnyObject){
        if let _ = uid {
            getUsersImages()
        }
        refreshControl.endRefreshing()
    }

}
