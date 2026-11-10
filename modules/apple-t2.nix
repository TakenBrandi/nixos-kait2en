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
  };
}
