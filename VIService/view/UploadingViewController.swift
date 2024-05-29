//
//  UploadingViewController.swift
//  VIService
//
//  Created by Fresobile on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import MBProgressHUD
import mobileffmpeg

class UploadingViewController: UIViewController, LogDelegate {
    
    @IBOutlet weak var carNumberTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var technicianTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var uploadButton: UIButton!
        
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var dateTextField: SkyFloatingLabelTextField!
    
    var inactivityTimer: Timer?
    var originalBrightness: CGFloat = UIScreen.main.brightness
    
    var deviceId : String = ""
    var carNumber : String = ""
    var technician : String = ""
    var videoUrl : URL?
    var compressedUrl: URL?
    var videoData : [String] = []
    
    var progressingView: MBProgressHUD!
    var duration: Float = 0.0
    
    var isCameraUsed: Bool = false
    
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
//        startInactivityTimer()
        
        deviceId = UserDefaults.standard.string(forKey: "DEVICE_ID") ?? ""
        isCameraUsed = UserDefaults.standard.bool(forKey: "CAMERA_USED")
        
        if isCameraUsed {
            carNumberTextField.text = UserDefaults.standard.string(forKey: "CAR_NUMBER") ?? ""
            technicianTextField.text = UserDefaults.standard.string(forKey: "TECHNICIAN") ?? ""
            videoUrl = UserDefaults.standard.url(forKey: "VIDEO_URL")
        } else {
            if let storedArray = UserDefaults.standard.array(forKey: "selectedVideo") as? [String] {
                self.videoData = storedArray
                self.videoUrl = URL(string: self.videoData[0])
                self.dateTextField.text = self.videoData[2]
                self.carNumberTextField.text = self.videoData[1]
            } else {
                print("No data found for key 'selectedVideo'")
            }
        }
        
       
        uploadButton.layer.cornerRadius = 5
        deleteButton.layer.cornerRadius = 5
        
