/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

/// Creates and owns componetns enabling RUM feature.
/// Bundles dependencies for other RUM-related components created later at runtime  (i.e. `RUMMonitor`).
internal final class RUMFeature: V1FeatureInitializable {
    typealias Configuration = FeaturesConfiguration.RUM

    // MARK: - Configuration

    let configuration: Configuration

    // MARK: - Dependencies

    let vitalCPUReader: SamplingBasedVitalReader
    let vitalMemoryReader: SamplingBasedVitalReader
    let vitalRefreshRateReader: ContinuousVitalReader

    // MARK: - Components

    /// RUM files storage.
    let storage: FeatureStorage
    /// RUM upload worker.
    let upload: FeatureUpload

    // MARK: - Initialization

    init(
        storage: FeatureStorage,
        upload: FeatureUpload,
        configuration: Configuration,
        /// TODO: RUMM-2169 Remove `commonDependencies` from `V1FeatureInitializable` interface when all Features are migrated to use `DatadogV1Context`:
        commonDependencies: FeaturesCommonDependencies,
        telemetry: Telemetry?
    ) {
        // Configuration
        self.configuration = configuration

        // Initialize stacks
        self.storage = storage
        self.upload = upload

        self.vitalCPUReader = VitalCPUReader(telemetry: telemetry)
        self.vitalMemoryReader = VitalMemoryReader()
        self.vitalRefreshRateReader = VitalRefreshRateReader()
    }

    internal func deinitialize() {
        storage.flushAndTearDown()
        upload.flushAndTearDown()
    }
}
