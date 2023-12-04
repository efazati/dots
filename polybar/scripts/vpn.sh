
#!/bin/sh

if [ "$(pgrep openvpn)" ]; then
    echo " VPN"
else
    echo " Vpn"
fi