        carNumber = carNumberTextField.text ?? ""
        technician = technicianTextField.text ?? ""

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
        let alert = UIAlertController.init(title: "", message: "Do you want to cancel uploading?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel) { (alertAction) in
            
        })
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { (alertAction) in
//            self.deleteFile(url: self.videoUrl!)
            if self.compressedUrl != nil {
                self.deleteFile(url: self.compressedUrl!)
            }
            
            UserDefaults.standard.removeObject(forKey: "selectedVideo")
            
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
//                            self.deleteFile(url: self.videoUrl!)
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
            if !isCameraUsed {
                MBProgressHUD.showAdded(to: view, animated: true)
                
                ApiManager.shared.videoCheck(deviceId: deviceId, carNumber: carNumber) { (result) in
                    MBProgressHUD.hide(for: self.view, animated: true)
                    switch result {
                        case .success(let response):
                            if response.error {
                                self.showAlert(title: "Error", message: response.msg) {
                                    if let viewController = self.storyboard?.instantiateViewController(withIdentifier: "CarNumberViewController") {
                                        self.navigationController?.setViewControllers([viewController], animated: true)
                                    }
                                }
                            } else {
                                self.compressVideoWithProgress(inputURL: self.videoUrl!)
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
                self.compressVideoWithProgress(inputURL: self.videoUrl!)
            }
        }
    }
    
    
    // MARK: - Video Upload
    func videoUpload (deviceId: String, carNumber: String, technician: String) {
        
        UIApplication.shared.isIdleTimerDisabled = true
        self.progressingView = MBProgressHUD.showAdded(to: view, animated: true)
        self.progressingView.mode = .indeterminate
        self.progressingView.label.text = "Uploading..."
        
        ApiManager.shared.videoUpload(deviceId: deviceId, carNumber: carNumber, technician: technician, video: compressedUrl!, progressHandler: { (progress) in
            self.progressingView.label.text = "Uploading... \(Int(progress * 100))%"
            }) { (result) in
            UIApplication.shared.isIdleTimerDisabled = false
                
                self.progressingView.hide(animated: true)
            switch result {
            case .success(let response):
                if response.error {
                    self.uploadButton.setTitle("Resend video", for: .normal)
                    self.showAlert(title: "Error", message: "Upload Failed, Try again later.")
                } else {
                    self.showAlert(title: "", message: "Video upload done") {
//                        self.deleteFile(url: self.videoUrl!)
                        self.deleteFile(url: self.compressedUrl!)
                        UserDefaults.standard.removeObject(forKey: "selectedVideo")
                        UserDefaults.standard.removeObject(forKey: "CAR_NUMBER")
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
    
    // MARK: - LogDelegate Function
    func logCallback(_ executionId: Int, _ level: Int32, _ message: String) {
        
        guard level == AV_LOG_INFO else { return }
        
        print("Compress status===>: \(message)")
        
        
        if message.starts(with: "00:") {
            self.duration = parseDuration(message) ?? 60.0
        }
        if let time = parseTime(message) {
            let progress = Float(time / duration)
            print("progress: \(progress)==== \(duration)/\(time)")
            DispatchQueue.main.async {
                self.progressingView.label.text = "Compressing... \(Int(progress * 100))%"
            }
            
        }
        
    }
    
    private func parseDuration(_ log: String) -> Float? {
        let durationPattern = "(\\d{2}:\\d{2}:\\d{2}.\\d{2})"
        return extractTime(from: log, with: durationPattern)
    }
    
    private func parseTime(_ log: String) -> Float? {
        let timePattern = "time=(\\d{2}:\\d{2}:\\d{2}.\\d{2})"
        return extractTime(from: log, with: timePattern)
    }
    
    private func extractTime(from log: String, with pattern: String) -> Float? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsString = log as NSString
        let results = regex?.matches(in: log, options: [], range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results?.first, let range = Range(match.range(at: 1), in: log) else {
            return nil
        }
        
        let timeString = String(log[range])
        return timeString.hhmmssToSeconds()
    }
    
    func dateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss dd.MM.yyyy"
        return dateFormatter.string(from: date)
    }
    
}



// MARK: - Video Compress function
extension UploadingViewController {
    
    func compressVideoWithProgress(inputURL: URL) {
        progressingView = MBProgressHUD.showAdded(to: view, animated: true)
        progressingView.mode = .indeterminate
        progressingView.label.text = "Compressing..."
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.compressedUrl = documentsDirectory.appendingPathComponent("\(carNumber)_\(generateRandomString(length: 20)).mp4")
        
        let command = "-i \(inputURL.path) -c:v h264 -r 30 -b:v 2800k -s 1280x720 -c:a aac -b:a 128k \(self.compressedUrl!.path)"
        
        DispatchQueue.global(qos: .background).async {
            MobileFFmpegConfig.setLogDelegate(self)
            //            let result = MobileFFmpeg.executeAsync(command, withCallback: self)
            let result = MobileFFmpeg.execute(command)
            
            DispatchQueue.main.async {
                self.progressingView.hide(animated: true)
                if result == RETURN_CODE_SUCCESS {
                    
                    self.videoUpload(deviceId: self.deviceId, carNumber: self.carNumber, technician: self.technician)
                    
                } else if result == RETURN_CODE_CANCEL {
                    print("Video compressing was cancelled.")
                } else {
                    self.errorAlert(url: inputURL)
                }
            }
            
        }
    }
    
    public func datePresentString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        
        let iso8601String = dateFormatter.string(from: date as Date)
        
        return iso8601String
    }
    
    
    public func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func errorAlert(url : URL) {
        let message = NSLocalizedString("Something goes wrong during compress recorded video. Try Again?", comment: "")
        let alertController = UIAlertController(title: "Compress Video", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Yes", style: .default) { (action:UIAlertAction!) in
            
            self.compressVideoWithProgress(inputURL: url)
        }
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel) { (action:UIAlertAction!) in
            print("Cancel button tapped")
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}


extension UploadingViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        //        resetInactivityTimer()
        //        restoreBrightness()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        //        resetInactivityTimer()
        //        restoreBrightness()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        //        resetInactivityTimer()
        //        restoreBrightness()
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        //        resetInactivityTimer()
        //        restoreBrightness()
    }
    
    private func startInactivityTimer() {
        //        stopInactivityTimer()
        //        inactivityTimer = Timer.scheduledTimer(timeInterval: 600, target: self, selector: #selector(dimScreen), userInfo: nil, repeats: false)
        //        print("Screen brightness restored to \(originalBrightness)")
    }
    
    private func stopInactivityTimer() {
        //        inactivityTimer?.invalidate()
        //        inactivityTimer = nil
    }
    
    private func resetInactivityTimer() {
        stopInactivityTimer()
        startInactivityTimer()
    }
    
    @objc private func dimScreen() {
        originalBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 0.1
        print("Screen dimmed to 0.1")
    }
    
    private func restoreBrightness() {
        UIScreen.main.brightness = originalBrightness
        print("Screen brightness restored to \(originalBrightness)")
    }
}
