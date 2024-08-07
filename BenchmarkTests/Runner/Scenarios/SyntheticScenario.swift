/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-Present Datadog, Inc.
 */

import Foundation
import UIKit

/// The Synthetics Scenario reads the `BENCHMARK_SCENARIO` environment
/// variable to instantiate a `Scenario` compliant object.
internal struct SyntheticScenario: Scenario {
    /// The scenario's name.
    let name: String
    
    /// The underlying scenario.
    private let _scenario: Scenario
    
    /// Creates the scenario by reading the `BENCHMARK_SCENARIO` value from the
    /// environment vairables.
    ///
    /// - Parameter processInfo: The `ProcessInfo` with environment vairables
    /// configured
    init?(processInfo: ProcessInfo = .processInfo) {
        guard let name = processInfo.environment["BENCHMARK_SCENARIO"] else {
            return nil
        }

        switch name {
        case "sessionReplay":
            _scenario = SessionReplayScenario()
        default:
            return nil
        }

        self.name = name
    }

    var initialViewController: UIViewController {
        _scenario.initialViewController
    }

    func instrument(with info: AppInfo) {
        _scenario.instrument(with: info)
    }
}

/// The Synthetics benchark run value.
internal enum SyntheticRun: String {
    case baseline
    case metrics
    case profiling

    /// Creates the scenario by reading the `BENCHMARK_RUN` value from the
    /// environment vairables.
    ///
    /// - Parameter processInfo: The `ProcessInfo` with environment vairables
    /// configured
    init?(processInfo: ProcessInfo = .processInfo) {
        guard
            let rawValue = processInfo.environment["BENCHMARK_RUN"],
            let run = Self(rawValue: rawValue)
        else {
            return nil
        }

        self = run
    }
}
