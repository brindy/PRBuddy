//
//  AppDelegate.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 Chris Brind. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let settings = AppSettings()
    let polling = GithubPolling()
    
    var windowController: NSWindowController!
    var item: NSStatusItem!
    
    var lastProgress: Git.Progress?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Main")) as? NSWindowController


        item = NSStatusBar.system.statusItem(withLength: 100)
        buildMenu()
        updateStatus()
        
        if settings.username == nil || settings.personalAccessToken == nil || settings.repos.isEmpty || settings.checkoutDir == nil {
            showWindowInFront()
        } else {
            polling.pollNow()
        }
    }
    
    func updateStatus() {
        buildMenu()
        resetStatus()
        if !polling.reviewsRequested.isEmpty {
            item.button?.title = "\(settings.reviewRequested): \(polling.reviewsRequested.count)/\(polling.allPullRequests.count)"
        }
    }

    func resetStatus() {
        item.button?.title = "\(settings.noPRs) (\(polling.allPullRequests.count))"
    }
    
    func buildMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "About PRBuddy", action: #selector(self.aboutPRBuddy), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Check now", action: #selector(self.checkNow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        if polling.allPullRequests.count > 0 {
            let requested = polling.allPullRequests.filter({ $0.requested_reviewers.contains(where: { $0.login == settings.username }) })
            let others = polling.allPullRequests.subtracting(requested)
            for pr in requested.sorted(by: { $0.repoName < $1.repoName }) {
                menu.addItem(createPRMenuItem(pr: pr, requested: true))
            }
            for pr in others.sorted(by: { $0.repoName < $1.repoName }) {
                 menu.addItem(createPRMenuItem(pr: pr, requested: false))
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
    
    @objc func checkNow(sender: Any) {
        print(#function, sender)
        resetStatus()
        polling.stop()
        polling.start()
        polling.pollNow()
    }

    @objc func checkoutPullRequest(sender: PullRequestMenuItem) {
        print(#function, sender)
        
        guard let xcodePath = settings.xcodePath else { return }
        guard let checkoutDir = settings.checkoutDir else { return }

        guard xcodePath.startAccessingSecurityScopedResource() else { return }
        guard checkoutDir.startAccessingSecurityScopedResource() else {
            xcodePath.stopAccessingSecurityScopedResource()
            return
        }

        let tmpCheckoutDir = NSURL.fileURL(withPathComponents: [String(checkoutDir.absoluteString.dropFirst("file://".count)),  UUID.init().uuidString])!
        try? FileManager.default.createDirectory(at: tmpCheckoutDir, withIntermediateDirectories: true, attributes: [:])
        
        let branchName = sender.pr.head.ref
        let projectName = sender.pr.base.repo.name

        polling.stop()
        updateBuildingStatus(progress: 0.0)
        
        Git(xcodePath: xcodePath, checkoutDir: tmpCheckoutDir, project: projectName)
            .clone(url: sender.pr.base.repo.clone_url)
            .fetch(from: "origin")
            .checkout(branch: branchName, from: "origin/\(branchName)")
            .merge(branch: "develop").start { progress in
        
                let startTimer = self.lastProgress == nil
                self.lastProgress = progress
                
                if startTimer {
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                        if self.lastProgress?.finished ?? true {
                            timer.invalidate()
                            return
                        }
                        self.updateBuildingStatus(progress: self.lastProgress?.progress ?? 0.0)
                    }
                }
                
                DispatchQueue.main.async {
                    guard progress.finished else { return }
                    self.lastProgress = nil
                    self.resetStatus()
                    self.polling.pollNow()
                    self.polling.start()
                    
                    let projectDir = tmpCheckoutDir.appendingPathComponent(projectName)
                    let openResult = NSWorkspace.shared.open(projectDir)
                    print(#function, projectDir, openResult)
                    
                    xcodePath.stopAccessingSecurityScopedResource()
                    checkoutDir.stopAccessingSecurityScopedResource()
                }
        }
        
        
    }

    @objc func ignorePullRequest(sender: PullRequestMenuItem) {
        print(#function, sender)
        // TODO keep track of requests we're not interested in
    }

    @objc func aboutPRBuddy() {
        showWindowInFront()
        guard let controller = windowController.contentViewController as? SettingsViewController else { return }
        controller.showAbout()
    }

    private func updateBuildingStatus(progress: Double) {
        let percent = Int(progress * 100)
        var lifter = " 🏋️‍♀️"
        if item.button?.title.starts(with: " ") ?? false {
            lifter = "🏋️‍♀️ "
        }
        item.button?.title = "\(lifter)\(percent)%"
    }
    
    private func createPRMenuItem(pr: GithubPolling.GithubPullRequest, requested: Bool) -> PullRequestMenuItem {
        let title = "\(requested ? settings.reviewRequested : "")\(pr.repoName): \(pr.title)"
        let menuItem = PullRequestMenuItem(title: title, action: #selector(self.openPullRequestURL), pr: pr)
        menuItem.submenu = NSMenu(title: "Actions")
        menuItem.submenu?.addItem(PullRequestMenuItem(title: "Open in Browser", action: #selector(self.openPullRequestURL), pr: pr))
        menuItem.submenu?.addItem(PullRequestMenuItem(title: "Checkout...", action: #selector(self.checkoutPullRequest), pr: pr))
        
        if requested {
            menuItem.submenu?.addItem(PullRequestMenuItem(title: "Ignore", action: #selector(self.ignorePullRequest), pr: pr))
        }
        
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

extension GithubPolling.GithubPullRequest {
    
    var repoName: String {
        return url.components(separatedBy: "/")[4...5].joined(separator: "/").lowercased()
    }
    
}




