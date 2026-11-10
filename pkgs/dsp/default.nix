{ stdenv, lib, python3, coreutils, upstream }:

stdenv.mkDerivation {
  pname = "t2-dsp";
  version = "1.0.0";

  src = upstream + "/dsp";

  nativeBuildInputs = [ python3 ];

  buildPhase = ''
    runHook preBuild
    python3 tools/build.py --output build --datadir $out/share
    substituteInPlace build/89-t2-dsp.rules \
      --replace '/usr/bin/cat' '${coreutils}/bin/cat'
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -d $out/share/t2-dsp/profiles
    cp -r build/profiles/. $out/share/t2-dsp/profiles/

    install -d $out/share/t2-dsp/pipewire
    cp -r build/pipewire/. $out/share/t2-dsp/pipewire/

    install -m 0644 build/models.json $out/share/t2-dsp/models.json

    install -D -m 0644 build/51-t2-dsp.conf $out/share/wireplumber/wireplumber.conf.d/51-t2-dsp.conf
    if [ -f integration/wireplumber/t2-default-output.lua ]; then
      install -D -m 0644 integration/wireplumber/t2-default-output.lua $out/share/wireplumber/scripts/t2-default-output.lua
    fi

    install -D -m 0644 build/89-t2-dsp.rules $out/lib/udev/rules.d/89-t2-dsp.rules
    runHook postInstall
  '';

  meta = with lib; {
    description = "PipeWire/WirePlumber DSP graphs and udev rules for Apple T2 Mac speakers";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
