//
//  AntigravityProcessManager.swift
//  Quotio
//
//  Manages Antigravity IDE process lifecycle for account switching.
//  Handles detection, graceful termination, and restart.
//

import Foundation
import AppKit
import OSLog

private let logger = Logger(subsystem: "proseek.io.vn.Quotio", category: "AntigravityProcessManager")

/// Manages Antigravity IDE process lifecycle
@MainActor
final class AntigravityProcessManager {
    
    // MARK: - Constants
    
    private static let bundleIdentifiers = [
        "com.google.antigravity",
        "com.todesktop.230313mzl4w4u92"
    ]
    private static let appName = "Antigravity"
    private static let terminationTimeout: TimeInterval = 20.0
    private static let forceKillTimeout: TimeInterval = 3.0
    
    // MARK: - Singleton
    
    static let shared = AntigravityProcessManager()
    private init() {}
    
    // MARK: - Process Detection
    
    func isRunning() -> Bool {
        !runningInstances().isEmpty
    }
    
    private func runningInstances() -> [NSRunningApplication] {
        var instances: [NSRunningApplication] = []
        for bundleId in Self.bundleIdentifiers {
            instances.append(contentsOf: NSRunningApplication.runningApplications(withBundleIdentifier: bundleId))
        }
        return instances
    }
    
    // MARK: - Process Control
    
    @discardableResult
    func terminate() async -> Bool {
        let apps = runningInstances()
        guard !apps.isEmpty else { return true }
        
        for app in apps {
            app.terminate()
        }
        
        let gracefullyTerminated = await waitForTermination(timeout: Self.terminationTimeout)
        
        if gracefullyTerminated {
            await killHelperProcesses()
            return true
        }
        
        for app in apps {
            app.forceTerminate()
        }
        
        _ = await waitForTermination(timeout: Self.forceKillTimeout)
        
        await killHelperProcesses()
        
        return false
    }
    
    /// Terminate Antigravity and any helper processes, even if the main app is not running
    @discardableResult
    func terminateAllProcesses() async -> Bool {
        logger.debug("Terminating all Antigravity processes")
        let terminated = await terminate()
        await killHelperProcesses()
        return terminated
    }
    
    /// Check if any Antigravity helper processes are still running
    private func areHelperProcessesRunning() -> Bool {
        let pgrep = Process()
        pgrep.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        pgrep.arguments = ["-f", "Antigravity Helper"]
        pgrep.standardOutput = FileHandle.nullDevice
        pgrep.standardError = FileHandle.nullDevice
        
        do {
            try pgrep.run()
            pgrep.waitUntilExit()
            return pgrep.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    /// Wait for all Antigravity processes (main app + helpers) to fully terminate
    func waitForAllProcessesDead(timeout: TimeInterval) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            let mainRunning = isRunning()
            let helpersRunning = areHelperProcessesRunning()
            
            if !mainRunning && !helpersRunning {
                return true
            }
            
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
        
        return false
    }
    
    private func killHelperProcesses() async {
        let helperPatterns = [
            "Antigravity Helper",
            "Antigravity Helper (GPU)",
            "Antigravity Helper (Plugin)",
            "Antigravity Helper (Renderer)"
        ]
        
        for pattern in helperPatterns {
            let killall = Process()
            killall.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            killall.arguments = ["-9", pattern]
            killall.standardOutput = FileHandle.nullDevice
            killall.standardError = FileHandle.nullDevice
            try? killall.run()
            killall.waitUntilExit()
        }
        
        let pkill = Process()
        pkill.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        pkill.arguments = ["-9", "-f", "Antigravity Helper"]
        pkill.standardOutput = FileHandle.nullDevice
        pkill.standardError = FileHandle.nullDevice
        try? pkill.run()
        pkill.waitUntilExit()
        
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    private func waitForTermination(timeout: TimeInterval) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if runningInstances().isEmpty {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        
        return runningInstances().isEmpty
    }
    
    func launch() async throws {
        let applicationsPath = "/Applications/Antigravity.app"
        let userApplicationsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications/Antigravity.app")
        
        var appURL: URL?
        
        if FileManager.default.fileExists(atPath: applicationsPath) {
            appURL = URL(fileURLWithPath: applicationsPath)
        } else if FileManager.default.fileExists(atPath: userApplicationsPath.path) {
            appURL = userApplicationsPath
        } else {
            for bundleId in Self.bundleIdentifiers {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    appURL = url
                    break
                }
            }
        }
        
        guard let url = appURL else {
            throw ProcessError.applicationNotFound
        }
        
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        
        let workspace = NSWorkspace.shared
        try await workspace.openApplication(at: url, configuration: configuration)
        logger.info("Antigravity IDE launched")
    }
    
    // MARK: - Errors
    
    enum ProcessError: LocalizedError {
        case applicationNotFound
        case terminationFailed
        case launchFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .applicationNotFound:
                return "Antigravity IDE not found. Please ensure it is installed."
            case .terminationFailed:
                return "Failed to terminate Antigravity IDE"
            case .launchFailed(let error):
                return "Failed to launch Antigravity IDE: \(error.localizedDescription)"
            }
        }
    }
}
