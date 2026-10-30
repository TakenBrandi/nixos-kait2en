{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.apple-t2;

  gpuRuntimePmPatches = [
    { name = "0001-drm-amdgpu-reset-VI-ASIC-on-MacBookPro15-1"; patch = ../src/patches/gpu-runtime-pm/0001-drm-amdgpu-reset-VI-ASIC-on-MacBookPro15-1.patch; }
    { name = "0002-drm-amdgpu-Add-Apple-GMUX-runtime-PM-support"; patch = ../src/patches/gpu-runtime-pm/0002-drm-amdgpu-Add-Apple-GMUX-runtime-PM-support.patch; }
    { name = "0003-drm-amdgpu-add-support-for-5K-iMacs"; patch = ../src/patches/gpu-runtime-pm/0003-drm-amdgpu-add-support-for-5K-iMacs.patch; }
    { name = "0004-drm-amdgpu-catch-register-access-while-GMUX-keeps-the-GPU-off"; patch = ../src/patches/gpu-runtime-pm/0004-drm-amdgpu-catch-register-access-while-GMUX-keeps-the-GPU-off.patch; }
    { name = "0005-drm-amd-display-refuse-DP-AUX-while-GMUX-keeps-the-GPU-off"; patch = ../src/patches/gpu-runtime-pm/0005-drm-amd-display-refuse-DP-AUX-while-GMUX-keeps-the-GPU-off.patch; }
    { name = "0006-drm-amdgpu-skip-AC-DC-notification-while-the-GPU-is-runtime-suspended"; patch = ../src/patches/gpu-runtime-pm/0006-drm-amdgpu-skip-AC-DC-notification-while-the-GPU-is-runtime-suspended.patch; }
    { name = "0007-drm-amd-display-skip-panel-power-savings-on-eDP-links-without-a-panel"; patch = ../src/patches/gpu-runtime-pm/0007-drm-amd-display-skip-panel-power-savings-on-eDP-links-without-a-panel.patch; }
    { name = "0008-drm-amd-pm-use-the-VBIOS-trained-UCLK-levels-on-the-MacBookPro16-1"; patch = ../src/patches/gpu-runtime-pm/0008-drm-amd-pm-use-the-VBIOS-trained-UCLK-levels-on-the-MacBookPro16-1.patch; }
    { name = "0009-drm-amd-pm-let-Apple-Navi-boards-lower-the-power-limit-to-40-percent"; patch = ../src/patches/gpu-runtime-pm/0009-drm-amd-pm-let-Apple-Navi-boards-lower-the-power-limit-to-40-percent.patch; }
    { name = "0011-drm-amd-pm-remove-UMC-CDR-workaround-for-Apple-systems"; patch = ../src/patches/gpu-runtime-pm/0011-drm-amd-pm-remove-UMC-CDR-workaround-for-Apple-systems.patch; }
    { name = "0012-drm-amd-display-avoid-MPC-pipe-split-on-the-MacBookPro16-1"; patch = ../src/patches/gpu-runtime-pm/0012-drm-amd-display-avoid-MPC-pipe-split-on-the-MacBookPro16-1.patch; }
  ];

  wirelessPatches = [
    { name = "0001-wifi-brcmfmac-disable-TX-beamforming-on-BCM4364"; patch = ../src/patches/wireless/0001-wifi-brcmfmac-disable-TX-beamforming-on-BCM4364.patch; }
    { name = "0002-Bluetooth-btbcm-raise-ACL-priority-on-Apple-Broadcom-controllers"; patch = ../src/patches/wireless/0002-Bluetooth-btbcm-raise-ACL-priority-on-Apple-Broadcom-controllers.patch; }
    { name = "0003-wifi-brcmfmac-use-a-200-ms-power-save-timeout-by-default"; patch = ../src/patches/wireless/0003-wifi-brcmfmac-use-a-200-ms-power-save-timeout-by-default.patch; }
    { name = "0004-wifi-brcmfmac-match-firmware-capabilities-as-whole-words"; patch = ../src/patches/wireless/0004-wifi-brcmfmac-match-firmware-capabilities-as-whole-words.patch; }
    { name = "0005-wifi-brcmfmac-leave-the-AP-4-way-handshake-to-the-host-on-Apple-chips"; patch = ../src/patches/wireless/0005-wifi-brcmfmac-leave-the-AP-4-way-handshake-to-the-host-on-Apple-chips.patch; }
  ];

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
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

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
