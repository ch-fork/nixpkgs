{ lib
, stdenv
, fetchurl

  # unpacking/patching
, autoPatchelfHook
, dpkg
, makeWrapper
, util-linux
, xxd

  # runtime dependencies
, a2ps
, coreutils
, cups
, file
, ghostscript
, gnused
, runtimeShell
}:

# Explanation copied and modified from the sibling package 'mfcj6510dwlpr'.
#
# Why:
# The executable "brprintconf_mfcj625dw" binary is looking for "/opt/brother/Printers/%s/inf/br%sfunc" and "/opt/brother/Printers/%s/inf/br%src".
# Whereby, %s is printf(3) string substitution for stdin's arg0 (the command's own filename) from the 10th char forwards, as a runtime dependency.
# e.g. Say the filename is "0123456789ABCDE", the runtime will be looking for /opt/brother/Printers/ABCDE/inf/brABCDEfunc.
# Presumably, the binary was designed to be deployed under the filename "printconf_mfcj625dw", whereby it will search for "/opt/brother/Printers/mfcj625dw/inf/brmfcj625dwfunc".
# For NixOS, we want to change the string to the store path of brmfcj625dwfunc and brmfcj625dwrc but we're faced with two complications:
# 1. Too little room to specify the nix store path. We can't even take advantage of %s by renaming the file to the store path hash since the variable is too short and can't contain the whole hash.
# 2. The binary needs the directory it's running from to be r/w.
# What:
# As such, we strip the path and substitution altogether, leaving only "brmfcj625dwfunc" and "brmfcj625dwrc", while filling the leftovers with nulls.
# Fully null terminating the cstrings is necessary to keep the array the same size and preventing overflows.
# We then use a shell script to link and execute the binary, func and rc files in a temporary directory.
# How:
# In the package, we dump the raw binary as a string of search-able hex values using hexdump. We execute the substitution with sed. We then convert the hex values back to binary form using xxd.
# We also write a shell script that invoked "mktemp -d" to produce a r/w temporary directory and link what we need in the temporary directory.
# Result:
# The user can run brprintconf_mfcj625dw in the shell.

stdenv.mkDerivation rec {
  pname = "mfcj625dwlpr";
  version = "3.0.1-1";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf006606/${pname}-${version}.i386.deb";
    sha256 = "1cv2ysw5shyipiq7zd5lq5cpb6isk97szlkfz3y8s4kl844vkm9l";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];
  buildInputs = [ a2ps cups ghostscript ];

  # wrapper script that links the relevant files to a writeable directory and
  # calls the original executable
  brprintconf_mfcj625dw_script = ''
    #!${runtimeShell}
    cd $(mktemp -d)
    cp @out@/bin/brprintconf_mfcj625dw_patched brprintconf_mfcj625dw_patched
    cp @out@/opt/brother/Printers/mfcj625dw/inf/brmfcj625dwfunc brmfcj625dwfunc
    cp @out@/opt/brother/Printers/mfcj625dw/inf/brmfcj625dwrc brmfcj625dwrc
    ./brprintconf_mfcj625dw_patched "$@"
  '';

  unpackPhase = ''
    dpkg-deb -x $src $out
  '';

  patchPhase = ''
    substituteInPlace $out/opt/brother/Printers/mfcj625dw/lpd/filtermfcj625dw \
        --replace /opt "$out/opt"
    substituteInPlace $out/opt/brother/Printers/mfcj625dw/lpd/psconvertij2 \
        --replace "GHOST_SCRIPT=\`which gs\`" "GHOST_SCRIPT=gs"
    substituteInPlace $out/opt/brother/Printers/mfcj625dw/inf/setupPrintcapij \
      --replace "/opt/brother/Printers" "$out/opt/brother/Printers" \
      --replace "printcap.local" "printcap"

    # replace "/opt/brother/Printers/%s/inf/br%sfunc" with "brmfcj625dwfunc" and
    # replace "/opt/brother/Printers/%s/inf/br%src" with "brmfcj625dwrc"
    mkdir $out/bin
    ${util-linux}/bin/hexdump -ve '1/1 "%.2x"' $out/usr/bin/brprintconf_mfcj625dw | \
        sed 's/2f6f70742f62726f746865722f5072696e746572732f25732f696e662f6272257366756e63/62726d66636a363235647766756e6300000000000000000000000000000000000000000000/' | \
        sed 's/2f6f70742f62726f746865722f5072696e746572732f25732f696e662f627225737263/62726d66636a3632356477726300000000000000000000000000000000000000000000/' | \
        ${xxd}/bin/xxd -r -p > $out/bin/brprintconf_mfcj625dw_patched
    chmod +x $out/bin/brprintconf_mfcj625dw_patched
  '';

  installPhase = ''
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

    # we masquerade our wrapper script as a binary of the same name
    echo "$brprintconf_mfcj625dw_script" > $out/bin/brprintconf_mfcj625dw
    chmod +x $out/bin/brprintconf_mfcj625dw
    substituteInPlace $out/bin/brprintconf_mfcj625dw --replace "@out@" "$out"

    mkdir -p $out/lib/cups/filter
    ln -s $out/opt/brother/Printers/mfcj625dw/lpd/filtermfcj625dw \
        $out/lib/cups/filter/brother_lpdwrapper_mfcj625dw
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
