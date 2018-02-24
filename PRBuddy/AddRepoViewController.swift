//
//  AddRepoViewController.swift
//  PRBuddy
//
//  Created by Chris Brind on 24/02/2018.
//  Copyright © 2018 DuckDuckGo, Inc. All rights reserved.
//

import Cocoa

class AddRepoViewController: NSViewController {
    
    @IBOutlet var repoField: NSTextField!
    @IBOutlet var addButton: NSButton!

    let settings = AppSettings()
    
    @IBAction func addRepo(sender: Any) {
        print(#function)
        settings.repos.append(repoField.stringValue)
        dismiss(self)
    }
    
}

extension AddRepoViewController: NSTextFieldDelegate {
    
    override func controlTextDidChange(_ obj: Notification) {
        addButton.isEnabled = !repoField.stringValue.isEmpty && repoField.stringValue.contains("/")
    }
    
}
