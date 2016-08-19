//
//  PhotoCell.swift
//  Pic Please
//
//  Created by Gordon Seto on 2016-08-19.
//  Copyright © 2016 Gordon Seto. All rights reserved.
//

import UIKit
import INSPhotoGallery

class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func populateWithPhoto(photo: INSPhotoViewable) {
        photo.loadThumbnailImageWithCompletionHandler { [weak photo] (image, error) in
            if let image = image {
                if let photo = photo as? INSPhoto {
                    photo.thumbnailImage = image
                }
                self.imageView.image = image
            }
        }
    }
}
