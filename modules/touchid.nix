{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.apple-t2;
  t2TouchId = pkgs.callPackage ../pkgs/touchid { upstream = cfg.upstreamSource; };
in {
  options.hardware.apple-t2.touchid = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable Apple T2 Touch ID bridge for fprintd, allowing macOS-enrolled fingerprints
        to unlock the lockscreen, GDM/SDDM, and authenticate sudo.
      '';
    };

    bindUser = lib.mkOption {
      type = lib.types.str;
      default = "none";
      example = "alice";
      description = ''
        Linux username that the macOS-enrolled fingers are bound to automatically.
        If set to "none", enrollment can be performed manually with `fprintd-enroll`.
      '';
    };

    macOsUid = lib.mkOption {
      type = lib.types.str;
      default = "auto";
      example = "501";
      description = ''
        macOS UID whose enrolled fingers to verify against. "auto" looks for the first
        macOS UID (501+) with enrolled fingers.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.touchid.enable) {
    # Enable fprintd and PAM fingerprint authentication
    services.fprintd.enable = true;

    # KaiT2en Touch ID bridge daemon
    systemd.services.kait2en-t2-touchid = {
      description = "KaiT2en Touch ID bridge for fprintd";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${t2TouchId}/bin/t2-touchid --socket /run/t2-touchid/fprint.sock --uid ${cfg.touchid.macOsUid} --flags 0 --bind-user ${cfg.touchid.bindUser}";
        Restart = "on-failure";
        RestartSec = 5;

        RuntimeDirectory = "t2-touchid";
        RuntimeDirectoryMode = "0700";
        RuntimeDirectoryPreserve = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      };
    };

    # Direct fprintd to communicate with the virtual storage socket driven by t2-touchid
    systemd.services.fprintd = {
      requires = [ "kait2en-t2-touchid.service" ];
      after = [ "kait2en-t2-touchid.service" ];
      environment = {
        FP_VIRTUAL_DEVICE_STORAGE = "/run/t2-touchid/fprint.sock";
      };
      serviceConfig = {
        ReadWritePaths = [ "/run/t2-touchid" ];
        RuntimeDirectory = "t2-touchid";
        RuntimeDirectoryMode = "0700";
        RuntimeDirectoryPreserve = true;
      };
    };

    # Install D-Bus policies and binary
    services.dbus.packages = [ t2TouchId ];
    environment.systemPackages = [ t2TouchId ];
  };
}
