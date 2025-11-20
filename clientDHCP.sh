#!/bin/bash
[[ $EUID -ne 0 ]] && { echo "Запустите от root"; exit 1; }
apt update -yqq
apt install -yqq nano sudo syslog-ng isc-dhcp-client
read -rp "Введите Фамилию и Имя (пример: Петров Иван): " f i _ || exit 1
[[ -z $f || -z $i ]] && { echo "Ошибка: укажите Фамилию и Имя"; exit 1; }
full_surname="$f"
f=${f::1} i=${i::1}
[[ $f$i =~ ^[А-Яа-яЁё]{2}$ ]] || { echo "Ошибка: используйте кириллицу"; exit 1; }
ALPH=АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ
X=$(expr index "$ALPH" "${f^^}") Y=$(expr index "$ALPH" "${i^^}")
((X && Y)) || { echo "Ошибка: буква не в алфавите"; exit 1; }
h=$(echo "$full_surname" | sed 's/[Аа]/a/g;s/[Бб]/b/g;s/[Вв]/v/g;s/[Гг]/g/g;s/[Дд]/d/g;s/[Ее]/e/g;s/[Ёё]/yo/g;s/[Жж]/zh/g;s/[Зз]/z/g;s/[Ии]/i/g;s/[Йй]/y/g;s/[Кк]/k/g;s/[Лл]/l/g;s/[Мм]/m/g;s/[Нн]/n/g;s/[Оо]/o/g;s/[Пп]/p/g;s/[Рр]/r/g;s/[Сс]/s/g;s/[Тт]/t/g;s/[Уу]/u/g;s/[Фф]/f/g;s/[Хх]/kh/g;s/[Цц]/ts/g;s/[Чч]/ch/g;s/[Шш]/sh/g;s/[Щщ]/sch/g;s/[ЪъЬь]//g;s/[Ыы]/y/g;s/[Ээ]/e/g;s/[Юю]/yu/g;s/[Яя]/ya/g;s/[^a-z0-9]//g')
[[ -z $h ]] && { echo "Ошибка: не удалось создать hostname"; exit 1; }
hostnamectl set-hostname "${h}_CLI"

touch /var/log/esckere.log
chmod 644 /var/log/esckere.log

cat > /etc/network/interfaces <<EOF
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback
allow-hotplug enp0s3
iface enp0s3 inet dhcp
EOF

systemctl restart networking

SYSLOG_CONF="/etc/syslog-ng/syslog-ng.conf"

if grep -q 'destination d_net\|destination d_esckere\|filter f_dhcp\|log.*destination(d_net)\|log.*destination (d_esckere)' "$SYSLOG_CONF"; then
    sed -i '
        /destination d_net {/,/};/d;
        /destination d_esckere {/,/};/d;
        /filter f_dhcp {/,/};/d;
        /log.*destination(d_net)/d;
        /log.*destination (d_esckere)/d;
        /^$/d
    ' "$SYSLOG_CONF"
fi
cat >> "$SYSLOG_CONF" <<EOF
destination d_net { udp("10.$X.$Y.10" port(514)); };
destination d_esckere { file("/var/log/esckere.log"); };
filter f_dhcp { program(dhclient); };
log { source(s_src); destination(d_net); };
log { source(s_src); filter(f_dhcp); destination(d_esckere); };
EOF

systemctl restart syslog-ng

clear
cat << 'EOF'

                             ⠀⣠⣤⣄⡀⠀
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
