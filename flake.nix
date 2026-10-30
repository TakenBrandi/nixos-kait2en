{
  description = "NixOS hardware support for Apple T2 Macs using KaiT2en modules, patches, and DSP profiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in (import ./pkgs { inherit pkgs; }) // {
          iso-minimal = self.nixosConfigurations.iso-minimal.config.system.build.isoImage;
          iso-full = self.nixosConfigurations.iso-full.config.system.build.isoImage;
          # aliases
          minimal = self.packages.${system}.iso-minimal;
          full = self.packages.${system}.iso-full;
        }
      );

      nixosModules = rec {
        default = apple-t2;
        apple-t2 = import ./modules;
        kernel = import ./modules/kernel.nix;
        graphics = import ./modules/graphics.nix;
        audio = import ./modules/audio.nix;
        touchbar = import ./modules/touchbar.nix;
        firmware = import ./modules/firmware.nix;
        touchid = import ./modules/touchid.nix;
      };

      nixosConfigurations = {
        iso-minimal = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            ./iso/minimal.nix
          ];
        };

        iso-full = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            self.nixosModules.default
            ./iso/full.nix
          ];
        };
      };

      overlays = {
        default = import ./overlays;
      };
    };
}
