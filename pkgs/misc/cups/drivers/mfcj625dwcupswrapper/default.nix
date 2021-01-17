{ stdenv
, fetchurl
, makeWrapper

  # lpr driver
, mfcj625dwlpr

  # runtime dependencies
, coreutils
, cups
, gnused
}:

stdenv.mkDerivation rec {
  pname = "mfcj625dwcupswrapper";
  version = "3.0.0-1";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf006812/${pname}-src-${version}.tar.gz";
    sha256 = "0qjivraiy81vij5q4cm92ad4nc98p6xpqkxfqj3vk8xb35w7p68g";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ mfcj625dwlpr ];

  patchPhase = ''
    sed -i -e '26,304d' cupswrapper/cupswrappermfcj625dw
    substituteInPlace cupswrapper/cupswrappermfcj625dw \
        --replace "\$ppd_file_name" \
          "$out/share/cups/model/brother_mfcj625dw_printer_en.ppd"
  '';

  buildPhase = ''
    make -C brcupsconfig
  '';

  installPhase = ''
    TGT_FOLDER=$out/opt/brother/Printers/mfcj625dw/cupswrapper
    mkdir -p $TGT_FOLDER
    cp brcupsconfig/brcupsconfpt1 $TGT_FOLDER
    cp cupswrapper/cupswrappermfcj625dw $TGT_FOLDER
    cp ppd/brother_mfcj625dw_printer_en.ppd $TGT_FOLDER
    wrapProgram $TGT_FOLDER/cupswrappermfcj625dw \
        --prefix PATH : ${stdenv.lib.makeBinPath [
          coreutils
          cups
          gnused
        ]}

    mkdir -p $out/lib/cups/filter
    ln -s ${mfcj625dwlpr}/lib/cups/filter/brother_lpdwrapper_mfcj625dw \
        $out/lib/cups/filter/brother_lpdwrapper_mfcj625dw

    mkdir -p $out/share/cups/model
    ln -s $TGT_FOLDER/brother_mfcj625dw_printer_en.ppd \
        $out/share/cups/model/brother_mfcj625dw_printer_en.ppd
  '';

  cleanPhase = ''
    make -C brcupsconfig clean
  '';

  meta = {
    description = "Brother MFC-J625DW CUPS wrapper driver";
    homepage = "https://global.brother";
    license = stdenv.lib.licenses.gpl2;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = "https://support.brother.com/g/b/downloadlist.aspx?c=sg&lang=en&prod=mfcj625dw_all&os=128";
    maintainers = stdenv.lib.maintainers.chuahou;
  };
}
