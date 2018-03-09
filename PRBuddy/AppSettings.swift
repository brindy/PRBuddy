//
//  AppSettings.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 Chris Brind. All rights reserved.
//

import Foundation

class AppSettings {
    
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
    
    var repos: [String] {
        get {
            return userDefaults.array(forKey: Keys.repos) as? [String] ?? []
        }
        set {
            let set = Set<String>(newValue)
            let array = Array<String>(set)
            userDefaults.set(array, forKey: Keys.repos)
        }
    }
    
    // Call #startAccessingSecurityScopedResource before and #stopAccessingSecurityScopedResource after using this URL
    var checkoutDir: URL? {
        get {
            guard let data = userDefaults.data(forKey: Keys.checkoutDir) else { return nil}
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { return nil }
            return url
        }
        set {
            let data = try? newValue?.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            userDefaults.set(data as Any, forKey: Keys.checkoutDir)
        }
    }

    // Call #startAccessingSecurityScopedResource before and #stopAccessingSecurityScopedResource after using this URL
    var xcodePath: URL? {
        get {
            guard let data = userDefaults.data(forKey: Keys.xcodePath) else { return nil}
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale) else { return nil }
            // guard url?.startAccessingSecurityScopedResource() ?? false else { return nil }
            return url
        }
        set {
            let data = try? newValue?.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            userDefaults.set(data as Any, forKey: Keys.xcodePath)
        }
    }

}
