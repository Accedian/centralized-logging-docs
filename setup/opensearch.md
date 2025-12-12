# OpenSearch Setup Guide

## Prerequisites

- Minimum 4 CPU cores, 8GB RAM (16GB recommended for production)
- At least 50GB of storage (SSD recommended)
- Java 11 or later
- Linux-based operating system (Ubuntu 20.04 LTS recommended)

## Installation

### 1. Add the OpenSearch repository

```bash
# Install required packages
sudo apt-get update && sudo apt-get install -y apt-transport-https

# Add the OpenSearch GPG key
wget -qO - https://artifacts.opensearch.org/publickeys/opensearch.pgp | sudo apt-key add -

# Add the repository
echo "deb https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/opensearch-2.x.list

# Update package index
sudo apt-get update
```

### 2. Install OpenSearch

```bash
# Install OpenSearch
sudo apt-get install opensearch

# Enable and start the service
sudo systemctl enable opensearch
sudo systemctl start opensearch
```

## Configuration

### 1. Basic Configuration

Edit the main configuration file:

```yaml
# /etc/opensearch/opensearch.yml

# Cluster and node settings
cluster.name: logging-cluster
node.name: ${HOSTNAME}
node.roles: [data, ingest, master]

# Network settings
network.host: 0.0.0.0
http.port: 9200
transport.port: 9300

# Discovery settings
discovery.type: single-node  # For single-node setup

# Security settings (basic)
plugins.security.ssl.transport.pemcert_filepath: node1.pem
plugins.security.ssl.transport.pemkey_filepath: node1-key.pem
plugins.security.ssl.transport.pemtrustedcas_filepath: root-ca.pem
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: node1_http.pem
plugins.security.ssl.http.pemkey_filepath: node1_http-key.pem
plugins.security.ssl.http.pemtrustedcas_filepath: root-ca.pem
plugins.security.authcz.admin_dn:
  - 'CN=admin,OU=SSL,O=Test,L=Test,C=DE'
plugins.security.nodes_dn:
  - 'CN=node1,OU=SSL,O=Test,L=Test,C=DE'
  - 'CN=node2,OU=SSL,O=Test,L=Test,C=DE'
  - 'CN=node3,OU=SSL,O=Test,L=Test,C=DE'
plugins.security.audit.type: internal_opensearch

# Performance tuning
bootstrap.memory_lock: true
indices.memory.index_buffer_size: 20%
indices.breaker.total.limit: 60%
```

### 2. JVM Configuration

Edit the JVM options:

```yaml
# /etc/opensearch/jvm.options

# Xms represents the initial size of total heap space
# Xmx represents the maximum size of total heap space

# Set initial and max heap size to 4GB (adjust based on available RAM)
-Xms4g
-Xmx4g

# Garbage collection settings
-XX:+UseG1GC
-XX:G1ReservePercent=25
-XX:InitiatingHeapOccupancyPercent=30
```

## Security Setup

### 1. Generate Certificates

```bash
# Create a directory for certificates
sudo mkdir -p /etc/opensearch/certs
cd /etc/opensearch/certs

# Generate root CA
openssl genrsa -out root-ca-key.pem 2048
openssl req -new -x509 -sha256 -key root-ca-key.pem -out root-ca.pem -subj "/C=DE/ST=Test/L=Test/O=Test/CN=root"

# Generate node certificate
openssl genrsa -out node1-key-temp.pem 2048
openssl pkcs8 -inform PEM -outform PEM -in node1-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out node1-key.pem
openssl req -new -key node1-key.pem -out node1.csr -subj "/C=DE/ST=Test/L=Test/O=Test/OU=SSL/CN=node1"
openssl x509 -req -in node1.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out node1.pem
```

### 2. Set File Permissions

```bash
sudo chown -R opensearch:opensearch /etc/opensearch/
sudo chmod -R 750 /etc/opensearch/
```

## Index Management

### 1. Create Index Template

```bash
# Create a template for application logs
curl -XPUT -u admin:admin https://localhost:9200/_index_template/application-logs -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["app-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 1,
      "opensearch.index.mapping.total_fields.limit": 2000
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "message": { "type": "text" },
        "level": { "type": "keyword" },
        "service": { "type": "keyword" },
        "host": { "type": "ip" },
        "tags": { "type": "keyword" }
      }
    },
    "aliases": {
      "app-logs": {}
    }
  },
  "priority": 100,
  "version": 1
}'
```

### 2. Set Up Index Lifecycle Management (ILM)

```bash
# Create ILM policy
curl -XPUT -u admin:admin https://localhost:9200/_ilm/policy/logs-policy -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_size": "50gb",
            "max_age": "30d"
          }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'
```

## Verification

### 1. Check Cluster Health

```bash
curl -XGET -u admin:admin https://localhost:9200/_cluster/health?pretty
```

### 2. List Nodes

```bash
curl -XGET -u admin:admin https://localhost:9200/_cat/nodes?v
```

## Performance Tuning

### 1. File Descriptors

```bash
# Add to /etc/security/limits.conf
opensearch - nofile 65535
opensearch - memlock unlimited
```

### 2. Virtual Memory

```bash
# Add to /etc/sysctl.conf
vm.max_map_count=262144

# Apply changes
sudo sysctl -p
```

## Backup and Restore

### 1. Create Snapshot Repository

```bash
# Create a directory for snapshots
sudo mkdir -p /mnt/opensearch-backups
sudo chown -R opensearch:opensearch /mnt/opensearch-backups

# Register the repository
curl -XPUT -u admin:admin https://localhost:9200/_snapshot/fs_backup -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/mnt/opensearch-backups",
    "compress": true
  }
}'
```

### 2. Create a Snapshot

```bash
# Create a snapshot
curl -XPUT -u admin:admin "https://localhost:9200/_snapshot/fs_backup/snapshot_1?wait_for_completion=true"
```

## Next Steps

1. Configure FluentD to send logs to OpenSearch
2. Set up index patterns and visualizations in OpenSearch Dashboards
3. Configure alerts and notifications
4. Implement role-based access control (RBAC) for your team

## Troubleshooting

### Common Issues

1. **Node not starting**: Check logs at `/var/log/opensearch/opensearch.log`
2. **Memory issues**: Ensure `bootstrap.memory_lock` is set to true and the user has the right permissions
3. **Certificate errors**: Verify certificate paths and permissions in `opensearch.yml`
4. **Connection refused**: Check if OpenSearch is running and listening on the correct interface

### Logs

- Main log file: `/var/log/opensearch/opensearch.log`
- Garbage collection logs: `/var/log/opensearch/gc.log`

## Security Considerations

1. Always use TLS for communication
2. Enable authentication and authorization
3. Regularly rotate certificates
4. Follow the principle of least privilege for user roles
5. Keep OpenSearch updated with the latest security patches
