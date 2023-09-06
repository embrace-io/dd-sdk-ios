/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
import TestUtilities

@testable import DatadogInternal

class TelemetryTests: XCTestCase {
    func testTelemetryDebug() {
        // Given
        class TelemetryTest: Telemetry {
            var debug: (id: String, message: String, attributes: [String: Encodable]?)?

            func send(telemetry: DatadogInternal.TelemetryMessage) {
                guard case let .debug(id, message, attributes) = telemetry else {
                    return
                }

                debug = (id: id, message: message, attributes: attributes)
            }
        }

        let telemetry = TelemetryTest()

        struct SwiftError: Error {
            let description = "error description"
        }

        // When
        #sourceLocation(file: "File.swift", line: 1)
        telemetry.debug("debug message", attributes: ["foo": "bar"])
        #sourceLocation()

        // Then
        XCTAssertEqual(telemetry.debug?.id, "File.swift:1:debug message")
        XCTAssertEqual(telemetry.debug?.message, "debug message")
        XCTAssertEqual(telemetry.debug?.attributes as? [String: String], ["foo": "bar"])
    }

    func testTelemetryErrorFormatting() {
        // Given
        class TelemetryTest: Telemetry {
            var error: (id: String, message: String, kind: String?, stack: String?)?

            func send(telemetry: DatadogInternal.TelemetryMessage) {
                guard case let .error(id, message, kind, stack) = telemetry else {
                    return
                }

                error = (id: id, message: message, kind: kind, stack: stack)
            }
        }

        let telemetry = TelemetryTest()

        struct SwiftError: Error {
            let description = "error description"
        }

        let swiftError = SwiftError()

        let nsError = NSError(
            domain: "custom-domain",
            code: 10,
            userInfo: [
                NSLocalizedDescriptionKey: "error description"
            ]
        )

        // When
        #sourceLocation(file: "File.swift", line: 1)
        telemetry.error(swiftError)
        #sourceLocation()

        // Then
        XCTAssertEqual(telemetry.error?.id, #"File.swift:1:SwiftError(description: "error description")"#)
        XCTAssertEqual(telemetry.error?.message, #"SwiftError(description: "error description")"#)
        XCTAssertEqual(telemetry.error?.kind, "SwiftError")
        XCTAssertEqual(telemetry.error?.stack, #"SwiftError(description: "error description")"#)

        // When
        #sourceLocation(file: "File.swift", line: 2)
        telemetry.error(nsError)
        #sourceLocation()

        // Then
        XCTAssertEqual(telemetry.error?.id, "File.swift:2:error description")
        XCTAssertEqual(telemetry.error?.message, "error description")
        XCTAssertEqual(telemetry.error?.kind, "custom-domain - 10")
        XCTAssertEqual(
            telemetry.error?.stack,
            """
            Error Domain=custom-domain Code=10 "error description" UserInfo={NSLocalizedDescription=error description}
            """
        )

        // When
        telemetry.error("swift error", error: swiftError)
        // Then
        XCTAssertEqual(telemetry.error?.message, #"swift error - SwiftError(description: "error description")"#)

        // When
        telemetry.error("ns error", error: nsError)
        // Then
        XCTAssertEqual(telemetry.error?.message, "ns error - error description")
    }

    func testTelemetryConfiguration() {
        // Given
        class TelemetryTest: Telemetry {
            var configuration: ConfigurationTelemetry?

            func send(telemetry: DatadogInternal.TelemetryMessage) {
                guard case .configuration(let configuration) = telemetry else {
                    return
                }

                self.configuration = configuration
            }
        }

        let expectedConfiguration = ConfigurationTelemetry(
            actionNameAttribute: .mockRandom(),
            allowFallbackToLocalStorage: .mockRandom(),
            allowUntrustedEvents: .mockRandom(),
            batchSize: .mockRandom(),
            batchUploadFrequency: .mockRandom(),
            dartVersion: .mockRandom(),
            defaultPrivacyLevel: .mockRandom(),
            forwardErrorsToLogs: .mockRandom(),
            initializationType: .mockRandom(),
            mobileVitalsUpdatePeriod: .mockRandom(),
            premiumSampleRate: .mockRandom(),
            reactNativeVersion: .mockRandom(),
            reactVersion: .mockRandom(),
            replaySampleRate: .mockRandom(),
            sessionReplaySampleRate: .mockRandom(),
            sessionSampleRate: .mockRandom(),
            silentMultipleInit: .mockRandom(),
            startSessionReplayRecordingManually: .mockRandom(),
            telemetryConfigurationSampleRate: .mockRandom(),
            telemetrySampleRate: .mockRandom(),
            traceSampleRate: .mockRandom(),
            trackBackgroundEvents: .mockRandom(),
            trackCrossPlatformLongTasks: .mockRandom(),
            trackErrors: .mockRandom(),
            trackFlutterPerformance: .mockRandom(),
            trackFrustrations: .mockRandom(),
            trackInteractions: .mockRandom(),
            trackLongTask: .mockRandom(),
            trackNativeErrors: .mockRandom(),
            trackNativeLongTasks: .mockRandom(),
            trackNativeViews: .mockRandom(),
            trackNetworkRequests: .mockRandom(),
            trackResources: .mockRandom(),
            trackSessionAcrossSubdomains: .mockRandom(),
            trackUserInteractions: .mockRandom(),
            trackViewsManually: .mockRandom(),
            useAllowedTracingOrigins: .mockRandom(),
            useAllowedTracingUrls: .mockRandom(),
            useBeforeSend: .mockRandom(),
            useCrossSiteSessionCookie: .mockRandom(),
            useExcludedActivityUrls: .mockRandom(),
            useFirstPartyHosts: .mockRandom(),
            useLocalEncryption: .mockRandom(),
            useProxy: .mockRandom(),
            useSecureSessionCookie: .mockRandom(),
            useTracing: .mockRandom(),
            useWorkerUrl: .mockRandom()
        )

        let telemetry = TelemetryTest()

        // When
        telemetry.configuration(
            actionNameAttribute: expectedConfiguration.actionNameAttribute,
            allowFallbackToLocalStorage: expectedConfiguration.allowFallbackToLocalStorage,
            allowUntrustedEvents: expectedConfiguration.allowUntrustedEvents,
            batchSize: expectedConfiguration.batchSize,
            batchUploadFrequency: expectedConfiguration.batchUploadFrequency,
            dartVersion: expectedConfiguration.dartVersion,
            defaultPrivacyLevel: expectedConfiguration.defaultPrivacyLevel,
            forwardErrorsToLogs: expectedConfiguration.forwardErrorsToLogs,
            initializationType: expectedConfiguration.initializationType,
            mobileVitalsUpdatePeriod: expectedConfiguration.mobileVitalsUpdatePeriod,
            premiumSampleRate: expectedConfiguration.premiumSampleRate,
            reactNativeVersion: expectedConfiguration.reactNativeVersion,
            reactVersion: expectedConfiguration.reactVersion,
            replaySampleRate: expectedConfiguration.replaySampleRate,
            sessionReplaySampleRate: expectedConfiguration.sessionReplaySampleRate,
            sessionSampleRate: expectedConfiguration.sessionSampleRate,
            silentMultipleInit: expectedConfiguration.silentMultipleInit,
            startSessionReplayRecordingManually: expectedConfiguration.startSessionReplayRecordingManually,
            telemetryConfigurationSampleRate: expectedConfiguration.telemetryConfigurationSampleRate,
            telemetrySampleRate: expectedConfiguration.telemetrySampleRate,
            traceSampleRate: expectedConfiguration.traceSampleRate,
            trackBackgroundEvents: expectedConfiguration.trackBackgroundEvents,
            trackCrossPlatformLongTasks: expectedConfiguration.trackCrossPlatformLongTasks,
            trackErrors: expectedConfiguration.trackErrors,
            trackFlutterPerformance: expectedConfiguration.trackFlutterPerformance,
            trackFrustrations: expectedConfiguration.trackFrustrations,
            trackInteractions: expectedConfiguration.trackInteractions,
            trackLongTask: expectedConfiguration.trackLongTask,
            trackNativeErrors: expectedConfiguration.trackNativeErrors,
            trackNativeLongTasks: expectedConfiguration.trackNativeLongTasks,
            trackNativeViews: expectedConfiguration.trackNativeViews,
            trackNetworkRequests: expectedConfiguration.trackNetworkRequests,
            trackResources: expectedConfiguration.trackResources,
            trackSessionAcrossSubdomains: expectedConfiguration.trackSessionAcrossSubdomains,
            trackUserInteractions: expectedConfiguration.trackUserInteractions,
            trackViewsManually: expectedConfiguration.trackViewsManually,
            useAllowedTracingOrigins: expectedConfiguration.useAllowedTracingOrigins,
            useAllowedTracingUrls: expectedConfiguration.useAllowedTracingUrls,
            useBeforeSend: expectedConfiguration.useBeforeSend,
            useCrossSiteSessionCookie: expectedConfiguration.useCrossSiteSessionCookie,
            useExcludedActivityUrls: expectedConfiguration.useExcludedActivityUrls,
            useFirstPartyHosts: expectedConfiguration.useFirstPartyHosts,
            useLocalEncryption: expectedConfiguration.useLocalEncryption,
            useProxy: expectedConfiguration.useProxy,
            useSecureSessionCookie: expectedConfiguration.useSecureSessionCookie,
            useTracing: expectedConfiguration.useTracing,
            useWorkerUrl: expectedConfiguration.useWorkerUrl
        )

        // Then
        XCTAssertEqual(telemetry.configuration, expectedConfiguration)
    }

    func testWhenSendingTelemetryMessage_itForwardsToCore() {
        // Given
        class Receiver: FeatureMessageReceiver {
            var telemetry: TelemetryMessage?

            func receive(message: FeatureMessage, from core: DatadogCoreProtocol) -> Bool {
                guard case .telemetry(let telemetry) = message else {
                    return false
                }

                self.telemetry = telemetry
                return true
            }
        }

        let receiver = Receiver()
        let core = PassthroughCoreMock(messageReceiver: receiver)

        // When
        core.telemetry.debug("debug")

        // Then
        guard case .debug(_, let message, _) = receiver.telemetry else {
            return XCTFail("A debug should be send to core.")
        }
        XCTAssertEqual(message, "debug")

        // When
        core.telemetry.error("error")

        // Then
        guard case .error(_, let message, _, _) = receiver.telemetry else {
            return XCTFail("An error should be send to core.")
        }
        XCTAssertEqual(message, "error")

        // When
        core.telemetry.configuration(batchSize: 0)

        // Then
        guard case .configuration(let configuration) = receiver.telemetry else {
            return XCTFail("An error should be send to core.")
        }
        XCTAssertEqual(configuration.batchSize, 0)
    }
}
