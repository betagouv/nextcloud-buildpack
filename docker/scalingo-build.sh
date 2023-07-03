#!/bin/bash
#  mimic Scalingo build as unprivileged user
#    - build the buildpack
#    - build the php-buildpack
cat <<'EOF' | su - appsdeck
set -x
tmpdir=$(mktemp -u -p /buildpack buildpackXXXX)
rm -rf $tmpdir
mkdir -p $tmpdir && tar -zxv -C $tmpdir -f /buildpack/buildpack.tar.gz
chmod -f +x $tmpdir/bin/{detect,compile,release} || true
$tmpdir/bin/detect  /build
$tmpdir/bin/compile /build /cache /env/.env
$tmpdir/bin/release /build

tmpdir=$(mktemp -u -p /buildpack buildpackXXXX)
rm -rf $tmpdir
git clone https://github.com/Scalingo/php-buildpack.git $tmpdir
chmod -f +x $tmpdir/bin/{compile,release,detect}
cd $tmpdir
$tmpdir/bin/detect  /build
$tmpdir/bin/compile /build /cache /env/.env
$tmpdir/bin/release /build
EOF
