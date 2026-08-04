{ ... }:

{
  imports = [
    ./image.nix
  ];

  boot.loader.grub.device = "/dev/vda";

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
