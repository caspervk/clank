{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in {
    # `nix fmt`
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # `nix build`
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      container = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [./container];
      };

      app = pkgs.writeShellApplication {
        name = "f";
        runtimeInputs = [
          pkgs.podman
        ];
        text = pkgs.lib.strings.concatStringsSep " " [
          "podman run"
          "--rm"
          "-it"
          # Kinda yolo, but you need at least `--device=/dev/fuse`, and
          # `--cap-add=SYS_ADMIN,NET_ADMIN,NET_RAW,mknod` to make compose work
          # anyway.
          # https://www.redhat.com/en/blog/podman-inside-container
          "--privileged"
          "--volume /proc/sys:/proc/sys:rw"
          # TODO
          "--volume \"$HOME/.local/share/containers/storage\":/var/lib/shared:ro"
          # TODO: doesn't work actually
          # https://github.com/anthropics/claude-code/issues/24317
          "--volume \"$HOME/.claude/.credentials.json\":/run/secrets/claude-credentials.json:ro"
          # Mount current directory to /host/
          "--volume ./:/root/host:rw"
          # https://discourse.nixos.org/t/running-nix-os-containers-directly-from-the-store-with-podman/29220
          # https://github.com/metaspace/container-nixos/tree/main
          "--volume /nix/store:/nix/store:ro"
          "--mount=type=tmpfs,tmpfs-size=512M,destination=/run"
          "--mount=type=tmpfs,tmpfs-size=512M,destination=/run/wrappers,suid"
          "--systemd=always"
          "--rootfs /var/empty:O"
          "${self.packages.${system}.container.config.system.build.toplevel}/init"
        ];
      };
    });

    # `nix run`
    apps = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = {
        type = "app";
        program = pkgs.lib.getExe self.packages.${system}.app;
      };
    });
  };
}
