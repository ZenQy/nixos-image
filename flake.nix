{
  description = "Clean Native NixOS BIOS/MBR raw image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    # 1. 注册 NixOS 系统
    nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./vps
        ./configuration.nix
      ];
    };

    # 2. 直接引用我们在 configuration.nix 中定义的 system.build.vpsImage
    packages.x86_64-linux.vps = self.nixosConfigurations.vps.config.system.build.vpsImage;

  };
}
