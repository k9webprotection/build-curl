## cURL Building ##

This project provides some prebuilt cURL configuration scripts for easy building on various platforms.  It contains as a submodule, [k9webprotection/curl][curl-release] git project.

You can check this directory out in any location on your computer, but the default location that the `build.sh` script looks for is as a parent directory to where you check out the [k9webprotection/curl][curl-release] git project.  By default, this project contains a submodule of the [k9webprotection/curl][curl-release] git project in the correct location.

[curl-release]: https://github.com/bagder/curl

### Requirements ###

The following are supported to build the cURL project:

To build on macOS:

 * macOS 10.13 (High Sierra)
 
 * Xcode 9.1 (From Mac App Store)
     * Run Xcode and accept all first-run prompts

 * Build dependencies
     * Autoconf
     * Automake
     * Libtool

To build for Android:

 * macOS requirements above
 
 * Android NDK r15c
     * You must set the environment variable `ANDROID_NDK_HOME` to point to your NDK installation

     
##### Steps (Bootstrap script) #####

The `build.sh` script accepts a "bootstrap" argument which will install the dependencies for building from Homebrew.  It can be run multiple times safely.

    ./build.sh bootstrap


### Build Steps ###

If you installed `autoconf` from homebrew, it may conflict with the `autoconf213` package and not be linked. If this has happened, you will want to run `brew link --overwrite  autoconf`

You can build the libraries using the `build.sh` script:

    ./build.sh [/path/to/curl-dist] <plat.arch|plat|'bootstrap'|'clean'>

Run `./build.sh` itself to see details on its options.

You can modify the execution of the scripts by setting various environment variables.  See the script sources for lists of these variables.


### Linking with OpenSSL ###

You can link the output of the libraries with OpenSSL that has been built using the [k9webprotection/build-openssl][build-openssl] project.  To do this, set the `OPENSSL_TARGET` environment variable to point to the directory to the output (or unzipped distribution) of the build-openssl project before running `build.sh`

By default iOS and macOS will link using the `--with-darwinssl` flag.  By default Android will fail to compile unless `OPENSSL_TARGET` is set.

Setting `OPENSSL_TARGET` explicitly to "none" will disable SSL support in cURL.

[build-openssl]: https://github.com/k9webprotection/build-openssl

### TODO: Windows ###

These scripts don't build the windows binaries yet - that still needs to be implemented.  We can look at https://github.com/blackrosezy/build-libcurl-windows/blob/master/build.bat as a starting point for doing that.
