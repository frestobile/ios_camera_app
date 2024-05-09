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
import MBProgressHUD
import MediaPlayer
import MobileCoreServices
import Photos
import mobileffmpeg

class CameraViewController: SwiftyCamViewController,  UIImagePickerControllerDelegate, UINavigationControllerDelegate, LogDelegate {

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
    
    var recordedVideoURLs: [URL] = []
    let maxRecordedVideos = 5
    
    var duration: Float = 0.0
    
    var progressingView: MBProgressHUD!
    
  
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        presentVideoPicker()
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
    
    func presentVideoPicker() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("The photo library is not available.")
            return
        }

        let videoPicker = UIImagePickerController()
        videoPicker.delegate = self
        videoPicker.sourceType = .photoLibrary
        videoPicker.mediaTypes = [kUTTypeMovie as String] // Ensure import MobileCoreServices
        videoPicker.allowsEditing = true // Optional: if you allow editing

        // Customizing the navigation bar
        videoPicker.navigationBar.barTintColor = UIColor.black // Bar background
        videoPicker.navigationBar.tintColor = UIColor.white // Tint color for buttons
        videoPicker.navigationBar.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ] // Title color
        
        present(videoPicker, animated: true, completion: nil)
    }
    
    func saveRecordedVideos() {
        // Save recorded video URLs persistently
        let savedVideoStrings = self.recordedVideoURLs.map { $0.absoluteString }
        UserDefaults.standard.set(savedVideoStrings, forKey: "recordedVideos")
        print("SAVED URLS: \(savedVideoStrings)")
    }
    
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
//                self.progressBar.setProgress(progress, animated: true)
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

extension CameraViewController {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        if let videoURL = info[.mediaURL] as? URL {
            print("Selected video URL: \(videoURL)")

//            compressVideo(sourceURL: videoURL)                    // ios self compress
//            compressVideowithFFmpeg(inputURL: videoURL)             // FFmpeg compress without progress
            compressVideoWithProgress(inputURL: videoURL)           // Compress video with progress
        } else {
            print("video not found")
            return
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func compressVideoWithProgress(inputURL: URL) {
        hideButtons()
        progressingView = MBProgressHUD.showAdded(to: view, animated: true)
        progressingView.mode = .indeterminate
        progressingView.label.text = "Compressing..."
        
//        progressBar.isHidden = false

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let compressedURL = documentsDirectory.appendingPathComponent("\(UserDefaults.standard.string(forKey: "CAR_NUMBER") ?? datePresentString())_\(generateRandomString(length: 20)).mp4")

        let command = "-i \(inputURL.path) -c:v h264 -r 30 -b:v 2800k -s 1280x720 -c:a aac -b:a 128k \(compressedURL.path)"

        DispatchQueue.global(qos: .background).async {
            MobileFFmpegConfig.setLogDelegate(self)
//            let result = MobileFFmpeg.executeAsync(command, withCallback: self)
            
            let result = MobileFFmpeg.execute(command)
            
            DispatchQueue.main.async {
                if result == RETURN_CODE_SUCCESS {
                    
                    self.handleCompressedVideo(compressedURL)
                    
                } else if result == RETURN_CODE_CANCEL {
                    print("Video compressing was cancelled.")
                } else {
                    self.errorAlert(url: inputURL)
                }
            }
            
        }
    }

    func compressVideowithFFmpeg(inputURL: URL) {
        progressingView = MBProgressHUD.showAdded(to: view, animated: true)
        progressingView.mode = .indeterminate
        progressingView.label.text = "Compressing..."
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let compressedURL = documentsDirectory.appendingPathComponent("Video_\(datePresentString()).mp4")

        let videoProcessor = Compress()

        videoProcessor.compressVideo(inputVideoUrl: inputURL, outputVideoUrl: compressedURL) { [self] (status, compressedUrl, any) in
            self.progressingView.hide(animated: true)
            if status {
                handleCompressedVideo(compressedUrl)
                
            } else {
                self.errorAlert(url: inputURL)
            }
        }
    }
    
    func compressVideo(sourceURL: URL) {   // photogallery self compressing
        
        progressingView = MBProgressHUD.showAdded(to: view, animated: true)
        progressingView.mode = .indeterminate
        progressingView.label.text = "Compressing..."
        
        let asset = AVAsset(url: sourceURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: /*AVAssetExportPresetMediumQuality*/ AVAssetExportPreset1280x720) else {
            print("Cannot create export session.")
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let compressedURL = documentsDirectory.appendingPathComponent("Video_\(datePresentString()).mp4")
        
        // Delete existing file
        try? FileManager.default.removeItem(at: compressedURL)
        
        exportSession.outputURL = compressedURL
        exportSession.outputFileType = AVFileType.mp4
        exportSession.metadata = asset.metadata
//        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                self.progressingView.hide(animated: true)
                switch exportSession.status {
                    case .completed:
                        print("Video compression successful.")
                        self.handleCompressedVideo(compressedURL)
                    case .failed:
                        print("Video compression failed:", exportSession.error ?? "unknown error")
                    default:
                        break
                }
            }
        }
    }
    
