//
//  AppDelegate.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 DuckDuckGo, Inc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let settings = AppSettings()
    let polling = GithubPolling()
    
    var windowController: NSWindowController!
    var item: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Main")) as? NSWindowController


        item = NSStatusBar.system.statusItem(withLength: 100)
        buildMenu()
        updateStatus()
        
        if settings.username == nil || settings.personalAccessToken == nil {
            showWindowInFront()
        } else {
            polling.pollNow()
        }
    }
    
    func updateStatus() {
        
        buildMenu()
        if polling.reviewsRequested.isEmpty {
            item.button?.title = "\(settings.noPRs) (\(polling.allPullRequests.count))"
        } else {
            item.button?.title = "\(settings.reviewRequested): \(polling.reviewsRequested.count)/\(polling.allPullRequests.count)"
        }
        
    }
    
    func buildMenu() {
        let menu = NSMenu()
        if polling.allPullRequests.count > 0 {
            
            let requested = polling.allPullRequests.filter({ $0.requested_reviewers.contains(where: { $0.login == settings.username }) })
            let others = polling.allPullRequests.subtracting(requested)
            
            for pr in requested {
                menu.addItem(createPRMenuItem(pr: pr, icon: "\(settings.reviewRequested) "))
            }

            for pr in others {
                 menu.addItem(createPRMenuItem(pr: pr, icon: ""))
            }

            menu.addItem(NSMenuItem.separator())
        }
        
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(self.showWindowInFront), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(self.quit), keyEquivalent: ""))
        item.menu = menu
    }
    
    @objc func showWindowInFront() {
        windowController.showWindow(nil)
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.window?.orderFrontRegardless()
    }

    @objc func quit() {
        NSApp.terminate(self)
    }
    
    @objc func openPullRequestURL(sender: PullRequestMenuItem) {
        print(#function, sender)
        NSWorkspace.shared.open(URL(string: sender.pr.html_url)!)
    }

    @objc func checkoutPullRequest(sender: PullRequestMenuItem) {
        print(#function, sender)
        // TODO checkout base
        // TODO merge head
        // TODO open terminal at that location
    }

    private func createPRMenuItem(pr: GithubPolling.GithubPullRequest, icon: String) -> PullRequestMenuItem {
        let title = "\(icon)\(pr.repo): \(pr.title)"
        let menuItem = PullRequestMenuItem(title: title, action: #selector(self.openPullRequestURL), pr: pr)
        menuItem.submenu = NSMenu(title: "Actions")
        menuItem.submenu?.addItem(PullRequestMenuItem(title: "Checkout...", action: #selector(self.checkoutPullRequest), pr: pr))
        return menuItem
    }
    
    class var instance: AppDelegate {
        get {
            return NSApp.delegate as! AppDelegate
        }
    }
    
}

class PullRequestMenuItem: NSMenuItem {
    
    var pr: GithubPolling.GithubPullRequest!
    
    init(title string: String, action selector: Selector?, pr: GithubPolling.GithubPullRequest) {
        self.pr = pr
        super.init(title: string, action: selector, keyEquivalent: "")
    }
    
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
}




