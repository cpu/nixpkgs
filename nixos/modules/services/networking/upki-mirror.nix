{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.upki-mirror;
  mirrorRoot = "/var/lib/upki-mirror";
in
{
  options.services.upki-mirror = {
    enable = lib.mkEnableOption "a Mozilla CRLite mirror for UPKI";

    package = lib.mkPackageOption pkgs "upki-mirror" { };

    manifestComment = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "Operated by example.com";
      description = "Comment included in the generated manifest.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "2h";
      example = "1h";
      description = "How often to update the mirror.";
    };

    nginx = {
      enable = lib.mkEnableOption "an nginx virtual host for the mirror";

      domain = lib.mkOption {
        type = lib.types.str;
        example = "upki.example.com";
        description = "Domain to use for the nginx virtual host.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      users.users.upki-mirror = {
        isSystemUser = true;
        group = "upki-mirror";
      };
      users.groups.upki-mirror = { };

      systemd.tmpfiles.rules = [
        "d ${mirrorRoot}/revocation 0755 upki-mirror upki-mirror -"
      ];

      systemd.services.upki-mirror = {
        description = "Mirror Mozilla CRLite data for UPKI";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.escapeShellArgs [
            (lib.getExe cfg.package)
            "${mirrorRoot}/revocation"
            "--manifest-comment=${cfg.manifestComment}"
          ];
          User = "upki-mirror";
          Group = "upki-mirror";
          StateDirectory = "upki-mirror";
          StateDirectoryMode = "0755";
          UMask = "0022";

          CapabilityBoundingSet = [ "" ];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProcSubset = "pid";
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          ProtectSystem = "strict";
          RemoveIPC = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          SystemCallErrorNumber = "EPERM";
          SystemCallFilter = [
            "@system-service"
            "~@privileged @resources"
          ];
        };
      };

      systemd.timers.upki-mirror = {
        description = "Update the UPKI mirror every ${cfg.interval}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = cfg.interval;
          RandomizedDelaySec = "10min";
        };
      };
    })

    # Keep serving independent so nginx can publish externally synchronized data.
    (lib.mkIf cfg.nginx.enable {
      services.nginx = {
        enable = true;
        virtualHosts.${cfg.nginx.domain} = {
          root = mirrorRoot;
          locations = {
            "= /revocation/manifest.json".extraConfig = ''
              expires -1;
            '';
            "^~ /revocation/".extraConfig = ''
              expires 1d;
            '';
          };
        };
      };
    })
  ];

  meta.maintainers = [ lib.maintainers.cpu ];
}
