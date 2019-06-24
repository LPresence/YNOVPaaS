#!/bin/sh

#--VARIABLES--

PrxPubVBR="vmbr0"
PrxVmWanVBR="vmbr1"
PrxVmPrivVBR="vmbr2"

VmWanNET="10.0.0.0/30"
PrivNET="192.168.9.0/24"
VpnNET="10.2.2.0/24"

PublicIP="51.91.14.202"
ProxVmWanIP="10.0.0.1"
ProxVmPrivIP="192.168.9.1"
PfsVmWanIP="10.0.0.2"

#--Suppression des règles existantes--

iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X
ip6tables -P INPUT DROP
ip6tables -P OUTPUT DROP
ip6tables -P FORWARD DROP
	
#--Default policy--

iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP

#--Chaines--

iptables -N TCP
iptables -N UDP


iptables -A INPUT -p udp -m conntrack --ctstate NEW -j UDP
iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP

#--Règles globales--

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

iptables -A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT

#--Vmbr0--

### INPUT

iptables -A TCP -i $PrxPubVBR -d $PublicIP -p tcp --dport 22 -j ACCEPT
iptables -A TCP -i $PrxPubVBR -d $PublicIP -p tcp --dport 8006 -j ACCEPT

### OUTPUT

iptables -A OUTPUT -p icmp -j ACCEPT
iptables -A OUTPUT -o $PrxPubVBR -s $PfsVmWanIP -d $PublicIP -j ACCEPT
iptables -A OUTPUT -o $PrxPubVBR -s $PublicIP -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -o $PrxPubVBR -s $PublicIP -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -o $PrxPubVBR -s $PublicIP -p tcp --dport 43 -j ACCEPT
iptables -A OUTPUT -o $PrxPubVBR -s $PublicIP -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -o $PrxPubVBR -s $PublicIP -p tcp --dport 443 -j ACCEPT 
iptables -A OUTPUT -o $PrxPubVBR -s $PublicIP -p tcp --sport 22 -j ACCEPT
iptables -A OUTPUT -o $PrxPubVBR -s $PublicIP -p tcp --sport 8006 -j ACCEPT

### FORWARD

iptables -A FORWARD -i $PrxPubVBR -d $PfsVmWanIP -o $PrxVmWanVBR -p tcp -j ACCEPT
iptables -A FORWARD -i $PrxPubVBR -d $PfsVmWanIP -o $PrxVmWanVBR -p udp -j ACCEPT
iptables -A FORWARD -i $PrxVmWanVBR -s $VmWanNET -j ACCEPT
iptables -t nat -A POSTROUTING -s $VmWanNET -o $PrxPubVBR -j MASQUERADE
iptables -A PREROUTING -t nat -i $PrxPubVBR -p tcp --match multiport ! --dports 22,8006 -j DNAT --to $PfsVmWanIP
iptables -A PREROUTING -t nat -i $PrxPubVBR -p udp -j DNAT --to $PfsVmWanIP

#--PrxVmWanVBR--

### INPUT

iptables -A TCP -i $PrxVmWanVBR -d $ProxVmWanIP -p tcp --dport 22 -j ACCEPT
iptables -A TCP -i $PrxVmWanVBR -d $ProxVmWanIP -p tcp --dport 8006 -j ACCEPT

### OUTPUT

iptables -A OUTPUT -o $PrxVmWanVBR -s $ProxVmWanIP -p tcp --sport 22 -j ACCEPT
iptables -A OUTPUT -o $PrxVmWanVBR -s $ProxVmWanIP -p tcp --sport 8006 -j ACCEPT

#--PrxVmPrivVBR--

#Pas de règles donc tout est bloqué
