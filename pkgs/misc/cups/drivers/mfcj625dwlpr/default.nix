{ stdenv
, fetchurl

  # unpacking / patching
, autoPatchelfHook
, dpkg
, makeWrapper

  # runtime dependencies
, a2ps
, coreutils
, file
, ghostscript
, gnused
}:

stdenv.mkDerivation rec {
  pname = "mfcj625dwlpr";
  version = "3.0.1-1";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf006606/${pname}-${version}.i386.deb";
    sha256 = "1cv2ysw5shyipiq7zd5lq5cpb6isk97szlkfz3y8s4kl844vkm9l";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];

  unpackPhase = ''
    dpkg-deb -x $src $out
  '';

  patchPhase = ''
    substituteInPlace $out/opt/brother/Printers/mfcj625dw/lpd/filtermfcj625dw \
        --replace /opt "$out/opt"
    sed -i '/GHOST_SCRIPT=/c\GHOST_SCRIPT=gs' \
        $out/opt/brother/Printers/mfcj625dw/lpd/psconvertij2
  '';

  installPhase = ''
    mkdir -p $out/lib/cups/filter
    ln -s $out/opt/brother/Printers/mfcj625dw/lpd/filtermfcj625dw \
        $out/lib/cups/filter/brother_lpdwrapper_mfcj625dw

    wrapProgram $out/opt/brother/Printers/mfcj625dw/lpd/psconvertij2 \
        --prefix PATH : ${stdenv.lib.makeBinPath [
          coreutils
          ghostscript
          gnused
        ]}
    wrapProgram $out/opt/brother/Printers/mfcj625dw/lpd/filtermfcj625dw \
        --prefix PATH : ${stdenv.lib.makeBinPath [
          a2ps
          coreutils
          file
          ghostscript
          gnused
        ]}
  '';

  meta = {
    description = "Brother MFC-J625DW lpr driver";
    homepage = "https://global.brother";
    license = stdenv.lib.licenses.unfree;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = "https://support.brother.com/g/b/downloadlist.aspx?c=sg&lang=en&prod=mfcj625dw_all&os=128";
    maintainers = stdenv.lib.maintainers.chuahou;
  };
}
