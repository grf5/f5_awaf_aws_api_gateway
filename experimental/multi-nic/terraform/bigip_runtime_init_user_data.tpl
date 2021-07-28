#!/bin/bash -x 

# Send output to log file and serial console
mkdir -p  /var/log/cloud /config/cloud /var/config/rest/downloads
LOG_FILE=/var/log/cloud/startup-script.log
[[ ! -f $LOG_FILE ]] && touch $LOG_FILE || { echo "Run Only Once. Exiting"; exit; }
npipe=/tmp/$$.tmp
trap "rm -f $npipe" EXIT
mknod $npipe p
tee <$npipe -a $LOG_FILE /dev/ttyS0 &
exec 1>&-
exec 1>$npipe
exec 2>&1

### write_files:
# shell script execution with debug enabled
cat << "EOF" > /config/cloud/manual_run.sh
#!/bin/bash

# Set logging level (least to most)
# error, warn, info, debug, silly
export F5_BIGIP_RUNTIME_INIT_LOG_LEVEL=silly

# runtime init execution, with telemetry skipped
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml --skip-telemetry
EOF

# runtime init configuration
cat << "EOF" > /config/cloud/runtime-init-conf.yaml
---
runtime_parameters:
  - name: DATAPLANE_IP
    type: metadata
    metadataProvider: 
      environment: aws
      type: network
      field: local-ipv4s
      index: 1
  - name: DATAPLANE_SUBNET
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: subnet-ipv4-cidr-block
      index: 1
  - name: DATAPLANE_CIDR_MASK
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: subnet-ipv4-cidr-block
      index: 1
      ipcalc: bitmask
  - name: DATAPLANE_GATEWAY
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: local-ipv4s
      index: 1
      ipcalc: first
  - name: DATAPLANE_MASK
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: subnet-ipv4-cidr-block
      index: 1
      ipcalc: mask
pre_onboard_enabled:
  - name: provision_rest
    type: inline
    commands:
      - /usr/bin/setdb provision.extramb 500
      - /usr/bin/setdb restjavad.useextramb true
      - /usr/bin/setdb setup.run false
extension_packages:
    install_operations:
        - extensionType: do
          extensionVersion: 1.21.1
        - extensionType: as3
          extensionVersion: 3.29.0
        - extensionType: ts
          extensionVersion: 1.20.1
extension_services:
    service_operations: []
post_onboard_enabled: []
EOF

# runcmd:

# Download the f5-bigip-runtime-init package
# 30 attempts, 5 second timeout and 10 second pause between attempts
for i in {1..30}; do
    curl -fv --retry 1 --connect-timeout 5 -L https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.2.1/dist/f5-bigip-runtime-init-1.2.1-1.gz.run -o /var/config/rest/downloads/f5-bigip-runtime-init-1.2.1-1.gz.run && break || sleep 10
done

# Set logging level (least to most)
# error, warn, info, debug, silly
export F5_BIGIP_RUNTIME_INIT_LOG_LEVEL=silly

# Execute the installer
bash /var/config/rest/downloads/f5-bigip-runtime-init-1.2.1-1.gz.run -- "--cloud aws"

# Runtime Init execution on configuration file created above
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml