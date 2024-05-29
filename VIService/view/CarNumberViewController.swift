//
//  CarNumberViewController.swift
//  VIService
//
//  Created by Frestobile on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import MBProgressHUD
import SkyFloatingLabelTextField
import MediaPlayer

class CarNumberViewController: UIViewController {

 
    @IBOutlet weak var carNumberTextField: SkyFloatingLabelTextField!
    @IBOutlet weak var technicianTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBOutlet weak var companyLogo: UIImageView!
    
    var inactivityTimer: Timer?
    var originalBrightness: CGFloat = UIScreen.main.brightness

    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let logoUrl = UserDefaults.standard.string(forKey: "COMPANY_LOGO")!
        let imageURL = URL(string: ASSETS_URL + logoUrl)!
        
        companyLogo.loadImage(fromURL: imageURL)
    }
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
//        startInactivityTimer()
        
        nextButton.layer.cornerRadius = 5
        logoutButton.layer.cornerRadius = 5
        listButton.layer.cornerRadius = 5

    }
    
    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }

    @IBAction func logoutButtonPressed(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "COMPANY_LOGO")
        UserDefaults.standard.removeObject(forKey: "DEVICE_ID")
        performSegue(withIdentifier: "login", sender: nil)
    }
    
    @IBAction func listButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "list", sender: nil)
    }
    @IBAction func nextButtonPressed(_ sender: Any) {
        let deviceId = UserDefaults.standard.string(forKey: "DEVICE_ID") ?? ""
        let carNumber = carNumberTextField.text ?? ""
        let technician = technicianTextField.text ?? ""
        
        if carNumber.isEmpty {
            showAlert(title: "Error", message: "Please enter car number.")
            return
        }
//        else if technician.isEmpty {
//            showAlert(title: "Error", message: "Please enter technician.")
//            return
//        }
        self.nextStep(deviceId: deviceId, carNumber: carNumber, technician: technician)
    }
    
    func nextStep(deviceId: String, carNumber: String, technician: String) {
        MBProgressHUD.showAdded(to: view, animated: true)
        
        ApiManager.shared.videoCheck(deviceId: deviceId, carNumber: carNumber) { (result) in
            MBProgressHUD.hide(for: self.view, animated: true)
            
            switch result {
            case .success(let response):
                if response.error {
                    self.showAlert(title: "Error", message: response.msg)
                } else {
                    UserDefaults.standard.set(carNumber, forKey: "CAR_NUMBER")
                    if technician.isEmpty {
                        UserDefaults.standard.set("", forKey: "TECHNICIAN")
                    }
                    else {
                        UserDefaults.standard.set(technician, forKey: "TECHNICIAN")
                    }
                    self.performSegue(withIdentifier: "recording", sender: nil)
                }
            case .failure(let error):
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
}

extension UIImageView {
    func loadImage(fromURL url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let imageData = try? Data(contentsOf: url) {
                if let image = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        // Need to use the MPVolumeView in order to change volume, but don't care about UI set so frame to .zero
        let volumeView = MPVolumeView()
        let screenSize: CGRect = UIScreen.main.bounds
        volumeView.frame = CGRect( x: 0, y: screenSize.height/2, width: volumeView.frame.size.width, height: volumeView.frame.size.height )
        // Search for the slider
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        // Update the slider value with the desired volume.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
        // Optional - Remove the HUD
        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
            volumeView.alpha = 0.9
            window.addSubview(volumeView)
        }
    }
    
}

extension CarNumberViewController {
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
