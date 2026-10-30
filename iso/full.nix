{ modulesPath, lib, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
    ./common.nix
  ];

  isoImage.edition = "t2-full";
  isoImage.showConfiguration = lib.mkDefault false;

  specialisation = {
    gnome.configuration =
      { ... }:
      {
        imports = [
          "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-gnome.nix"
        ];
        isoImage.showConfiguration = true;
        isoImage.configurationName = "GNOME";
      };

    plasma.configuration =
      { ... }:
      {
        imports = [
          "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
        ];
        isoImage.showConfiguration = true;
        isoImage.configurationName = "Plasma 6 (KDE)";
      };
  };
}

