{ stdenv, lib, kernel, kmod, kmodigest ? null }:

stdenv.mkDerivation {
  pname = "t2bce_stack";
  version = "1.0.0";

  src = ../../src/modules/t2bce_stack;

  nativeBuildInputs = kernel.moduleBuildDependencies ++ lib.optional (kmodigest != null) kmodigest;

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KVERSION=${kernel.modDirVersion}"
    "KERNELRELEASE=${kernel.modDirVersion}"
    "INSTALL_MOD_DIR=updates"
    "M=$(PWD)"
  ];

  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$(pwd) modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -d $out/lib/modules/${kernel.modDirVersion}/updates
    find . -name '*.ko' -exec install -m 644 {} $out/lib/modules/${kernel.modDirVersion}/updates/ \;
    if command -v kmodigest >/dev/null 2>&1; then
      find $out/lib/modules/${kernel.modDirVersion} -name '*.ko' -exec kmodigest {} \;
    fi
    runHook postInstall
  '';

  meta = with lib; {
    description = "Apple T2 BCE (Buffer Copy Engine) and VHCI driver stack";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
