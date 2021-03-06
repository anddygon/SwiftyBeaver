//
//  GoogleCloudDestination.swift
//  SwiftyBeaver
//
//  Copyright © 2017 Sebastian Kreutzberger. All rights reserved.
//

import Foundation

public final class GoogleCloudDestination: BaseDestination {

    private let serviceName: String

    public init(serviceName: String) {
        self.serviceName = serviceName
        super.init()
    }

    override public var asynchronously: Bool {
        get {
            return false
        }
        set {
            return
        }
    }

    override public func send(_ level: SwiftyBeaver.Level, msg: String, thread: String,
                              file: String, function: String, line: Int) -> String? {

        let gcpJSON: [String: Any] = [
            "serviceContext": [
                "service": serviceName
            ],
            "message": msg,
            "severity": level.severity,
            "context": [
                "reportLocation": ["filePath": file, "lineNumber": line, "functionName": function]
            ]
        ]

        let finalLogString: String

        do {
            finalLogString = try jsonString(obj: gcpJSON)
        } catch {
            let uncrashableLogString = "{\"context\":{\"reportLocation\":{\"filePath\": \"\(file)\"" +
                ",\"functionName\":\"\(function)\"" +
                ",\"lineNumber\":\(line)},\"severity\"" +
                ":\"CRITICAL\",\"message\":\"Error encoding " +
            "JSON log entry. You may be losing log messages!\"}"
            finalLogString = uncrashableLogString.description
        }

        return finalLogString
    }

    private func jsonString(obj: Dictionary<String, Any>) throws -> String {
        let json = try JSONSerialization.data(withJSONObject: obj, options: [])
        guard let string = String(data: json, encoding: .utf8) else {
            throw GCPError.serialization
        }
        return string
    }
}

///
/// https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#LogSeverity
extension SwiftyBeaver.Level {

    /// Verbose is reported as Debug to GCP.
    /// Recommend you don't bother using it.
    var severity: String {
        switch self {
        // There is only one level below "Debug": "Default", which becomes "Any" and is considered as a potential error as well
        case .verbose: return "DEBUG"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
}

private enum GCPError: Error {
    case serialization
}
