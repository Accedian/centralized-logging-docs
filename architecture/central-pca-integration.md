# Central PCA Integration Architecture

## Overview

The Central PCA (Provider Connectivity Assurance) solution, deployed via AOD Deployer, serves as the central aggregation point for telemetry from distributed Mobility Collector instances.

## Central PCA Components (AOD Deployer)

### Ingress Layer

| Component | Port | Purpose |
|-----------|------|--------|
| nginx | 443 | Tenant API access |
| nginx | 2443 | Admin API access |
| nginx | 3443 | Zitadel authentication |

### Existing Telemetry Receivers

| Component | Protocol | Purpose |
|-----------|----------|--------|
| Bellhop (OTEL Collector) | OTLP/HTTP | Receives traces, metrics, logs via `/otel/` |
| Kafka | TCP 9092 | Event streaming and message bus |
| Prometheus Gateway | HTTP | Push gateway for batch metrics |

### Storage Components

| Component | Purpose | Data Type |
|-----------|---------|----------|
| Elasticsearch | Log storage and search | Logs, events |
| Druid | Analytics OLAP database | Time-series analytics |
| Kafka | Event streaming | Real-time events |
| PostgreSQL | Relational data | Configuration, metadata |
| HDFS | Distributed file storage | Large datasets |
| MinIO | S3-compatible object storage | Backups, artifacts |

## Recommended Technology Stack

### Logs: FluentD + OpenSearch

**Why OpenSearch?**
- Apache 2.0 license (no vendor lock-in)
- Drop-in compatible with Elasticsearch
- Active open-source community
- Built-in security features

### Metrics: Prometheus + Thanos

**Why Thanos?**
- Seamless Prometheus integration
- Global query view across sites
- Long-term storage in object storage
- High availability and deduplication

## Implementation Phases

### Phase 1: Log Collection (2-3 weeks)
1. Deploy FluentD to Mobility Collectors
2. Deploy FluentD Aggregator at Central PCA
3. Deploy OpenSearch cluster
4. Configure and test log forwarding

### Phase 2: Metrics Federation (2-3 weeks)
1. Deploy Prometheus to Mobility Collectors
2. Deploy Thanos Receive at Central PCA
3. Configure remote_write
4. Create Grafana dashboards

### Phase 3: Alerting Integration (1-2 weeks)
1. Configure Alertmanager at remote sites
2. Set up alert forwarding
3. Create alerting rules

## Resource Estimates

### Central PCA Additions

| Component | CPU | Memory | Storage |
|-----------|-----|--------|--------|
| OpenSearch (3 nodes) | 4 cores x 3 | 16GB x 3 | 500GB x 3 |
| FluentD Aggregator | 1 core x 2 | 2GB x 2 | 50GB |
| Thanos Receive | 2 cores x 2 | 4GB x 2 | 100GB |

### Per Remote Site

| Component | CPU | Memory | Storage |
|-----------|-----|--------|--------|
| FluentD/Fluent Bit | 0.5 core | 512MB | 10GB |
| Prometheus | 1 core | 2GB | 50GB |

## Recommendations Summary

| Priority | Recommendation | Technology |
|----------|---------------|------------|
| **High** | Centralize logs | FluentD + OpenSearch |
| **High** | Federate metrics | Prometheus + Thanos |
| **High** | Unified dashboards | Grafana |
| Medium | Cross-site alerting | Alertmanager federation |
| Low | APM/Tracing | Extend existing OTEL |
