#!/bin/bash

echo "=== Instalando BIND9 ==="
apt update
apt install -y bind9 bind9-utils bind9-dnsutils

echo "=== Fazendo backup da configuração original ==="
cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bkp

echo "=== Configurando DNS Recursivo ==="

cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";

    recursion yes;
    allow-recursion { 192.168.0.0/24; };
    allow-query { 192.168.0.0/24; };

    listen-on { 127.0.0.1; 192.168.0.10; };
    listen-on-v6 { none; };

    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    dnssec-validation auto;

    auth-nxdomain no;
};
EOF

echo "=== Reiniciando serviço ==="
systemctl restart bind9
systemctl enable bind9

echo "=== Liberando porta DNS no firewall (nftables exemplo) ==="
nft add rule inet filter input udp dport 53 accept 2>/dev/null
nft add rule inet filter input tcp dport 53 accept 2>/dev/null

echo "=== Verificando status ==="
systemctl status bind9 --no-pager

echo "=== Teste com dig ==="
dig @127.0.0.1 google.com

echo "=== Instalação concluída ==="
