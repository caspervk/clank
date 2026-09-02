# 🤖 Clank

`clank` is an AI sandbox, pre-configured to quickly start using AI.

## ⚡ Quick Start

### ❄️ Get Nix

Clank is built using the [Nix package
manager](https://nixos.org/download/#nix-install-linux).

#### Debian / Ubuntu

```sh
sudo apt install -y nix uidmap
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
sudo usermod -aG nix-users $USER
```

**At this point you need to log out and in again to effectuate the change to
your user's groups.**

### 🚀 Try Clank

Through the power of Nix, you can run Clank without installing anything else.

```sh
nix run github:magenta-aps/clank
```

This mounts the current directory into a sandbox, which the AI will have full
access to, so maybe don't do it in a directory with sensitive data. Get the
vibes going by running [`opencode`](https://opencode.ai) or
[`claude`](https://code.claude.com). See below for more.

## 🔧 Customise Clank

### NixOS

Add the clank input to your `flake.nix`:

```nix
{
  inputs = {
    clank = {
      url = "github:magenta-aps/clank";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
      # inputs.home-manager.follows = "home-manager-unstable";
    };
  };
}
```

Add the `clank` package with overrides:

```nix
{inputs, pkgs, ...}: {
  environment.systemPackages = [
    (inputs.clank.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      extraModules = [
        ({pkgs, ...}: {
          home-manager.users.root = {
            # https://search.nixos.org/options?channel=unstable&query=programs.opencode&source=home_manager
            programs.opencode = {
              context = "Call me Alice";
            };
            # https://search.nixos.org/options?channel=unstable&query=programs.claude-code&source=home_manager
            programs.claude-code = {
              context = "Call me Bob";
            };
          };
        })
      ];
    })
  ];
}
```

### Elsewhere

Create a `flake.nix` in an empty directory, e.g. `~/clank/flake.nix`:

```nix
{
  inputs = {
    clank = {
      url = "github:magenta-aps/clank";
    };
  };

  outputs = {...} @ inputs: let
    nixpkgs = inputs.clank.inputs.nixpkgs;
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = inputs.clank.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        extraModules = [
          ({pkgs, ...}: {
            home-manager.users.root = {
              # https://search.nixos.org/options?channel=unstable&query=programs.opencode&source=home_manager
              programs.opencode = {
                context = "Call me Alice";
              };
              # https://search.nixos.org/options?channel=unstable&query=programs.claude-code&source=home_manager
              programs.claude-code = {
                context = "Call me Bob";
              };
            };
          })
        ];
      };
    });
  };
}
```

Run it using

```sh
nix run ~/clank
```

### 🔐 Credentials Proxy

Giving AI access to secrets is certainly one of the ideas ever. Fortunately, we
can keep secrets out of the sandbox container by configuring the harness to use
dummy credentials and a credentials-injecting proxy.

```text
              Sandbox
┌─────────────────────────────────┐
│                                 │
│ ┌─────────────┐                 │    ┌───────────┐                           ┌──────────────┐
│ │  Open Code  │  apiKey: dummy  │    │   Caddy   │   apiKey: aHVudGVyMg==    │  Mistral AI  │
│ │  (harness)  ├─────────────────┼───►│  (proxy)  ├──────────────────────────►│  (provider)  │
│ └─────────────┘                 │    └───────────┘                           └──────────────┘
│                                 │
└─────────────────────────────────┘
```

First, configure OpenCode or Claude Code to use the proxy. See the [OpenCode
documentation](https://opencode.ai/docs/providers) for a list of supported
providers. Base URLs can be found at <https://models.dev/api.json>. Some
providers use a custom SDK, in which case they are documented at
<https://ai-sdk.dev/providers/ai-sdk-providers>.

```nix
{pkgs, ...}: {
  home-manager.users.root = {
    programs.opencode = {
      settings = {
        provider = {
          mistral = {
            options = {
              apiKey = "dummy";
              baseURL = "http://clank-proxy:1643/v1";
            };
          };
        };
      };
    };
    programs.claude-code = {
      settings = {
        env = {
          CLAUDE_CODE_OAUTH_TOKEN = "dummy";
          ANTHROPIC_BASE_URL = "http://clank-proxy:1666";
        };
      };
    };
  };
}
```

Then, configure the [Caddy](https://caddyserver.com) proxy with the actual
credentials.

`~/.config/clank/Caddyfile`:

```Caddy
:1643 {
	reverse_proxy https://api.mistral.ai {
		header_up Authorization "Bearer <token>"  # https://console.mistral.ai/?profile_dialog=api-keys
	}
}

:1666 {
	reverse_proxy https://api.anthropic.com {
		header_up Authorization "Bearer <token>"  # `claude setup-token`
	}
}
```

## 💡 Tips and Tricks

### OpenCode Web

```sh
CLANK_PODMAN_OPTS='--publish=127.0.0.1:4096:4096' clank opencode web --hostname=0.0.0.0 --port=4096
```

## 🧑‍🔧 Development

```sh
git clone https://github.com/magenta-aps/clank.git
nix run ~/clank
```

## 🗑️ Remove All State

```sh
nix run nixpkgs#podman -- rm --force --filter 'name=^clank'
nix run nixpkgs#podman -- volume rm clank-persist
```
