{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.apple-t2;

  # Linux version the patch series in src/patches is rebased onto. The
  # series comes from KaiT2en-Fedora, which maintains it against Fedora's
  # kernel; see src/patches/README.md for what changed for this version.
  patchedKernelVersion = "7.3";

  # One kernelPatches entry per line of src/patches/<set>/series.
  patchSeries = set:
    let
      dir = ../src/patches + "/${set}";
      lines = lib.splitString "\n" (builtins.readFile (dir + "/series"));
      names = lib.filter (l: l != "" && !lib.hasPrefix "#" l) lines;
    in
    map (name: {
      name = lib.removeSuffix ".patch" name;
      patch = dir + "/${name}";
    }) names;

  gpuRuntimePmPatches = patchSeries "gpu-runtime-pm";
  wirelessPatches = patchSeries "wireless";

  patchesEnabled = cfg.kernelPatches.enable
    && (cfg.kernelPatches.gpuRuntimePm || cfg.kernelPatches.wireless);

  kmods = pkgs.callPackage ../pkgs/kernel-modules {
    kernel = config.boot.kernelPackages.kernel;
  };

in {
  options.hardware.apple-t2 = {
    kernelPatches = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Apply KaiT2en Linux kernel runtime patches for AMDGPU GMUX runtime PM and Broadcom WiFi/BT";
      };
      gpuRuntimePm = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Apply AMDGPU and GMUX runtime power management patches";
      };
      wireless = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Apply Broadcom BCM4364 Wi-Fi and Bluetooth runtime patches";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # The patches only apply to one kernel series, so default to it rather
    # than linuxPackages_latest, which moves on to versions they don't fit.
    boot.kernelPackages = lib.mkDefault
      pkgs."linuxPackages_${lib.replaceStrings [ "." ] [ "_" ] patchedKernelVersion}";

    assertions = [
      {
        assertion = !patchesEnabled
          || lib.versions.majorMinor config.boot.kernelPackages.kernel.version == patchedKernelVersion;
        message = ''
          hardware.apple-t2.kernelPatches are rebased onto Linux ${patchedKernelVersion}, but
          boot.kernelPackages is Linux ${config.boot.kernelPackages.kernel.version}. Use
          pkgs.linuxPackages_${lib.replaceStrings [ "." ] [ "_" ] patchedKernelVersion}, or set
          hardware.apple-t2.kernelPatches.enable = false to run this kernel unpatched.
        '';
      }
    ];

    # kernel patches
    boot.kernelPatches = lib.mkMerge [
      (lib.mkIf (cfg.kernelPatches.enable && cfg.kernelPatches.gpuRuntimePm) gpuRuntimePmPatches)
      (lib.mkIf (cfg.kernelPatches.enable && cfg.kernelPatches.wireless) wirelessPatches)
    ];

    # out-of-tree kernel modules
    boot.extraModulePackages = [
      kmods.t2bce_stack
      kmods.t2smc
      kmods.t2gmux
      kmods.t2bdrm
      kmods.t2touchbar
      kmods.t2_precision_trackpad
      kmods.t2_trackpad_actuator
      kmods.hid_t2magicmouse
      kmods.t2thunderbolt
      kmods.t2smp
      kmods.t2sbs
      kmods.t2mfi_fastcharge
    ];

    # early initrd modules for keyboard, storage, and graphics
    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "thunderbolt"
      "t2bce_core"
      "t2bce_dma"
      "t2bce_vhci"
      "t2smc"
      "t2gmux"
    ];

    boot.initrd.kernelModules = [
      "t2bce_core"
      "t2bce_dma"
      "t2bce_vhci"
      "t2smc"
      "t2gmux"
    ];

    # load core Apple T2 drivers on boot
    boot.kernelModules = [
      "t2bce_core"
      "t2bce_dma"
      "t2bce_vhci"
      "t2bce_audio"
      "t2bdrm"
      "t2touchbar"
      "t2smc"
      "t2gmux"
    ];

    # kernel parameters
    boot.kernelParams = [
      "amdgpu.aspm=1"
      "i915.enable_guc=2"
      "intel_iommu=on"
      "iommu=pt"
      "pm_async=off"
      "pcie_aspm=force"
      "pcie_aspm.policy=powersave"
      "pcie_ports=compat"
      "pci=noaer"
      "mem_sleep_default=deep"
      "initcall_blacklist=cmos_init,magicmouse_driver_init"
    ];

    # blacklist conflicting in-tree kernel drivers
    boot.blacklistedKernelModules = [
      "acpi_tad"
      "applesmc"
      "macsmc"
      "hid_apple"
      "hid_appletb_bl"
      "hid_appletb_kbd"
      "hid_magicmouse"
      "appletbdrm"
      "apple_bce"
      "apple_mfi_fastcharge"
      "apple_gmux"
      "sbs"
    ];

    # power management / suspend handling
    powerManagement.enable = lib.mkDefault true;
  };
}
