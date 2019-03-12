TEMPLATE = aux

android {
	equals(ANDROID_TARGET_ARCH, arm64-v8a): ARCH_ID = android-arm64
	else:equals(ANDROID_TARGET_ARCH, armeabi-v7a): ARCH_ID = android-arm
	else:equals(ANDROID_TARGET_ARCH, x86): ARCH_ID = android-x86
	else:error("Unsupported ANDROID_TARGET_ARCH: $$ANDROID_TARGET_ARCH")

	PATH_EXTRA = $$NDK_LLVM_PATH/bin:$$NDK_TOOLCHAIN_PATH/bin

	openssl_configure.target = openssl/Makefile
	openssl_configure.commands = @test -d openssl || mkdir -p openssl \
		$$escape_expand(\\n\\t)cd openssl && PATH=\"$$PATH_EXTRA:$(PATH)\" $$PWD/openssl/Configure $$ARCH_ID shared no-ssl3 -fstack-protector-strong -DANDROID -D__ANDROID_API__=$$replace(ANDROID_PLATFORM, "android-", "")
	QMAKE_EXTRA_TARGETS += openssl_configure
	PRE_TARGETDEPS += openssl/Makefile

	openssl_build.target = openssl_build
	openssl_build.commands = @test -d openssl || mkdir -p openssl \
		$$escape_expand(\\n\\t)cd openssl && \
			$(MAKE) depend && \
			$(MAKE) \
				CC=$(CC) \
				CXX=$(CXX) \
				RANLIB=$(RANLIB) \
				SHLIB_VERSION_NUMBER= \
				SHLIB_EXT=.so \
				SHLIB_EXT_SIMPLE=.so.simple \
				build_libs
	openssl_build.depends += openssl_configure
	QMAKE_EXTRA_TARGETS += openssl_build
	PRE_TARGETDEPS += openssl_build

	# qdep stuff
	LIBS = -L$$OUT_PWD/openssl -lcrypto -lssl
	ANDROID_EXTRA_LIBS = $$OUT_PWD/openssl/libcrypto.so $$OUT_PWD/openssl/libssl.so
	QDEP_VAR_EXPORTS += LIBS ANDROID_EXTRA_LIBS
}

CONFIG += qdep_link_export qdep_no_link
!load(qdep):error("Failed to load qdep feature! Run 'qdep prfgen --qmake $$QMAKE_QMAKE' to create it.")

# cleanups
QMAKE_EXTRA_COMPILERS -= __qdep_hook_importer_c
