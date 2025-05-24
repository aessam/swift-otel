# Security and Authentication

Secure your gRPC connections to the OpenTelemetry collector.

## Overview

The OTLP exporter in Swift OTel allows you to configure secure connections to your OpenTelemetry collector using TLS. This documentation covers how to set up a secure connection with custom certificates.

## Secure Connections

By default, the exporter uses a secure connection unless explicitly configured to use an insecure one. You can control this behavior using the `shouldUseAnInsecureConnection` parameter or the `OTEL_EXPORTER_OTLP_INSECURE` environment variable.

```swift
// Using insecure connection (not recommended for production)
let configuration = try OTLPGRPCSpanExporterConfiguration(
    environment: [:], 
    shouldUseAnInsecureConnection: true
)
```

## Custom Certificates

You can provide custom certificates for secure connections either programmatically or through environment variables:

### Server Certificate Verification

To verify the server certificate using your own CA or self-signed certificate:

```swift
// Using a custom certificate programmatically
let certificateData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/cert.pem"))
let configuration = try OTLPGRPCSpanExporterConfiguration(
    environment: [:],
    certificate: certificateData
)
```

Or using environment variables:

```bash
# Set the certificate path in the environment
export OTEL_EXPORTER_OTLP_CERTIFICATE=/path/to/cert.pem

# Signal-specific variants are also supported
export OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE=/path/to/traces-cert.pem
export OTEL_EXPORTER_OTLP_METRICS_CERTIFICATE=/path/to/metrics-cert.pem
```

### Client Authentication

To use client certificates for mutual TLS authentication:

```swift
// Using client certificates programmatically
let clientCertificateData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/client-cert.pem"))
let clientKeyData = try Data(contentsOf: URL(fileURLWithPath: "/path/to/client-key.pem"))
let configuration = try OTLPGRPCSpanExporterConfiguration(
    environment: [:],
    clientCertificate: clientCertificateData,
    clientKey: clientKeyData
)
```

Or using environment variables:

```bash
# Set the client certificate and key paths in the environment
export OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE=/path/to/client-cert.pem
export OTEL_EXPORTER_OTLP_CLIENT_KEY=/path/to/client-key.pem

# Signal-specific variants are also supported
export OTEL_EXPORTER_OTLP_TRACES_CLIENT_CERTIFICATE=/path/to/traces-client-cert.pem
export OTEL_EXPORTER_OTLP_TRACES_CLIENT_KEY=/path/to/traces-client-key.pem
export OTEL_EXPORTER_OTLP_METRICS_CLIENT_CERTIFICATE=/path/to/metrics-client-cert.pem
export OTEL_EXPORTER_OTLP_METRICS_CLIENT_KEY=/path/to/metrics-client-key.pem
```

## Environment Variables Summary

| Environment Variable | Description |
|---------------------|-------------|
| `OTEL_EXPORTER_OTLP_INSECURE` | Whether to use an insecure connection (true/false) |
| `OTEL_EXPORTER_OTLP_CERTIFICATE` | Path to a PEM-encoded certificate file for server verification |
| `OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE` | Path to a PEM-encoded client certificate file for client authentication |
| `OTEL_EXPORTER_OTLP_CLIENT_KEY` | Path to a PEM-encoded private key file for client authentication |

Signal-specific variants of these variables are also supported by adding `_TRACES` or `_METRICS` before the last part of the variable name.