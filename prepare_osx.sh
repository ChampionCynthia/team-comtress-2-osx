#!/usr/bin/env bash
set -e  # Stop on error
cd "$(dirname "$0")/src"

if pwd | grep -q " "; then
        echo "You have cloned the source directory into a path with spaces"
        echo "This will break a lot of thirdparty build scripts"
        echo "Please move the source directory somewhere without a space in the path"
        exit 1
fi

VPC_FLAGS="/define:LTCG /define:CERT"
CORES=$(sysctl -n hw.physicalcpu)
# shellcheck disable=SC2155
export CC="$(pwd)/devtools/bin/osx32/ccache clang"
# shellcheck disable=SC2155
export CXX="$(pwd)/devtools/bin/osx32/ccache clang++"

if [[ ! -f "thirdparty/protobuf-2.6.1/src/.libs/libprotobuf.a" ]]; then
	pushd .
	cd "thirdparty/protobuf-2.6.1/"
	chmod u+x configure
	./configure "CFLAGS=-m32 -Wno-reserved-user-defined-literal -D_GLIBCXX_USE_CXX11_ABI=0" \
		"CXXFLAGS=-m32 -Wno-reserved-user-defined-literal -D_GLIBCXX_USE_CXX11_ABI=0" \
		"LDFLAGS=-m32"
	chmod u+x install-sh
	make "-j$CORES"
	popd
fi

if [[ ! -f "./devtools/bin/vpc_osx" ]]; then
	pushd .
	cd "./external/vpc/utils/vpc"
	# shellcheck disable=SC2086
	make "-j$CORES" CC="$CC" CXX="$CXX"
	popd
fi

# shellcheck disable=SC2086   # we want arguments to be split
devtools/bin/vpc_osx /define:WORKSHOP_IMPORT_DISABLE /define:SIXENSE_DISABLE /define:NO_X360_XDK \
				/define:RAD_TELEMETRY_DISABLED /define:DISABLE_ETW /retail /tf ${VPC_FLAGS} +game /mksln games

echo "Open games.xcproj in Xcode 9.4.1."

