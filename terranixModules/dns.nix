{ config, lib, ...}:
with lib;
let
  cfg = config.dns;
  cname_records = map (name: {
    dns_cname_record.${name} = {
      inherit name;
      zone = "faultymuse.com.";
      cname = "us-west-1.faultymuse.com.";
      ttl = 300;
    };
  }) cfg.public.cnames;
in
{
  options.dns = {
    public = {
      cnames = mkOption {
        type = with types; listOf str;
        description = "List of CNAME records to create";
        default = [];
      };
    };
  };
  
  config = {
    provider.dns.update = {
      server = "10.0.20.2";
      key_name = "terraform.";
      key_algorithm = "hmac-sha512";
      key_secret = "\${data.sops_file.secrets.data[\"deployment.tsig\"]}";
    };
  };

  config.resource = mkMerge cname_records;
}