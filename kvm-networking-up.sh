#!/bin/sh
 
## IP forwarding activation
echo 1 > /proc/sys/net/ipv4/ip_forward
 
# Point PFSense WAN as route to VMs
ip route change 192.168.9.0/24 via 10.0.0.2 dev vmbr1
 
# Point PFSense WAN as route to VPN
ip route add 10.2.2.0/24 via 10.0.0.2 dev vmbr1
