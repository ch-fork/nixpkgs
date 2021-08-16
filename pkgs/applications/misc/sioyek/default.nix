{ mkDerivation
, fetchFromGitHub
, harfbuzz
, pkg-config
, qt3d
, qtbase
, xorg
}:

mkDerivation rec {
  pname = "sioyek";
  version = "0.31.5";

  src = fetchFromGitHub {
    owner = "ahrm";
    repo = "sioyek";
    rev = "v${version}";
    sha256 = "sha256-h9caNkrNfkVSq8Qf+bB63+PnyzrMMHGC3AJQlhajIKQ=";
    fetchSubmodules = true;
  };

  buildInputs = [
    harfbuzz.dev
    qt3d
    qtbase
    xorg.libXrandr
  ];
  nativeBuildInputs = [ pkg-config ];

  patches = [
    ./g++-9.patch
  ];

  buildPhase = ''
    ./build_linux.sh
  '';

  installPhase = ''
    mv build $out
  '';
}
