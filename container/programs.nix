{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.coreutils
    pkgs.git
    pkgs.jq
    pkgs.python3
  ];
}
