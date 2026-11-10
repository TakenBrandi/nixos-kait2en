{ config, lib, pkgs, ... }:

{
  imports = [
    ./kernel.nix
    ./graphics.nix
    ./audio.nix
    ./touchbar.nix
    ./firmware.nix
    ./touchid.nix
  ];

  options.hardware.apple-t2 = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Apple T2 Mac hardware support (KaiT2en modules, patches, DSP, and power management)";
    };
  };

  config = lib.mkIf config.hardware.apple-t2.enable {
    nixpkgs.overlays = [
      (import ../overlays { upstream = config.hardware.apple-t2.upstreamSource; })
    ];

    # Internal T2 CDC-NCM link (05ac:8233) that Touch ID and the other T2
    # services talk over (upstream: t2-services/shared/integration). Keep
    # NetworkManager off it so it isn't offered as a wired network, and bring
    # it up with an IPv6 link-local address instead.
    networking.networkmanager.unmanaged = [ "mac:ac:de:48:00:11:22" ];
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ENV{ID_BUS}=="usb", ENV{ID_VENDOR_ID}=="05ac", ENV{ID_MODEL_ID}=="8233", ENV{ID_USB_DRIVER}=="cdc_ncm", RUN+="${pkgs.iproute2}/bin/ip link set dev $name addrgenmode eui64", RUN+="${pkgs.iproute2}/bin/ip link set dev $name up"
    '';
  };
}
