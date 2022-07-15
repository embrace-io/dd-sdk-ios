/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation

// MARK: - iOS 12+

import Network

/// Thread-safe wrapper for `NWPathMonitor`.
///
/// The `NWPathMonitor` provides two models of getting the `NWPath` info:
/// * pulling the value with `monitor.currentPath`,
/// * pushing the value with `monitor.pathUpdateHandler = { path in ... }`.
///
/// We found the pulling model to not be thread-safe: accessing `currentPath` properties lead to occasional crashes.
/// The `ThreadSafeNWPathMonitor` listens to path updates and synchonizes the values on `.current` property.
/// This adds the necessary thread-safety and keeps the convenience of pulling.
@available(iOS 12, tvOS 12, *)
internal struct NWPathMonitorPublisher: ContextValuePublisher {
    let initialValue: NetworkConnectionInfo

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue

    init(monitor: NWPathMonitor, queue: DispatchQueue) {
        self.monitor = monitor
        self.queue = queue
        self.initialValue = .init(
            reachability: .maybe,
            availableInterfaces: nil,
            supportsIPv4: nil,
            supportsIPv6: nil,
            isExpensive: nil,
            isConstrained: nil
        )
    }

    init(monitor: NWPathMonitor = .init()) {
        let queue = DispatchQueue(
            label: "com.datadoghq.nw-path-monitor-publisher",
            target: .global(qos: .utility)
        )

        self.init(monitor: monitor, queue: queue)
    }

    func publish(to receiver: @escaping ContextValueReceiver<NetworkConnectionInfo>) {
        monitor.pathUpdateHandler = {
            let info = NetworkConnectionInfo($0)
            receiver(info)
        }

        monitor.start(queue: queue)
    }

    func cancel() {
        monitor.cancel()
    }
}

extension NetworkConnectionInfo {
    @available(iOS 12, tvOS 12, *)
    init(_ path: NWPath) {
        self.init(
            reachability: NetworkConnectionInfo.Reachability(path.status),
            availableInterfaces: path.availableInterfaces.map { .init($0.type) },
            supportsIPv4: path.supportsIPv4,
            supportsIPv6: path.supportsIPv6,
            isExpensive: path.isExpensive,
            isConstrained: {
                guard #available(iOS 13, tvOS 13, *) else {
                    return nil
                }
                return path.isConstrained
            }()
        )
    }
}

extension NetworkConnectionInfo.Reachability {
    @available(iOS 12, tvOS 12, *)
    init(_ status: NWPath.Status) {
        switch status {
        case .satisfied: self = .yes
        case .requiresConnection: self = .maybe
        case .unsatisfied: self = .no
        @unknown default: self = .maybe
        }
    }
}

extension NetworkConnectionInfo.Interface {
    @available(iOS 12, tvOS 12, *)
    init(_ interface: NWInterface.InterfaceType) {
        switch interface {
        case .wifi: self = .wifi
        case .wiredEthernet: self = .wiredEthernet
        case .cellular: self = .cellular
        case .loopback: self = .loopback
        case .other: self = .other
        @unknown default: self = .other
        }
    }
}

// MARK: - iOS 11

import SystemConfiguration

internal struct SCNetworkReachabilityReader: ContextValueReader {
    let initialValue: NetworkConnectionInfo

    private let reachability: SCNetworkReachability

    init(reachability: SCNetworkReachability) {
        self.initialValue = NetworkConnectionInfo(reachability)
        self.reachability = reachability
    }

    init() {
        var zero = sockaddr()
        zero.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zero.sa_family = sa_family_t(AF_INET)
        let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zero)! // swiftlint:disable:this force_unwrapping
        self.init(reachability: reachability)
    }

    func read(to receiver: inout NetworkConnectionInfo) {
        receiver = NetworkConnectionInfo(reachability)
    }
}

extension NetworkConnectionInfo {
    init(_ reachability: SCNetworkReachability) {
        var retrieval = SCNetworkReachabilityFlags()
        let flags = (SCNetworkReachabilityGetFlags(reachability, &retrieval)) ? retrieval : nil
        self.init(
            reachability: .init(flags),
            availableInterfaces: NetworkConnectionInfo.Interface(flags).map { [$0] },
            supportsIPv4: nil,
            supportsIPv6: nil,
            isExpensive: nil,
            isConstrained: nil
        )
    }
}

extension NetworkConnectionInfo.Reachability {
    init(_ flags: SCNetworkReachabilityFlags?) {
        switch flags?.contains(.reachable) {
        case .none: self = .maybe
        case .some(true): self = .yes
        case .some(false): self = .no
        }
    }
}

extension NetworkConnectionInfo.Interface {
    @available(iOS 2.0, macCatalyst 13.0, *)
    init?(_ flags: SCNetworkReachabilityFlags?) {
        guard let flags = flags, flags.contains(.isWWAN) else {
            return nil
        }
        self = .cellular
    }
}
