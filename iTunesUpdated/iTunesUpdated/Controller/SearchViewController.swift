//
//  SearchViewController.swift
//  iTunesUpdated
//
//  Created by lake on 10/7/18.
//  Copyright © 2018 Lake. All rights reserved.
//

import UIKit
import AVKit

class SearchViewController: UITableViewController, URLSessionDelegate, URLSessionDownloadDelegate, UISearchBarDelegate, TrackTableViewCellDelegate
{
    
    var hasTrack = false
    var trackToPlay: Track?
    var activeDownloads = [String: Download]()
    var searchResults = [Track]()
    
    let defaultSession = Foundation.URLSession(configuration: URLSessionConfiguration.default)
    
    var dataTask: URLSessionDataTask?
    
    //search bar - ARC
    @IBOutlet weak var searchBar: UISearchBar!
    
    //Lazy instantiation - make when needed
    lazy var tapRecognizer: UITapGestureRecognizer =
    {
        var recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            return recognizer
    }()
    
    
    //Lazy again
    lazy var downloadsSession: Foundation.URLSession =
    {
        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration")
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session;
    }()
    
    @objc func dismissKeyboard()
    {
        self.searchBar.resignFirstResponder()
       
    }

    //Download Helper Methods
    func localFilePathForUrl(_ previewURL: String) -> URL?
    {
        let documentsPath =
            NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let url = URL(string: previewURL)
        let lastPathComponent = url?.lastPathComponent
        let fullPath = documentsPath.appendingPathComponent(lastPathComponent!)
        
        return URL(fileURLWithPath: fullPath)
    }
    
    
    func localFileExistsForTrack(_ track: Track) -> Bool
    {
        if let urlString = track.previewUrl, let localUrl = localFilePathForUrl(urlString)
        {
            var isDir: ObjCBool = false
            let path = localUrl.path
            return FileManager.default.fileExists(atPath: path,
                                                  isDirectory: &isDir)
        }
        return false
    }
    
    func trackIndexForDownloadTask(_ downloadTask: URLSessionDownloadTask) -> Int?
    {
        if let url = downloadTask.originalRequest?.url?.absoluteString
        {
            for(index, track) in searchResults.enumerated()
            {
                if url == track.previewUrl
                {
                    return index
                }
            }
        }
        return nil
    }
   
    
    
    //DELEGATION - TOO MANY!!!
    //Session and Search Delegate Methods
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate
        {
            if let completionHandler = appDelegate.backgroundSessionCompletionHandler
            {
                appDelegate.backgroundSessionCompletionHandler = nil
                //GCD - Queue
                DispatchQueue.main.async(execute:
                {
                    completionHandler()
                })
                
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        
        if let originalURL = downloadTask.originalRequest?.url?.absoluteString,
         let destinationURL = localFilePathForUrl(originalURL)
        {
             print(destinationURL)
            
            let fileManager = FileManager.default
            do
            {
                try fileManager.removeItem(at: destinationURL)
            }
            catch
            {
                //file does not exist
            }
            
            do
            {
                try fileManager.copyItem(at: location, to: destinationURL)
            }
            catch let error as NSError
            {
                print(error.localizedDescription)
            }
        }
        
        if let url = downloadTask.originalRequest?.url?.absoluteString
        {
            activeDownloads[url] = nil
            
            if let trackIndex = trackIndexForDownloadTask(downloadTask)
            {
                DispatchQueue.main.async(execute:
                {
                    self.tableView.reloadRows(at: [IndexPath(row: trackIndex, section: 0)], with: .none)
                })
            }
            
        }
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        //keeps track of the download and update the progress bar
        
        if let downloadUrl = downloadTask.originalRequest?.url?.absoluteString,
            let download = activeDownloads[downloadUrl]
        {
            download.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
            
            let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: ByteCountFormatter.CountStyle.binary)
            
            if let trackIndex = trackIndexForDownloadTask(downloadTask)
            {
                DispatchQueue.main.async(execute:
                {
                    let trackCell = self.tableView.cellForRow(at: IndexPath(row: trackIndex, section: 0)) as? TrackTableViewCell
                    
                    trackCell?.progressView.progress = download.progress
                    
                    print(String(format: "%.1f%% of %@", download.progress*100,
                                 totalSize))
                })
            }
        }
    }
    
    
    //Error fixed: change searchBarCanelButtonClicked to searchBarSearchButtonClicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.dismissKeyboard()
        
