{ lib, stdenv, fetchFromGitHub, autoreconfHook, pkg-config, bison }:

stdenv.mkDerivation rec {
  pname = "ldmud";
  version = "3.6.4";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = version;
    sha256 = "01jprn42s63kg54v9cr5a6ki08bhx2nqjygw6cw9y0abggb7qr9q";
  };

  nativeBuildInputs = [ autoreconfHook pkg-config bison ];

  sourceRoot = "source/src";

  postUnpack = ''
    cp $sourceRoot/autoconf/configure.ac $sourceRoot/
  '';

  configureFlags = [ "--enable-use-pcre=no" "--enable-use-gcrypt=no" ];

  installTargets = "install-driver install-utils";

  meta = with lib; {
    description =
      "LDMud is a gamedriver for LPMuds. (LPC compiler, interpreter and runtime environment.)";
    homepage = "https://ldmud.eu";
    license = licenses.bsd2; # TODO: This is only the license for new contribs.
    platforms = with platforms; linux; # TODO: Likely also freebsd?
    maintainers = with maintainers; [ cpu ];
  };
}
