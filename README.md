# nixos-kait2en

[![NixOS](https://img.shields.io/badge/NixOS-unstable-blue.svg)](https://nixos.org)
[![License](https://img.shields.io/badge/License-GPLv2%20%7C%20GPLv3-green.svg)](LICENSE)
[![Apple T2](https://img.shields.io/badge/Apple-T2%20Security%20Chip-silver.svg)](https://t2linux.org)

Comprehensive NixOS hardware support flake for **all Apple T2 Macs (2018–2020)** powered by the [KaiT2en](https://github.com/kaiT2en/KaiT2en-Fedora) modular driver stack, hybrid graphics runtime power management, universal Touch Bar support, and calibrated speaker DSP.

Works out of the box on **MacBook Pro (13", 15", 16")**, **MacBook Air**, **Mac mini**, **Mac Pro**, and **iMac Pro**.

---

## Supported Devices

| Model | Codename | GPU Type | Audio / DSP | Touch Bar |
| :--- | :--- | :--- | :--- | :--- |
| **MacBook Pro 16" (2019)** | `MacBookPro16,1`, `16,4` | Hybrid (Intel UHD 630 + AMD Radeon Pro 5300M/5500M/5600M) | Calibrated DSP | Supported (`tiny-dfr`) |
| **MacBook Pro 15" (2018–2019)** | `MacBookPro15,1`, `15,3` | Hybrid (Intel UHD 630 + AMD Radeon Pro) | Calibrated DSP | Supported (`tiny-dfr`) |
| **MacBook Pro 13" (2018–2020)** | `MacBookPro15,2`, `15,4`, `16,2`, `16,3` | Integrated (Intel Iris Plus) | Calibrated DSP | Supported (`tiny-dfr`) |
| **MacBook Air (2018–2020)** | `MacBookAir8,1`, `8,2`, `9,1` | Integrated (Intel UHD / Iris Plus) | Calibrated DSP | N/A (physical function keys) |
| **Mac mini (2018)** | `Macmini8,1` | Integrated (Intel UHD 630) | Standard PCM | N/A |
| **Mac Pro (2019)** | `MacPro7,1` | Discrete PCIe AMD GPU | Standard PCM | N/A |
| **iMac Pro (2017)** | `iMacPro1,1` | Discrete AMD Radeon Pro Vega | Standard PCM | N/A |

---

## Features

- **Automated Wi-Fi & Bluetooth Firmware**:
  - Broadcom BCM4364 / BCM4355 firmware blobs are **automatically fetched and installed** out of the box via verified GitHub releases (`RNGDesign/t2-apple-fw`).
  - Pre-baked into the live ISOs — Wi-Fi works immediately on first boot.
  - Option to override with local macOS-extracted firmware if working completely offline.
- **Universal Calibrated Speaker DSP (PipeWire / WirePlumber)**:
  - **Automatic model detection**: reads `/sys/class/dmi/id/product_name` at boot and selects the exact calibrated profile from `models.json`.
  - Multi-band crossovers, Biquad EQs, `lsp-plugins` limiters (speaker protection against blowout), and `bankstown` virtual bass.
  - Studio sound quality matching macOS audio processing.
- **Universal Touch Bar Support**:
  - `t2bdrm` & `t2touchbar` DRM drivers.
  - Pre-patched `tiny-dfr` daemon supporting Intel, AMD dGPU, and GMUX backlight synchronization without crashing.
  - Dynamic Touch ID prompt animations on Touch Bar.
- **Hybrid Graphics & Power Management (AMD + Apple GMUX)**:
  - Custom kernel runtime power management for dual-GPU models (`MacBookPro15,1`, `15,3`, `16,1`, `16,4`).
  - Puts the discrete AMD Radeon Pro GPU into **D3cold sleep (0W consumption)** when idle while Intel UHD 630 drives the internal display.
  - Transparent on-demand acceleration via `DRI_PRIME=1 <app>`. Restores cool thermals and multi-hour battery life.
  - Kernel patches come from KaiT2en-Fedora's `patches/runtime/` (pinned by the `kait2en-fedora` flake input) and target **Linux 7.3**, the default kernel.
- **Native Force Touch Haptics & Input**:
  - Modular `t2bce_stack` and `t2_precision_trackpad` with realistic click vibration simulation.
- **Touch ID Biometrics (Apple Secure Enclave bridge)**:
  - `t2-touchid` daemon bridges macOS-enrolled fingerprints to `fprintd` and PAM.
  - Unlock session, login via GDM/SDDM/LightDM, and authorize `sudo` with Touch ID.

---

## Feature Comparison

| Component / Feature | Stock Upstream Linux | Legacy t2linux | KaiT2en / `nixos-kait2en` |
| :--- | :--- | :--- | :--- |
| **Wi-Fi & Bluetooth** | ❌ Missing firmware | ⚠️ Manual extraction required | ✅ **Automatic download out-of-the-box** + pre-baked in Live ISOs |
| **Audio & Speakers** | ❌ No audio | ⚠️ Raw PCM (danger of blowing tweeters) | ✅ **Automatic DSP detection** + calibrated speaker protection |
| **Touch Bar Display** | ❌ Blank / default ESC row | ⚠️ May crash on dGPU/AMD backlight | ✅ **Universal**: patched `tiny-dfr` with fallback across all T2 Macs |
| **Keyboard & Trackpad** | ❌ Unusable | ⚠️ Monolithic `apple-bce` | ✅ Modular `t2bce_stack` + native Force Touch haptics |
| **Hybrid GPU (15" & 16")** | ❌ dGPU stuck on (25W+ drain) | ⚠️ Discrete only or broken sleep | ✅ **D3cold (0W) runtime PM** with Intel primary + `DRI_PRIME=1` |
| **Touch ID** | ❌ Unsupported | ❌ Unsupported | ✅ **Integrated**: Secure Enclave (SEP) bridge to `fprintd` & PAM |

---

## Live Installation ISOs

Ready-to-use NixOS live installer ISOs matching the official NixOS format, pre-loaded with all Apple T2 kernel modules, firmware, and hardware configs:

- **`iso-full`**: Graphical live installer with the **Calamares GUI installer** and desktop picker (**GNOME** & **KDE Plasma 6**).
- **`iso-minimal`**: Minimal command-line installer.

### Building the ISOs:

```bash
# Full Graphical Installer (GNOME / KDE Plasma 6 + Calamares)
nix build github:gmglbn-0/nixos-kait2en#iso-full

# Minimal CLI Installer
nix build github:gmglbn-0/nixos-kait2en#iso-minimal
```

The resulting ISO image will be in `./result/iso/nixos-t2-*.iso`.

### Flashing to USB:

```bash
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

---

## Installation Walkthrough

### 1. Prepare your Mac
1. Boot into **macOS Recovery** (`Command + R` at startup).
2. Open **Utilities → Startup Security Utility**.
3. Set **Secure Boot** to *"Medium Security"* or *"No Security"*.
4. Set **Allowed Boot Media** to *"Allow booting from external or removable media"*.
5. (Optional) Enforce Touch ID enrollment in macOS if you wish to use Touch ID in Linux.

### 2. Boot the Live USB
1. Insert the USB drive and power on your Mac while holding the **Option (Alt)** key.
2. Select **EFI Boot** with the yellow external drive icon.
3. Choose **NixOS Graphical Installer (GNOME or KDE Plasma)** or minimal mode.

### 3. Network Connection
- **Wi-Fi**: Works immediately via the embedded Broadcom firmware. Click the network icon in the top right to join your Wi-Fi.
- **Offline fallback**: If installing without Wi-Fi, you can connect your smartphone via a USB cable and enable **USB Tethering** (or use a USB-C Ethernet adapter).

### 4. Install NixOS
- **Graphical**: Launch the **Calamares** installer from the desktop and follow the guided wizard.
- **Manual (CLI)**: Use `disko` or standard `fdisk`/`nixos-generate-config`/`nixos-install`.

---

## Adding to Your Flake Configuration

Add `nixos-kait2en` to your system's `flake.nix`:

```nix
{
  description = "My MacBook Pro NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    kait2en = {
      url = "github:gmglbn-0/nixos-kait2en";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, kait2en, ... }: {
    nixosConfigurations.my-macbook = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        kait2en.nixosModules.default
      ];
    };
  };
}
```

In your `configuration.nix`:

```nix
{ config, pkgs, lib, ... }:

{
  # Enable Apple T2 hardware support
  hardware.apple-t2 = {
    enable = true;

    # Graphics mode for 15" / 16" dual-GPU models:
    # "hybrid" (Intel primary + AMD D3cold sleep), "discrete", or "integrated"
    graphics.mode = "hybrid";

    # Audio DSP: "auto" automatically detects your Mac model (16_1, 15_1, etc.)
    dsp.model = "auto";

    # Broadcom Wi-Fi & Bluetooth Firmware
    # Automatically downloads tested firmware from RNGDesign/t2-apple-fw.
    firmware.enable = true;
    # To use manually extracted firmware instead:
    # firmware.path = ./firmware;

    # Touch Bar daemon (tiny-dfr)
    touchbar.enable = true;

    # Touch ID (Apple Secure Enclave bridge for fprintd and PAM)
    touchid.enable = true;
  };

  # PipeWire Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Apple T2 UEFI Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
```

---

## (Optional) Manual Firmware Extraction

If you prefer to extract the firmware directly from your macOS partition instead of the automatic online download:

```bash
# In the live environment:
sudo mkdir -p /mnt/macos
sudo apfs-fuse -o allow_other /dev/nvme0n1p2 /mnt/macos

# Run the extraction tool:
nix run github:gmglbn-0/nixos-kait2en#extract-t2-firmware -- ./firmware /mnt/macos
```

Then set `hardware.apple-t2.firmware.path = ./firmware;` in your NixOS configuration.

---

## Verification & Health Check

After booting into your installed system:

- **AMD GPU Sleep State** (MacBook Pro 15" & 16"):
  ```bash
  cat /sys/class/drm/card*/device/power_state
  # Returns 'D3cold' or 'D3hot' when idle, 'D0' under load
  ```
- **Launch Application on dGPU**:
  ```bash
  DRI_PRIME=1 glxinfo | grep "OpenGL renderer"
  ```
- **Verify Audio DSP Pipeline**:
  ```bash
  pw-cli list-objects Module | grep filter-chain
  ```
- **Test Touch ID**:
  ```bash
  fprintd-enroll
  fprintd-verify
  ```

---

## License

- Kernel modules & drivers: GPL-2.0.
- DSP profiles, configurations, and tools: GPL-3.0-or-later.
