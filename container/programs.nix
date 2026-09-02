{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.coreutils
    pkgs.jq
    pkgs.python3
  ];

  programs.git.enable = true;

  # NixOS enables systemd's ssh proxy by default, which `Include`s a /nix/store
  # file in /etc/ssh/ssh_config, but the store is uid mapped, so it is owned by
  # `nobody` which isn't allowed by openssh.
  programs.ssh.systemd-ssh-proxy.enable = false;
}
