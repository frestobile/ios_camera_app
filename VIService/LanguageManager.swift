
import Foundation
class LanguageManager {
    static let shared = LanguageManager()
    private init() {}
    
    var bundle: Bundle?

    func setLanguage(_ code: String) {
        UserDefaults.standard.set(code, forKey: "appLanguage")
        UserDefaults.standard.synchronize()

        if let path = Bundle.main.path(forResource: code, ofType: "lproj") {
            bundle = Bundle(path: path)
        } else {
            bundle = Bundle.main
        }
        Bundle.setLanguageBundle(bundle!)
    }
    
    
    func localizedString(for key: String, comment: String = "") -> String {
        return bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }

    func loadSavedLanguage() {
        let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en" // Default to English
        setLanguage(savedLanguage)
    }
    
    func getCurrentLanguage() -> String {
        return UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    }

}

private var bundleKey: UInt8 = 0

extension Bundle {
    static let once: Void = {
        if let path = Bundle.main.path(forResource: UserDefaults.standard.string(forKey: "appLanguage"), ofType: "lproj") {
            object_setClass(Bundle(path: path), PrivateBundle.self)
        } else {
            object_setClass(Bundle.main, PrivateBundle.self)
        }
        
    }()

    static func setLanguageBundle(_ bundle: Bundle) {
        Bundle.once
        objc_setAssociatedObject(bundle, &bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

private class PrivateBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let bundle = objc_getAssociatedObject(Bundle.main, &bundleKey) as? Bundle
        return bundle?.localizedString(forKey: key, value: value, table: tableName) ?? super.localizedString(forKey: key, value: value, table: tableName)
    }
}
