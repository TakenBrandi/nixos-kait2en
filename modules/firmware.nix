{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.apple-t2;

  onlineFirmware = pkgs.fetchFromGitHub {
    owner = "RNGDesign";
    repo = "t2-apple-fw";
    rev = "d25434275e67a4230f1c5d27f0e32a41fb5de404";
    hash = "sha256-Q0/JWiCHi+OjiYXXDyLIcU5hrIa/K1Zq5Fkbeg5TLb4=";
  };

  firmwareSrc = if cfg.firmware.path != null then cfg.firmware.path else onlineFirmware;

  firmwarePkg = pkgs.stdenvNoCC.mkDerivation {
    name = "apple-t2-broadcom-firmware";
    src = firmwareSrc;
    dontBuild = true;
    installPhase = ''
      install -d $out/lib/firmware/brcm
      if [ -d "$src/brcm" ]; then
        cp -r $src/brcm/* $out/lib/firmware/brcm/
      else
        cp -r $src/* $out/lib/firmware/brcm/
      fi
    '';
  };
in {
  options.hardware.apple-t2.firmware = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Broadcom Wi-Fi and Bluetooth firmware loading for Apple T2 Macs";
    };
    path = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "./firmware";
      description = ''
        path to local directory containing extracted Apple Broadcom firmware files
        If null (the default), firmware is automatically fetched from the online repository
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.firmware.enable) {
    hardware.firmware = [ firmwarePkg ];
  };
}
