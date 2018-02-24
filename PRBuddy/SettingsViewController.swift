//
//  ViewController.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 DuckDuckGo, Inc. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController {

    @IBOutlet var usernameField: NSTextField!
    @IBOutlet var personalAccessTokenField: NSTextField!
    @IBOutlet var pollingMinutesField: NSTextField!
    @IBOutlet var reviewRequestedField: NSTextField!
    @IBOutlet var noPRsField: NSTextField!
    
    @IBOutlet var validateButton: NSButton!
    @IBOutlet var validationProgress: NSProgressIndicator!

    @IBOutlet var reposOutlineView: NSOutlineView!
    @IBOutlet var removeRepoButton: NSButton!

    let settings = AppSettings()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onSettingsChanged), name: AppSettings.Notifications.changed, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onReviewsRequestedChanged), name: GithubPolling.Notifications.reviewsRequested, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onPollingStarted), name: GithubPolling.Notifications.pollingStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onPollingFinished), name: GithubPolling.Notifications.pollingFinished, object: nil)

        usernameField.stringValue = settings.username ?? ""
        personalAccessTokenField.stringValue = settings.personalAccessToken ?? ""
        pollingMinutesField.integerValue = settings.pollingTime
        reviewRequestedField.stringValue = settings.reviewRequested
        noPRsField.stringValue = settings.noPRs
        
    }
    
    @IBAction func validate(sender: Any) {
        print(#function)
        AppDelegate.instance.polling.pollNow()
    }

    @IBAction func removeRepo(sender: Any) {
        print(#function)
        settings.repos.remove(at: reposOutlineView.selectedRow)
        removeRepoButton.isEnabled = false
    }

    @objc func onReviewsRequestedChanged() {
        AppDelegate.instance.updateStatus()
    }
    
    @objc func onPollingStarted() {
        validationProgress.startAnimation(nil)
        validateButton.isEnabled = false
    }
    
    @objc func onPollingFinished() {
        validationProgress.stopAnimation(nil)
        validateButton.isEnabled = true
    }
    
    @objc func onSettingsChanged() {
        reposOutlineView.reloadData()
    }

}

extension SettingsViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return item == nil ? settings.repos.count : 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return settings.repos[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        print(#function, item)
        return false
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        removeRepoButton.isEnabled = reposOutlineView.selectedRow != -1
    }
    
}

extension SettingsViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        print(#function, item)
        let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("DataCell"), owner: self) as? NSTableCellView
        if let textField = view?.textField {
            textField.stringValue = item as! String
        }
        return view
    }
    
}

extension SettingsViewController: NSTextFieldDelegate {
    
    override func controlTextDidChange(_ obj: Notification) {
        
        settings.username = usernameField.stringValue
        settings.personalAccessToken = personalAccessTokenField.stringValue
        settings.noPRs = noPRsField.stringValue
        settings.reviewRequested = reviewRequestedField.stringValue
        settings.pollingTime = pollingMinutesField.integerValue
        
    }
    
}

class SingleCharFormatter: Formatter {
    
    override func string(for obj: Any?) -> String? {
        return obj as? String
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if string.count == 1 {
            obj?.pointee = string as AnyObject
        } else {
            error?.pointee = "Single character required" as NSString
        }
        return string.count == 1
    }
    
}
