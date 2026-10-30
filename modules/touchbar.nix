{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.apple-t2;
in {
  options.hardware.apple-t2.touchbar = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Touch Bar support using t2bdrm/t2touchbar and tiny-dfr";
    };

    mediaLayerDefault = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show media controls (volume, brightness, playback) by default instead of F1-F12";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.touchbar.enable) {
    # enable Touch Bar userspace display daemon
    hardware.apple.touchBar = {
      enable = lib.mkDefault true;
      settings = {
        MediaLayerDefault = lib.mkDefault cfg.touchbar.mediaLayerDefault;
      };
    };

    # Udev rules matching kait2en module names so tiny-dfr and Mutter/KDE handle the Touch Bar correctly
    services.udev.extraRules = ''
      # Ensure Touch Bar switches to DRM framebuffer mode (USB config 2)
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="05ac", ATTR{idProduct}=="8302", ATTR{bConfigurationValue}=="1", ATTR{bConfigurationValue}="0", ATTR{bConfigurationValue}="2"

      # Isolate Touch Bar DRM display to seat-touchbar so Mutter/KDE does not use it as a desktop monitor
      SUBSYSTEM=="drm", KERNEL=="card*", DRIVERS=="t2bdrm", TAG-="master-of-seat", ENV{ID_SEAT}="seat-touchbar"

      # Systemd device alias for tiny-dfr display binding (BindsTo=dev-tiny_dfr_display.device)
      SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="t2bdrm", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/tiny_dfr_display", ENV{SYSTEMD_WANTS}="tiny-dfr.service"

      # Systemd device alias for Touch Bar backlight (appletb_backlight / t2tb_backlight)
      SUBSYSTEM=="backlight", KERNEL=="appletb_backlight|t2tb_backlight", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/tiny_dfr_backlight"

      # Display backlight alias fallback for discrete AMD graphics (MacBook Pro 15,1 / 16,1), Intel (13-inch), and GMUX
      SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl*|intel_backlight|gmux_backlight|apple-panel-bl|acpi_video0", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/tiny_dfr_display_backlight"

      # Touch Bar input device rules
      SUBSYSTEM=="input", ATTR{name}=="Apple Inc. Touch Bar Display Touchpad", TAG+="systemd", ENV{ID_SEAT}="seat-touchbar", ENV{SYSTEMD_WANTS}="tiny-dfr.service"
      SUBSYSTEM=="input", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="8302", TAG+="systemd", ENV{ID_SEAT}="seat-touchbar", ENV{SYSTEMD_WANTS}="tiny-dfr.service"
    '';

    # Suspend/resume fix: restart tiny-dfr across sleep transitions so it does not hold stale DRM file descriptors
    systemd.services.touchbar-sleep-fix = {
      description = "Restart tiny-dfr around sleep to refresh DRM descriptors";
      before = [ "sleep.target" ];
      wantedBy = [ "sleep.target" ];
      unitConfig.StopWhenUnneeded = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.systemd}/bin/systemctl --no-block stop tiny-dfr.service";
        ExecStop = "${pkgs.systemd}/bin/systemctl --no-block restart tiny-dfr.service";
      };
    };
  };
}
