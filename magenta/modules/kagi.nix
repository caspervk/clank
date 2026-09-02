{...}: {
  environment.variables = {
    OPENCODE_ENABLE_EXA = "0";
  };

  home-manager.users.root = {
    programs.opencode = {
      settings = {
        mcp = {
          kagi = {
            enabled = true;
            type = "remote";
            url = "http://clank-proxy:1394/mcp";
          };
        };
      };
    };
  };
}
