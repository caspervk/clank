{
  lib,
  pkgs,
  vars,
  ...
}: {
  # Cringe
  nixpkgs.config.allowUnfreePackages = ["claude-code"];

  home-manager.users.root = {
    programs.claude-code = {
      enable = true;
      # The most upvoted issue on Claude Code: "Feature Request: Support
      # AGENTS.md", i.e. "stop requiring me to put ads for Anthropic in my
      # repo". Don't let them win.
      # https://github.com/anthropics/claude-code/issues/6235
      package = pkgs.claude-code.overrideAttrs (previousAttrs: {
        postInstall = ''
          ${previousAttrs.postInstall or ""}
          # Claude Code is a binary file, but luckily the strings `CLAUDE.md`
          # and `AGENTS.md` are of the same length 😎
          sed -i -e 's/CLAUDE\.md/AGENTS\.md/g' $out/bin/.claude-wrapped
        '';
      });
      context = vars.AGENTS_md;
      # https://code.claude.com/docs/en/settings
      settings = {
        # Disable commercials in git commits
        attribution = {
          commit = "";
          pr = "";
        };
        env = {
          # Allow bypassPermissions as root
          # https://github.com/anthropics/claude-code/issues/3490
          IS_SANDBOX = "1";
          # DISABLE_AUTOUPDATER, DISABLE_BUG_COMMAND,
          # DISABLE_ERROR_REPORTING and DISABLE_TELEMETRY.
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
        };
        # Default to the best model
        model = "opus[1m]";
        # yolo
        permissions.defaultMode = "bypassPermissions";
        skipDangerousModePermissionPrompt = true;
      };
    };
  };

  # TODO: remove once everyone is using latest Clank
  home-manager.users.root.home.file."/root/.claude/settings.json".force = true;

  systemd.tmpfiles.rules = let
    claudeJson = pkgs.writeText "claude.json" (builtins.toJSON {
      # Claude Code asks us to log in even though we may be using
      # CLAUDE_CODE_OAUTH_TOKEN.
      hasCompletedOnboarding = true;
    });
  in [
    # It's annoying to bind mount and persist a single file, so we symlink
    # /root/.claude.json to the persisted directory instead.
    "L+ /root/.claude.json - - - - /root/.claude/claude.json"
    "C /root/.claude/claude.json 0600 root root - ${claudeJson}"
    # The Home Manager module creates CLAUDE.md, but we must use AGENTS.md
    # since we patched the binary.
    "L+ /root/.claude/AGENTS.md - - - - /root/.claude/CLAUDE.md"
  ];

  # Automatically trust the mounted directory
  systemd.services.claude-auto-trust = {
    wantedBy = ["multi-user.target"];
    after = ["systemd-tmpfiles-setup.service"];
    before = ["console-getty.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.yq-go}/bin/yq \
        --inplace \
        --input-format=json \
        --output-format=json \
        '.projects[loadstr("/clank/cwd")].hasTrustDialogAccepted = true' \
        /root/.claude.json
    '';
  };

  # https://code.claude.com/docs/en/claude-directory#application-data
  fileSystems."/root/.claude" = {
    device = "/persist/root/.claude";
    fsType = "none";
    options = ["bind"];
  };
}
