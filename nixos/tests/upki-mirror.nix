{ pkgs, ... }:

let
  fakeMirror = pkgs.writeShellApplication {
    name = "fake-upki-mirror";
    text = ''
      test "$(id --user --name)" = upki-mirror
      test "$#" -eq 2
      test "$2" = "--manifest-comment=NixOS test mirror"

      printf '%s\n' 'test filter' > "$1/test.filter"
      printf '%s\n' \
        '{"generated_at":1,"comment":"NixOS test mirror","files":[]}' \
        > "$1/manifest.json"
    '';
  };
in
{
  name = "upki-mirror";

  meta.maintainers = [ pkgs.lib.maintainers.cpu ];

  nodes.machine = {
    environment.systemPackages = [ pkgs.curl ];

    networking.hosts."127.0.0.1" = [ "upki.test" ];

    services.upki-mirror = {
      enable = true;
      package = fakeMirror;
      manifestComment = "NixOS test mirror";
      interval = "1h";
      nginx = {
        enable = true;
        domain = "upki.test";
      };
    };
  };

  testScript = ''
    start_all()

    machine.wait_for_unit("upki-mirror.timer")
    machine.succeed("systemctl start upki-mirror.service")
    machine.wait_for_unit("nginx.service")

    machine.succeed(
        "test \"$(stat --format=%U:%G,%a /var/lib/upki-mirror/revocation)\" "
        "= upki-mirror:upki-mirror,755"
    )
    machine.succeed(
        "test \"$(stat --format=%U:%G /var/lib/upki-mirror/revocation/manifest.json)\" "
        "= upki-mirror:upki-mirror"
    )

    machine.succeed(
        "curl --fail --silent http://upki.test/revocation/manifest.json "
        "| grep --fixed-strings 'NixOS test mirror'"
    )
    machine.succeed(
        "curl --fail --silent http://upki.test/revocation/test.filter "
        "| grep --fixed-strings 'test filter'"
    )

    machine.succeed(
        "curl --silent --head http://upki.test/revocation/manifest.json "
        "| grep --ignore-case --fixed-strings 'Cache-Control: no-cache'"
    )
    machine.succeed(
        "curl --silent --head http://upki.test/revocation/test.filter "
        "| grep --ignore-case --fixed-strings 'Cache-Control: max-age=86400'"
    )
    machine.succeed(
        "curl --fail --silent --remote-time "
        "--output /tmp/test.filter http://upki.test/revocation/test.filter"
    )
    machine.succeed(
        'test "$(curl --silent --time-cond /tmp/test.filter '
        '--output /dev/null --write-out "%{http_code}" '
        'http://upki.test/revocation/test.filter)" = 304'
    )
  '';
}
