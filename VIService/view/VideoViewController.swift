//
//  PreviewVideoViewController.swift
//  VIService
//
//  Created by HONGYUN on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import AVKit

class VideoViewController: UIViewController {

   var videoPath:URL?
   fileprivate  var player = AVPlayer()
   fileprivate var playerController = AVPlayerViewController()
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var videoView: UIView!
    var selectedVideo : [String] = []
    
    @IBOutlet weak var backgroundImg: UIImageView!
    var isPlaying : Bool = false
    
    
    var playImage : UIImage?
    var pauseImage : UIImage?

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let storedArray = UserDefaults.standard.array(forKey: "selectedVideo") as? [String] {
            self.selectedVideo = storedArray
            
            self.videoPath = URL(string: self.selectedVideo[0])
            
        } else {
            print("No data found for key 'selectedVideo'")
        }
        
//        playImage = UIImage(named: "play_blue")!
//        pauseImage = UIImage(named: "pause_blue")!
//        playButton.setBackgroundImage(playImage, for: .normal)
        playButton.setTitle("", for: .normal)
        backgroundImg.image = UIImage(named: "play_blue")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.videoPath != nil {
            player = AVPlayer(url: self.videoPath!)
            player.rate = 1
            let playerController = AVPlayerViewController()
            playerController.player = player
            playerController.videoGravity = .resizeAspect
            player.isMuted = false
            self.addChild(playerController)
            _ = AVAsset(url: self.videoPath!)
            self.videoView.addSubview(playerController.view)
            
            player.pause()
            
            UIView.animate(withDuration: 0.3, animations: {
                self.controlView.alpha = 1.0
            }) { (finished) in
                self.controlView.isHidden = false
            }
           
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        player.pause()
        UserDefaults.standard.removeObject(forKey: "selectedVideo")
//        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "camera") {
//            self.navigationController?.setViewControllers([viewController], animated: true)
//        }
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func chooseButtonTapped(_ sender: Any) {
        player.pause()
        UserDefaults.standard.set(self.selectedVideo, forKey: "selectedVideo")
        self.performSegue(withIdentifier: "upload", sender: nil)
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        if isPlaying {
            backgroundImg.image = UIImage(named: "play_blue")
            player.pause()
            self.isPlaying = false

        } else {
            backgroundImg.image = UIImage(named: "pause_blue")
            player.play()
            self.isPlaying = true	
        }
        
    }
}
