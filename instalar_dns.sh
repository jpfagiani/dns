#!/bin/bash

echo "Atualizando sistema..."
apt update -y

echo "Instalando BIND9..."
apt install -y bind9 bind9-utils bind9-dnsutils

echo "Configurando named.conf.options..."

cat > /etc/bind/named.conf.options <<EOF
options {
    directory "/var/cache/bind";

    recursion yes;
    allow-recursion { 127.0.0.1; 192.168.0.0/24; 10.14.29.0/24 };
    allow-query { any; };

    forwarders {
        10.14.8.16;
        10.14.8.20;
        10.1.6.222;
        8.8.8.8;
        8.8.4.4;
    };

    forward only;

    dnssec-validation auto;

    listen-on { any; };
    listen-on-v6 { any; };
};
EOF

echo "Reiniciando serviço..."
systemctl restart bind9
systemctl enable bind9

echo "Liberando porta 53 no firewall (caso nftables esteja ativo)..."
nft add rule inet firewall input udp dport 53 accept 2>/dev/null
nft add rule inet firewall input tcp dport 53 accept 2>/dev/null

echo "Servidor DNS configurado com sucesso!"
