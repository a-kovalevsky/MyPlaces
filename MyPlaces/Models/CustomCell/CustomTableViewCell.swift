//
//  CustomTableViewCell.swift
//  MyPlaces
//
//  Created by andrew on 12.05.22.
//

import UIKit
import Cosmos

class CustomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ImageOfPlace: UIImageView! {
        didSet {
            ImageOfPlace.layer.cornerRadius = ImageOfPlace.frame.size.height / 2
            ImageOfPlace.clipsToBounds = true
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var cosmosView: CosmosView! {
        didSet{
            cosmosView.settings.updateOnTouch = false 
        }
    }
}
