# Tri(10/100/1000)-Mode-Ethernet-MAC
Ethernet-MAC System verilog
## 802.3 Ethernet packet and frame structure
| Preamble | Start of frame delimiter | MAC destination | MAC source 802.1Q tag (optional) | Ethertype (Ethernet II) or length (IEEE 802.3) | Payload | Frame check sequence (32‑bit CRC) | Interpacket gap |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 7 octets | 1 octet | 6 octets | 6 octets (4 octets) | 2 octets | 46–1500 octets | 4 octets | 12 octets |
