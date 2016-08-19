//
//  INSPhotosViewControllerDataSource.swift
//  INSPhotoViewer
//
//  Created by Michal Zaborowski on 28.02.2016.
//  Copyright © 2016 Inspace Labs Sp z o. o. Spółka Komandytowa. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this library except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import Foundation

struct INSPhotosDataSource{
    var photos: [INSPhotoViewable] = []
    
    var numberOfPhotos: Int {
        return photos.count
    }
    
    func photoAtIndex(index: Int) -> INSPhotoViewable? {
        if (index < photos.count && index >= 0) {
            return photos[index];
        }
        return nil
    }
    
    func indexOfPhoto(photo: INSPhotoViewable) -> Int? {
        return photos.indexOf({ $0 === photo})
    }

    func containsPhoto(photo: INSPhotoViewable) -> Bool {
        return indexOfPhoto(photo) != nil
    }
    
    subscript(index: Int) -> INSPhotoViewable? {
        get {
            return photoAtIndex(index)
        }
    }
}