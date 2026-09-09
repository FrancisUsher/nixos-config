# LAN-only *.usher.zone domain, resolved locally but with a real
# publicly-trusted wildcard cert (issued via Cloudflare DNS-01, so no
# public reachability is ever needed - only DNS API access).
#
# bubu-brain's LAN IP is reserved as 192.168.1.199 on the router (GFiber
# app, DHCP reservation on MAC 04:cf:4b:48:e8:d8) - dnsmasq answers every
# usher.zone / *.usher.zone query with that address.
{ config, lib, pkgs, ... }:

let
  lanIP = "192.168.1.199";
  lanInterface = "wlp5s0";
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "francis.w.usher@gmail.com";
    certs."usher.zone" = {
      dnsProvider = "cloudflare";
      environmentFile = "/etc/cloudflare-dns-token.env";
      extraDomainNames = [ "*.usher.zone" ];
      group = "nginx";
    };
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      address = [ "/usher.zone/${lanIP}" ];
      server = [ "1.1.1.1" "1.0.0.1" ];
      interface = [ "lo" lanInterface ];
      # bind-dynamic (rather than bind-interfaces) binds a wildcard socket
      # and tracks interface addresses dynamically, so dnsmasq serves the
      # LAN IPv4 address correctly even if it starts (or restarts, e.g.
      # during nixos-rebuild switch) before dhcpcd has finished acquiring
      # the WiFi lease - bind-interfaces requires the address to already
      # exist at bind time and silently drops it otherwise (observed both
      # on first deploy and on a later switch that restarted dhcpcd and
      # dnsmasq together).
      bind-dynamic = true;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 443 ];
    allowedUDPPorts = [ 53 ];
  };

  services.nginx.virtualHosts."usher.zone" = {
    forceSSL = true;
    useACMEHost = "usher.zone";
    locations."/label".proxyPass = "http://127.0.0.1:8180/print";
  };
}
