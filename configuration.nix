{
  config,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot.kernelParams = [
    "audit=0"
    "net.ifnames=0"
  ];
  boot.growPartition = true;
  boot.loader.grub.enable = true;
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
    "sr_mod"
  ];

  nix.extraOptions = "experimental-features = nix-command flakes";

  users.users.root = {
    hashedPassword = "$6$4pRV3Gia$3OfrxJ8V95zIGk1D7p/fR5/brb8s5okIYpmIvSYXCPmuzd7AaibroCvPwfOUxokcHJb.HnqwZ2xsbJCutGwvp/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCm/fzBKSSrwR8taYQURb/0p21tBpk6QCL9JviqUOvj zenith@linux"
    ];
  };
  environment.etc."ssh/ssh_host_ed25519_key.pub".text =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ45CA7BpSSt3qrC64G4/uZsSzH8Fzi5bZW30EOaN2Y8 root@nixos-vps";

  networking.firewall.enable = false;
  networking.useDHCP = false;
  networking.hostName = "nixos-vps";
  systemd.network.enable = true;
  services.openssh = {
    enable = true;
    ports = [
      22
      2022
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };
  services.resolved.enable = false;
  networking.nameservers = [
    "2606:4700:4700::1111"
    "1.1.1.1"
  ];

  time.timeZone = "Asia/Shanghai";
  environment.systemPackages = with pkgs; [
    fastfetch
  ];

  system.stateVersion = builtins.substring 0 5 config.system.nixos.version;

}
