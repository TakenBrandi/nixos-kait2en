{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.apple-t2;

  # Apple's boot GPU preference: 4 attribute bytes, then a u32 that is
  # 1 for the integrated and 0 for the discrete GPU.
  bootGpuVar = "/sys/firmware/efi/efivars/gpu-power-prefs-fa4ce28d-b62f-4c99-9cc3-6815686e30f9";
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

    # The firmware switches the panel to the GPU named in gpu-power-prefs
    # before the OS starts, and only the GPU that drives the panel at boot
    # can drive it under Linux. macOS sets the discrete GPU on every boot,
    # which keeps the dGPU awake in hybrid mode. Write the wanted GPU on
    # every boot; it applies from the next power-on. (Upstream's
    # t2-gpu-preboot also restarts once after macOS; not packaged yet.)
    systemd.services.kait2en-boot-gpu = {
      description = "Select the boot GPU of dual-GPU Apple T2 MacBook Pros";
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = bootGpuVar;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.e2fsprogs pkgs.coreutils ];
      script = ''
        case "$(cat /sys/class/dmi/id/product_name)" in
          MacBookPro15,1|MacBookPro16,1|MacBookPro16,4) ;;
          *) exit 0 ;;
        esac
        want='${if cfg.graphics.mode == "discrete" then "00" else "01"}'
        have=$(od -An -tx1 -j4 -N1 ${bootGpuVar} | tr -d ' ')
        [ "$have" = "$want" ] && exit 0
        chattr -i ${bootGpuVar}
        trap 'chattr +i ${bootGpuVar} 2>/dev/null || true' EXIT
        printf '\x07\x00\x00\x00\x'"$want"'\x00\x00\x00' > ${bootGpuVar}
        echo "boot GPU set to ${if cfg.graphics.mode == "discrete" then "discrete" else "integrated"}; applies from the next boot"
      '';
    };

    # dynamic PRIME offloading support
    hardware.graphics = {
      enable = lib.mkDefault true;
      enable32Bit = lib.mkDefault true;
    };
  };
}
