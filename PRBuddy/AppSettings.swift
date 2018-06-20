//
//  AppSettings.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 Chris Brind. All rights reserved.
//

import Foundation

class AppSettings {
    
    struct Repo {
        
        let githubPath: String
        let postCheckoutCommand: String
        let checkoutFolder: URL?
        
    }
    
    struct Defaults {
        
        static let assigned = "✍️"
        static let reviewRequested = "👋"
        static let noPRs = "💤"
        static let pollingTime = 1
        
    }
    
    struct Keys {
        
        static let username = "username"
        static let personalAccessToken = "personalAccessToken"
        static let reviewRequested = "reviewRequested"
        static let noPRs = "noPRs"
        static let assigned = "assigned"
        static let pollingTime = "pollingTime"
        static let repos = "repos"
        static let repoCommand = "command"
        static let repoCheckoutFolder = "checkoutFolder"
        static let checkoutDir = "checkoutDir"
        static let xcodePath = "xcodePath"
        static let launchTerminal = "launchTerminal"
        
    }
    
    private var userDefaults: UserDefaults = UserDefaults.standard
    
    var reviewRequested: String {
        get {
            return userDefaults.string(forKey: Keys.reviewRequested) ?? Defaults.reviewRequested
        }
        set {
            userDefaults.set(newValue, forKey: Keys.reviewRequested)
        }
    }

    var assigned: String {
        get {
            return userDefaults.string(forKey: Keys.assigned) ?? Defaults.assigned
        }
        set {
            userDefaults.set(newValue, forKey: Keys.assigned)
        }
    }

    var noPRs: String {
        get {
            return userDefaults.string(forKey: Keys.noPRs) ?? Defaults.noPRs
        }
        set {
            userDefaults.set(newValue, forKey: Keys.noPRs)
        }
    }
    
    var pollingTime: Int {
        get {
            return userDefaults.object(forKey: Keys.pollingTime) != nil ? userDefaults.integer(forKey: Keys.pollingTime) : Defaults.pollingTime
        }
        set {
            userDefaults.set(newValue, forKey: Keys.pollingTime)
        }
    }
    
    var username: String? {
        get {
            return userDefaults.string(forKey: Keys.username)
        }
        set {
            userDefaults.set(newValue == "" ? nil : newValue, forKey: Keys.username)
        }
    }
    
    var personalAccessToken: String? {
        get {
            return userDefaults.string(forKey: Keys.personalAccessToken)
        }
        set {
            userDefaults.set(newValue == "" ? nil : newValue, forKey: Keys.personalAccessToken)
        }
    }
    
    var launchTerminal: Bool {
        get {
            return userDefaults.bool(forKey: Keys.launchTerminal)
        }
        
        set {
            userDefaults.set(newValue, forKey: Keys.launchTerminal)
        }
    }
    
    var repos: [Repo] {
        get {
            guard let repoPaths = userDefaults.array(forKey: Keys.repos) as? [String] else { return [] }
            
            var repos = [Repo]()
            for repoPath in repoPaths {
                
                repos.append(Repo(githubPath: repoPath,
                                  postCheckoutCommand: userDefaults.string(forKey: repoPath.commandKey) ?? "",
                                  checkoutFolder: userDefaults.secureUrl(forKey: repoPath.checkoutFolderKey)))

            }
            
            return repos.sorted(by: { $0.githubPath > $1.githubPath })
        }
        set {
            
            if let oldRepoPaths = userDefaults.array(forKey: Keys.repos) as? [String] {
                for repoPath in oldRepoPaths {
                    userDefaults.removeObject(forKey: repoPath.commandKey)
                    userDefaults.removeObject(forKey: repoPath.checkoutFolderKey)
                }
            }
            
            var repoPaths = [String]()
            for repo in newValue {
                let repoPath = repo.githubPath
                repoPaths.append(repoPath)
                userDefaults.set(repo.postCheckoutCommand, forKey: repoPath.commandKey)
                userDefaults.set(repo.checkoutFolder, forKey: repoPath.checkoutFolderKey)
            }
            userDefaults.set(repoPaths, forKey: Keys.repos)
            
        }
    }
    
    // Call #startAccessingSecurityScopedResource before and #stopAccessingSecurityScopedResource after using this URL
    var checkoutDir: URL? {
        get {
            return userDefaults.secureUrl(forKey: Keys.checkoutDir)
        }
        set {
            userDefaults.set(secureUrl: newValue, forKey: Keys.checkoutDir)
        }
    }

    // Call #startAccessingSecurityScopedResource before and #stopAccessingSecurityScopedResource after using this URL
    var xcodePath: URL? {
        get {
            let url = userDefaults.secureUrl(forKey: Keys.xcodePath)
            print(#function, url)
            return url
        }
        set {
            userDefaults.set(secureUrl: newValue, forKey: Keys.xcodePath)
        }
    }
    
}

fileprivate extension String {
    
    var commandKey: String {
        return "\(AppSettings.Keys.repos).\(self).\(AppSettings.Keys.repoCommand)"
    }
    
    var checkoutFolderKey: String {
        return "\(AppSettings.Keys.repos).\(self).\(AppSettings.Keys.repoCheckoutFolder)"
    }
    
}

fileprivate extension UserDefaults {
    
    func secureUrl(forKey key: String) -> URL? {
        guard let data = data(forKey: key) else { return nil}
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { return nil }
        return isStale ? nil : url
    }
    
    func set(secureUrl url: URL?, forKey key: String) {
        let data = try? url?.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        set(data as Any, forKey: key)
    }
    
}

