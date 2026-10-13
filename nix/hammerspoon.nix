{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "hammerspoon";
  version = "1.1.1";

  src = fetchurl {
    url = "https://github.com/Hammerspoon/hammerspoon/releases/download/${version}/Hammerspoon-${version}.zip";
    hash = "sha256-EbsckPr1Qn83x71P5+q5d0rkPh1csCDFswiNrDKEnvo=";
  };

  nativeBuildInputs = [
    unzip
  ];

  unpackPhase = ''
    unzip "$src"
  '';

  installPhase = ''
    mkdir -p "$out/Applications"
    cp -R Hammerspoon.app "$out/Applications/"
  '';

  meta = {
    description = "Desktop automation tool for macOS";
    homepage = "https://www.hammerspoon.org/";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
  };
}
