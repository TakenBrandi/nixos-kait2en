{ stdenv, lib, kernel, kmod, upstream, kmodigest ? null }:

# Upstream's DKMS installer stages the stack's members below
# modules/t2bce_stack so Kbuild and modpost share one symbol namespace:
# dma, core, vhci and audio from modules/, AVE and Sidecar from
# t2-services/t2-ave/kernel/. Do the same here.
stdenv.mkDerivation {
  pname = "t2bce_stack";
  version = "1.0.0";

  src = upstream;

  unpackPhase = ''
    runHook preUnpack
    mkdir t2bce_stack
    cp -r $src/modules/t2bce_stack/. t2bce_stack/
    for m in dma core vhci audio; do
      cp -r $src/modules/t2bce_$m t2bce_stack/
    done
    for m in ave sidecar; do
      cp -r $src/t2-services/t2-ave/kernel/t2bce_$m t2bce_stack/
    done
    chmod -R u+w t2bce_stack
    cd t2bce_stack
    runHook postUnpack
  '';

  # AVE and Sidecar need V4L2 mem2mem, which Fedora enables and the NixOS
  # kernel does not. Build them only when the kernel has it.
  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail $'obj-m += t2bce_ave/\nobj-m += t2bce_sidecar/' \
        $'ifneq ($(CONFIG_V4L2_MEM2MEM_DEV),)\nobj-m += t2bce_ave/\nobj-m += t2bce_sidecar/\nendif'
  '';

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
