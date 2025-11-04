#!/bin/bash
[[ $EUID -ne 0 ]] && { echo "Запустите от root"; exit 1; }
apt update -qq
apt install -y -qq nano sudo syslog-ng isc-dhcp-server || { echo "Ошибка установки пакетов";}
read -rp "Введите Фамилию и Имя (пример: Петров Иван): " f i _ || exit 1
[[ -z $f || -z $i ]] && { echo "Ошибка: укажите Фамилию и Имя"; exit 1; }
full_surname="$f"
f=${f::1} i=${i::1}
[[ $f$i =~ ^[А-Яа-яЁё]{2}$ ]] || { echo "Ошибка: используйте кириллицу"; exit 1; }
ALPH=АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ
X=$(expr index "$ALPH" "${f^^}") Y=$(expr index "$ALPH" "${i^^}")
((X && Y)) || { echo "Ошибка: буква не в алфавите"; exit 1; }
h=$(echo "$full_surname" | sed 's/[Аа]/a/g;s/[Бб]/b/g;s/[Вв]/v/g;s/[Гг]/g/g;s/[Дд]/d/g;s/[Ее]/e/g;s/[Ёё]/yo/g;s/[Жж]/zh/g;s/[Зз]/z/g;s/[Ии]/i/g;s/[Йй]/y/g;s/[Кк]/k/g;s/[Лл]/l/g;s/[Мм]/m/g;s/[Нн]/n/g;s/[Оо]/o/g;s/[Пп]/p/g;s/[Рр]/r/g;s/[Сс]/s/g;s/[Тт]/t/g;s/[Уу]/u/g;s/[Фф]/f/g;s/[Хх]/kh/g;s/[Цц]/ts/g;s/[Чч]/ch/g;s/[Шш]/sh/g;s/[Щщ]/sch/g;s/[ЪъЫыЬьЭэ]//g;s/[Юю]/yu/g;s/[Яя]/ya/g;s/[^a-z0-9]//g')
h=${h^}
[[ -z $h ]] && { echo "Ошибка: не удалось создать hostname"; exit 1; }
hostnamectl set-hostname "${h}_SRV"
cat > /etc/network/interfaces <<EOF
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
allow-hotplug enp0s3
iface enp0s3 inet static
    address 169.254.1.1
    netmask 255.255.255.0
auto enp0s8
iface enp0s8 inet static
address 10.$X.$Y.10
netmask 255.255.255.0
EOF
systemctl restart networking

cat > /etc/default/isc-dhcp-server <<EOF
INTERFACESv4="enp0s3"
INTERFACESv6=""
EOF

cat > /etc/dhcp/dhcpd.conf <<EOF
option domain-name "shusha.ru";
option domain-name-servers 10.$X.$Y.10;
default-lease-time 6000;
max-lease-time 7200;
ddns-update-style none;
authoritative;
subnet 10.$X.$Y.0 netmask 255.255.255.0 {
  range 10.$X.$Y.20 10.$X.$Y.250;
  option routers 10.$X.$Y.10;
  option broadcast-address 10.$X.$Y.255;
}
EOF
systemctl restart isc-dhcp-server

touch /var/log/esckere.log
chmod 644 /var/log/esckere.log  # безопаснее, чем 777

grep -q 'd_esckere' /etc/syslog-ng/syslog-ng.conf ||
cat >> /etc/syslog-ng/syslog-ng.conf <<EOF

destination d_esckere { file("/var/log/esckere.log"); };
source s_net { udp(port(514)); };
filter f_dhcp { program(dhclient); };
log { source(s_net); filter(f_dhcp); destination(d_esckere); };
EOF

systemctl restart networking
clear
cat << 'EOF'

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣤⣄⡀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡸⠋⠀⠘⣇⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠇⠀⠀⠀⢸⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⠀⠀⠀⠀⢸⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠇⠀⠀⠀⠀⢸⠇⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡎⠀⠀⠀⠀⠀⢸⠀⠀⠀
⠀⠀⢀⣀⣀⣀⠀⠀⠀⠀⠀⢀⣀⣤⡤⠤⠤⠤⠤⢤⣤⣀⡤⢖⡿⠛⠉⢳⠀⠀⠀⠀⠀⢸⠀⠀⠀
⠀⢼⠁⠉⠉⠛⠻⢭⡓⠒⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⣏⠀⠀⠀⢸⠀⠀⠀⠀⠀⡤⠀⠀⠀
⠀⠸⡄⠀⠀⠀⠀⢸⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠂⠀⠀⡜⠀⠀⠀⠀⢀⡇⠀⠀⠀
⠀⠀⢷⠀⠀⠀⠠⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢣⢠⠏⠀⠀⠀⠀⢸⠃⠀⠀⠀
⠀⠀⠈⢧⠀⢀⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡞⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀
⠀⠀⠀⠈⢳⡈⠁⠀⠀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠀⠀⣶⣶⣦⠀⠀⢹⠀⠀⠀⠀⠀⡎⠀⠀⠀⠀
⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⢠⣾⣟⣹⡄⠀⠀⠀⠀⡀⠀⣿⣿⣿⡇⠀⢈⣧⠤⠤⠶⠶⢷⠒⠒⠂⠀
⠀⠀⢀⣀⣠⡧⠄⠀⠀⠀⣾⣿⣿⣿⠇⠀⠀⠀⠙⠁⠀⠙⠻⠿⠃⠀⠨⣼⣤⣀⡀⠀⠈⢧⠀⠀⠀
⠘⠉⠁⠀⢸⣤⡤⠀⠀⠀⠛⢿⡿⠋⠀⠀⠀⠀⠴⠦⠀⠀⠀⠀⠀⠐⣲⣯⡀⠀⠈⠙⠓⠺⣧⣄⡀
⠀⣀⡤⠚⠉⢳⡴⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡼⠃⠀⠈⠓⢦⡀⠀⠀⢸⠀⠈
⠀⠁⠀⢀⡔⠉⠙⡶⢄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠴⠚⠁⠀⠀⠀⠀⠀⠀⠈⠓⠆⠀⡇⠀
⠀⠀⠰⠋⠀⠀⢸⡇⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠁⠀
⠀⠀⠀⠀⠀⠀⠈⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡎⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠹⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠙⢆⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠄⠀⢰⠇⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠶⠺⣇⠀⣀⡜⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢱⡄⠀⠀⠀⠹⡟⠒⢢⡀⠀⠀⠀⠀⢀⡏⠀⠀⠀⠈⠉⠉⠁⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣄⠀⠀⢀⡇⠀⠀⠻⣄⠀⠀⠀⡸⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢷⠶⠋⠀⠀⠀⠀⠈⣣⠶⠖⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
EOF

echo -e "\n✅ Все успешно выполнено!\n"
