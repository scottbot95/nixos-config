{ config, lib, pkgs, ... }:
{
  # Telegraf ingestion for InfluxDB
  services.telegraf = {
    enable = true;
    extraConfig = {
      processors.regex = [{
        fields = [{
          key = "log-dates";
          pattern = "^(?P<YYYY>\\d{4})(?P<MM>\\d{2})(?P<DD>\\d{2})(?P<HH>\\d{2})(?P<mm>\\d{2})(?P<ss>\\d{2})\\.(?P<SSSSSS>\\d{6})(?P<ZZ>[-+]\\d{3,4})$";
          replacement = "\${YYYY}-\${MM}-\${DD} \${HH}:\${mm}:\${ss}";
        }];
      }];
      inputs.snmp = [{
        agents = [ "idrac.lan.faultymuse.com:161" ];
        version = 1;
        community = "public";
        name = "idrac-hosts";
        field = [
          {
            name = "system-name";
            oid  = ".1.3.6.1.2.1.1.5.0";
            is_tag = true;
          }
          {
            name = "system-osname";
            oid = ".1.3.6.1.4.1.674.10892.5.1.3.6.0";
          }
          {
            name = "system-osversion";
            oid = ".1.3.6.1.4.1.674.10892.5.1.3.14.0";
          }
          {
            name = "system-model";
            oid = ".1.3.6.1.4.1.674.10892.5.1.3.12.0";
          }
          {

            name = "idrac-url";
            oid = ".1.3.6.1.4.1.674.10892.5.1.1.6.0";
          }
          {
            name = "power-state";
            oid = ".1.3.6.1.4.1.674.10892.5.2.4.0";
          }
          {
            name = "system-uptime";
            oid = ".1.3.6.1.4.1.674.10892.5.2.5.0";
          }
          {
            name = "system-servicetag";
            oid = ".1.3.6.1.4.1.674.10892.5.1.3.2.0";
          }

          {
            name = "system-globalstatus";
            oid = ".1.3.6.1.4.1.674.10892.5.2.1.0";
          }
          {
            name = "fan1-speed";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.12.1.6.1.1";
          }
          {
            name = "fan2-speed";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.12.1.6.1.2";
          }
          {
            name = "fan3-speed";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.12.1.6.1.3";
          }
          {
            name = "fan4-speed";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.12.1.6.1.4";
          }
          {
            name = "fan5-speed";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.12.1.6.1.5";
          }
          {
            name = "fan6-speed";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.12.1.6.1.6";
          }
          {
            name = "inlet-temp";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.20.1.6.1.1";
          }
          {
            name = "exhaust-temp";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.20.1.6.1.2";
          }
          {
            name = "cpu1-temp";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.20.1.6.1.3";
          }
          {
            name = "cpu2-temp";
            oid = ".1.3.6.1.4.1.674.10892.5.4.700.20.1.6.1.4";
          }
          {
            name = "cmos-batterystate";
            oid = ".1.3.6.1.4.1.674.10892.5.4.600.50.1.6.1.1";
          }
          {
            name = "system-watts";
            oid = ".1.3.6.1.4.1.674.10892.5.4.600.30.1.6.1.3";
          }
        ];
        table = [{
          name = "idrac-hosts";
          inherit_tags = [ "system-name" "disks-name" ];
          field = [

            {
              name = "bios-version";
              oid = ".1.3.6.1.4.1.674.10892.5.4.300.50.1.8";
            }
            {
              name = "raid-batterystate";
              oid = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.15.1.4";
            }
            {
              name = "intrusion-sensor";
              oid = ".1.3.6.1.4.1.674.10892.5.4.300.70.1.6";
            }
            {
              name = "disks-mediatype";
              oid = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.35";
            }
            {
              name = "disks-state";
              oid = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.4";
            }
            {
              name = "disks-predictivefail";
              oid = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.31";
            }
            {
              name = "disks-capacity";
              oid = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.11";
            }
            {
              name = "disks-name";
              oid = ".1.3.6.1.4.1.674.10892.5.5.1.20.130.4.1.2";
              is_tag = true;
            }
            {
              name = "memory-status";
              oid = ".1.3.6.1.4.1.674.10892.5.4.200.10.1.27";
            }
            {
              name = "storage-status";
              oid = ".1.3.6.1.4.1.674.10892.5.2.3";
            }
            {
              name = "temp-status";
              oid = ".1.3.6.1.4.1.674.10892.5.4.200.10.1.63";
            }
            {
              name = "psu-status";
              oid = ".1.3.6.1.4.1.674.10892.5.4.200.10.1.9";
            }
            {
              name = "log-dates";
              oid = ".1.3.6.1.4.1.674.10892.5.4.300.40.1.8";
            }
            {
              name = "log-entry";
              oid = ".1.3.6.1.4.1.674.10892.5.4.300.40.1.5";
            }
            {
              name = "log-severity";
              oid = ".1.3.6.1.4.1.674.10892.5.4.300.40.1.7";
            }
            {
              name = "log-number";
              oid = ".1.3.6.1.4.1.674.10892.5.4.300.40.1.2";
              is_tag = true;
            }
            {
              name = "nic-name";
              oid = ".1.3.6.1.4.1.674.10892.5.4.1100.90.1.30";
              is_tag = true;
            }
            {
              name = "nic-vendor";
              oid = ".1.3.6.1.4.1.674.10892.5.4.1100.90.1.7";
            }
            {
              name = "nic-status";
              oid = ".1.3.6.1.4.1.674.10892.5.4.1100.90.1.4";
            }
            {
              name = "nic-current_mac";
              oid = ".1.3.6.1.4.1.674.10892.5.4.1100.90.1.15";
              conversion = "hwaddr";
            }
          ];
        }];
      }];
      outputs = {
        influxdb = {
          database = "homelab";
          urls = [ "http://localhost:8086" ];
        };
      };
    };
  };

  users.users.telegraf.extraGroups = [ "utmp" ];
}
