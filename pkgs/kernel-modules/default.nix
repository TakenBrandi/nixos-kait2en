{ lib, callPackage, kernel, kmod, upstream, kmodigest ? null }:

# Modules are built from KaiT2en-Fedora's source tree (`upstream`, the
# kait2en-fedora flake input) as is. Only t2thunderbolt, which upstream
# retired, is still kept in this repository.

let
  mkKmod = callPackage ./mk-kmod.nix { inherit kernel kmod kmodigest; };

  fromUpstream = pname: description: extra: mkKmod ({
    inherit pname;
    src = upstream + "/modules/${pname}";
    meta.description = description;
  } // extra);
in {
  t2bce_stack = callPackage ./t2bce_stack.nix { inherit kernel kmod kmodigest upstream; };

  t2smc = fromUpstream "t2smc" "Apple T2 System Management Controller (SMC) driver" { };

  t2gmux = fromUpstream "t2gmux" "Apple GMUX dual-GPU switching driver" { };

  t2bdrm = fromUpstream "t2bdrm" "Apple T2 Touch Bar DRM display driver" { };

  t2touchbar = fromUpstream "t2touchbar" "Apple T2 Touch Bar input and backlight driver" {
    extraMakeFlags = [ "ccflags-y=-I$(srctree)/drivers/hid" ];
  };

  t2_precision_trackpad = fromUpstream "t2_precision_trackpad"
    "Apple T2 Force Touch Precision Trackpad driver" { };

  t2_trackpad_actuator = fromUpstream "t2_trackpad_actuator"
    "Apple T2 Trackpad Haptic Actuator driver" { };

  hid_t2magicmouse = fromUpstream "hid_t2magicmouse"
    "Apple T2 Magic Mouse and multi-touch trackpad protocol driver" { };

  t2smp = fromUpstream "t2smp" "Apple T2 System Management Protocol and sleep driver" { };

  t2sbs = fromUpstream "t2sbs" "Apple T2 Smart Battery System driver" { };

  t2mfi_fastcharge = fromUpstream "t2mfi_fastcharge" "Apple T2 MFi Fast Charge driver" { };

  # Retired upstream in favour of the Thunderbolt runtime patch; only used
  # when hardware.apple-t2.kernelPatches.thunderbolt is disabled.
  t2thunderbolt = mkKmod {
    pname = "t2thunderbolt";
    src = ../../src/modules/t2thunderbolt;
    meta.description = "Apple T2 Thunderbolt Titan Ridge power management driver";
  };
}