    func handleCompressedVideo(_ url: URL) {
        
        print("Compressed video path: \(url.path)")
        
        UserDefaults.standard.set(dateString(date: Date()), forKey: "CREATED_TIME");
        UserDefaults.standard.set(url, forKey: "VIDEO_URL")
        
        self.performSegue(withIdentifier: "upload", sender: nil)
    }
    
    func handleLastvideos(_ url: URL) {
        self.recordedVideoURLs.append(url)
        
        // Ensure only the last 5 recorded videos are kept
        if self.recordedVideoURLs.count > self.maxRecordedVideos {
            let removeURL = self.recordedVideoURLs.removeFirst()
            try? FileManager.default.removeItem(at: removeURL)
        }
        self.saveRecordedVideos()
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
            
            self.compressVideo(sourceURL: url)
        }

        let cancelAction = UIAlertAction(title: "No", style: .cancel) { (action:UIAlertAction!) in
            print("Cancel button tapped")
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}

extension UIImagePickerController {
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.isHidden = true
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
        self.compressVideoWithProgress(inputURL: url)
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Permission to access photo library denied.")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                if success {
                    print("Video saved to photo library.")
                    self.recordedVideoURLs.append(url)
                    
                    // Ensure only the last 5 recorded videos are kept
                    if self.recordedVideoURLs.count > self.maxRecordedVideos {
                        let removeURL = self.recordedVideoURLs.removeFirst()
                        try? FileManager.default.removeItem(at: removeURL)
                        self.removeVideoFromPhotoLibrary(videoURL: removeURL)
                    }
                    self.saveRecordedVideos()
                    
                } else if let error = error {
                    print("Error saving video to photo library: \(error.localizedDescription)")
                }
            }
        }
        
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
    
    func removeVideoFromPhotoLibrary(videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            if let asset = PHAsset.fetchAssets(withALAssetURLs: [videoURL], options: nil).firstObject {
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            }
        }, completionHandler: { success, error in
            if success {
                print("Video removed successfully.")
            } else {
                print("Failed to remove video:", error?.localizedDescription ?? "Unknown error")
            }
        })
    }

    
}

//extension CameraViewController: LogDelegate {
//    func logCallback(_ executionId: Int, _ level: Int32, _ message: String) {
//        guard level == AV_LOG_INFO else { return }
//
//        print("Compress status===>: \(message)")
//
//
//        if message.starts(with: "00:") {
//            self.duration = parseDuration(message) ?? 60.0
//        }
//        if let time = parseTime(message) {
//            let progress = Float(time / duration)
//            print("progress: \(progress)==== \(duration)/\(time)")
//            DispatchQueue.main.async {
//                self.progressBar.setProgress(progress, animated: true)
//            }
//
//        }
//
//    }
//
//    private func parseDuration(_ log: String) -> Float? {
//        let durationPattern = "(\\d{2}:\\d{2}:\\d{2}.\\d{2})"
//        return extractTime(from: log, with: durationPattern)
//    }
//
//    private func parseTime(_ log: String) -> Float? {
//        let timePattern = "time=(\\d{2}:\\d{2}:\\d{2}.\\d{2})"
//        return extractTime(from: log, with: timePattern)
//    }
//
//    private func extractTime(from log: String, with pattern: String) -> Float? {
//        let regex = try? NSRegularExpression(pattern: pattern, options: [])
//        let nsString = log as NSString
//        let results = regex?.matches(in: log, options: [], range: NSRange(location: 0, length: nsString.length))
//
//        guard let match = results?.first, let range = Range(match.range(at: 1), in: log) else {
//            return nil
//        }
//
//        let timeString = String(log[range])
//        return timeString.hhmmssToSeconds()
//    }
//}

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



