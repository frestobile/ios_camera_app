//
//  UploadingViewController.swift
//  VIService
//
//  Created by HONGYUN on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import MBProgressHUD

class UploadingViewController: UIViewController {
    
    @IBOutlet weak var carNumberTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var technicianTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var uploadButton: UIButton!
        
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var dateTextField: SkyFloatingLabelTextField!
    var deviceId : String = ""
    var carNumber : String = ""
    var technician : String = ""
    var videoUrl = UserDefaults.standard.url(forKey: "VIDEO_URL")!
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let logoUrl = UserDefaults.standard.string(forKey: "COMPANY_LOGO")!
        let imageURL = URL(string: ASSETS_URL + logoUrl)!
        
        companyLogo.loadImage(fromURL: imageURL)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        carNumberTextField.text = UserDefaults.standard.string(forKey: "CAR_NUMBER") ?? ""
        technicianTextField.text = UserDefaults.standard.string(forKey: "TECHNICIAN") ?? ""
        dateTextField.text = UserDefaults.standard.string(forKey: "CREATED_TIME") ?? dateString(date: Date())
        uploadButton.layer.cornerRadius = 1
        deleteButton.layer.cornerRadius = 1
        
        deviceId = UserDefaults.standard.string(forKey: "DEVICE_ID") ?? ""
        carNumber = carNumberTextField.text ?? ""
        technician = technicianTextField.text ?? ""
        videoUrl = UserDefaults.standard.url(forKey: "VIDEO_URL")!
    
    }
    
    func dateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss dd.MM.yyyy"
        return dateFormatter.string(from: date)
    }
    
    
    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }
    
    func deleteFile(url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        let alert = UIAlertController.init(title: "Delete video", message: "Are you sure to delete video?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) in
            
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { (alertAction) in
            let videoUrl = UserDefaults.standard.url(forKey: "VIDEO_URL")!
            self.deleteFile(url: videoUrl)
            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
                self.navigationController?.setViewControllers([viewController], animated: true)
            }
        })
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func uploadButtonPressed(_ sender: Any) {
        
        if self.uploadButton.currentTitle == "Resend video" {
            MBProgressHUD.showAdded(to: view, animated: true)
            
            ApiManager.shared.videoCheck(deviceId: deviceId, carNumber: carNumber) { (result) in
                MBProgressHUD.hide(for: self.view, animated: true)
                switch result {
                case .success(let response):
                    if response.error {
                        self.showAlert(title: "Error", message: response.msg) {
                            self.deleteFile(url: self.videoUrl)
                            if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
                                self.navigationController?.setViewControllers([viewController], animated: true)
                            }
                        }
                    } else {
                        self.videoUpload(deviceId: self.deviceId, carNumber: self.carNumber, technician: self.technician)
                    }
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription) {
                        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
                            self.navigationController?.setViewControllers([viewController], animated: true)
                        }
                    }
                }
            }
        } else {
            self.videoUpload(deviceId: self.deviceId, carNumber: self.carNumber, technician: self.technician)
        }
    }
    
//    func videoCreate(deviceId: String, carNumber: String, technician: String) {
//        MBProgressHUD.showAdded(to: view, animated: true)
//
//        ApiManager.shared.videoCreate(deviceId: deviceId, carNumber: carNumber, technician: technician) { (result) in
//            MBProgressHUD.hide(for: self.view, animated: true)
//            switch result {
//            case .success(let response):
//                if response.error {
//                    self.uploadButton.setTitle("Resend video", for: .normal)
//                    self.showAlert(title: "Error", message: response.message)
//                } else {
//                    let jwplatform_token = response.token
//                    let jwplatform_key = response.key
//                    self.videoUpload(deviceId: deviceId, carNumber: carNumber, technician: technician)
//                }
//            case .failure(let error):
//                self.uploadButton.setTitle("Resend video", for: .normal)
//                self.showAlert(title: "Error", message: error.localizedDescription)
//            }
//        }
//    }
    
    func videoUpload (deviceId: String, carNumber: String, technician: String) {
        
        UIApplication.shared.isIdleTimerDisabled = true
        let progressView = MBProgressHUD.showAdded(to: view, animated: true)
        progressView.mode = .indeterminate
        progressView.label.text = "Uploading..."
        
        ApiManager.shared.videoUpload(deviceId: deviceId, carNumber: carNumber, technician: technician, video: videoUrl, progressHandler: { (progress) in
            progressView.label.text = "Uploading... \(Int(progress * 100))%"
            }) { (result) in
            UIApplication.shared.isIdleTimerDisabled = false
                
            progressView.hide(animated: true)
            switch result {
            case .success(let response):
                if response.error {
                    self.uploadButton.setTitle("Resend video", for: .normal)
                    self.showAlert(title: "Error", message: "Upload Failed, Try again later.")
                } else {
                    self.showAlert(title: "VIServ", message: "Video upload done") {
//                        self.deleteFile(url: self.videoUrl)
                        if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
                            self.navigationController?.setViewControllers([viewController], animated: true)
                        }
                    }
                }
            case .failure(let error):
                self.uploadButton.setTitle("Resend video", for: .normal)
                if error._code == NSURLErrorTimedOut {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
                print(error)
                
            }
        }
    }
}
