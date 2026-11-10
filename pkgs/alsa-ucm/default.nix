{ stdenv, lib, upstream }:

stdenv.mkDerivation {
  pname = "t2bce-audio-alsa-ucm";
  version = "1.0.0";

  src = upstream + "/modules/t2bce_audio-alsa-ucm-conf";

  installPhase = ''
    install -d $out/share/alsa/ucm2
    cp -r ucm2/* $out/share/alsa/ucm2/
  '';

  meta = with lib; {
    description = "ALSA Use Case Manager (UCM2) configuration for Apple T2 Audio";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
