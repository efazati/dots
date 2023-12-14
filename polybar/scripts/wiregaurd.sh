#!/bin/bash 

configs_path="/etc/wireguard"
connected_interface=$(nmcli connection show | grep wireguard | awk '{print $1}')

connect() {
    # Use rofi instead of dmenu
    selected_config=$(ls $configs_path/*.conf | xargs basename -a -s .conf | rofi -dmenu -p "Select config")
    
    if zenity --question --text="Are you sure you want to connect to $selected_config?" --title="Confirmation"; then
        # zenity --info --text "$selected_config"
        [[ $selected_config ]] && sudo wg-quick up "$configs_path"/"$selected_config".conf
    fi

}


disconnect() {
    # Normally we should have a single connected interface but technically
    # there's nothing stopping us from having multiple active intgerfaces so
    # let's do this in a loop:
    if zenity --question --text="Are you sure you want to disconnect?" --title="Confirmation"; then
        for connected_config in $(nmcli connection show | grep wireguard | awk '{print $1}')
        do
            # zenity --info --text "$connected_config"
            sudo wg-quick down $configs_path/"$connected_config".conf
        done
    fi

}

toggle() {
    if [[ -n "$connected_interface" ]]; then
        disconnect
    else
        connect
    fi
}

print() {
    if [[ $connected_interface ]]
    then
        echo %{u"$green"}%{+u}%{T4}%{F"$green"}%{T-}%{F-} "$connected_interface"
    else
        echo %{T4}%{T-}
    fi
}

case "$1" in
    --connect)
        connect
        ;;
    --disconnect)
        disconnect
        ;;
    --toggle)
        toggle
        ;;
    *)
        print
        ;;
esac