{
  pkgs,
  vars,
  ...
}: {
  environment.systemPackages = [
    pkgs.opencode
  ];

  environment.variables = {
    # Enable Exa web search tools
    # https://opencode.ai/docs/tools/#websearch
    OPENCODE_ENABLE_EXA = "1";
  };

  # https://opencode.ai/docs/config
  systemd.tmpfiles.rules = let
    opencodeJson = pkgs.writeText "opencode.json" (builtins.toJSON {
      autoupdate = false;
      # By default, OpenCode isn't allowed to read .env files, and has to ask
      # permission to do anything outside the working directory.
      permission = "allow";
    });
  in [
    "L+ /root/.config/opencode/AGENTS.md - - - - ${vars.AGENTS_md}"
    "L+ /root/.config/opencode/opencode.json - - - - ${opencodeJson}"
  ];

  fileSystems."/root/.local/share/opencode" = {
    device = "/persist/root/.local/share/opencode";
    fsType = "none";
    options = ["bind"];
  };
  fileSystems."/root/.local/state/opencode" = {
    device = "/persist/root/.local/state/opencode";
    fsType = "none";
    options = ["bind"];
  };
}
