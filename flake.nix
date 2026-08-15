{
  description = "Clean Native NixOS BIOS/MBR raw image builder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (builtins)
        filter
        attrNames
        readDir
        concatMap
        listToAttrs
        ;
      floder =
        dir:
        let
          files = readDir dir;
        in
        filter (name: files.${name} == "directory") (attrNames files);

      hosts = concatMap (
        dir:
        map (subdir: {
          inherit dir;
          name = subdir;
        }) (floder ./hosts/${dir})
      ) (floder ./hosts);

      nixos = listToAttrs (
        map (host: {
          name = host.name;
          value = nixpkgs.lib.nixosSystem {
            system = host.dir;
            modules = [
              ./configuration.nix
              ./hosts/${host.dir}/${host.name}
            ];
          };
        }) hosts
      );

      image =
        platforms:
        listToAttrs (
          map (platform: {
            name = platform;
            value = listToAttrs (
              map (host: {
                name = host;
                value = self.nixosConfigurations.${host}.config.system.build.vpsImage;
              }) (floder ./hosts/${platform})
            );
          }) platforms
        );
    in
    {
      nixosConfigurations = nixos;

      packages = image [
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
}
