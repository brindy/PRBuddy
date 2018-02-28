//
//  AboutViewController.swift
//  PRBuddy
//
//  Created by Chris Brind on 28/02/2018.
//  Copyright © 2018 Chris Brind. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {
    
    @IBOutlet weak var versionLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let buildVersion = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        versionLabel.stringValue = "v\(appVersion) - build \(buildVersion)"
    }
        
    @IBAction func showProject(sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://github.com/brindy/PRBuddy")!)
    }
    
}
