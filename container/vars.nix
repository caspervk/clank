{...}: {
  _module.args.vars = {
    AGENTS_md = ''
      - Run unknown commands using `nix shell nixpkgs#<package>`
      - Avoid writing em-dashes (`—`) in comments or commit messages
    '';
  };
}
