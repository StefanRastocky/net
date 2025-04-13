#!/bin/sh

# connect to internet using ip link, wpa supplicant (if wireless) and dhcpcd for ip address resolv.
# dependencies: wpa_supplicant, dhcpcd, iw, 
#
# supplicant info is read from confPath variable, which is by default /etc/wpa_supplicant/wpa_supplicant.conf
# where desired wireless network data needs to be saved. To append a new network to the file use:
#wpa_passphrase <yourSSID> | grep -v '^\s*#psk=' | sudo tee -a /path/to/your/etc.conf > /dev/null
#wpa_passphrase networkName | grep -v '^\s*#psk=' | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
#

# select interface. If user provided -i flag followed by valid iface name, then select this. if no
# flag provided, then prompt user to select iface using the bash "select" function:
#
# select iface using 'select'
select_interface() {
	interfaces=($(ip link | grep -oP '^\d+: \K[^:]+')) # lists valid ifaces
	# exit if no valid ifaces on the system
	[ "${#interfaces[@]}" -eq 0 ] && echo "No network interfaces accessible on the system." && exit 1
	# display list to user and let select one, use dmenu if $DISPLAY is not empty:
	[ -n "$DISPLAY" ] && iface_name=$(printf "%s\n" "${interfaces[@]}" | dmenu -i -p "Select iface" -l 5 ) || {	
		echo "Select network interface:"
		select iface in "${interfaces[@]}"; do
			[ -n "$iface" ] && echo "Interface $iface selected!" && iface_name="$iface" && break || echo "Selected interface $iface is not accessible on the system"
		done
	}
}

# check for user args:
while getopts ":i:" opt; do
	case $opt in
		i) iface_name=$OPTARG ;;
		*) echo "Usage: $0 [-i interfaceName]" && exit 1 ;;
	esac
done

# check if user selection exists, if yes make it selection of iface, if not, then trigger select_interface function
[ -n "iface_name" ] && ip link show "$iface_name" > /dev/null 2>&1 && iface=$iface_name && echo "Interface $iface selected!" || select_interface
# now enable the interface, if this fails exit. No check if it is already enbled - it might send ip link extra
# enable request for already enabled interface, this should not be problem. We will improve later.
sudo ip link set "$iface_name" up && echo "Interface UP!" || { echo "Failed to enable the interface" ; exit 1; } 

# run wpa_supplicant, let user select from among SSIDs extracted from wpa_supplicant.conf
confPath="/etc/wpa_supplicant/wpa_supplicant.conf"

# first check if interface selected is wireless,
# if yes then check if connection on that interface exists.
# if connection doesn't exist yet, then run wpa_supplicant
# with that iface and selected config file.
iw dev | grep -q "$iface_name" && {
	iw dev $iface_name link 2>/dev/null | grep -q 'Connected to' && echo "Local Wifi Connection exists on $iface_name" || {
		sudo wpa_supplicant -B -dd -i "$iface_name" -c "$confPath" &&
		while ! iw dev "$iface_name" link; do sleep 0.8; done;
		echo "Local Connection Established on $iface_name but no IP acquired yet";
		[ -n "$DISPLAY" ] && notify-send -u low -t 8000 -i ~/.local/share/icons/tp.png "📡WiFi Connected!" "Interface: ${iface_name}\nNo IP acquired!" 
	} 
} ; {
# restart dhcpcd if it is running
	pgrep -x dhcpcd && sudo pkill dhcpcd && notify-send -i ~/.local/share/icons/tp.png "Restarted Dhcpcd 🕰" "Waiting for IP address." && \
	sudo dhcpcd "$iface_name" || sudo dhcpcd "$iface_name"
	IP_addr=$(ip addr show "$iface_name" | grep 'inet ' | awk '{print $2}')
	[ -n "$DISPLAY" ] && \
	notify-send -u low -t 8000 -i ~/.local/share/icons/tp.png \
	"🟢 Obtained IP Address!" "${IP_addr} on ${iface_name}" 
}


