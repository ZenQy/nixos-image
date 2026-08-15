{
  pkgs,
  config,
  lib,
  ...
}:
let
  bootStart = 4;
  bootSize = 0;
  rootStart = 4;
  rootSize = 2500;
  label = "nixos";
  baseName = "tx3";
in
{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/${label}";
      fsType = "btrfs";
      options = [
        "compress-force=zstd"
        "nosuid"
        "nodev"
      ];
    };
  }
  // (
    if bootSize == 0 then
      { }
    else
      {
        "/boot" = {
          device = "/dev/disk/by-label/BOOT";
          fsType = "vfat";
          options = [ "umask=0077" ];
        };
      }
  );

  system.build.vpsImage = import ../../../make-disk-image.nix {
    inherit
      config
      pkgs
      lib
      bootStart
      bootSize
      rootStart
      rootSize
      label
      baseName
      ;

    postVM = ''
      cd $out
      dd if=${./u-boot.bin} of=${baseName}.img conv=fsync bs=1 count=444
      dd if=${./u-boot.bin} of=${baseName}.img conv=fsync bs=512 skip=1 seek=1
    '';
  };
}
