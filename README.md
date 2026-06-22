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

## 📦 Install Clank

#### NixOS

```nix
{
  inputs = {
    clank = {
      url = "github:magenta-aps/clank";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

```nix
{clank, pkgs, ...}: {
  environment.systemPackages = [
    clank.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

#### Everything Else

```sh
alias clank='nix run github:magenta-aps/clank --'
```

## 🔐 Credentials Proxy

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

First, configure _OpenCode_ or _Claude Code_ to use the proxy. See the
[OpenCode documentation](https://opencode.ai/docs/providers) for a list of
supported providers. Base URLs can be found at <https://models.dev/api.json>.
Some providers use a custom SDK, in which case they are documented at
<https://ai-sdk.dev/providers/ai-sdk-providers>.

`~/.config/clank/opencode.json`:

```json
{
  "provider": {
    "deepseek": {
      "options": {
        "baseURL": "http://clank-proxy:8000"
      }
    },
    "google": {
      "options": {
        "apiKey": "dummy",
        "baseURL": "http://clank-proxy:8001/v1beta"
      }
    },
    "mistral": {
      "options": {
        "apiKey": "dummy",
        "baseURL": "http://clank-proxy:8002/v1"
      }
    },
    "scaleway": {
      "options": {
        "baseURL": "http://clank-proxy:8003/v1"
      }
    },
    "zai": {
      "options": {
        "baseURL": "http://clank-proxy:8004/api/paas/v4"
      }
    }
  }
}
```

`~/.config/clank/claude.json`:

```json
{
  "env": {
    "CLAUDE_CODE_OAUTH_TOKEN": "dummy",
    "ANTHROPIC_BASE_URL": "http://clank-proxy:666"
  }
}
```

Then, configure the [Caddy](https://caddyserver.com) proxy with the actual
credentials. API keys are
[here](https://vault.bitwarden.com/#/vault?itemId=c9b60efc-e0b3-4a7a-a3d7-b43500d29310)
if you work at Magenta.

`~/.config/clank/Caddyfile`:

```Caddy
:8000 {
	reverse_proxy https://api.deepseek.com {
		header_up Authorization "Bearer <token>"  # https://platform.deepseek.com/api_keys
	}
}

:8001 {
	reverse_proxy https://generativelanguage.googleapis.com {
		header_up X-Goog-Api-Key "<token>"
	}
}

:8002 {
	reverse_proxy https://api.mistral.ai {
		header_up Authorization "Bearer <token>"  # https://console.mistral.ai/codestral/cli
	}
}

:8003 {
	rewrite * /594a268d-8577-4b86-a983-be375e13e197{uri}  # project id
	reverse_proxy https://api.scaleway.ai {
		header_up Authorization "Bearer <token>"
	}
}

:8004 {
	reverse_proxy https://api.z.ai {
		header_up Authorization "Bearer <token>"  # https://z.ai/manage-apikey/apikey-list
	}
}

:666 {
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
