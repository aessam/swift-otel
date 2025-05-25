# ``OTLPGRPC``

Export spans and metrics to an OpenTelemetry collector using gRPC.

## Overview

The OTLPGRPC module provides exporters that send telemetry data to an [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) using the OTLP/gRPC protocol.

## Topics

### Tracing

- ``OTLPGRPCSpanExporter``
- ``OTLPGRPCSpanExporterConfiguration``

### Metrics

- ``OTLPGRPCMetricExporter`` 
- ``OTLPGRPCMetricExporterConfiguration``

### General

- ``OTLPGRPCEndpoint``
- ``OTLPGRPCEndpointConfigurationError``
- <doc:SecurityAndAuthentication>