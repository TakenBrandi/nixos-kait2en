{
  description = "NixOS hardware support for Apple T2 Macs using KaiT2en modules, patches, and DSP profiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # The KaiT2en driver stack this flake packages. The lock file pins the
    # upstream commit; `nix flake update kait2en-fedora` syncs to a newer one.
    kait2en-fedora = {
      url = "github:kaiT2en/KaiT2en-Fedora";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, kait2en-fedora }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in (import ./pkgs { inherit pkgs; upstream = kait2en-fedora; }) // {
          iso-minimal = self.nixosConfigurations.iso-minimal.config.system.build.isoImage;
          iso-full = self.nixosConfigurations.iso-full.config.system.build.isoImage;
          # aliases
          minimal = self.packages.${system}.iso-minimal;
          full = self.packages.${system}.iso-full;
        }
      );

      nixosModules =
        let
          # Every exported module gets hardware.apple-t2.upstreamSource, set
          # to this flake's pinned KaiT2en-Fedora input.
          withUpstream = module: { lib, ... }: {
            imports = [ ./modules/upstream.nix module ];
            hardware.apple-t2.upstreamSource = lib.mkDefault kait2en-fedora;
          };
        in rec {
          default = apple-t2;
          apple-t2 = withUpstream ./modules;
          kernel = withUpstream ./modules/kernel.nix;
          graphics = withUpstream ./modules/graphics.nix;
          audio = withUpstream ./modules/audio.nix;
          touchbar = withUpstream ./modules/touchbar.nix;
          firmware = withUpstream ./modules/firmware.nix;
          touchid = withUpstream ./modules/touchid.nix;
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
        default = import ./overlays { upstream = kait2en-fedora; };
      };
    };
}
