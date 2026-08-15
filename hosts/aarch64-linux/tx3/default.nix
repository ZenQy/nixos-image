{ modulesPath, ... }:

{
  imports = [
    ./image.nix
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  hardware.deviceTree = {
    enable = true;
    name = "amlogic/meson-sm1-x96-air-gbit.dtb";
    filter = "*x96*.dtb";
  };

  boot = {
    initrd.systemd.tpm2.enable = false;
    loader.grub.enable = false;
    loader.generic-extlinux-compatible.enable = true;
    loader.generic-extlinux-compatible.configurationLimit = 2;
    kernelParams = [
      "console=ttyAML0,115200n8"
      "console=tty0"
    ];
  };

  systemd.network.networks.eth0 = {
    name = "eth0";

    address = [
      "10.0.0.10/24"
    ];
    routes = [
      {
        Gateway = "10.0.0.1";
        GatewayOnLink = true;
      }
    ];

  };

}
