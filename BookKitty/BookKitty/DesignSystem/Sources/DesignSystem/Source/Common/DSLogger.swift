//
//  DSLogger.swift
//  DesignSystem
//
//  Created by 권승용 on 2/20/25.
//

import OSLog

enum DSLogger {
    // MARK: - Static Properties

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DesignSystemPackage",
        category: "general"
    )

    // MARK: - Static Functions

    static func log(_ message: String) {
        logger.log("\(message)")
    }

    static func error(_ message: String) {
        logger.error("\(message)")
    }

    static func debug(_ message: String) {
        logger.debug("\(message)")
    }

    static func info(_ message: String) {
        logger.info("\(message)")
    }
}
