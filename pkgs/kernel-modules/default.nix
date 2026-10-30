{ lib, callPackage, kernel, kmod, kmodigest ? null }:

let
  mkKmod = callPackage ./mk-kmod.nix { inherit kernel kmod kmodigest; };
in {
  t2bce_stack = callPackage ./t2bce_stack.nix { inherit kernel kmod kmodigest; };

  t2smc = mkKmod {
    pname = "t2smc";
    src = ../../src/modules/t2smc;
    meta.description = "Apple T2 System Management Controller (SMC) driver";
  };

  t2gmux = mkKmod {
    pname = "t2gmux";
    src = ../../src/modules/t2gmux;
    meta.description = "Apple GMUX dual-GPU switching driver";
  };

  t2bdrm = mkKmod {
    pname = "t2bdrm";
    src = ../../src/modules/t2bdrm;
    meta.description = "Apple T2 Touch Bar DRM display driver";
  };

  t2touchbar = mkKmod {
    pname = "t2touchbar";
    src = ../../src/modules/t2touchbar;
    extraMakeFlags = [ "ccflags-y=-I$(srctree)/drivers/hid" ];
    meta.description = "Apple T2 Touch Bar input and backlight driver";
  };

  t2_precision_trackpad = mkKmod {
    pname = "t2_precision_trackpad";
    src = ../../src/modules/t2_precision_trackpad;
    meta.description = "Apple T2 Force Touch Precision Trackpad driver";
  };

  t2_trackpad_actuator = mkKmod {
    pname = "t2_trackpad_actuator";
    src = ../../src/modules/t2_trackpad_actuator;
    meta.description = "Apple T2 Trackpad Haptic Actuator driver";
  };

  hid_t2magicmouse = mkKmod {
    pname = "hid_t2magicmouse";
    src = ../../src/modules/hid_t2magicmouse;
    meta.description = "Apple T2 Magic Mouse and multi-touch trackpad protocol driver";
  };

  t2thunderbolt = mkKmod {
    pname = "t2thunderbolt";
    src = ../../src/modules/t2thunderbolt;
    meta.description = "Apple T2 Thunderbolt Titan Ridge power management driver";
  };

  t2smp = mkKmod {
    pname = "t2smp";
    src = ../../src/modules/t2smp;
    meta.description = "Apple T2 System Management Protocol and sleep driver";
  };

  t2sbs = mkKmod {
    pname = "t2sbs";
    src = ../../src/modules/t2sbs;
    meta.description = "Apple T2 Smart Battery System driver";
  };

  t2mfi_fastcharge = mkKmod {
    pname = "t2mfi_fastcharge";
    src = ../../src/modules/t2mfi_fastcharge;
    meta.description = "Apple T2 MFi Fast Charge driver";
  };
}
