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
    @IBOutlet weak var addressField: SkyFloatingLabelTextField!
    @IBOutlet weak var btnLogin: UIButton!
    
    
//    var connected :Int = 0
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnLogin.layer.cornerRadius = 5
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .languageDidChange, object: nil)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.delegate = self // This is not required
        self.view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        requestPermission()
        updateUI()
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
        let serverUrl = addressField.text ?? ""
        
        if deviceId.isEmpty {
            showAlert(title: LanguageManager.shared.localizedString(for: "error"), message: LanguageManager.shared.localizedString(for: "enter_devide_id"))
            return
        } else if pinPassword.isEmpty {
            showAlert(title: LanguageManager.shared.localizedString(for: "error"), message: LanguageManager.shared.localizedString(for: "enter_password"))
            return
        } else if serverUrl.isEmpty {
            showAlert(title: LanguageManager.shared.localizedString(for: "error"), message: LanguageManager.shared.localizedString(for: "server_address_error"))
            return
        }
        
        if isValidURL("https://\(serverUrl)") {
            UserDefaults.standard.set("https://\(serverUrl)/backend1", forKey: "SERVER_URL")
            UserDefaults.standard.set("https://\(serverUrl)/uploads/company_img/", forKey: "ASSET_URL")
        } else {
            showAlert(title: LanguageManager.shared.localizedString(for: "error"), message: LanguageManager.shared.localizedString(for: "url_type_error"))
            return
        }
        
        if ApiManager.isConnectedToInternet {
            login(deviceId: deviceId, password: pinPassword)
        } else {
            self.showAlert(title: LanguageManager.shared.localizedString(for: "network_error"), message: LanguageManager.shared.localizedString(for: "network_status"))
        }

    }
    
    func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              UIApplication.shared.canOpenURL(url),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme) else {
            return false
        }
        return true
    }
    
    @objc func updateUI() {
        addressField.placeholder = LanguageManager.shared.localizedString(for: "server_address")
        userField.placeholder = LanguageManager.shared.localizedString(for: "device_id")
        passwordField.placeholder = LanguageManager.shared.localizedString(for: "password")
        btnLogin.setTitle(LanguageManager.shared.localizedString(for: "login"), for: .normal)
        
    }
    
    func login(deviceId: String, password: String) {
        MBProgressHUD.showAdded(to: view, animated: true)
        
        ApiManager.shared.deviceLogin(id: deviceId, password: password) { (result) in
            MBProgressHUD.hide(for: self.view, animated: true)
            switch result {
            case .success(let response):
                if response.error {
                    self.showAlert(title: LanguageManager.shared.localizedString(for: "error"), message: response.msg)
                } else {                    
                    self.saveLangToUserDefaults(lang: response.lang)
                    UserDefaults.standard.set(response.url, forKey: "COMPANY_LOGO")
                    UserDefaults.standard.set(deviceId, forKey: "DEVICE_ID")
                    self.performSegue(withIdentifier: "next", sender: nil)
                }
            case .failure(let error):
                self.showAlert(title: LanguageManager.shared.localizedString(for: "error"), message: error.localizedDescription)
            }
        }
    }
    
    func saveLangToUserDefaults(lang: [Language]) {
        do {
            let encodedData = try JSONEncoder().encode(lang)
            UserDefaults.standard.set(encodedData, forKey: "LANGUAGES")
            print("Language data saved successfully.")
        } catch {
            print("Error saving lang data to UserDefaults: \(error)")
        }
    }
}

