#!/bin/bash
[[ $EUID -ne 0 ]] && exit 1

apt update -yqq
apt install -yqq nano sudo syslog-ng isc-dhcp-client || exit 1

read -rp "Введите Фамилию и Имя (пример: Петров Иван): " s i _ || exit 1
[[ -z $s || -z $i || ! ${s::1}${i::1} =~ ^[А-Яа-яЁё]{2}$ ]] && exit 1

ALPH=АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ
X=$(expr index "$ALPH" "${s::1^^}")
Y=$(expr index "$ALPH" "${i::1^^}")
((X && Y)) || exit 1

# Сеть
cat > /etc/network/interfaces <<EOF
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
allow-hotplug enp0s3
iface enp0s3 inet dhcp
EOF
systemctl restart networking

# Hostname: полная фамилия → транслит → _CLI
h=$(echo "$s" | tr 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя' \
               'ABVGDEYOZHIZIKLMNOPRSTUFKHTSCHSHSCH''Y''YEYUABVGDEYOZHIZIKLMNOPRSTUFKHTSCHSHSCH''Y''YEYU' | \
   sed 's/[^A-Za-z0-9]//g')_CLI
[[ $h = _CLI ]] && exit 1
hostnamectl set-hostname "$h"

# Syslog-ng: очистка старых правил
SYSLOG_CONF="/etc/syslog-ng/syslog-ng.conf"
sed -i '/destination d_net {/,/};/d;
        /destination d_esckere {/,/};/d;
        /filter f_dhcp {/,/};/d;
        /log.*destination.*d_net/d;
        /log.*destination.*d_esckere/d' "$SYSLOG_CONF"

# Добавление новых правил
cat >> "$SYSLOG_CONF" <<EOF

destination d_net { udp("10.$X.$Y.10" port(514)); };
destination d_esckere { file("/var/log/esckere.log"); };
filter f_dhcp { program("dhclient"); };
log { source(system()); destination(d_net); };
log { source(system()); filter(f_dhcp); destination(d_esckere); };
EOF

systemctl restart syslog-ng
