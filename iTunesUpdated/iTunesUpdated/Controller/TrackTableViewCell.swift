//
//  TrackTableViewCell.swift
//  iTunesUpdated
//
//  Created by lake on 10/6/18.
//  Copyright © 2018 Lake. All rights reserved.
//

import UIKit

protocol TrackTableViewCellDelegate //interface
{
    func cancelTapped(_ cell: TrackTableViewCell)
    func downloadTapped(_ cell: TrackTableViewCell)
}

class TrackTableViewCell: UITableViewCell
{
    //Delegation
    var delegate: TrackTableViewCellDelegate?
    
    //Cell UI
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var albumArt: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBAction func downloadTapped(_ sender: AnyObject)
    {
        delegate?.downloadTapped(self)
        
    }
    
    
    @IBAction func cancelTapped(_ sender: AnyObject)
    {
        delegate?.cancelTapped(self)
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }

}
