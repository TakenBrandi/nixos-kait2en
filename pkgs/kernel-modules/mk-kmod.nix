{ stdenv, lib, kernel, kmod, kmodigest ? null }:

{ pname
, version ? "1.0.0"
, src
, sourceRoot ? null
, extraMakeFlags ? [ ]
, postInstall ? ""
, meta ? { }
}:

stdenv.mkDerivation (finalAttrs: {
  inherit pname version src;

  nativeBuildInputs = kernel.moduleBuildDependencies ++ lib.optional (kmodigest != null) kmodigest;

  makeFlags = [
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KERNEL_RELEASE=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "KVER=${kernel.modDirVersion}"
    "INSTALL_MOD_DIR=updates"
    "M=$(PWD)"
  ] ++ extraMakeFlags;

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
    ${postInstall}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Apple T2 Linux kernel module: ${pname}";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  } // meta;
})
