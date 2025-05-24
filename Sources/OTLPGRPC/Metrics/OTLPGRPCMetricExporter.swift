//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift OTel open source project
//
// Copyright (c) 2024 the Swift OTel project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import GRPC
import Logging
import NIO
import NIOHPACK
import NIOSSL
import OTel
import OTLPCore

/// Exports metrics to an OTel collector using OTLP/gRPC.
public final class OTLPGRPCMetricExporter: OTelMetricExporter {
    private let configuration: OTLPGRPCMetricExporterConfiguration
    private let connection: ClientConnection
    private let client: Opentelemetry_Proto_Collector_Metrics_V1_MetricsServiceAsyncClient
    private let logger = Logger(label: String(describing: OTLPGRPCMetricExporter.self))

    public init(
        configuration: OTLPGRPCMetricExporterConfiguration,
        group: any EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
        requestLogger: Logger = ._otelDisabled,
        backgroundActivityLogger: Logger = ._otelDisabled,
        trustRoots: NIOSSLTrustRoots = .default
    ) {
        self.configuration = configuration

        if configuration.endpoint.isInsecure {
            logger.debug("Using insecure connection.", metadata: [
                "host": "\(configuration.endpoint.host)",
                "port": "\(configuration.endpoint.port)",
            ])
            connection = ClientConnection.insecure(group: group)
                .withBackgroundActivityLogger(backgroundActivityLogger)
                .connect(host: configuration.endpoint.host, port: configuration.endpoint.port)
        } else {
            logger.debug("Using secure connection.", metadata: [
                "host": "\(configuration.endpoint.host)",
                "port": "\(configuration.endpoint.port)",
            ])
            
            var tlsConfiguration = ClientConnection
                .usingPlatformAppropriateTLS(for: group)

            // Use custom certificate if provided
            if let certificateData = configuration.certificate {
                do {
                    let certificate = try NIOSSLCertificate(bytes: [UInt8](certificateData), format: .pem)
                    tlsConfiguration = tlsConfiguration.withTLS(trustRoots: .certificates([certificate]))
                    logger.debug("Using custom certificate for server verification")
                } catch {
                    logger.error("Failed to load certificate: \(error)")
                    tlsConfiguration = tlsConfiguration.withTLS(trustRoots: trustRoots)
                }
            } else {
                tlsConfiguration = tlsConfiguration.withTLS(trustRoots: trustRoots)
            }
            
            // Use client certificate and key if both are provided
            if let clientCertificateData = configuration.clientCertificate,
               let clientKeyData = configuration.clientKey {
                do {
                    let clientCertificate = try NIOSSLCertificate(bytes: [UInt8](clientCertificateData), format: .pem)
                    let clientKey = try NIOSSLPrivateKey(bytes: [UInt8](clientKeyData), format: .pem)
                    tlsConfiguration = tlsConfiguration.withTLS(certificateChain: [clientCertificate])
                    tlsConfiguration = tlsConfiguration.withTLS(privateKey: clientKey)
                    logger.debug("Using client certificate and key for client authentication")
                } catch {
                    logger.error("Failed to load client certificate or key: \(error)")
                }
            }
            
            connection = tlsConfiguration
                .withBackgroundActivityLogger(backgroundActivityLogger)
                .connect(host: configuration.endpoint.host, port: configuration.endpoint.port)
        }

        var headers = configuration.headers
        if !headers.isEmpty {
            logger.trace("Configured custom request headers.", metadata: [
                "keys": .array(headers.map { "\($0.name)" }),
            ])
        }
        headers.replaceOrAdd(name: "user-agent", value: "OTel-OTLP-Exporter-Swift/\(OTelLibrary.version)")

        client = Opentelemetry_Proto_Collector_Metrics_V1_MetricsServiceAsyncClient(
            channel: connection,
            defaultCallOptions: .init(customMetadata: headers, logger: requestLogger)
        )
    }

    public func export(_ batch: some Collection<OTelResourceMetrics> & Sendable) async throws {
        if case .shutdown = connection.connectivity.state {
            logger.error("Attempted to export batch while already being shut down.")
            throw OTelMetricExporterAlreadyShutDownError()
        }
        let request = Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest.with { request in
            request.resourceMetrics = batch.map(Opentelemetry_Proto_Metrics_V1_ResourceMetrics.init)
        }

        _ = try await client.export(request)
    }

    public func forceFlush() async throws {
        // This exporter is a "push exporter" and so the OTel spec says that force flush should do nothing.
    }

    public func shutdown() async {
        let promise = connection.eventLoop.makePromise(of: Void.self)
        connection.closeGracefully(deadline: .now() + .milliseconds(500), promise: promise)
        try? await promise.futureResult.get()
    }
}
