#!/bin/bash

# Überprüfung, ob die IP oder der IP-Bereich übergeben wurde
if [ -z "$1" ]; then
  echo "Usage: $0 <IP-Range>"
  exit 1
fi

IP_RANGE=$1

echo "[*] Starte Ping-Scan für IP-Bereich: $IP_RANGE"
# Ping-Scan zum Finden aktiver Hosts
LIVE_HOSTS=$(nmap -sn $IP_RANGE | grep "Nmap scan report for" | awk '{print $5}')

if [ -z "$LIVE_HOSTS" ]; then
  echo "[!] Keine aktiven Hosts gefunden."
  exit 1
fi

echo "[*] Aktive Hosts gefunden:"
echo "$LIVE_HOSTS"

# Schleife durch alle gefundenen Hosts
for IP in $LIVE_HOSTS; do
  echo "[*] Starte Nmap-Scan für Host: $IP"
  # Nmap-Scan mit Versions- und OS-Erkennung
  nmap -sV -O $IP -oN nmap_scan_$IP.txt

  # Aus den Nmap-Scan-Ergebnissen extrahieren wir die gefundenen Dienste und Versionen
  SERVICES=$(grep "open" nmap_scan_$IP.txt | awk '{print $3" "$4}')
  
  echo "[*] Gefundene Dienste und Versionen:"
  echo "$SERVICES"

  # Suche nach Exploits für jede gefundene Version
  echo "[*] Suche nach Exploits mit searchsploit..."
  while IFS= read -r SERVICE; do
    if [ -n "$SERVICE" ]; then
      VERSION=$(echo $SERVICE | awk '{print $2}')
      searchsploit "$SERVICE" "$VERSION" | tee searchsploit_$IP.txt
    fi
  done <<< "$SERVICES"

  echo "[*] Exploit-Suche abgeschlossen für Host: $IP"
done

echo "[*] Scan und Exploit-Suche abgeschlossen."
