# net

A minimal shell script to connect to the internet via `ip`, `wpa_supplicant`, and `dhcpcd`. Supports both wired and wireless interfaces.

Optionally uses `dmenu` for interface selection `notify-send` to post progress in the GUI. Falls back on command line interface for console use.

## Prerequisites:
### dependencies
  - [`iproute2`](https://wiki.linuxfoundation.org/networking/iproute2) (for the `ip` command)
  - [`wpa_supplicant`](https://w1.fi/wpa_supplicant/)
  - [`dhcpcd`](https://roy.marples.name/projects/dhcpcd/)
  - [`iw`](https://wireless.wiki.kernel.org/en/users/documentation/iw)
  
### optional dependencies
  - [`dmenu`](https://tools.suckless.org/dmenu/) – for graphical interface selection (requires `$display`).
  - [`notify-send`](https://www.freedesktop.org/wiki/software/notification-spec/) – for desktop notifications.
  - a notification icon (e.g., located at `~/.local/share/icons/tp.png`).

### Add a WPA2 Wi-Fi network (for wireless connections only)
Use:
```bash
wpa_passphrase "YourSSID" | grep -v '^\s*#psk=' | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null
```
This adds a new entry in your wpa supplicant config file for the wireless network where you want to connect. Make sure the config file path is correct for your system.

## Features
  
  - **Interactive Interface Selection:**  
    Uses `dmenu` (optional) for a graphical selection if a display is available; otherwise, falls back to a command-line prompt.
  - **Wireless Connection Setup:**  
    Automatically runs `wpa_supplicant` when a wireless interface is detected and manages your WiFi connection details.
  - **IP Assignment:**  
    Uses `dhcpcd` to assign an IP address after a connection is established.
  - **Notifications:**  
    Integrates with `notify-send` to display desktop notifications about connection status (opitional).

## Usage
  
  1. **Make the script executable:**
  
     ```bash
     chmod +x net
     ```
  
  2. **Run the script:**
  
     ```bash
     ./net
     ```
or invoke through dmenu.
  
     Optionally, specify the network interface (for use in scripts). In interactive use see **Run the script** above:
  
     ```bash
     ./net -i <interface_name>
     ```
  
  3. **Follow the prompts:**  
     - If no interface flag is given, the script lists available network interfaces.
     - For graphical users, `dmenu` will appear (if available) for interactive selection.
     - notifications or shell will inform you about the progress of connection.
  
## How It Works
  
  - **Interface Detection:**  
    The script retrieves available interfaces using `ip link` and either auto-selects one or prompts the user.
  - **Wireless Check:**  
    If the selected interface is wireless, the script checks for an existing connection. If none exists, it launches `wpa_supplicant` with the configuration file `/etc/wpa_supplicant/wpa_supplicant.conf`.
  - **IP Assignment:**  
    After a connection is established, `dhcpcd` (or a restarted instance) acquires an IP address.
  
## Customization
  
  - **Configuration File:**  
    By default, the WiFi settings are read from `/etc/wpa_supplicant/wpa_supplicant.conf`. Adjust this variable in the script if needed.
  - **Interface Selection:**  
    Use the `-i` flag to bypass interactive selection if you prefer a non-interactive mode.
  
## License
  
  This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
