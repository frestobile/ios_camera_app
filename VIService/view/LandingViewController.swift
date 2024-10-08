//
//  LandingViewController.swift
//  VIService
//
//  Created by Frestobile on 2/26/20.
//  Copyright © 2020 Star. All rights reserved.
//

import UIKit
import Network
import MBProgressHUD

class LandingViewController: UIViewController {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if UserDefaults.standard.string(forKey: "DEVICE_ID") == nil {
            performSegue(withIdentifier: "login", sender: nil)
        } else {
            print("Network Status: \(ApiManager.isConnectedToInternet)")
            if ApiManager.isConnectedToInternet {
                deviceCheck()
            } else {
                showErrorAlert(title: "Network Error", message: "You are not connected in Network. Please check out the network status.")
            }
           
        }
    }
    
    func deviceCheck() {
        
        MBProgressHUD.showAdded(to: view, animated: true)
        let deviceId = UserDefaults.standard.string(forKey: "DEVICE_ID")
        ApiManager.shared.device_check(deviceId: deviceId!) { (result) in
            MBProgressHUD.hide(for: self.view, animated: true)
            
            switch result {
                case .success(let response):
                    if response.error {
                        self.showErrorAlert(title: "Error", message: response.msg)
                        UserDefaults.standard.removeObject(forKey: "DEVICE_ID")
                        self.performSegue(withIdentifier: "login", sender: nil)
                    } else {
//                        UserDefaults.standard.set(response.url, forKey: "COMPANY_LOGO")
                        UserDefaults.standard.set(deviceId, forKey: "DEVICE_ID")
                        self.performSegue(withIdentifier: "carnumber", sender: nil)
                    }
                case .failure(let error):
                    self.showErrorAlert(title: "Error", message: error.localizedDescription)
                }
            }
    }
    
    
    func showErrorAlert(title: String, message: String) {
        
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Try Again", style: .default) { (action:UIAlertAction!) in
            self.deviceCheck()
        }
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

}
