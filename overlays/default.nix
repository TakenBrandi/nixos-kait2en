# upstream: KaiT2en-Fedora source tree the kernel modules are built from.
{ upstream }:

final: prev:

let
  kait2enPkgs = import ../pkgs { pkgs = final; inherit upstream; };
in {
  inherit (kait2enPkgs) t2-dsp t2bce-audio-alsa-ucm extract-t2-firmware t2-touchid;

  tiny-dfr = prev.tiny-dfr.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/backlight.rs \
        --replace-fail '"appletb_backlight"' '"appletb_backlight", "t2tb_backlight"' \
        --replace-fail '"apple-panel-bl",' '"apple-panel-bl", "amdgpu_bl",' \
        --replace-fail 'let display_bl_path = find_display_backlight().unwrap();' 'let display_bl_path = find_display_backlight().unwrap_or_else(|_| bl_path.clone());'
    '';
  });

  linuxKernel = prev.linuxKernel // {
    packagesFor = kernel: (prev.linuxKernel.packagesFor kernel).extend (kfinal: kprev:
      import ../pkgs/kernel-modules {
        lib = final.lib;
        callPackage = kfinal.callPackage;
        inherit kernel;
        kmod = final.kmod;
        inherit upstream;
      }
    );
  };
}
