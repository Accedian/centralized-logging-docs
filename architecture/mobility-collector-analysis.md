# Mobility Collector Architecture Analysis

## Overview

The Mobility Collector is a distributed data collection system deployed as a remote agent. It consists of two main namespaces handling Fault Management (FM) and Performance Management (PM) workloads.

## Current Architecture

### Namespaces

| Namespace | Purpose | Key Components |
|-----------|---------|----------------|
| `matrix-fm-analytics` | Fault Management | SNMP trap handling, alerting, OTEL export |
| `matrix-pm-analytics` | Performance Management | Data collection, processing, web UI |

### FM Components (matrix-fm-analytics)

| Component | Purpose | Technology |
|-----------|---------|------------|
| `snmptrapd` | SNMP trap receiver | Net-SNMP daemon, UDP 1162 |
| `snmppipeline` | Trap processing pipeline | Custom Python |
| `of-framework` | OpenFlow framework | Custom service |
| `of-alertmanager` | Alert management with whitelist | Prometheus Alertmanager fork |
| `of-consumer` | Alert event consumer | Custom service |
| `alertservice` | External notification service | Custom Python |
| `otel-transformer` | Telemetry transformation | Custom service |
| `otel-exporter` | OTLP export to central PCA | OpenTelemetry Collector |

### PM Components (matrix-pm-analytics)

| Component | Purpose | Technology |
|-----------|---------|------------|
| `matrixweb` | Web application | Django |
| `coordinator` | Task coordination | Custom Python |
| `celeryworker` | Async task workers | Celery |
| `celerybeat` | Scheduled tasks | Celery Beat |
| `flower` | Celery monitoring | Flower |
| `fileservice` | File storage service | Custom Python |

### Infrastructure Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| `timescaledb-single` | Time-series database | TimescaleDB (PostgreSQL) |
| `redis-cluster` | Distributed cache | Redis Cluster (6 nodes) |
| `rabbitmq` | Message broker | RabbitMQ |
| `kafka` | Event streaming | Apache Kafka |
| `zookeeper` | Distributed coordination | Apache Zookeeper |
| `nginx-ingress` | Ingress controller | NGINX |
| `metallb` | Load balancer | MetalLB (L2 mode) |

## Current Monitoring Status

### What's Currently Implemented

1. **OTEL Collector Export** (Operational)
   - Location: `otel-exporter` in `matrix-fm-analytics`
   - Export Target: `https://pca2507.rmn.local/otel/`
   - Protocol: OTLP/HTTP with Bearer token authentication
   - Pipelines: traces, metrics, logs

2. **Internal Alert Processing**
   - `of-alertmanager` processes FM alerts locally
   - `alertservice` handles external notifications

### Current Gaps

| Gap | Impact | Priority |
|-----|--------|----------|
| No centralized log aggregation | Logs remain local, no searchability | **High** |
| No Prometheus metrics scraping | Limited visibility into service health | **High** |
| No log shipping to OpenSearch | Cannot correlate logs across sites | **High** |
| Single OTEL export target | No redundancy, single point of failure | Medium |
| No Thanos integration | Limited long-term metric storage | Medium |

## Recommendations

### High Priority

1. **Enable Prometheus metrics endpoints** on all services
2. **Deploy FluentD/Fluent Bit** DaemonSet for log collection
3. **Configure remote_write** to central Thanos receiver
4. **Set up FluentD aggregator** at central PCA with OpenSearch output

### Medium Priority

1. Add Prometheus Alertmanager for local alerting
2. Implement log retention policies
3. Create Grafana dashboards for Mobility Collector health
4. Set up cross-site log correlation using trace IDs

### Security Considerations

1. TLS encryption for all telemetry traffic
2. Bearer tokens or mTLS for authentication
3. Network policies to restrict egress
4. Credential rotation and management
5. PII filtering in log pipelines
