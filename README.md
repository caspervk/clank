# clank

## Try

```sh
nix run git+https://git.caspervk.net/caspervk/clank.git -- claude setup-token
nix run git+https://git.caspervk.net/caspervk/clank.git -- CLAUDE_CODE_OAUTH_TOKEN=hunter2 claude
```

## Install

```nix
{
  inputs = {
    clank = {
      url = "git+https://git.caspervk.net/caspervk/clank.git";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

```nix
{clank, pkgs}: {
  environment.systemPackages = [
    clank.packages.${pkgs.system}.app
  ];
}
```

### Run

```sh
clank
```
