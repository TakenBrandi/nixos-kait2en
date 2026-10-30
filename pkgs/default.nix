{ pkgs }:

rec {
  t2-dsp = pkgs.callPackage ./dsp { };
  t2bce-audio-alsa-ucm = pkgs.callPackage ./alsa-ucm { };
  extract-t2-firmware = pkgs.writeShellApplication {
    name = "extract-t2-firmware";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils ];
    text = builtins.readFile ./tools/extract-t2-firmware.sh;
  };
  t2-touchid = pkgs.callPackage ./touchid { };
}
