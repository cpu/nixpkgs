{
  lib,
  rustPlatform,
  pkg-config,
  aws-lc,
  nixosTests,
  rustc,
  upki,
}:

rustPlatform.buildRustPackage {
  pname = "upki-mirror";
  version = "0.2.0";

  inherit (upki) src cargoDeps;

  cargoBuildFlags = [
    "--package=upki-mirror"
    "--bin=mozilla-crlite"
  ];
  cargoInstallFlags = [
    "--package=upki-mirror"
    "--bin=mozilla-crlite"
  ];
  cargoTestFlags = [
    "--package=upki-mirror"
    "--bin=mozilla-crlite"
  ];

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ aws-lc ];

  postInstall = ''
    mv "$out/bin/mozilla-crlite" "$out/bin/upki-mirror-mozilla-crlite"
  '';

  passthru.tests.nixos = nixosTests.upki-mirror;

  meta = {
    description = "Mirrors Mozilla CRLite revocation data for UPKI";
    homepage = "https://github.com/rustls/upki";
    license = lib.licenses.OR [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    maintainers = [
      lib.maintainers.skyesoss
      lib.maintainers.cpu
    ];
    mainProgram = "upki-mirror-mozilla-crlite";
    platforms = rustc.meta.platforms;
  };
}
