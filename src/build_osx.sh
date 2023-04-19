#!/usr/bin/env bash
set -e  # Stop on error
cd "$(dirname "$0")"

if pwd | grep -q " "; then
        echo "You have cloned the source directory into a path with spaces"
        echo "This will break a lot of thirdparty build scripts"
        echo "Please move the source directory somewhere without a space in the path"
        exit 1
fi

VPC_FLAGS="/define:LTCG /define:CERT"
CORES=$(sysctl -n hw.physicalcpu)
# shellcheck disable=SC2155
export OSX_TOOLS_BIN="$(pwd)/devtools/bin/osx32"
export CC="${OSX_TOOLS_BIN}/ccache clang"
export CXX="${OSX_TOOLS_BIN}/ccache clang++"
chmod u+x "${OSX_TOOLS_BIN}/ccache" "${OSX_TOOLS_BIN}/protoc" "${OSX_TOOLS_BIN}/xcode_ccache_wrapper"
export SDKROOT="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.13.sdk"

if [[ ! -f "lib/public/osx32/libprotobuf.a" ]]; then
	pushd .
	cd "thirdparty/protobuf-2.6.1/"
	chmod u+x ./configure
	chmod u+x ./install-sh
	# Hack: We need -stdlib=libc++ passed to libtool but LDFLAGS doesn't seem to work here.
	#       We add the flag to the CXX command-line to fix this.
	./configure "CXX=${CXX} -stdlib=libc++" \
	    "CFLAGS=-m32 -mmacosx-version-min=10.7 -isysroot ${SDKROOT}" \
		"CXXFLAGS=-m32 -D_GLIBCXX_USE_CXX11_ABI=0 -mmacosx-version-min=10.7 -stdlib=libc++ -isysroot ${SDKROOT}" \
		"LDFLAGS=-m32 -mmacosx-version-min=10.7 -stdlib=libc++" \
		"--prefix=$(pwd)/build_osx32" \
		"--bindir=$(pwd)/bin/osx32/libc++" \
		"--libdir=$(pwd)/bin/osx32/libc++"
	make "-j$CORES"
	make install
	popd
	cp thirdparty/protobuf-2.6.1/bin/osx32/libc++/*.a "lib/public/osx32"
fi

if [[ ! -f "lib/public/osx32/libedit.a" ]]; then
    pushd .
    cd "thirdparty/libedit-3.1/"
	chmod u+x ./configure
	chmod u+x ./install-sh
	./configure "CFLAGS=-m32 -mmacosx-version-min=10.7 -isysroot ${SDKROOT} -stdlib=libc++" \
		"CXXFLAGS=-m32 -D_GLIBCXX_USE_CXX11_ABI=0 -mmacosx-version-min=10.7 -stdlib=libc++ -isysroot ${SDKROOT}" \
		"LDFLAGS=-m32 -mmacosx-version-min=10.7 -stdlib=libc++" \
		"--prefix=$(pwd)/build_osx32" \
		"--bindir=$(pwd)/bin/osx32/libc++" \
		"--libdir=$(pwd)/bin/osx32/libc++"
	make "-j$CORES"
	make install
	popd
	cp thirdparty/libedit-3.1/bin/osx32/libc++/*.a "lib/public/osx32"
fi

# if [[ ! -f "lib/common/osx32/libcryptopp.a" ]]; then
#	pushd .
#	cd "external/crypto++-5.6.3/"
#	make "-j$CORES" "CFLAGS=-m32 -mmacosx-version-min=10.7 -stdlib=libc++" \
#		"CXXFLAGS=-m32 -mmacosx-version-min=10.7 -stdlib=libc++" \
#		"SDKROOT=\"\""
#	popd
# fi

if [[ ! -f "./devtools/bin/vpc_osx" ]]; then
	pushd .
	cd "./external/vpc/utils/vpc"
	# shellcheck disable=SC2086
	make "-j$CORES" CC="$CC" CXX="$CXX"
	popd
fi

# shellcheck disable=SC2086   # we want arguments to be split
devtools/bin/vpc_osx /define:WORKSHOP_IMPORT_DISABLE /define:SIXENSE_DISABLE /define:NO_X360_XDK \
				/define:RAD_TELEMETRY_DISABLED /retail /tf ${VPC_FLAGS} +everything -panel_zoo /mksln everything

#xcodebuild -workspace "$(pwd)/games.xcodeproj/project.xcworkspace" -scheme All -configuration Debug
xcodebuild -project "$(pwd)/everything.xcodeproj" -alltargets -configuration Debug
