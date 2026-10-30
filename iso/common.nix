{ pkgs, lib, ... }:

let
  extractT2Firmware = pkgs.writeShellApplication {
    name = "extract-t2-firmware";
    runtimeInputs = [ pkgs.coreutils pkgs.findutils ];
    text = builtins.readFile ../pkgs/tools/extract-t2-firmware.sh;
  };
  # installation instructions on the live desktop
  t2InstallGuide = pkgs.writeText "T2-Mac-Installation-Guide.txt" ''
    ====================================================================
      Apple T2 Mac NixOS Installation Guide (MacBook Pro / Air / Mac mini)
    ====================================================================

    This Live ISO includes full support for Apple T2 hardware:
    - Internal Keyboard & Force Touch Trackpad (t2bce / precision trackpad)
    - Internal NVMe SSD & Apple Security Chip
    - Touch Bar display & touch input (t2bdrm / t2touchbar)
    - Hybrid Graphics Power Management (Intel UHD 630 + AMD Radeon Pro D3cold)
    - Studio-grade calibrated speaker DSP profiles (PipeWire / WirePlumber)

    --------------------------------------------------------------------
    1. Wi-Fi & Bluetooth Firmware (Broadcom BCM4364)
    --------------------------------------------------------------------
    Apple T2 Wi-Fi and Bluetooth require proprietary Broadcom firmware.
    Because macOS partitions use APFS (often encrypted with FileVault),
    mounting them via standard Linux 'mount' is not supported.

    Choose one of the following methods to supply the firmware:

    A) Prepare beforehand in macOS (Recommended, works with FileVault):
       Before booting Linux, open Terminal in macOS and copy firmware
       to your FAT32 USB drive or the EFI system partition:
           mkdir -p /Volumes/EFI/apple-firmware
           cp -r /usr/share/firmware/wifi /Volumes/EFI/apple-firmware/
           cp -r /usr/share/firmware/bluetooth /Volumes/EFI/apple-firmware/
       Then in NixOS:
           sudo extract-t2-firmware /lib/firmware/brcm /boot/EFI/apple-firmware
           sudo modprobe -r brcmfmac && sudo modprobe brcmfmac

    B) Phone USB Tethering / USB-Ethernet:
       Connect your smartphone with a USB cable and enable "USB Tethering"
       in settings for instant internet access during installation.

    C) Unencrypted APFS partition with apfs-fuse:
       If FileVault is disabled on your macOS container:
           sudo mkdir -p /mnt/macos
           sudo apfs-fuse -o allow_other /dev/nvme0n1p2 /mnt/macos
           sudo extract-t2-firmware /lib/firmware/brcm /mnt/macos
           sudo modprobe -r brcmfmac && sudo modprobe brcmfmac

    --------------------------------------------------------------------
    2. Installation Method
    --------------------------------------------------------------------
    A) Graphical Installation with Calamares (Full ISO):
       Click the "Install NixOS" icon on your desktop to launch Calamares.
       Follow the step-by-step wizard to partition your drive and set up your
       user account.

    B) Manual / Terminal Installation (Minimal or Full ISO):
       Format your drive, generate config, and install manually:
           sudo parted /dev/nvme0n1 ...
           sudo nixos-generate-config --root /mnt
           nano /mnt/etc/nixos/configuration.nix
           sudo nixos-install

    --------------------------------------------------------------------
    3. Enabling Apple T2 Hardware Support in your Configuration
    --------------------------------------------------------------------
    The complete nixos-kait2en flake is embedded directly on this ISO at:
        /etc/nixos-kait2en

    To enable full T2 support on your installed system, add the module to
    your /etc/nixos/configuration.nix:

        imports = [
          ./hardware-configuration.nix
          (import /etc/nixos-kait2en).nixosModules.default
        ];

        hardware.apple-t2 = {
          enable = true;
          graphics.mode = "hybrid"; # Intel primary + AMD D3cold sleep
          dsp.model = "16_1";       # MacBookPro16,1 audio DSP profile
          touchbar.enable = true;
        };

    ====================================================================
  '';
in {
  hardware.apple-t2 = {
    enable = true;
    # build liveCD with patched kernel
    kernelPatches.enable = lib.mkDefault false;
  };

  # zfs is broken on 7.3 at moment of writing this
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # put the nixos-kait2en repo into ISO so it can be used instantly
  environment.etc."nixos-kait2en".source = ../.;

  environment.systemPackages = [
    extractT2Firmware
    pkgs.apfs-fuse
    pkgs.git
    pkgs.pciutils
    pkgs.usbutils
    pkgs.efibootmgr
    pkgs.parted
  ];

  # getty login message helper for minimal console & TTYs
  services.getty.helpLine = ''
    Apple T2 Mac NixOS Live Installer:
    - Wi-Fi firmware helper: sudo extract-t2-firmware /lib/firmware/brcm <macOS_mountpoint>
    - Installation guide: cat ~/T2-Mac-Installation-Guide.txt
  '';

  # place installation guide on the live desktop and in user home
  system.activationScripts.t2DesktopGuide = ''
    mkdir -p /home/nixos/Desktop
    cp -f ${t2InstallGuide} /home/nixos/Desktop/T2-Mac-Installation-Guide.txt
    cp -f ${t2InstallGuide} /home/nixos/T2-Mac-Installation-Guide.txt
    chown -R nixos:users /home/nixos || true
  '';
}
