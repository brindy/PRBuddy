//
//  ViewController.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 Chris Brind. All rights reserved.
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

    @IBOutlet var validationGoodLabel: NSTextField!
    
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
        validationGoodLabel.stringValue = ""
        AppDelegate.instance.polling.pollNow()
        AppDelegate.instance.updateStatus()
    }

    @IBAction func removeRepo(sender: Any) {
        print(#function)
        settings.repos.remove(at: reposOutlineView.selectedRow)
        removeRepoButton.isEnabled = false
        AppDelegate.instance.polling.pollNow()
    }

    @IBAction func openPersonalAccessTokenPage(sender: Any) {
        print(#function)
        NSWorkspace.shared.open(URL(string: "https://github.com/settings/tokens")!)
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
        
        if let error = AppDelegate.instance.polling.error,
            let window = AppDelegate.instance.windowController.window {
            
            if !window.isVisible {
                AppDelegate.instance.showWindowInFront()
            }
            
            if presentedViewControllers?.isEmpty ?? true {
                let alert = NSAlert()
                alert.informativeText = "\(error)\nCheck your username and personal access token, then try again."
                alert.beginSheetModal(for: window)
            }
            
            validationGoodLabel.stringValue = "☹️"
        } else {
            validationGoodLabel.stringValue = "🙂"
        }
        
    }
    
    @objc func onSettingsChanged() {
        reposOutlineView.reloadData()
    }
    
    func showAbout() {
        guard presentedViewControllers?.isEmpty ?? true else { return }
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("about"), sender: self)
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
        return false
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        removeRepoButton.isEnabled = reposOutlineView.selectedRow != -1
    }
    
}

extension SettingsViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
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
        validationGoodLabel.stringValue = ""
        
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
