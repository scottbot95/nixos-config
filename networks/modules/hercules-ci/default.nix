{config, pkgs, lib, inputs, ...}:
let
  cfg = config.scott.hercules-ci;
in
with lib; {
  options.scott.hercules-ci = {
    agent = {
      enable = mkEnableOption "Hercules CI Agent";
      concurrentTasks = mkOption {
        type = types.ints.unsigned;
        description = "Max number of concurrent tasks to allow on this machine";
        example = 4;
      };
    };
  };

  config = 
    (mkIf cfg.agent.enable {

      services.hercules-ci-agent = {
        enable = true;
        settings.concurrentTasks = cfg.agent.concurrentTasks;
      };

      # Can't use normal sops-nix because hercules is overly particular about how it's keys get deployed
      deployment.keys = 
        let
          localPkgs = import inputs.nixpkgs {};
          sops = "${localPkgs.sops}/bin/sops";
          createBinaryCachesJsonCmd = ''
cat << EOF
{
  "scottbot95-homelab": {
    "kind": "CachixCache",
    "authToken": "$(${sops} --extract '["services"]["cachix"]["auth_token"]' -d secrets/homelab.yaml)",
    "publicKeys": ["scottbot95-homelab.cachix.org-1:elNonYZMihwOSvEe4WGJFUNpmloOb4VtD4iR9poXGng="]
  }
}
EOF'';
        in {
          "cluster-join-token.key".keyCommand = [
            sops 
            "--extract" ''["hercules"]["cluster_join_token"]''
            "-d" "secrets/homelab.yaml"
          ];
          
          "binary-caches.json".keyCommand = [ "sh" "-c" createBinaryCachesJsonCmd ];
        };
    });
}