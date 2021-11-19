{ buildGoModule
, fetchFromGitHub
, fetchpatch
, protobuf
, go-protobuf
, pkg-config
, libnetfilter_queue
, libnfnetlink
, lib
, coreutils
, iptables
}:

buildGoModule rec {
  pname = "opensnitch";
  version = "1.4.2";

  src = fetchFromGitHub {
    owner = "evilsocket";
    repo = "opensnitch";
    rev = "v${version}";
    sha256 = "sha256-+TplEevRQBaE58camZ6zPlZV+R2xBS4J7EzKlxKUEFk=";
  };

  modRoot = "daemon";

  postBuild = ''
    mv $GOPATH/bin/daemon $GOPATH/bin/opensnitchd
    mkdir -p $out/lib/systemd/system
    substitute opensnitchd.service $out/lib/systemd/system/opensnitchd.service \
      --replace "/usr/local/bin/opensnitchd" "$out/bin/opensnitchd" \
      --replace "/etc/opensnitchd/rules" "/var/lib/opensnitch/rules" \
      --replace "/bin/mkdir" "${coreutils}/bin/mkdir"
    sed -i '/\[Service\]/a Environment=PATH=${iptables}/bin' $out/lib/systemd/system/opensnitchd.service
  '';

  vendorSha256 = "sha256-KhDSbCXXUKTFc4oBDub0sw8JSMSH7oEhkp//qhbyXNU=";

  nativeBuildInputs = [ pkg-config protobuf go-protobuf ];

  preBuild = ''
    make -C ../proto ../daemon/ui/protocol/ui.pb.go
  '';

  buildInputs = [ libnetfilter_queue libnfnetlink ];

  meta = with lib; {
    description = "An application firewall";
    homepage = "https://github.com/evilsocket/opensnitch/wiki";
    license = licenses.gpl3Only;
    maintainers = [ maintainers.raboof ];
    platforms = platforms.linux;
  };
}
