{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.apple-t2;
in {
  options.hardware.apple-t2.graphics = {
    mode = lib.mkOption {
      type = lib.types.enum [ "hybrid" "discrete" "integrated" ];
      default = "hybrid";
      description = ''
        Graphics mode for dual-GPU Apple T2 Macs (MacBook Pro 15" and 16" with Intel + AMD).
        - hybrid: Intel UHD 630 drives the display, AMD GPU sleeps in D3cold (0W) and activates via DRI_PRIME=1.
        - discrete: AMD GPU stays primary.
        - integrated: Intel GPU only (where supported).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # early DRM loading in initrd
    boot.initrd.kernelModules = [ "i915" "amdgpu" ];

    # runtime power management for AMD GPU
    services.udev.extraRules = lib.mkIf (cfg.graphics.mode == "hybrid") ''
      # enable runtime power management for AMD dGPU (D3cold sleep when idle)
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1002", ATTR{power/control}="auto"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{power/control}="auto"
    '';

    # dynamic PRIME offloading support
    hardware.graphics = {
      enable = lib.mkDefault true;
      enable32Bit = lib.mkDefault true;
    };
  };
}
