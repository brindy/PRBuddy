//
//  Git.swift
//  PRBuddy
//
//  Created by Chris Brind on 28/02/2018.
//  Copyright © 2018 DuckDuckGo, Inc. All rights reserved.
//

import Foundation
import os.log

class Git {
    
    struct Progress {
        
        let command: String?
        let exitStatus: Int32?
        let description: String
        let finished: Bool
        
    }
    
    private struct Command {
        
        let dir: String
        let arguments: [String]
        let description: String
        
    }
    
    private var commands = [Command]()
    
    let xcodePath: URL
    let checkoutDir: URL
    let project: String

    static func validPath(xcodePath: URL) -> Bool {
        return FileManager.default.fileExists(atPath: xcodePath.git)
    }
    
    init(xcodePath: URL, checkoutDir: URL, project: String) {
        self.xcodePath = xcodePath
        self.checkoutDir = checkoutDir
        self.project = project
    }
    
    var checkoutPath: String {
        return String(checkoutDir.absoluteString.dropFirst("file://".count))
    }
    
    var projectPath: String {
        return "\(checkoutPath)/\(project)"
    }
    
    func clone(url: String) -> Git {
        commands.append(Command(dir: checkoutPath, arguments: [ "clone",  "--recursive", url ], description: "Cloning"))
        return self
    }
    
    func fetch(fromRepo repo: String, withRef ref: String) -> Git {
        commands.append(Command(dir: projectPath, arguments: [ "fetch",  repo, ref ], description: "Fetching"))
        return self
    }
    
    func checkout(branch: String, fromRef ref: String) -> Git {
        commands.append(Command(dir: projectPath, arguments: [ "checkout",  "-b", branch, ref ], description: "Checking out"))
        return self
    }

    func merge(branch localBranch: String) -> Git {
        commands.append(Command(dir: projectPath, arguments: [ "merge",  localBranch ], description: "Merging"))
        return self
    }
    
    func pull(repoUrl: String, branch: String) -> Git {
        commands.append(Command(dir: projectPath, arguments: [ "pull",  repoUrl, branch, "--squash" ], description: "Pulling"))
        return self
    }
    
    func start(withProgressHandler handler: @escaping (Progress) -> ()) {
        os_log("Git START")
        next(progressHandler: handler)
    }
    
    private func next(progressHandler: @escaping (Progress) -> ()) {
        guard let command = commands.first else {
            progressHandler(Progress(command: nil, exitStatus: nil, description: "Done", finished: true))
            os_log("Git END")
            return
        }
        
        commands.remove(at: 0)
        
        let commandString = command.arguments.joined(separator: " ")
        progressHandler(Progress(command: commandString, exitStatus: nil, description: command.description, finished: false))

        execute(command: command) { exitStatus, error in
            
            guard exitStatus == 0 else {
                progressHandler(Progress(command: nil, exitStatus: exitStatus, description: "Error running command\n\ngit \(command.arguments.joined(separator: " "))\n\n\(error ?? "<unknown error>")", finished: true))
                os_log("Git END, error %d", exitStatus)
                return
            }
            
            self.next(progressHandler: progressHandler)
        }
        
    }
    
    private func execute(command: Command, completion: @escaping (Int32, String?) -> ()) {
        var lastLine: String?

        let errPipe = Pipe()

        let process = Process()
        process.launchPath = xcodePath.git
        process.arguments = ["-C", command.dir ] + command.arguments
        process.standardError = errPipe
        process.terminationHandler = { process in
            
            let outdata = errPipe.fileHandleForReading.readDataToEndOfFile()
            if var string = String(data: outdata, encoding: .utf8) {
                string = string.trimmingCharacters(in: .newlines)
                for line in string.components(separatedBy: "\n") {
                    lastLine = line
                }
            }
            
            completion(process.terminationStatus, lastLine)
        }
        
        os_log("> %@ %@", process.launchPath!, process.arguments!.joined(separator: " "))
        do {
            try process.run()
        } catch {
            print(error)
            completion(-1, "Failed to run command")
        }
        
    }
    
}

fileprivate extension URL {
    
    static let gitExecutable = "Contents/Developer/usr/bin/git"
    
    var git: String {
        let gitPath = String(absoluteString.dropFirst("file://".count))
        return "\(gitPath)/\(URL.gitExecutable)"
    }
    
}

