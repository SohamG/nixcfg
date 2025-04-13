{ lib
, stdenv
, fetchurl
}:

stdenv.mkDerivation rec {
  pname = "nebula-nightly";

  version = "v2.0.0-nightly20250409";

  src = fetchurl {
    url = "https://github.com/NebulaOSS/nebula-nightly/releases/download/${version}/nebula-linux-amd64.tar.gz";
    sha256 = "sha256-nDFUg85gki4TDqFVGCCMTJ6nf1maLufUK0Sj+HvrqQA="; 
  };

  # No build phase needed
  dontBuild = true;

  # Skip configure phase
  dontConfigure = true;

  # Custom unpack phase if needed (rarely necessary)
  unpackPhase = "tar -xzf $src";

  installPhase = ''
    mkdir -p $out/bin
    cp nebula nebula-cert $out/bin/
    chmod +x $out/bin/nebula $out/bin/nebula-cert
  '';
}
