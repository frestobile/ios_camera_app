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
    
    @IBOutlet weak var langSelectButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    
    @IBOutlet weak var companyLogo: UIImageView!
    
    var languageData: [Language] = []
    var filteredLang: [Language] = []
    
    var languageView = UIView()
    var showLangView: Bool = false
    
    let languages = [
        Language(id: "0", name: "English", code: "en", status: "1"),
        Language(id: "1", name: "Spanish", code: "es", status: "1"),
        Language(id: "2", name: "Finnish", code: "fi", status: "1"),
        Language(id: "3", name: "Estonian", code: "et", status: "1"),
        Language(id: "4", name: "German", code: "de", status: "1"),
        Language(id: "5", name: "Swedish", code: "sv", status: "1")
    ]
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let logoUrl = UserDefaults.standard.string(forKey: "COMPANY_LOGO")!
        let assetUrl = UserDefaults.standard.string(forKey: "ASSET_URL") ?? ASSETS_URL
        let imageURL = URL(string: assetUrl + logoUrl)!
        
        companyLogo.loadImage(fromURL: imageURL)
    }
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .languageDidChange, object: nil)
        
        nextButton.layer.cornerRadius = 5
        logoutButton.layer.cornerRadius = 5
        listButton.layer.cornerRadius = 5
        languageView.isHidden = true
        
        updateUI()

    }
    
    @objc func updateUI() {
        if let langArray = getLangFromUserDefaults() {
            languageData = langArray
        } else {
            languageData = languages
        }
        let selectedLanguageCode = LanguageManager.shared.getCurrentLanguage()
        let flagImage = UIImage(named: selectedLanguageCode)
        langSelectButton.setImage(flagImage, for: .normal)
        langSelectButton.layer.borderWidth = 1
        langSelectButton.layer.borderColor = UIColor.black.cgColor
        nextButton.setTitle(LanguageManager.shared.localizedString(for: "next"), for: .normal)
        listButton.setTitle(LanguageManager.shared.localizedString(for: "list"), for: .normal)
        logoutButton.setTitle(LanguageManager.shared.localizedString(for: "logout"), for: .normal)
        langSelectButton.setTitle("", for: .normal)
        carNumberTextField.placeholder = LanguageManager.shared.localizedString(for: "car_number")
        technicianTextField.placeholder = LanguageManager.shared.localizedString(for: "tech")
        createLanguageSelectionView()
    }
    
    func getLangFromUserDefaults() -> [Language]? {
        guard let savedData = UserDefaults.standard.data(forKey: "LANGUAGES") else {
            print("No lang data found in UserDefaults.")
            return nil
        }
        do {
            let decodedLang = try JSONDecoder().decode([Language].self, from: savedData)
            return decodedLang
        } catch {
            print("Error decoding lang data from UserDefaults: \(error)")
            return nil
        }
    }
    
    func showAlert(title: String, message: String, handler: (() -> Void)? = nil) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (alertAction) in
            handler?()
        })
        present(alert, animated: true, completion: nil)
    }

    @IBAction func logoutButtonPressed(_ sender: Any) {
        LanguageManager.shared.setLanguage("en")
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
        UserDefaults.standard.removeObject(forKey: "LANGUAGES")
        UserDefaults.standard.removeObject(forKey: "SERVER_URL")
        UserDefaults.standard.removeObject(forKey: "ASSET_URL")
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
            showAlert(title: LanguageManager.shared.localizedString(for: "error"), message: LanguageManager.shared.localizedString(for: "car_number_empty"))
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
                    self.showAlert(title: NSLocalizedString("error", comment: ""), message: response.msg)
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
                self.showAlert(title: NSLocalizedString("error", comment: ""), message: error.localizedDescription)
            }
        }
    }
    @IBAction func langSelectBtnClicked(_ sender: Any) {
        if showLangView {
            languageView.isHidden = true
            showLangView = false
        } else {
            languageView.isHidden = false
            showLangView = true
        }
        

    }
    
    func createLanguageSelectionView() {
        languageView.translatesAutoresizingMaskIntoConstraints = false
        languageView.backgroundColor = .lightGray
        languageView.layer.cornerRadius = 10
        
        // Add the languageView to the main view
        view.addSubview(languageView)
        
        // Create a vertical stack view for buttons
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill // Ensure buttons fill the stack view width
        stackView.spacing = 1
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the stackView to the languageView
        languageView.addSubview(stackView)
        
        // Constraints for the languageView (position it under the language select button and match width)
        NSLayoutConstraint.activate([
            languageView.topAnchor.constraint(equalTo: langSelectButton.bottomAnchor, constant: 2),
            languageView.centerXAnchor.constraint(equalTo: langSelectButton.centerXAnchor),
            languageView.widthAnchor.constraint(equalTo: langSelectButton.widthAnchor), // Match width
            languageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.8)
        ])
        
        // Constraints for the stackView (inside the languageView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: languageView.topAnchor, constant: 0),
            stackView.bottomAnchor.constraint(equalTo: languageView.bottomAnchor, constant: 0),
            stackView.leadingAnchor.constraint(equalTo: languageView.leadingAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: languageView.trailingAnchor, constant: 0)
        ])
        languageData.removeAll { $0.code == LanguageManager.shared.getCurrentLanguage() }
        // Add buttons for each language
        for (index, language) in languageData.enumerated() {
            let button = UIButton(type: .custom)
            let flagImage = UIImage(named: language.code)
            button.setImage(flagImage, for: .normal)
            button.tag = index // Set a tag to identify the button
            button.backgroundColor = .white
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.black.cgColor
            button.translatesAutoresizingMaskIntoConstraints = false
            
            // Add action to the button
            button.addTarget(self, action: #selector(languageButtonTapped(_:)), for: .touchUpInside)
            
            // Add button to the stack view
            stackView.addArrangedSubview(button)
        }
    }
    
    @objc func languageButtonTapped(_ sender: UIButton) {
        languageData.removeAll { $0.code == LanguageManager.shared.getCurrentLanguage() }
        let selectedLanguage = languageData[sender.tag].code
        let image = UIImage(named: selectedLanguage)
        langSelectButton.setImage(image, for: .normal)
        languageView.isHidden = true
        showLangView = false
        
        LanguageManager.shared.setLanguage(selectedLanguage)
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
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

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
