/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation

internal protocol ITNVMetricTracking {
    func trackAction(at actionDate: Date, actionType: RUMActionType)
    func trackViewStart(at viewStart: Date, viewID: RUMUUID)
    func trackViewComplete(viewID: RUMUUID)
    func value(for viewID: RUMUUID) -> TimeInterval?
}

internal final class ITNVMetric: ITNVMetricTracking {
    enum Constants {
        static let maxDuration: TimeInterval = 3
    }

    private var lastActionDate: Date?
    private var valuesByViewID: [RUMUUID: TimeInterval] = [:]

    func trackAction(at actionDate: Date, actionType: RUMActionType) {
        guard actionType.isSupportedITNVAction else {
            return // Ignore this action type
        }
        lastActionDate = actionDate
    }

    func trackViewStart(at viewStart: Date, viewID: RUMUUID) {
        guard let actionDate = lastActionDate else {
            return // No action in earlier views
        }

        // Compute interval from last action in previous view:
        let itnvValue = viewStart.timeIntervalSince(actionDate)

        // Since new view just started, reset the last action:
        lastActionDate = nil

        guard itnvValue <= Constants.maxDuration else {
            return // Value above threshold
        }

        valuesByViewID[viewID] = itnvValue
    }

    func trackViewComplete(viewID: RUMUUID) {
        valuesByViewID[viewID] = nil
    }

    func value(for viewID: RUMUUID) -> TimeInterval? {
        return valuesByViewID[viewID]
    }
}

private extension RUMActionType {
    var isSupportedITNVAction: Bool {
        switch self {
        case .tap, .click, .swipe: return true
        case .scroll, .custom: return false
        }
    }
}
