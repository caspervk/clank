{lib, vars, ...}: {
  home-manager.users.root = {
    programs.opencode = {
      enable = true;
      context = vars.AGENTS_md;
      # https://opencode.ai/docs/config
      settings = {
        autoupdate = false;
        # By default, OpenCode isn't allowed to read .env files, and has to ask
        # permission to do anything outside the working directory.
        permission = "allow";
      };
    };
  };

  environment.variables = {
    # Enable Exa web search tools
    # https://opencode.ai/docs/tools/#websearch
    OPENCODE_ENABLE_EXA = lib.mkDefault "1";
  };

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
