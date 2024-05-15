//
//  CameraViewController.swift
//  VIService
//
//  Created by HONGYUN on 16/06/17.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SwiftyCam
//import MBProgressHUD
import MediaPlayer
import MobileCoreServices
//import Photos
import mobileffmpeg

class CameraViewController: SwiftyCamViewController {

    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var datetimeLabel: UILabel!
    @IBOutlet weak var recordButton: KYShutterButton!
    @IBOutlet weak var cancelButton: UIButton!


    @IBOutlet weak var selectVideoBtn: UIButton!
    var isStarted: Bool = false
    var startedTime: Date = Date()
    var totalTime: Int = 0
    var seconds: Int = 180
    var countdownTimer: Timer = Timer()
    var isShowingDatetime: Bool = true
    var datetimeTimer: Timer = Timer()
    var splittedUrls: [URL] = []
    
    var flashSound =  AVAudioPlayer()
    
    var recordedVideoURLs: [[String]] = []
    let maxRecordedVideos = 5
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let storedArray = UserDefaults.standard.array(forKey: "recordedVideos") as? [[String]] {
//            print(storedArray)
            self.recordedVideoURLs = storedArray
        } else {
            print("No data found for key 'recordedVideos'")
        }
        
        cancelButton.isHidden = false
        datetimeLabel.isHidden = true
        UIApplication.shared.isIdleTimerDisabled = true

        
        setSystemVolume(volume: 1.0)
        
        doubleTapCameraSwitch = false
        shouldPrompToAppSettings = true
        cameraDelegate = self
        allowAutoRotate = true
        audioEnabled = true
        flashMode = .on
        flashButton.setImage(UIImage(named: "flash"), for: .normal)
        recordButton.isEnabled = false
        
        self.session.sessionPreset = AVCaptureSession.Preset.hd1280x720;
        videoQuality = .resolution1280x720
        
        if isShowingDatetime {
            runDatetimeTimer()
        }
        
        try! AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoRecording, options: .defaultToSpeaker)
        
        let path = Bundle.main.path(forResource: "tone2", ofType:"wav")!
        let url = URL(fileURLWithPath: path)

        do {
            flashSound = try AVAudioPlayer(contentsOf: url)
            flashSound.volume = 1.0
            flashSound.play()
        } catch {
            print("can't load mp3 file");
        }

    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func setSystemVolume(volume: Float) {
        let volumeView = MPVolumeView()

        for view in volumeView.subviews {
            if (NSStringFromClass(view.classForCoder) == "MPVolumeSlider") {
                let slider = view as! UISlider
                slider.setValue(volume, animated: false)
            }
        }
    }
    
    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }
    
    func runCountdownTimer() {
        isStarted = true
        startedTime = Date()
        seconds = 180
        countdownLabel.text = timeString(time: TimeInterval(seconds))
        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateCountdown)), userInfo: nil, repeats: true)
    }
    
    @objc func updateCountdown() {
        seconds -= 1
        countdownLabel.text = timeString(time: TimeInterval(seconds))
        
        if seconds == 0 {
            stopCountdownTimer()
            stopVideoRecording()
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%01i:%02i", minutes, seconds)
    }
    
    func stopCountdownTimer() {
        if isStarted {
            isStarted = false
            totalTime = Int(Date().timeIntervalSince(startedTime))
            countdownTimer.invalidate()
        }
    }
    
    func runDatetimeTimer() {
        datetimeLabel.text = dateString(date: Date())
        datetimeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(updateDatetime)), userInfo: nil, repeats: true)
    }
    
    @objc func updateDatetime() {
        datetimeLabel.text = dateString(date: Date())
    }
    
    func stopDatetimeTimer() {
        datetimeTimer.invalidate()
    }
    
    func hideButtons() {
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 0.0
            self.cancelButton.alpha = 0.0
            self.selectVideoBtn.alpha = 0.0
        }
    }
    
    func showButtons() {
        UIView.animate(withDuration: 0.25) {
            self.flashButton.alpha = 1.0
            self.cancelButton.alpha = 1.0
            self.selectVideoBtn.alpha = 1.0
        }
    }
    
    @IBAction func RecordButtonPressed(_ sender: Any) {
            if isStarted {
                
                stopVideoRecording()
            } else {
                
                startVideoRecording()
            }
    }
    
    @IBAction func selectVideoTapped(_ sender: Any) {
//        presentVideoPicker()
        self.performSegue(withIdentifier: "listview", sender: nil)
    }
    
    
    @IBAction func FlashButtonPressed(_ sender: Any) {
        if flashMode == .on {
            flashMode = .off
            flashButton.setImage(UIImage(named: "flashOutline"), for: .normal)
            
        } else if flashMode == .off {

            setSystemVolume(volume: 1.0)
            flashMode = .on
            flashButton.setImage(UIImage(named: "flash"), for: .normal)
            flashSound.volume = 1.0
            flashSound.play()
        }
        toggleFlash()
    }
    
    @IBAction func DateButtonPressed(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
//        if isShowingDatetime {
//            isShowingDatetime = false
//            datetimeButton.setTitle("Show Datetime", for: .normal)
//            datetimeLabel.isHidden = true
//            stopDatetimeTimer()
//        } else {
//            isShowingDatetime = true
//            datetimeButton.setTitle("Hide Datetime", for: .normal)
//            datetimeLabel.isHidden = false
//            runDatetimeTimer()
//        }
    }
    
    fileprivate func focusAnimationAt(_ point: CGPoint) {
        let focusView = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
    
    func dateString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss dd.MM.yyyy"
        return dateFormatter.string(from: date)
    }
    
    func saveRecordedVideos(url: URL) {
        let car_number = UserDefaults.standard.string(forKey: "CAR_NUMBER")
        var videoData: [String] = []
        videoData.append(url.absoluteString)
        videoData.append(car_number!)
        videoData.append(dateString(date: Date()))
        
        self.recordedVideoURLs.append(videoData)
        
        // Ensure only the last 5 recorded videos are kept
        if self.recordedVideoURLs.count > self.maxRecordedVideos {
            let removeData = self.recordedVideoURLs.removeFirst()
            try? FileManager.default.removeItem(at: URL(string: removeData[0])!)
        }
        
        // Save recorded video URLs persistently
        let savedVideoStrings = self.recordedVideoURLs.map { $0 as AnyObject }
        UserDefaults.standard.set(savedVideoStrings, forKey: "recordedVideos")
        
        self.performSegue(withIdentifier: "listview", sender: nil)
    }
    
}

extension CameraViewController: SwiftyCamViewControllerDelegate {
    
    func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did start running")
        recordButton.isEnabled = true
    }
    
    func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did stop running")
        recordButton.isEnabled = false
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did Begin Recording")
        runCountdownTimer()
        recordButton.buttonState = .recording
        hideButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did finish Recording")
        stopCountdownTimer()
        recordButton.buttonState = .normal
        showButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        self.saveRecordedVideos(url: url)
        
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        print("Did focus at point: \(point)")
        focusAnimationAt(point)
    }
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
        print(error)
    }
}

extension String {
    func hhmmssToSeconds() -> Float? {
        let components = self.split(separator: ":").map { String($0) }
        guard components.count == 3 else { return nil }
        let hours = Float(components[0]) ?? 0
        let minutes = Float(components[1]) ?? 0
        let seconds = Float(components[2]) ?? 0
        return hours * 3600 + minutes * 60 + seconds
    }
    
}



