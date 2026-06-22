{
  inputs,
  lib,
  ...
}: {
  # Like NixOS manages the system configuration, Home Manager manages the user
  # environment.
  # https://nix-community.github.io/home-manager/nix-flakes/nixos.html
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.root.home.stateVersion = lib.trivial.release; # No need to read any comments!
  };
}
