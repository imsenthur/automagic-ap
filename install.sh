#!/bin/bash
interfaceWifi=wlan0
interfaceWired=eth0
ipAddress=10.0.0.200/24
	
# Change over to systemd-networkd
# Refer to https://raspberrypi.stackexchange.com/questions/108592
# Uninstall classic networking
apt --autoremove -y purge ifupdown dhcpcd5 isc-dhcp-client isc-dhcp-common rsyslog
apt-mark hold ifupdown dhcpcd5 isc-dhcp-client isc-dhcp-common rsyslog raspberrypi-net-mods openresolv
rm -r /etc/network /etc/dhcp

# setup/enable systemd-resolved and systemd-networkd
apt --autoremove -y purge avahi-daemon
apt-mark hold avahi-daemon libnss-mdns
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable systemd-networkd.service systemd-resolved.service

## Install configuration files for systemd-networkd
cat > /etc/systemd/network/04-${interfaceWired}.network <<-EOF
	[Match]
	Name=$interfaceWired
	[Network]
	DHCP=yes
	MulticastDNS=yes
EOF

cat > /etc/systemd/network/08-${interfaceWifi}-CLI.network <<-EOF
	[Match]
	Name=$interfaceWifi
	[Network]
	DHCP=yes
	MulticastDNS=yes
EOF
		
cat > /etc/systemd/network/12-${interfaceWifi}-AP.network <<-EOF
	[Match]
	Name=$interfaceWifi
	[Network]
	Address=$ipAddress
	IPForward=yes
	IPMasquerade=yes
	DHCPServer=yes
	MulticastDNS=yes
	[DHCPServer]
	DNS=1.1.1.1
EOF

cp $(pwd)/auto-hotspot /usr/local/sbin/
chmod +x /usr/local/sbin/auto-hotspot

## Install systemd-service to configure interface automatically
if [ ! -f /etc/systemd/system/wpa_cli@${interfaceWifi}.service ] ; then
	cat > /etc/systemd/system/wpa_cli@${interfaceWifi}.service <<-EOF
		[Unit]
		Description=Wpa_cli to Automatically Create an Accesspoint if no Client Connection is Available
		After=wpa_supplicant@%i.service
		BindsTo=wpa_supplicant@%i.service
		[Service]
		ExecStart=/sbin/wpa_cli -i %I -a /usr/local/sbin/auto-hotspot
		Restart=on-failure
		RestartSec=1
		[Install]
		WantedBy=multi-user.target
	EOF
else
  echo "wpa_cli@$interfaceWifi.service is already installed"
fi

systemctl daemon-reload
systemctl enable wpa_cli@${interfaceWifi}.service
echo "Reboot now!"
exit 0
