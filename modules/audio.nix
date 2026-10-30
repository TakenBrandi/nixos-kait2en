{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.apple-t2;
  t2Dsp = pkgs.callPackage ../pkgs/dsp { };
  t2AlsaUcm = pkgs.callPackage ../pkgs/alsa-ucm { };

  t2DspPipewireConfig = pkgs.runCommand "t2-dsp-pipewire-config" {
    passthru.requiredLv2Packages = [ pkgs.bankstown-lv2 pkgs.lsp-plugins ];
  } ''
    mkdir -p $out/share/pipewire/pipewire.conf.d
    ln -s /run/t2-dsp/pipewire.conf $out/share/pipewire/pipewire.conf.d/51-t2-dsp.conf
  '';

  setupScript = pkgs.writeShellScript "t2-audio-dsp-setup" ''
    set -euo pipefail
    mkdir -p /run/t2-dsp

    MODEL="${cfg.dsp.model}"
    if [ "$MODEL" = "auto" ] || [ -z "$MODEL" ]; then
      if [ -r /sys/class/dmi/id/product_name ]; then
        DMI=$(tr -d '\0\r\n' < /sys/class/dmi/id/product_name)
        DETECTED=$(${pkgs.jq}/bin/jq -r --arg dmi "$DMI" '.[$dmi] // empty' "${t2Dsp}/share/t2-dsp/models.json")
        if [ -n "$DETECTED" ]; then
          MODEL="$DETECTED"
        fi
      fi
    fi

    if [ -f "${t2Dsp}/share/t2-dsp/pipewire/$MODEL.conf" ]; then
      cp -f "${t2Dsp}/share/t2-dsp/pipewire/$MODEL.conf" /run/t2-dsp/pipewire.conf
    else
      echo "{}" > /run/t2-dsp/pipewire.conf
    fi
    chmod 644 /run/t2-dsp/pipewire.conf
  '';
in {
  options.hardware.apple-t2.dsp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable KaiT2en audio DSP profiles and speaker protection filters for Apple T2 Macs";
    };
    model = lib.mkOption {
      type = lib.types.str;
      default = "auto";
      example = "16_1";
      description = "Apple T2 hardware model profile for DSP filters ('auto' to detect via DMI product name, or explicit profile like 16_1, 15_1, etc.)";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.dsp.enable) {
    # PipeWire and WirePlumber configuration
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      configPackages = [ t2DspPipewireConfig ];
      wireplumber.enable = lib.mkDefault true;
      wireplumber.configPackages = [ t2Dsp ];
      wireplumber.extraLv2Packages = [ pkgs.bankstown-lv2 pkgs.lsp-plugins ];
      extraLv2Packages = [ pkgs.bankstown-lv2 pkgs.lsp-plugins ];
    };

    # install ALSA UCM configuration
    environment.etc."alsa/ucm2/AppleT2".source = "${t2AlsaUcm}/share/alsa/ucm2/AppleT2";
    environment.etc."alsa/ucm2/conf.d/AppleT2x2".source = "${t2AlsaUcm}/share/alsa/ucm2/conf.d/AppleT2x2";
    environment.etc."alsa/ucm2/conf.d/AppleT2x4".source = "${t2AlsaUcm}/share/alsa/ucm2/conf.d/AppleT2x4";
    environment.etc."alsa/ucm2/conf.d/AppleT2x6".source = "${t2AlsaUcm}/share/alsa/ucm2/conf.d/AppleT2x6";

    # install DSP udev rules
    services.udev.packages = [ t2Dsp ];

    # install WirePlumber DSP configuration and Lua script
    environment.etc."wireplumber/wireplumber.conf.d/51-t2-dsp.conf".source =
      "${t2Dsp}/share/wireplumber/wireplumber.conf.d/51-t2-dsp.conf";
    environment.etc."wireplumber/scripts/t2-default-output.lua".source =
      "${t2Dsp}/share/wireplumber/scripts/t2-default-output.lua";

    # Early runtime generator for model-matched PipeWire filter chain
    system.activationScripts.t2DspSetup = ''
      ${setupScript}
    '';

    systemd.services.t2-audio-dsp-setup = {
      description = "Apple T2 Audio DSP PipeWire Configuration Generator";
      wantedBy = [ "basic.target" ];
      before = [ "pipewire.service" "sound.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = setupScript;
      };
    };

    # expose DSP profiles, tools, and LV2 plugins to system
    environment.systemPackages = [
      t2Dsp
      pkgs.lsp-plugins
      pkgs.bankstown-lv2
    ];
  };
}
