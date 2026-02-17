#!/bin/bash

echo "Atualizando sistema..."
apt update -y

echo "Instalando Chrony..."
apt install -y chrony

echo "Configurando servidor NTP..."

cat > /etc/chrony/chrony.conf <<EOF
# Servidores externos (upstream)
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Permitir rede interna
allow 192.168.0.0/24

# Arquivos de controle
driftfile /var/lib/chrony/chrony.drift
rtcsync
makestep 1.0 3

# Log
logdir /var/log/chrony
EOF

echo "Reiniciando serviço..."
systemctl restart chrony
systemctl enable chrony

echo "Liberando porta 123/UDP no nftables (caso exista firewall)..."
nft add rule inet firewall input udp dport 123 accept 2>/dev/null

echo "Servidor de horas configurado com sucesso!"
