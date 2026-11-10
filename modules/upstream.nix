{ lib, ... }:

{
  options.hardware.apple-t2.upstreamSource = lib.mkOption {
    type = lib.types.path;
    description = ''
      Source tree of KaiT2en-Fedora (https://github.com/kaiT2en/KaiT2en-Fedora)
      that kernel patches are taken from. The flake's modules default this to
      its pinned `kait2en-fedora` input. Point it at a local checkout to test
      upstream changes before they are locked.
    '';
  };
}
