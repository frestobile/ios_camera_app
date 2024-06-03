//
//  LoginViewController.swift
//  VIService
//
//  Created by Frestobile on 10/12/19.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import Network
import MBProgressHUD
import SkyFloatingLabelTextField
import AVFoundation
import Photos

class LoginViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var userField: SkyFloatingLabelTextField!
    @IBOutlet weak var passwordField: SkyFloatingLabelTextField!
    @IBOutlet weak var btnLogin: UIButton!
    
    var inactivityTimer: Timer?
    var originalBrightness: CGFloat = UIScreen.main.brightness
    
//    var connected :Int = 0
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startInactivityTimer()
        btnLogin.layer.cornerRadius = 5
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.delegate = self // This is not required
        self.view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        requestPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillAppear() {
        //Do something here
        if self.view.frame.origin.y == 0 {
            self.view.frame.origin.y -= 32
        }

    }

    @objc func keyboardWillDisappear() {
        //Do something here
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc fileprivate func dismissKeyboard(sender:UITapGestureRecognizer){
        self.view.endEditing(true)
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                // Permission granted, you can access the camera
                print("Camera access granted")
            } else {
                // Permission denied, handle accordingly
                print("Camera access denied")
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

    @IBAction func onLogin(_ sender: Any) {
        
        let deviceId = userField.text ?? ""
        let pinPassword = passwordField.text ?? ""
        
        if deviceId.isEmpty {
            showAlert(title: "Error", message: "Please enter device id.")
            return
        } else if pinPassword.isEmpty {
            showAlert(title: "Error", message: "Please enter pin password.")
            return
        }

        if ApiManager.isConnectedToInternet {
            login(deviceId: deviceId, password: pinPassword)
        } else {
            self.showAlert(title: "Network Error", message: "You are not connected in Network.  Please check out the network status.")
        }

    }
    
    func login(deviceId: String, password: String) {
        MBProgressHUD.showAdded(to: view, animated: true)
        
        ApiManager.shared.deviceLogin(id: deviceId, password: password) { (result) in
            MBProgressHUD.hide(for: self.view, animated: true)
            switch result {
            case .success(let response):
                if response.error {
                    self.showAlert(title: "Error", message: response.msg)
                } else {
                    UserDefaults.standard.set(response.url, forKey: "COMPANY_LOGO")
                    UserDefaults.standard.set(deviceId, forKey: "DEVICE_ID")
                    self.performSegue(withIdentifier: "next", sender: nil)
                }
            case .failure(let error):
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
}

extension LoginViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        resetInactivityTimer()
                restoreBrightness()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        resetInactivityTimer()
                restoreBrightness()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        resetInactivityTimer()
                restoreBrightness()
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        resetInactivityTimer()
                restoreBrightness()
    }
    
    private func startInactivityTimer() {
        stopInactivityTimer()
        inactivityTimer = Timer.scheduledTimer(timeInterval: 600, target: self, selector: #selector(dimScreen), userInfo: nil, repeats: false)
        
    }
    
    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
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

