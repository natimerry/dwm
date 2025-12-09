#!/bin/sh

usb() {
    # detect any removable USB drives
    dev=$(lsblk -rpo "NAME,TYPE,RM,MOUNTPOINT" | awk '$3==1{print $1; exit}')
    mnt=$(lsblk -rpo "NAME,TYPE,RM,MOUNTPOINT" | awk '$3==1{print $4; exit}')
    [ "$dev" ] && { [ -z "$mnt" ] && echo "usb:in" || echo "usb:$mnt"; }
}

fs() {
    root=$(df -h / | awk 'NR==2{print $3}')
    echo "d:root:$root "
}

ram() { free -h | awk '$1=="Mem:"{print "r:"$3}' | sed 's/i//'; }

cpu() {
    read -r _ a b c i _ < /proc/stat; pt=$((a+b+c+i))
    sleep 0.5
    read -r _ a b c j _ < /proc/stat; t=$((a+b+c+j))
    echo "c:$((100*((t-pt)-(j-i))/(t-pt)))%"
}

net() {
    t=$(ip route | awk '$1=="default"{print substr($5,1,1)}')
    [ -z "$t" ] && echo "n:down" || [ "$t" = e ] && echo "n:eth" || echo "n:wifi"
}

vol() {
    muted=$(pactl list sinks | awk '$1=="Mute:"{print $2}')
    v=$(pactl list sinks | awk '$1=="Volume:"{print $5; exit}' | tr -d '%')
    [ "$muted" = yes ] && echo "v:mut" && return
    echo "v:$v%"
}

battery() {
    cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null)
    stat=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null)
    [ -n "$cap" ] && {
        sym="d"  # discharging default
        [ "$stat" = "Charging" ] && sym="c"
        [ "$cap" -ge 95 ] && sym="="
        echo "b:$cap%$sym"
    }
}

clock() { echo "t:$(date +%H:%M)"; }

main() {
    while true; do
        xsetroot -name "$(usb) | $(fs) | $(ram) | $(cpu) | $(battery) | $(clock)"
        sleep 1
    done
}

main

