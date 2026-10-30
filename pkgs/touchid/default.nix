{ lib
, rustPlatform
, pkg-config
, libinput
, systemd
}:

rustPlatform.buildRustPackage {
  pname = "t2-touchid";
  version = "0.1.0";

  src = ../../src/services/t2-touchid;

  postUnpack = ''
    mkdir -p $NIX_BUILD_TOP/shared/protocols
    cp -r ${../../src/services/shared/protocols/t2-bridgexpc} $NIX_BUILD_TOP/shared/protocols/t2-bridgexpc
  '';

  cargoLock = {
    lockFile = ../../src/services/t2-touchid/Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libinput
    systemd
  ];

  postInstall = ''
    # Install D-Bus policy
    install -D -m 0644 integration/dbus/org.kait2en.TouchId.conf $out/share/dbus-1/system.d/org.kait2en.TouchId.conf
  '';

  meta = with lib; {
    description = "Apple T2 Touch ID bridge daemon for fprintd";
    homepage = "https://github.com/kaiT2en/KaiT2en-Fedora";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
