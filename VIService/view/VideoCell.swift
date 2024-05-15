//
//  VideoCell.swift
//  VIService
//
//  Created by Leoard on 5/13/24.
//  Copyright © 2024 Polestar. All rights reserved.
//

import UIKit

class VideoCell: UITableViewCell {
    @IBOutlet weak var videoThumbnail: UIImageView!
    
    @IBOutlet weak var textCarNumber: UILabel!
    
    @IBOutlet weak var textDateTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
