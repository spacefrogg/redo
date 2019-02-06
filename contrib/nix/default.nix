{ stdenv, fetchFromGitHub
, shellPkg ? dash, dash # Supply the shell to be used by redo, use dash by default
, mkdocs, python2, python2Packages, which
, doCheck ? true, perl, R, rPackages, texlive }:

let
  inherit (stdenv.lib) optional;
  name = "redo-${version}";
  version = "0.41";

in stdenv.mkDerivation {
  inherit name version doCheck;

  src = fetchFromGitHub {
    owner = "apenwarr";
    repo = "redo";
    rev = name;
    sha256 = "1xhskdc8h33qzsih420ia2bw3arjbwq48w11wi8iyg5czfznrfq0";
  };

  nativeBuildInputs = [ mkdocs which ]
    # Packages below are for running the testsuite
    ++ optional doCheck [ perl R rPackages.ggplot2 (texlive.combine { inherit (texlive) scheme-small dvipdfmx; }) ];

  buildInputs = [ shellPkg python2 ] ++ (with python2Packages; [ beautifulsoup4 markdown setproctitle pysqlite ]);

  patches = [ ./build-fixes.diff ];

  # Most of the patching is done to satisfy the test fixture
  postPatch = ''
    patchShebangs ./minimal
    chmod +x ./t/200-shell/nonshelltest.do
    patchShebangs ./t/200-shell/nonshelltest.do
    for f in do t/all.do t/clean.do t/105-sympath/all.do minimal/do.test ; do
      substituteInPlace $f --replace /bin/pwd pwd --replace /bin/ls ls
    done
    substituteInPlace t/110-compile/hello.o.do --replace /usr/include/stdio.h ""
    for f in docs/cookbook/latex/{default.pdf.do,all.do} ; do
      substituteInPlace $f --replace dvipdf dvipdfmx
    done
  '';

  buildPhase = ''
    ./minimal/do -c bin/all
    ./bin/redo bin/all || { e=$? ; ./bin/redo-log bin/all; printf "redo failed to rebuild itself"; exit $e ; }
  '';

  outputs = [ "out" "doc" "man" ];
  installPhase = ''
    DESTDIR=$out PREFIX="/"  MANDIR=$man/share/man DOCDIR=$doc/share/doc/redo ./bin/redo install
    cp -rP docs.out $doc/share/doc/redo/html
  '';

  checkPhase = ''
    ./bin/redo test
  '';

  meta = with stdenv.lib; {
    maintainers = [ maintainers.spacefrogg ];
    description = "Implementation of DJB's make replacement called redo";
  };
}
