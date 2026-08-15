# https://github.com/NixOS/nixpkgs/blob/master/nixos/lib/make-disk-image.nix
{
  # The NixOS configuration to be installed onto the disk image.
  config,
  pkgs,
  lib,

  bootStart ? 1,
  bootSize ? 256,
  rootStart ? 257,
  rootSize ? 3000,

  # Filesystem label
  label ? "nixos",

  # Disk image filename, without any extensions (e.g. `image_1`).
  baseName ? "nixos",

  # Shell code executed after the VM has finished.
  postVM ? "",

  # Guest memory size in MiB (1024*1024 bytes)
  memSize ? 1024,

  name ? "nixos-disk-image",
  # OVMF firmware derivation
  OVMF ? pkgs.OVMF.fd,
}:

assert (lib.assertMsg (bootStart + bootSize <= rootStart) "rootStart 起始位置有误.");

let

  filename = "${baseName}.img";

  rootPartition = if bootSize == 0 then "1" else "2";

  binPath = lib.makeBinPath (
    with pkgs;
    [
      rsync
      util-linux
      parted
      lkl
      config.system.build.nixos-install
      nixos-enter
      nix
      systemdMinimal
      btrfs-progs
    ]
    ++ stdenv.initialPath
  );

  closureInfo = pkgs.closureInfo {
    rootPaths = [ config.system.build.toplevel ];
  };

  prepareImage = ''
    export PATH=${binPath}

    mkdir $out

    root="$PWD/root"
    mkdir -p $root

    export HOME=$TMPDIR

    # Provide a Nix database so that nixos-install can copy closures.
    export NIX_STATE_DIR=$TMPDIR/state
    nix-store --load-db < ${closureInfo}/registration

    chmod 755 "$TMPDIR"
    echo "running nixos-install..."
    nixos-install --root $root --no-bootloader --no-root-passwd \
      --system ${config.system.build.toplevel} \
      --no-channel-copy \
      --substituters ""

    diskImage=nixos.raw

    truncate -s ${toString (rootStart + rootSize)}M $diskImage

    ${
      if bootSize == 0 then
        ''
          parted --script $diskImage -- \
            mklabel msdos \
            mkpart primary btrfs ${toString rootStart}MiB 100% \
            print
        ''
      else
        ''
          parted --script $diskImage -- \
            mklabel msdos \
            mkpart primary fat32 ${toString bootStart}MiB ${toString (bootStart + bootSize)}MiB \
            set 1 boot on \
            mkpart primary btrfs ${toString rootStart}MiB 100% \
            print
        ''
    }

    truncate -s ${toString rootSize}M btrfs.raw
    mkfs.btrfs -f -L ${label} btrfs.raw
    dd if=btrfs.raw of=$diskImage bs=1M seek=${toString rootStart} conv=notrunc
    rm btrfs.raw

    echo "copying staging root to image..."
    cptofs -p -P ${rootPartition} \
           -t btrfs \
           -i $diskImage \
           $root/* / ||
      (echo >&2 "ERROR: cptofs failed. diskSize might be too small for closure."; exit 1)
  '';

  moveOrConvertImage = ''
    mv $diskImage $out/${filename}
    diskImage=$out/${filename}
  '';

  buildImage = pkgs.vmTools.runInLinuxVM (
    pkgs.runCommand name
      {
        preVM = prepareImage;
        buildInputs = with pkgs; [
          util-linux
          btrfs-progs
          dosfstools
          virtiofsd
        ];
        postVM = moveOrConvertImage + postVM;
        QEMU_OPTS = lib.concatStringsSep " " (
          lib.optionals (OVMF.systemManagementModeRequired or false) [
            "-machine"
            "q35,smm=on"
            "-global"
            "driver=cfi.pflash01,property=secure,value=on"
          ]
        );
        inherit memSize;
      }
      ''
        export PATH=${binPath}:$PATH

        rootDisk="/dev/vda${rootPartition}"

        # make systemd-boot find ESP without udev
        mkdir /dev/block
        ln -s /dev/vda1 /dev/block/254:1

        mountPoint=/mnt
        mkdir $mountPoint
        mount $rootDisk $mountPoint

        ${lib.optionalString (bootSize != 0) ''
          mkdir -p /mnt/boot
          mkfs.vfat -n BOOT /dev/vda1
          mount /dev/vda1 /mnt/boot
        ''}


        # In this throwaway resource, we only have /dev/vda, but the actual VM may refer to another disk for bootloader, e.g. /dev/vdb
        # Use this option to create a symlink from vda to any arbitrary device you want.
        ${lib.optionalString (config.boot.loader.grub.enable) (
          lib.concatMapStringsSep " " (
            device:
            lib.optionalString (device != "/dev/vda") ''
              mkdir -p "$(dirname ${device})"
              ln -s /dev/vda ${device}
            ''
          ) config.boot.loader.grub.devices
        )}
        ${
          let
            limine = config.boot.loader.limine;
          in
          lib.optionalString (limine.enable && limine.biosSupport && limine.biosDevice != "/dev/vda") ''
            mkdir -p "$(dirname ${limine.biosDevice})"
            ln -s /dev/vda ${limine.biosDevice}
          ''
        }

        # Set up core system link, bootloader (sd-boot, GRUB, uboot, etc.), etc.

        # NOTE: systemd-boot-builder.py calls nix-env --list-generations which
        # clobbers $HOME/.nix-defexpr/channels/nixos This would cause a  folder
        # /homeless-shelter to show up in the final image which  in turn breaks
        # nix builds in the target image if sandboxing is turned off (through
        # __noChroot for example).
        export HOME=$TMPDIR
        NIXOS_INSTALL_BOOTLOADER=1 nixos-enter --root $mountPoint -- /nix/var/nix/profiles/system/bin/switch-to-configuration boot

        umount -R /mnt

      ''
  );
in
buildImage
