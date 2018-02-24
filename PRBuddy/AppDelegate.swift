//
//  AppDelegate.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 DuckDuckGo, Inc. All rights reserved.
//

import Cocoa

/*
 
 to get pull requests:
 
 result = GET https://api.github.com/notifications
 result[].reason = "review_requested"
 
 Pull URL = result[].subject.url
 Pull Title = result[].subject.title
 
 to get pull assignee:
 
 pull = GET result.subject.url (e.g. https://api.github.com/repos/duckduckgo/Android/pulls/197)
 
 Assignee name = result.assignee.login
 Assignee avatar = result.assignee.avatar_url
 
 */

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let settings = AppSettings()
    let polling = GithubPolling()
    
    var windowController: NSWindowController!
    var item: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Main")) as? NSWindowController

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show PR Buddy", action: #selector(self.showWindowInFront), keyEquivalent: ""))
        
        item = NSStatusBar.system.statusItem(withLength: 100)
        item.menu = menu
        updateStatus()
        
        if settings.username == nil || settings.personalAccessToken == nil {
            showWindowInFront()
        } else {
            polling.pollNow()
        }
    }
    
    func updateStatus() {
        
        if polling.reviewsRequested.isEmpty {
            item.button?.title = "\(settings.noPRs) (\(polling.allPullRequests.count))"
        } else {
            item.button?.title = "\(settings.reviewRequested): \(polling.reviewsRequested.count)/\(polling.allPullRequests.count)"
        }
        
    }
    
    @objc func showWindowInFront() {
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.window?.orderFrontRegardless()
    }

    class var instance: AppDelegate {
        get {
            return NSApp.delegate as! AppDelegate
        }
    }
    
}
