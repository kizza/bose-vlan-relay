# Bose VLAN Relay 🔊

Play music on a Bose soundbar without flattening your VLANs. Tested with a **Bose Smart Soundbar 900 and Music Assistant**; other setups may work too.

## Why a relay?

In this setup, the Bose did not accept connections from Music Assistant on another subnet, even though the networks could route between each other. A Raspberry Pi (or Debian host) on the **Bose's subnet** advertises a separate Cast receiver over mDNS and forwards its TCP connections to the real soundbar. The Bose sees a connection from its own subnet, and Music Assistant can play to it.

If your gateway can source-NAT this traffic to an address on the Bose's subnet, you might not need the Pi. Either approach still needs cross-VLAN Cast discovery.

## Installation

1. Clone this repository **as your normal user** on the Pi (install Git first if needed). The installer sets up Socat and Avahi, generates a stable Cast ID in `.env`, and saves nearby Cast announcements to `cast.original.txt`. It does **not** start the relay.

   ```sh
   git clone https://github.com/kizza/bose-vlan-relay.git
   cd bose-vlan-relay
   sudo ./bin/install
   ```
2. Find your Bose in `cast.original.txt`. Copy the template and set up your local files:

   ```sh
   cp cast.txt.example cast.txt
   nano .env
   nano cast.txt
   ```

   In `.env`, set the Pi's `RELAY_IP`, the soundbar's `BOSE_IP`, and the client CIDRs allowed to connect. Keep the generated `CAST_ID`. In `cast.txt`, copy your Bose's TXT entries from `cast.original.txt`, one `key=value` per line, keeping empty values like `rs=`. The relay substitutes its own `id` and `fn` using `CAST_ID` and `CAST_NAME`.
3. Run `sudo ./bin/configure` to install and start the service. Run it again whenever you change the configuration or relay code—there's no need to reinstall dependencies.

## Usage

Look for **Bose 900 Relay** in Music Assistant and try playing something. The client must reach the Pi on TCP **8008, 8009, and 8443** (plus **8082** for the Bose API); the Pi must reach the Bose on those ports. Arrange for `_googlecast._tcp` mDNS discovery to cross VLANs. **Do not expose these ports to the internet.**

```sh
./bin/discover                         # Refresh cast.original.txt
sudo ./bin/configure                   # Apply changes and restart
sudo systemctl status bose-vlan-relay
sudo journalctl -u bose-vlan-relay -f
```

The local `.env`, `cast.txt`, and `cast.original.txt` are ignored by Git. An older `.discovery` file is also left untouched and ignored. [Bose Home Assistant](https://github.com/cavefire/Bose-Homeassistant) might benefit from the same relay, but has **not** been tested with it.

This is an experimental TCP relay, not a Cast emulator: it forwards the Bose's responses unchanged, so other clients might object to its virtual ID or TLS certificate. [MIT licensed](LICENSE). ✨
