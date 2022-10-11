/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

public internal(set) var defaultDatadogCore: DatadogCoreProtocol = NOPDatadogCore()

/// A Datadog Core holds a set of features and is responsible of managing their storage
/// and upload mechanism. It also provides a thread-safe scope for writing events.
public protocol DatadogCoreProtocol {
    /// Registers a Feature instance.
    ///
    /// A Feature collect and transfer data to a Datadog Product (e.g. Logs, RUM, ...). A registered Feature can
    /// open a `FeatureScope` to write events, the core will then be responsible for storing and uploading events
    /// in a efficient manner. Performance presets for storage and upload are define when instanciating the core instance.
    ///
    /// A Feature can also communicate to other Features by sending message on the bus that is managed by the core.
    ///
    /// - Parameter feature: The Feature instance.
    func register(feature: DatadogFeature) throws

    /// Retrieves a Feature by its name and type.
    ///
    /// A Feature type can be specified as parameter or inferred from the return type:
    ///
    ///     let feature = core.feature(named: "foo", type: Foo.self)
    ///     let feature: Foo? = core.feature(named: "foo")
    ///
    /// - Parameters:
    ///   - name: The Feature's name.
    ///   - type: The Feature instance type.
    /// - Returns: The Feature if any.
    func feature<T>(named name: String, type: T.Type) -> T? where T: DatadogFeature

    /// Registers a Feature Integration instance.
    ///
    /// A Feature Integration collect and transfer data to a local Datadog Feature. An Integration will not store nor upload,
    /// it will collect data for other Features to consume.
    ///
    /// An Integration can commicate to Features via dependency or a communication channel such as the message-bus.
    ///
    /// - Parameter integration: The Feature Integration instance.
    func register(integration: DatadogFeatureIntegration) throws

    /// Retrieves a Feature Integration by its name and type.
    ///
    /// A Feature Integration type can be specified as parameter or inferred from the return type:
    ///
    ///     let integration = core.integration(named: "foo", type: Foo.self)
    ///     let integration: Foo? = core.integration(named: "foo")
    ///
    /// - Parameters:
    ///   - name: The Feature Integration's name.
    ///   - type: The Feature Integration instance type.
    /// - Returns: The Feature Integration if any.
    func integration<T>(named name: String, type: T.Type) -> T? where T: DatadogFeature

    /// Sets given attributes for a given Feature for sharing data through `DatadogContext`.
    ///
    /// This method provides a passive communication chanel between Features of the Core.
    /// For an active Feature-to-Feature communication, please use the `send(message:)`
    /// method.
    ///
    /// Setting attributes will update the Core Context and will be shared across Features.
    /// In the following examples, the Feature `foo` will set an attribute and a second
    /// Feature `bar` will read it through the event write context.
    ///
    ///     // Foo.swift
    ///     core.set(feature: "foo", attributes: [
    ///         "id": 1
    ///     ])
    ///
    ///     // Bar.swift
    ///     core.scope(for: "bar").eventWriteContext { context, writer in
    ///         let fooID: Int? = context.featuresAttributes["foo"]?.id
    ///     }
    ///
    /// - Parameters:
    ///   - feature: The Feature's name.
    ///   - attributes: The Feature's attributes to set.
    func set(feature: String, attributes: @escaping () -> FeatureBaggage)

    /// Sends a message on the bus shared by features registered in this core.
    ///
    /// If the message could not be processed by any registered feature, the fallback closure
    /// will be invoked. Do not make any assumption on which thread the fallback is called.
    ///
    /// - Parameters:
    ///   - message: The message.
    ///   - fallback: The fallback closure to call when the message could not be
    ///               processed by any Features on the bus.
    func send(message: FeatureMessage, else fallback: @escaping () -> Void)
}

extension DatadogCoreProtocol {
    /// Retrieves a Feature by its name and type.
    ///
    /// A Feature type can be specified as parameter or inferred from the return type:
    ///
    ///     let feature = core.feature(named: "foo", type: Foo.self)
    ///     let feature: Foo? = core.feature(named: "foo")
    ///
    /// - Parameters:
    ///   - name: The Feature's name.
    /// - Returns: The Feature if any.
    func feature<T>(named name: String) -> T? where T: DatadogFeature {
        feature(named: name, type: T.self)
    }

    /// Retrieves a Feature Integration by its name and type.
    ///
    /// A Feature Integration type can be specified as parameter or inferred from the return type:
    ///
    ///     let integration = core.integration(named: "foo", type: Foo.self)
    ///     let integration: Foo? = core.integration(named: "foo")
    ///
    /// - Parameters:
    ///   - name: The Feature Integration's name.
    /// - Returns: The Feature Integration if any.
    func integration<T>(named name: String) -> T? where T: DatadogFeature {
        integration(named: name, type: T.self)
    }

    /// Sends a message on the bus shared by features registered in this core.
    ///
    /// - Parameters:
    ///   - message: The message.
    func send(message: FeatureMessage) {
        send(message: message, else: {})
    }
}

/// Feature scope provides a context and a writer to build a record event.
internal protocol FeatureScope {
    /// Retrieve the event context and writer.
    ///
    /// The Feature scope provides the current Datadog context and event writer
    /// for the Feature to build and record events.
    ///
    /// A Feature has the ability to bypass the current user consent for data collection. The `bypassConsent`
    /// must be set to `true` only if the Feature is already aware of the user's consent for the event it is about
    /// to write.
    ///
    /// - Parameters:
    ///   - bypassConsent: `true` to bypass the current core consent and write events as authorized.
    ///                    Default is `false`, setting `true` must still respect user's consent for
    ///                    collecting information.
    ///   - block: The block to execute.
    func eventWriteContext(bypassConsent: Bool, _ block: @escaping (DatadogContext, Writer) throws -> Void)
}

/// Feature scope provides a context and a writer to build a record event.
extension FeatureScope {
    /// Retrieve the event context and writer.
    ///
    /// The Feature scope provides the current Datadog context and event writer
    /// for the Feature to build and record events.
    ///
    /// - Parameter block: The block to execute.
    func eventWriteContext(_ block: @escaping (DatadogContext, Writer) throws -> Void) {
        self.eventWriteContext(bypassConsent: false, block)
    }
}

/// No-op implementation of `DatadogFeatureRegistry`.
internal struct NOPDatadogCore: DatadogCoreProtocol {
    /// no-op
    func register(feature: DatadogFeature) throws { }
    /// no-op
    func feature<T>(named name: String, type: T.Type) -> T? where T: DatadogFeature { nil }
    /// no-op
    func register(integration: DatadogFeatureIntegration) throws { }
    /// no-op
    func integration<T>(named name: String, type: T.Type) -> T? where T: DatadogFeature { nil }
    /// no-op
    func set(feature: String, attributes: @escaping @autoclosure () -> FeatureBaggage) { }
    /// no-op
    func send(message: FeatureMessage, else fallback: @escaping () -> Void) { }
}