        if !searchBar.text!.isEmpty
        {
            if dataTask !=  nil
            {
                dataTask?.cancel()
            }
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let expectedCharSet = CharacterSet.urlQueryAllowed
            let searchTerm = searchBar.text?.addingPercentEncoding(withAllowedCharacters: expectedCharSet)
            
            //Error fixed: change searchTerm to searchTerm!
            let url = URL(string: "https://itunes.apple.com/search?term=\(searchTerm!)")
           
            dataTask  = defaultSession.dataTask(with: url!, completionHandler:
            {  data, response , error in
                
                DispatchQueue.main.async
                {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                if let e = error
                {
                    print(e.localizedDescription)
                }
                else if let httpResponse = response as? HTTPURLResponse
                {
                    if httpResponse.statusCode == 200
                    {
                        self.updateSearchResults(data)
                    }
                    
                }
                
                    
            })
            
            dataTask?.resume()
            
        }
    }
    func position(for bar: UIBarPositioning) -> UIBarPosition
    {
        return .topAttached
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar)
    {
        view.removeGestureRecognizer(tapRecognizer)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String)
    {
        if searchText == ""
        {
            self.searchResults.removeAll()
            self.tableView.reloadData()
        }
    }
    
    
    //TrackTableViewCellDelegate our delegate methods
    func cancelTapped(_ cell: TrackTableViewCell)
    {
        if let indexPath = tableView.indexPath(for: cell)
        {
            let track = searchResults[(indexPath as NSIndexPath).row]
            cancelDownload(track) //Error fixed: exucute this code
            tableView.reloadRows(at: [IndexPath(row: (indexPath as NSIndexPath).row, section: 0)], with: .none)
        }
    }
    
    func downloadTapped(_ cell: TrackTableViewCell)
    {
        if let indexPath = tableView.indexPath(for: cell)
        {
            let track = searchResults[(indexPath as NSIndexPath).row]
            startDownload(track) //Error fixed: exucute this code
            tableView.reloadRows(at: [IndexPath(row: (indexPath as NSIndexPath).row, section: 0)], with: .none)
        }
        
    }
    
    
    
    //TableView Delegate Methods
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 70.0 //depends on how many things on your cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let track = searchResults[indexPath.row]
        
        if localFileExistsForTrack(track)
        {
            playDownload(track)
            //segue
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //View Controller Methods
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.searchBar.delegate = self
       _ = self.downloadsSession
    }
    
    
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    
    //TableView DataSource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trackCell",
                                                 for: indexPath) as! TrackTableViewCell
        cell.delegate = self
        
        let track = searchResults[indexPath.row]
        
        cell.titleLabel.text = track.name
        cell.artistLabel.text = track.artist
        
        var showDownloadControls = false
        if let download = activeDownloads[track.previewUrl!]
        {
            showDownloadControls = true
            cell.progressView.progress =  download.progress
        }
      
        
        let downloaded = localFileExistsForTrack(track)
        
        //ternary operator
        cell.selectionStyle = downloaded
            ? UITableViewCell.SelectionStyle.gray:
            UITableViewCell.SelectionStyle.none
        
        cell.progressView.isHidden = !showDownloadControls
        
        cell.downloadButton.isHidden = downloaded || showDownloadControls
        
        cell.cancelButton.isHidden = !showDownloadControls
        
        return cell
        
    }
    
    
    //Helper method to update the search results and parse the JSON
    
    func updateSearchResults(_ data: Data?)
    {
        searchResults.removeAll()
        do
        {   if let data = data,
            let response = try
            JSONSerialization.jsonObject(with: data,
            options:JSONSerialization.ReadingOptions(rawValue: 0)) as?
            [String: AnyObject]
            {
                if let array: AnyObject = response["results"]
                {
                    for trackDictionary in array as! [AnyObject]
                    {
                        if let trackDictionary = trackDictionary as? [String: AnyObject], let previewUrl = trackDictionary["previewUrl"] as? String
                        {
                            let name = trackDictionary["trackName"] as? String
                            let artist = trackDictionary["artistName"] as? String
                            //let artistId = trackDictionary["artistId"] as? String
                            //"trackExplicitness":"notExplicit",
                            
                            //Example of how to separate tracks based on trackExplicitness
                            let trackExplicitness = trackDictionary["trackExplicitness"] as? String
                            
                            if trackExplicitness == "notExplicit"
                            {
                                searchResults.append(Track(name: name, artist: artist, previewUrl: previewUrl))
                            }
                        }
                    }
                }
            
            }
        
            
        }
        catch let error as NSError
        {
            print(error.localizedDescription)
        }
        
        DispatchQueue.main.async
        {
            self.tableView.reloadData()
            self.tableView.setContentOffset(CGPoint.zero, animated: false)
        }
    }
    
    func startDownload(_ track: Track)
    {
        if let urlString = track.previewUrl, let url = URL(string: urlString)
        {
            let download = Download(url: urlString)
            download.downloadTask = downloadsSession.downloadTask(with: url)
            download.downloadTask?.resume()
            download.isDownloading = true
            activeDownloads[download.url] = download
        }
    }
    
    //Cancel download added
    func cancelDownload(_ track: Track)
    {
        if let urlString = track.previewUrl,
            let download = activeDownloads[urlString]
        {
            download.downloadTask?.cancel()
            activeDownloads[urlString] = nil
        }
        
    }
    
    func playDownload(_ track: Track)
    {
        if let urlString = track.previewUrl,
            let url = localFilePathForUrl(urlString)
        {
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            
            self.present(playerViewController, animated: true)
            {
                playerViewController.player?.play()
            }
            
        }
    }
    
    
    
   
}

