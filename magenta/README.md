# Magenta

Add this to your NixOS configuration or `~/clank/flake.nix`:

```nix
{pkgs, ...}: {
  imports = [
    "${inputs.clank}/magenta/modules/gitlab.nix"
    "${inputs.clank}/magenta/modules/grafana-logs.nix"
    "${inputs.clank}/magenta/modules/kagi.nix"
  ];
  home-manager.users.root = {
    programs.opencode = {
      settings = {
        provider = {
          greenpt = {
            options = {
              baseURL = "http://clank-proxy:1689/v1";
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

`~/.config/clank/Caddyfile`:

```Caddy
# Providers
:1689 {
	reverse_proxy https://api.greenpt.ai {
		header_up Authorization "Bearer <token>"  # https://vault.bitwarden.com/#/vault?itemId=c9b60efc-e0b3-4a7a-a3d7-b43500d29310
	}
}
:1666 {
	reverse_proxy https://api.anthropic.com {
		header_up Authorization "Bearer <token>"  # `claude setup-token`
	}
}

# MCP Servers
:1394 {
	reverse_proxy https://mcp.kagi.com {
		header_up Authorization "Bearer <token>"  # https://vault.bitwarden.com/#/vault?itemId=c9b60efc-e0b3-4a7a-a3d7-b43500d29310
	}
}

# Agent Skills
:1932 {
	reverse_proxy https://logs-prod-us-central1.grafana.net {
		header_up Authorization "Basic <token>"  # https://vault.bitwarden.com/#/vault?itemId=c9b60efc-e0b3-4a7a-a3d7-b43500d29310
	}
}
:1942 {
	reverse_proxy https://git.magenta.dk {
		# https://git.magenta.dk/-/user_settings/personal_access_tokens (api, write_repository)
		header_up PRIVATE-TOKEN "<token>"
		header_up Authorization "Basic <base64>"  # `printf 'clank:<token>' | base64 --wrap=0`
	}
}
```
