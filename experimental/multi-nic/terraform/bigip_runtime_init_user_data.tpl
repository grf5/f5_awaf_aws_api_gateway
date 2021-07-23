#!/bin/bash

# Create the logging directory
mkdir -p /var/log/cloud

# Make the config directory
mkdir -p /config/cloud

cat << "EOF" > /config/cloud/manual_run.sh
#!/bin/bash

# Set logging level (least to most)
# error, warn, info, debug, silly
export F5_BIGIP_RUNTIME_INIT_LOG_LEVEL=silly

# runtime init execution, with telemetry skipped
f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml --skip-telemetry
EOF

cat << "EOF" > /config/cloud/runtime-init-conf.yaml
---
runtime_parameters:
  - name: MGMT_IP
    type: metadata
    metadataProvider: 
      environment: aws
      type: network
      field: local-ipv4s
      index: 0
  - name: MGMT_SUBNET
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: subnet-ipv4-cidr-block
      index: 0
  - name: MGMT_CIDR_MASK
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: subnet-ipv4-cidr-block
      index: 0
      ipcalc: bitmask
  - name: MGMT_GATEWAY
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: local-ipv4s
      index: 0
      ipcalc: first
  - name: MGMT_MASK
    type: metadata
    metadataProvider:
      environment: aws
      type: network
      field: subnet-ipv4-cidr-block
      index: 0
      ipcalc: mask
pre_onboard_enabled:
  - name: provision_rest
    type: inline
    commands:
      - /usr/bin/setdb provision.extramb 500
      - /usr/bin/setdb restjavad.useextramb true
bigip_ready_enabled:
  - name: licensing
    type: inline
    commands:
      - tmsh install sys license registration-key ${bigip_license}
extension_packages:
  install_operations:
    - extensionType: do
      extensionVersion: 1.20.0
# We're not using DO currently because static ARP entries and tunnel local-address/remote-address is not supported
# as of 22 Jun 2021 (DO v1.20.0) and mixing DO with TMSH commands in post_onboard_enabled have conflicted in testing.
# Once DO supports these items, that will be the preferred configuration mechanism.
post_onboard_enabled:
  - name: manual_tmsh_configuration
    type: inline
    commands:
      - source /usr/lib/bigstart/bigip-ready-functions; wait_bigip_ready
      - tmsh modify sys provision ltm level nominal
      - source /usr/lib/bigstart/bigip-ready-functions; wait_bigip_ready
      - tmsh modify sys provision asm level nominal
      - source /usr/lib/bigstart/bigip-ready-functions; wait_bigip_ready
      - tmsh modify auth user admin password ${bigipAdminPassword}
      - tmsh modify sys ntp servers add { 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org }
      - tmsh create net vlan dataplane interfaces add { 1.1 { untagged }} mtu 9001
      - tmsh create net route-domain dataplane id 1 vlans add { dataplane }
      - tmsh create net self inband-mgmt address `printf {{{ MGMT_IP }}} | cut -d "/" -f1`%1/`printf {{{ MGMT_IP }}} | cut -d "/" -f2` vlan dataplane allow-service all
      - tmsh create net route dataplane-default network 0.0.0.0%1 gw {{{ MGMT_GATEWAY }}}%1
      - tmsh create net tunnels tunnel geneve local-address `printf {{{ MGMT_IP }}} | cut -d "/" -f1`%1 remote-address any%1 profile geneve
      - tmsh modify net route-domain dataplane vlans add { geneve } 
      - tmsh create ltm virtual health_check destination `printf {{{ MGMT_IP }}} | cut -d "/" -f1`%1:1 ip-protocol tcp mask 255.255.255.255 profiles add { http tcp } source 0.0.0.0%1/0 vlans-enabled vlans add { dataplane } 
      - tmsh create net self geneve-tunnel address 10.131.0.1%1/24 vlan geneve allow-service all
      - tmsh create net arp fake_arp_entry ip-address 10.131.0.2%1 mac-address ff:ff:ff:ff:ff:ff
      - tmsh create ltm node geneve-tunnel address 10.131.0.2%1 monitor none 
      - tmsh create ltm pool geneve-tunnel members add { geneve-tunnel:0 } monitor none 
      - tmsh create ltm virtual forwarding_vs destination 0.0.0.0%1:any ip-protocol any vlans-enabled vlans add { geneve } translate-address disabled source-port preserve-strict pool geneve-tunnel mask any
      - tmsh modify sys db provision.tmmcount value 1
      - tmsh modify sys db configsync.allowmanagement value enable
      - tmsh modify sys global-settings gui-setup disabled
      - tmsh modify sys db provision.managementeth value eth1
      - tmsh save /sys config
      - sed -i 's/        1\.1 {/        1\.0 {/g' /config/bigip_base.conf
      - reboot
EOF

### runcmd:

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