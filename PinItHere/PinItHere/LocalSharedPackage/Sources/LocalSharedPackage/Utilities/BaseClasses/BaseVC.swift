//
//  BaseVC.swift
//  EmojiCalculator
//
//  Created by YY.COUPLE on 2025-06-02.
//

import UIKit

open class BaseVC: UIViewController {
    
    required public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemGroupedBackground

    }
    
    

}

// MARK: - Init & Static data
extension BaseVC {
    class func createOwnFromNib<T: BaseVC>() -> T {
        let name = String(describing: T.self)
        assert(Bundle.main.path(forResource: name, ofType: "nib") != nil, "❌ Nib file '\(name).xib' not found.")
        
        let vc = T.init(nibName: name, bundle: nil)
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    
}
