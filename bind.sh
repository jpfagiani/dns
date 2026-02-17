apt update
apt install bind9 bind9utils bind9-doc dnsutils -y

cat > /etc/bind/named.conf.options << EOF

options {
    directory "/var/cache/bind";

    # Habilita recursão
    recursion yes;

    # Permite recursão apenas para rede interna
    allow-recursion { 192.168.0.0/24; localhost; };

    # Permite consultas de qualquer lugar
    allow-query { any; };

    # DNS externos (forwarders)
    forwarders {
        10.14.8.20;
        10.14.8.16;
		10.14.29.4;
        8.8.8.8;
    };

    # Escuta nas duas interfaces
    listen-on { 192.168.0.9; 10.14.29.9; };

    listen-on-v6 { none; };

    dnssec-validation auto;
};
EOF

cat > /etc/bind/named.conf.local << EOF

zone "cdpni.sap" {
    type master;
    file "/etc/bind/db.cdpni.sap";
};

zone "0.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.192.168.0";
};
EOF

cat > /etc/bind/db.cdpni.sap << EOF

$TTL 604800
@   IN  SOA ns.cdpni.sap. admin.cdpni.sap. (
        1       ; Serial
        604800  ; Refresh
        86400   ; Retry
        2419200 ; Expire
        604800  ; Negative Cache TTL
)

@       IN  NS      ns.cdpni.sap.

ns      IN  A       192.168.0.9
dns     IN  A       192.168.0.9
server  IN  A       192.168.0.9
www     IN  A       192.168.0.9

EOF

cat > /etc/bind/db.192.168.0 << EOF

$TTL 604800
@   IN  SOA ns.cdpni.sap. admin.cdpni.sap. (
        1
        604800
        86400
        2419200
        604800 )

@       IN  NS      ns.cdpni.sap.

9       IN  PTR     ns.cdpni.sap.
EOF

chown bind:bind /etc/bind/db.*
named-checkconf
named-checkzone cdpni.sap /etc/bind/db.cdpni.sap
named-checkzone 0.168.192.in-addr.arpa /etc/bind/db.192.168.0
systemctl restart bind9
systemctl enable bind9

apt install nftables -y

cat > /etc/nftables.conf << EOF

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0;
        policy drop;

        ct state established,related accept
        iif lo accept

        # Liberar DNS
        tcp dport 53 accept
        udp dport 53 accept

        # Liberar SSH
        tcp dport 22 accept
    }
}
EOF

systemctl enable nftables
systemctl restart nftables

cat > /etc/resolv.conf << EOF
nameserver 127.0.0.1
EOF

