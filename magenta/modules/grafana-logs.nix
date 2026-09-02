{pkgs, ...}: {
  environment.variables = {
    LOKI_ADDR = "http://clank-proxy:1932";
  };

  environment.systemPackages = [
    pkgs.grafana-loki
  ];

  home-manager.users.root = {
    programs.opencode = {
      skills = {
        magenta-grafana-logs = ''
          ---
          name: magenta-grafana-logs
          description: Read production logs from Grafana Loki.
          ---

          The application is deployed in either Kubernetes or Docker Compose
          using Salt. Kubernetes deployments are identified by the labels
          `cluster`, `namespace` and `app`. Salt deployments are identified by
          the labels `minion` and `compose_service`. If the user requests logs
          for a specific environment, use `logcli labels
          <cluster|namespace|app|minion|compose_servic|>` to learn how that
          environment is deployed. For example, to get logs for the `mo`
          application in the `foo` production environment:

          ```bash
          logcli query '{minion="os2mo.example.prod", compose_service="mo"}'
          logcli query '{cluster="os2mo-all-example-az", namespace="os2mo-example-prod", app="mo"}'
          ```
        '';
      };
    };
  };
}
