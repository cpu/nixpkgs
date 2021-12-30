{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config, bison
, pcreSupport ? true, pcre, gcryptSupport ? true, libgcrypt }:

stdenv.mkDerivation rec {
  pname = "ldmud";
  version = "3.6.4";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = version;
    sha256 = "01jprn42s63kg54v9cr5a6ki08bhx2nqjygw6cw9y0abggb7qr9q";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config bison ]
    ++ lib.optional pcreSupport pcre ++ lib.optional gcryptSupport libgcrypt;

  sourceRoot = "source/src";

  enableParallelBuilding = true;

  postUnpack = ''
    cp $sourceRoot/autoconf/configure.ac $sourceRoot/
  '';

  # TODO:
  #   - erq
  #   - compat mode
  #   - filename spaces
  #   - ipv6
  #   - mysql
  #   - pgsql
  #   - sqlite
  #   - json
  #   - xml
  #   - deprecated
  #   - tls
  #   - python
  #   - max configs
  #     - malloc
  #     - eval cost
  #     - array size
  #     - mapping keys
  #     - mapping size
  #     - max callouts
  #     - max players
  #     - max local
  #     - hb interval
  #     - alarm time
  #     - time to reset
  #
  configureFlags = [
    (lib.enableFeature pcreSupport "pcre")
    (lib.enableFeature gcryptSupport "gcrypt")
  ];

  installTargets = "install-driver install-utils install-headers";

  meta = with lib; {
    description =
      "LDMud is a gamedriver for LPMuds. (LPC compiler, interpreter and runtime environment.)";
    #TODO - long description
    homepage = "https://ldmud.eu";
    license = licenses.bsd2; # TODO: This is only the license for new contribs.
    platforms = with platforms; linux; # TODO: Likely also freebsd?
    maintainers = with maintainers; [ cpu ];
  };
}
