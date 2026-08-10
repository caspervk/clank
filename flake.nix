{
  description = "clank";

  inputs = {
    nixpkgs = {
      url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # use the same nixpkgs
    };
    config = {
      url = "path:./empty.nix";
      flake = false;
    };
  };

  outputs = inputs @ {
    config,
    nixpkgs,
    ...
  }: let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in {
    # `nix fmt`
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # `nix build` / `nix run` / `nix shell`
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      mkClank = {extraModules ? []}: let
        container = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs;};
          modules = [./container] ++ extraModules;
        };
      in
        pkgs.python3Packages.buildPythonApplication {
          pname = "clank";
          version = "0.0.1";
          pyproject = true;

          src = ./.;

          build-system = [pkgs.python3Packages.setuptools];

          doCheck = false; # has no tests, of course

          dependencies = [
            pkgs.podman
          ];

          makeWrapperArgs = builtins.concatLists [
            ["--set" "CLANK_CADDY_BIN" "${pkgs.caddy}/bin/caddy"]
            ["--set" "CLANK_EMPTY_DIRECTORY" "${pkgs.emptyDirectory}"]
            ["--set" "CLANK_ROOT" container.config.system.build.toplevel]
          ];
        };
    in {
      # NixOS users customise the Clank container by overriding extraModules:
      #
      #   clank.packages.${system}.default.override {
      #     extraModules = [./my-module.nix];
      #   }
      #
      # Non-NixOS users *could* use the same mechanism, and define their own
      # flake.nix, but they would have to very vigilant about keeping it
      # non-dirty to avoid evaluation cache-misses. Instead, we (ab)use flake
      # inputs as parameters. Overriding an input doesn't cause cache-misses.
      #
      # This allows non-NixOS users to customise using:
      #
      #   nix run github:magenta-aps/clank --override-input config "path:$HOME/.config/clank/config.nix"
      #
      # https://github.com/NixOS/nix/issues/10437
      # https://github.com/NixOS/nix/issues/5663
      default = nixpkgs.lib.makeOverridable mkClank {
        extraModules = [(import config)];
      };
    });
  };
}
