{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ./common.nix
  ];

  isoImage.edition = "t2-minimal";
}

