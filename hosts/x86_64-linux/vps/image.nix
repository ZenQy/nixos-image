{
  pkgs,
  config,
  lib,
  ...
}:
let
  bootStart = 1;
  bootSize = 0;
  rootStart = 1;
  rootSize = 2500;
  label = "nixos";
  baseName = "nixos";
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
      echo "Compressing image..."
      cd $out
      ${pkgs.zstd}/bin/zstd -T0 -10 ${baseName}.img -o ${baseName}.img.zst
      rm ${baseName}.img
    '';
  };
}
