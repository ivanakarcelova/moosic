//
//  Track.swift
//  iTunesUpdated
//
//  Created by lake on 10/6/18.
//  Copyright © 2018 Lake. All rights reserved.
//

import UIKit

public class Track: NSObject
{
    var name: String?
    var artist: String?
    var previewUrl: String?
   // var price : Double?
  //  var albumImage : String?
    
    //take some more data
    
    
    init(name: String?, artist: String?, previewUrl: String?)
    {
        self.name = name
        self.artist = artist
        self.previewUrl = previewUrl
     
        
    }

}
