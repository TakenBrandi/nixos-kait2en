{ config, lib, pkgs, ... }:

let
  cfg = config.hardware.apple-t2;

  # Linux series the upstream runtime patches apply to. KaiT2en-Fedora
  # maintains them against Fedora's kernel; bump this together with the
  # kait2en-fedora input when upstream moves on.
  patchedKernelVersion = "7.3";

  # Patches upstream's installers skip on this kernel because it already
  # contains them (scripts/fedora/install-<set>.sh, patch_needed_for_kernel).
  inKernel = {
    gpu-runtime-pm = [
      "0001-drm-amdgpu-reset-VI-ASIC-on-MacBookPro15-1.patch" # merged in 7.3
    ];
  };

  # One kernelPatches entry per line of patches/runtime/<set>/series upstream.
  patchSeries = set:
    let
      dir = cfg.upstreamSource + "/patches/runtime/${set}";
      lines = lib.splitString "\n" (builtins.readFile (dir + "/series"));
      names = lib.filter
        (l: l != "" && !lib.hasPrefix "#" l && !lib.elem l (inKernel.${set} or [ ]))
        lines;
    in
    map (name: {
      name = "kait2en-${set}-${lib.removeSuffix ".patch" name}";
      patch = dir + "/${name}";
    }) names;

  # Option name -> upstream patch set.
  patchSets = {
    gpuRuntimePm = "gpu-runtime-pm";
    wireless = "wireless";
    i915 = "i915";
    thunderbolt = "thunderbolt";
  };

  setEnabled = opt: cfg.kernelPatches.enable && cfg.kernelPatches.${opt};
  patchesEnabled = lib.any setEnabled (lib.attrNames patchSets);

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
        description = ''
          Apply the Broadcom Wi-Fi and Bluetooth runtime patches (BCM4364,
          BCM4377): suspend/resume fixes, power saving and AWDL support.
        '';
      };
      i915 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Apply the i915 runtime patches: PSR on Apple T2 eDP panels and
          restoring the GMUX brightness on T2 MacBook Pros.
        '';
      };
      thunderbolt = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Apply the Thunderbolt runtime patch (Titan Ridge and Ice Lake RTD3),
          which lets the idle controller power down. It replaces the
          out-of-tree t2thunderbolt module.
        '';
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
    boot.kernelPatches = lib.concatLists (lib.mapAttrsToList
      (opt: set: lib.optionals (setEnabled opt) (patchSeries set))
      patchSets);

    # GMUX must provide the power callbacks before AMDGPU probes
    # (upstream: /usr/lib/modprobe.d/kait2en-gpu-runtime-pm.conf).
    boot.extraModprobeConfig = lib.mkIf (setEnabled "gpuRuntimePm") ''
      softdep amdgpu pre: t2gmux
    '';

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
      kmods.t2smp
      kmods.t2sbs
      kmods.t2mfi_fastcharge
    ]
    # Upstream retired t2thunderbolt in favour of the patched in-tree driver.
    ++ lib.optional (!setEnabled "thunderbolt") kmods.t2thunderbolt;

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
      "pcie_aspm=force"
      "pcie_aspm.policy=powersave"
      "pci=noaer"
      "mem_sleep_default=deep"
      "initcall_blacklist=cmos_init,magicmouse_driver_init"
    ]
    # Upstream dropped these: with the wireless patches the BCM4364 and BCM4377
    # survive S3 with asynchronous suspend, and Thunderbolt runtime PM needs
    # the PCIe port services. Keep them only when those patches are off.
    ++ lib.optional (!setEnabled "wireless") "pm_async=off"
    ++ lib.optional (!setEnabled "thunderbolt") "pcie_ports=compat";

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
