# Automagic AP
A shell script for Raspbian OS to create a wireless access point if no known networks can be found.

# Connectivity Routine
- Looks for known network(s) over `wlan0` interface.
  - If a known network is found, 
    - Activates **Client (CLI)** mode.
  - If known network(s) cannot be found, 
    - Activates **Access Point (AP)** mode.
      - Static IP Address : `10.0.0.200`
      - Access Point SSID: `NeurobionicsRPi`
      - Access Point Passphrase: `neurobionics`
 
- Searches for known network(s) again if no devices are connected to the Access Point after a timeout *(30 seconds)*.
- If an ethernet connection is detected, the Raspberry Pi acts as a WiFi router.
