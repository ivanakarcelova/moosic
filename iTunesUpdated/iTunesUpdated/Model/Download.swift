//
//  Download.swift
//  iTunesUpdated
//
//  Created by lake on 10/6/18.
//  Copyright © 2018 Lake. All rights reserved.
//

import UIKit

public class Download: NSObject
{
    var url: String
    var isDownloading = false
    var progress: Float = 0.0
    
    var downloadTask: URLSessionDownloadTask?
    var resumeData: Data?
    
    init(url: String)
    {
        self.url = url
    }

}
