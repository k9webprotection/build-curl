## OpenSSL/cURL Building ##

This project provides some prebuilt OpenSSL and cURL configuration scripts for easy building on various platforms.  It contains as submodules, the [k9webprotection/openssl][openssl-release] and [k9webprotection/curl][curl-release] git projects.

You can check this directory out in any location on your computer, but the default location that the `build.sh` script looks for is as a parent directory to where you check out the [k9webprotection/openssl][openssl-release] and [k9webprotection/curl][curl-release] git projects.  By default, this project contains submodules of the [k9webprotection/openssl][openssl-release] and [k9webprotection/curl][curl-release] git projects in the correct locations.

[openssl-release]: https://github.com/openssl/openssl
[curl-release]: https://github.com/bagder/curl

### Requirements ###

The following are supported to build the OpenSSL and cURL projects:

 * OS X 10.11 (El Capitan)
 
 * Android NDK r10e
     * You must set the environment variable `ANDROID_NDK_HOME` to point to your NDK installation

 * Build dependencies
     * Autoconf
     * Automake
     * Libtool
     
##### Steps (using Homebrew) #####

1.  Install Xcode from the Mac App Store
    * Run Xcode and accept all first-run prompts

2.  Install Homebrew and taps:
    ```
    # Install Homebrew
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    
    # Services for starting environment watcher
    brew tap homebrew/services
    
    # Extras for environment watching
    brew tap toonetown/extras
    brew install toonetown-extras
    brew services start toonetown-extras

    # Android (and pinned) for for android packages
    brew tap toonetown/android
    brew tap-pin toonetown/android
    ```
    
3.  Install required packages:
    ```
    # Install android NDK (and environment)
    brew install android-ndk
    brew install android-env
    
    # Install build dependencies
    brew install autoconf automake libtool
    ```

4.  Reboot (or open a new terminal window) to get your new environments

##### Shortcut Steps (Bootstrap script) #####

The `build.sh` script accepts a "bootstrap" argument which will run the Homebrew steps above (except for #1 and #4).  It can be run multiple times safely.

    ./build.sh bootstrap


### Build Steps ###

Before building you will want to link and overwrite "autoconf", you do this by running `brew link --overwrite  autoconf`

You can build the libraries using the `build.sh` script:

    ./build.sh [/path/to/openssl-dist] [/path/to/curl-dist] <plat.arch|plat|'bootstrap'|'clean'>

Run `./build.sh` itself to see details on its options.

You can modify the execution of the scripts by setting various environment variables.  See the script sources for lists of these variables.
