//
//  LanguageDropdownViewController.swift
//  VIService
//
//  Created by Coding Guru on 11/18/24.
//  Copyright © 2024 Polestar. All rights reserved.
//

import Foundation
import UIKit


class LanguageViewController: UIViewController {

    let languages = [
        ("en", "English", "en"),
        ("fi", "Finnish", "fi"),
        ("es", "Spanish", "es"),
        ("et", "Estonian", "et"),
        ("de", "German", "de"),
        ("sv", "Swedish", "sv")
    ]

    @IBOutlet weak var languageView: UIView!
    @IBOutlet weak var languageTitle: UILabel!
    @IBOutlet weak var languageTable: UITableView!
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(setupUI), name: .languageDidChange, object: nil)
        languageTable.dataSource = self
        languageTable.delegate = self
        languageTable.tableFooterView = UIView()
        languageView.layer.cornerRadius = 10
        languageTable.layer.cornerRadius = 10
        
        setupUI()
    }

    @IBAction func closeButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @objc func setupUI() {
        languageTitle.text = LanguageManager.shared.localizedString(for: "select_language")

    }

}

// MARK: - UITableView DataSource & Delegate
extension LanguageViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return languages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "LanguageViewCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! LanguageViewCell
        let flagImage = UIImage(named: languages[indexPath.row].0)
        cell.configureCell(with: flagImage, langName: LanguageManager.shared.localizedString(for: languages[indexPath.row].1))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        languageTable.deselectRow(at: indexPath, animated: true) // to show interaction when cell is tapped
        
        let selectedLanguageCode = languages[indexPath.row].0
        _ = languageTable.cellForRow(at: indexPath) as! LanguageViewCell

        LanguageManager.shared.setLanguage(selectedLanguageCode)
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
        
        dismiss(animated: true, completion: nil)
    }
    
    
}

//extension Notification.Name {
//    static let languageDidChange = Notification.Name("languageDidChange")
//}

