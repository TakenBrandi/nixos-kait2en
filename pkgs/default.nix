# upstream: KaiT2en-Fedora source tree (the kait2en-fedora flake input).
{ pkgs, upstream }:

rec {
  t2-dsp = pkgs.callPackage ./dsp { inherit upstream; };
  t2bce-audio-alsa-ucm = pkgs.callPackage ./alsa-ucm { inherit upstream; };
  extract-t2-firmware = pkgs.writeShellApplication {
    name = "extract-t2-firmware";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils ];
    text = builtins.readFile ./tools/extract-t2-firmware.sh;
  };
  t2-touchid = pkgs.callPackage ./touchid { inherit upstream; };
}
