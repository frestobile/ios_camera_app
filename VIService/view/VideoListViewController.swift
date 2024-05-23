//
//  VideoListViewController.swift
//  VIService
//
//  Created by Leoard on 5/13/24.
//  Copyright © 2024 Polestar. All rights reserved.
//
import AVFoundation
import UIKit

class VideoListViewController: UIViewController {

    @IBOutlet weak var companyLogo: UIImageView!
    
    @IBOutlet weak var videoTableView: UITableView!
    @IBOutlet weak var emptyView: UILabel!
    
    @IBOutlet weak var cancelBtn: UIButton!
    var videoArrayData: [[String]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set(false, forKey: "CAMERA_USED")
        videoTableView.dataSource = self
        videoTableView.delegate = self
        videoTableView.tableFooterView = UIView()
        
        let logoUrl = UserDefaults.standard.string(forKey: "COMPANY_LOGO")!
        let imageURL = URL(string: ASSETS_URL + logoUrl)!
        
        companyLogo.loadImage(fromURL: imageURL)
        
        cancelBtn.layer.cornerRadius = 5
        
        if let storedArray = UserDefaults.standard.array(forKey: "recordedVideos") as? [[String]] {
            self.videoArrayData = storedArray
        } else {
            print("No data found for key 'recordedVideos'")
        }

    }
    
    @IBAction func cancelBtnTapped(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
}

// MARK: - Table view data source
extension VideoListViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if videoArrayData.count == 0 {
            videoTableView.isHidden = true
//            emptyView.isHidden = false
        } else {
            videoTableView.isHidden = false
//            emptyView.isHidden = true
        }
        
        return videoArrayData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "VideoCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! VideoCell
        cell.textCarNumber?.text = videoArrayData[indexPath.row][1]
        cell.textDateTime?.text = videoArrayData[indexPath.row][2]
        let videoURL = URL(string: videoArrayData[indexPath.row][0])!
        let thumbnailSize = CGSize(width: 128, height: 72)
        generateThumbnail(from: videoURL, size: thumbnailSize) { thumbnail in
            if let thumbnail = thumbnail {
                cell.videoThumbnail.image = thumbnail
                
            } else {
                print("Failed to generate thumbnail.")
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        videoTableView.deselectRow(at: indexPath, animated: true) // to show interaction when cell is tapped
        
        _ = videoTableView.cellForRow(at: indexPath) as! VideoCell
        let selectedItem = videoArrayData[indexPath.row]
        
        UserDefaults.standard.set(selectedItem, forKey: "selectedVideo")

        self.performSegue(withIdentifier: "video_view", sender: nil)
        
    }
    
    // delete table row
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Remove the item from the data source array
            self.showAlert(title: "VIServ", message: "Are You Sure ?") { alertAction in
                if alertAction {
                    self.videoArrayData.remove(at: indexPath.row)
                    let savedVideoStrings = self.videoArrayData.map { $0 as AnyObject }
                    UserDefaults.standard.set(savedVideoStrings, forKey: "recordedVideos")
                    // Update the table view
                    tableView.deleteRows(at: [indexPath], with: .fade)
                } else {
                    print("delete action cancelled")
                }
                
            }
            
        }
    }
    
    // MARK: - get thumbnail from video url
    func generateThumbnail(from videoURL: URL, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        imageGenerator.maximumSize = size
        
        let time = CMTimeMake(value: 1, timescale: 60) // 1 second
        
        // Getting the thumbnail
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            completion(thumbnail)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    func showAlert(title: String, message: String, completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "YES", style: .default) { (alertAction) in
            completion(true)
        })
        alert.addAction(UIAlertAction(title: "NO", style: .cancel) {(alertAction) in
            completion(false)
        })
        present(alert, animated: true, completion: nil)
    }
}
