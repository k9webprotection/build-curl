#!/bin/bash

cd "$(dirname "${0}")"
BUILD_DIR="$(pwd)"
cd ->/dev/null

# Homebrew bootstrapping information
: ${HB_BOOTSTRAP_GIST_URL:="https://gist.githubusercontent.com/toonetown/48101686e509fda81335/raw"}
HB_BOOTSTRAP="t:*toonetown/android b:android-ndk 
              b:autoconf b:automake b:libtool
              t:toonetown/extras b:toonetown-extras s:toonetown-extras b:android-env"

# Overridable build locations
: ${DEFAULT_CURL_DIST:="${BUILD_DIR}/curl"}
: ${OBJDIR_ROOT:="${BUILD_DIR}/target"}
: ${CONFIGS_DIR:="${BUILD_DIR}/configs"}
: ${MAKE_BUILD_PARALLEL:=$(sysctl -n hw.ncpu)}

# Options for cURL - default ones are very secure (most stuff disabled)
: ${COMMON_CURL_BUILD_OPTIONS:="--disable-dependency-tracking --enable-static --disable-shared"}
: ${CURL_BUILD_OPTIONS:="--disable-ldap         \
                         --disable-ldaps        \
                         --disable-rtsp         \
                         --disable-dict         \
	                     --disable-telnet       \
                         --disable-tftp         \
                         --disable-pop3         \
                         --disable-imap         \
                         --disable-smb          \
                         --disable-smtp         \
                         --disable-gopher       \
                         --disable-sspi         \
                         --disable-ntlm-wb      \
                         --disable-crypto-auth  \
                         --disable-unix-sockets"}

# Include files which are platform-specific
PLATFORM_SPECIFIC_HEADERS=""

BUILD_PLATFORM=""
[ -n "${OPENSSL_TARGET}" ] && {
    [ "${OPENSSL_TARGET}" == "none" ] && {
        BUILD_PLATFORM="nossl-"
    } || {
        [ -d "${OPENSSL_TARGET}" -a -d "${OPENSSL_TARGET}/include/openssl" ] || {
            echo "Invalid OPENSSL_TARGET: '${OPENSSL_TARGET}'"
            exit 1
        }
        BUILD_PLATFORM="openssl_$(cat "${OPENSSL_TARGET}/include/openssl/opensslv.h" | \
                        sed -nE 's/# *define *OPENSSL_VERSION_TEXT *"OpenSSL (([0-9]+\.){2}[0-9a-z]+) .*$/\1-/p')"
    }
}

list_arch() {
    if [ -z "${1}" ]; then
        PFIX="${CONFIGS_DIR}/setup-*"
    else
        PFIX="${CONFIGS_DIR}/setup-${1}"
    fi
    ls -m ${PFIX}.*.sh 2>/dev/null | sed "s#${CONFIGS_DIR}/setup-\(.*\)\.sh#\1#" | \
                         tr -d '\n' | \
                         sed -e 's/ \+/ /g' | sed -e 's/^ *\(.*\) *$/\1/g'
}

list_plats() {
    for i in $(list_arch | sed -e 's/,//g'); do
        echo "${i}" | cut -d'.' -f1
    done | sort -u
}

print_usage() {
    while [ $# -gt 0 ]; do
        echo "${1}" >&2
        shift 1
        if [ $# -eq 0 ]; then echo "" >&2; fi
    done
    echo "Usage: ${0} [/path/to/curl-dist] <plat.arch|plat|'bootstrap'|'clean'>"            >&2
    echo ""                                                                                 >&2
    echo "\"/path/to/curl-dist\" is optional and defaults to:"                              >&2
    echo "    \"${DEFAULT_CURL_DIST}\""                                                     >&2
    echo ""                                                                                 >&2
    echo "Possible plat.arch combinations are:"                                             >&2
    for p in $(list_plats); do
        echo "    ${p}:"                                                                    >&2
        echo "        $(list_arch ${p})"                                                    >&2
        echo ""                                                                             >&2
    done
    echo "If you specify just a plat, then *all* architectures will be built for that"      >&2
    echo "platform, and the resulting libraries will be \"lipo\"-ed together to a single"   >&2
    echo "fat binary (if supported)."                                                       >&2
    echo ""                                                                                 >&2
    echo "When specifying clean, you may optionally include a plat or plat.arch to clean,"  >&2
    echo "i.e. \"${0} clean macosx.i386\" to clean only the i386 architecture on Mac OS X"  >&2
    echo "or \"${0} clean ios\" to clean all ios builds."                                   >&2
    echo ""                                                                                 >&2
    echo "You can copy the windows outputs to non-windows target directory by running"      >&2
    echo "\"${0} copy-windows /path/to/windows/target"                                      >&2
    echo ""                                                                                 >&2
    echo "You can specify to package the release (after it's already been built) by"        >&2
    echo "running \"${0} package /path/to/output"                                           >&2
    echo ""                                                                                 >&2
    return 1
}

do_bootstrap() {
    curl -sSL "${HB_BOOTSTRAP_GIST_URL}" | /bin/bash -s -- ${HB_BOOTSTRAP}
}

do_build_curl() {
    TARGET="${1}"
    OUTPUT_ROOT="${2}"
    BUILD_ROOT="${OUTPUT_ROOT}/build/curl"
    
    [ -n "${PLATFORM_DEFINITION}" ] || {
        echo "PLATFORM_DEFINITION is not set for ${TARGET}"
        return 1
    }
    
    [ "${OPENSSL_TARGET}" == "none" ] && { SSL_FLAG="--without-ssl ${SSL_FLAG}"; }
    [ -d "${OPENSSL_TARGET}" ] && {
        _OSSL_TGT="${OPENSSL_TARGET}/objdir-${TARGET}"
        [ -d "${_OSSL_TGT}" -a -d "${_OSSL_TGT}/lib" -a -d "${_OSSL_TGT}/include" ] || {
            echo "OpenSSL in ${OPENSSL_TARGET} is not built for ${TARGET}"
            exit 1
        }
        SSL_FLAG="--with-ssl ${SSL_FLAG}"
        export CPPFLAGS="${CPPFLAGS} -I${_OSSL_TGT}/include"
        export LDFLAGS="${LDFLAGS} -L${_OSSL_TGT}/lib"
    }
    
    [ -d "${BUILD_ROOT}" -a -f "${BUILD_ROOT}/configure.ac" -a \
                            -f "${BUILD_ROOT}/buildconf" -a \
                            -f "${BUILD_ROOT}/configure" ] || {
        echo "Creating build directory for '${TARGET}'..."
        mkdir -p "$(dirname "${BUILD_ROOT}")" || return $?
        cp -r "${PATH_TO_CURL_DIST}" "${BUILD_ROOT}" || return $?
        cd "${BUILD_ROOT}" || return $?
        ./buildconf || { rm -f "${BUILD_ROOT}/configure"; return 1; }
        cd ->/dev/null
    }

    if [ ! -f "${BUILD_ROOT}/config.status" ]; then
        echo "Configuring cURL build directory for '${TARGET}'..."
        cd "${BUILD_ROOT}" || return $?
        ./configure --host="${HOST}" \
                    ${COMMON_CURL_BUILD_OPTIONS} \
                    ${CURL_BUILD_OPTIONS} \
                    --prefix="${OUTPUT_ROOT}" \
                    ${THREAD_FLAG} ${SSL_FLAG} || {
            rm -f "${BUILD_ROOT}/config.status"
            return 1
        }
        cd ->/dev/null
    fi
    
    cd "${BUILD_ROOT}"
    echo "Building cURL architecture '${TARGET}'..."
    
    # Generate the project and build (and clean up cruft directories)
    make -j ${MAKE_BUILD_PARALLEL} && make install-data install-exec
    ret=$?
    rm -rf "${OUTPUT_ROOT}"/{bin,share,lib/pkgconfig} "${OUTPUT_ROOT}"/lib/*.la >/dev/null 2>&1

    # Update platform-specific headers
    if [ ${ret} -eq 0 ]; then
        _INC_OUT="${OUTPUT_ROOT}/include"
        for h in ${PLATFORM_SPECIFIC_HEADERS}; do
            echo "Updating header '${h}' for ${TARGET}..."
            echo "#if ${PLATFORM_DEFINITION}" > "${_INC_OUT}/${h}.tmp"
            cat "${_INC_OUT}/${h}" >> "${_INC_OUT}/${h}.tmp"
            echo "#endif" >> "${_INC_OUT}/${h}.tmp"
            mv "${_INC_OUT}/${h}.tmp" "${_INC_OUT}/${h}" || { ret=$?; break; }
        done
    fi
    
    cd ->/dev/null
    return ${ret}
}

do_build() {
    TARGET="${1}"; shift
    PLAT="$(echo "${TARGET}" | cut -d'.' -f1)"
    ARCH="$(echo "${TARGET}" | cut -d'.' -f2)"
    CONFIG_SETUP="${CONFIGS_DIR}/setup-${TARGET}.sh"
    
    # Clean here - in case we pass a "clean" command
    if [ "${1}" == "clean" ]; then do_clean ${TARGET}; return $?; fi

    if [ -f "${CONFIG_SETUP}" -a "${PLAT}" != "${ARCH}" ]; then
        # Load configuration files
        [ -f "${CONFIGS_DIR}/setup-${PLAT}.sh" ] && {
            source "${CONFIGS_DIR}/setup-${PLAT}.sh"    || return $?
        }
        source "${CONFIG_SETUP}" && source "${GEN_SCRIPT}" || return $?
        do_build_curl ${TARGET} "${OBJDIR_ROOT}/objdir-${BUILD_PLATFORM}${TARGET}" || return $?
        
        return $?
    elif [ -n "${TARGET}" -a -n "$(list_arch ${TARGET})" ]; then
        PLATFORM="${TARGET}"

        # Load configuration file for the platform
        [ -f "${CONFIGS_DIR}/setup-${PLATFORM}.sh" ] && {
            source "${CONFIGS_DIR}/setup-${PLATFORM}.sh"    || return $?
        }
        
        if [ -n "${LIPO_PATH}" ]; then
            echo "Building fat binary for platform '${PLATFORM}'..."
        else
            echo "Building all architectures for platform '${PLATFORM}'..."
        fi

        COMBINED_ARCHS="$(list_arch ${PLATFORM} | sed -e 's/,//g')"
        for a in ${COMBINED_ARCHS}; do
            do_build ${a} || return $?
        done
        
        # Combine platform-specific headers
        COMBINED_ROOT="${OBJDIR_ROOT}/objdir-${BUILD_PLATFORM}${PLATFORM}"
        mkdir -p "${COMBINED_ROOT}" || return $?
        cp -r ${COMBINED_ROOT}.*/include ${COMBINED_ROOT} || return $?
        _CMB_INC="${COMBINED_ROOT}/include"
        
        for h in ${PLATFORM_SPECIFIC_HEADERS}; do
            echo "Combining header '${h}'..."
            if [ -f "${_CMB_INC}/${h}" ]; then
                rm ${_CMB_INC}/${h} || return $?
                for a in ${COMBINED_ARCHS}; do
                    _A_INC="${OBJDIR_ROOT}/objdir-${BUILD_PLATFORM}${a}/include"
                    cat "${_A_INC}/${h}" >> "${_CMB_INC}/${h}" || return $?
                done
            fi
        done

        if [ -n "${LIPO_PATH}" ]; then
            # Set up variables to get our libraries to lipo
            PLATFORM_DIRS="$(find ${OBJDIR_ROOT} -type d -name "objdir-${BUILD_PLATFORM}${PLATFORM}.*" -depth 1)"
            PLATFORM_LIBS="$(find ${PLATFORM_DIRS} -type d -name "lib" -depth 1)"
            FAT_OUTPUT="${COMBINED_ROOT}/lib"

            mkdir -p "${FAT_OUTPUT}" || return $?
            for l in $(find ${PLATFORM_LIBS} -type f -name '*.a' -exec basename {} \; | sort -u); do
                echo "Running lipo for library '${l}'..."
                ${LIPO_PATH} -create $(find ${PLATFORM_LIBS} -type f -name "${l}") -output "${FAT_OUTPUT}/${l}"
            done
        fi
    else
        print_usage "Missing/invalid target '${TARGET}'"
    fi
    return $?
}

do_clean() {
    if [ -n "${1}" ]; then
        echo "Cleaning up ${1} builds in \"${OBJDIR_ROOT}\"..."
        rm -rf "${OBJDIR_ROOT}/objdir-${1}" "${OBJDIR_ROOT}/objdir-${1}."*
        rm -rf "${OBJDIR_ROOT}/objdir-${BUILD_PLATFORM}${1}" "${OBJDIR_ROOT}/objdir-${BUILD_PLATFORM}${1}."*
    else
        echo "Cleaning up all builds in \"${OBJDIR_ROOT}\"..."
        rm -rf "${OBJDIR_ROOT}/objdir-"*  
    fi
    
    # Remove some leftovers (an empty OBJDIR_ROOT)
    rmdir "${OBJDIR_ROOT}" >/dev/null 2>&1
    return 0
}

do_copy_windows() {
    [ -d "${1}" ] || {
        print_usage "Invalid windows target directory:" "    \"${1}\""
        exit $?
    }
    for WIN_PLAT in $(ls "${1}" | grep 'objdir-windows'); do
        [ -d "${1}/${WIN_PLAT}" -a -d "${1}/${WIN_PLAT}/lib" ] && {
            echo "Copying ${WIN_PLAT}..."
            rm -rf "${OBJDIR_ROOT}/${WIN_PLAT}" || exit $?
            mkdir -p "${OBJDIR_ROOT}/${WIN_PLAT}" || exit $?
            cp -r "${1}/${WIN_PLAT}/lib" "${OBJDIR_ROOT}/${WIN_PLAT}/lib" || exit $?
            cp -r "${1}/${WIN_PLAT}/include" "${OBJDIR_ROOT}/${WIN_PLAT}/include" || exit $?
        } || {
            print_usage "Invalid build target:" "    \"${1}\""
            exit $?
        }
    done
}

do_combine_headers() {
    # Combine the headers into a top-level location
    COMBINED_HEADERS="${OBJDIR_ROOT}/include"
    rm -rf "${COMBINED_HEADERS}"
    mkdir -p "${COMBINED_HEADERS}" || return $?
    COMBINED_PLATS="$(list_plats)"
    for p in ${COMBINED_PLATS}; do
        if [ "${p}" == "android" ]; then
            p="$(find "${OBJDIR_ROOT}" -type d -depth 1 -name "objdir-openssl_*-${p}" -exec basename {} \; | \
                 sort -nr | head -n1 | sed -e 's/^objdir-//g')"
        fi
        _P_INC="${OBJDIR_ROOT}/objdir-${p}/include"
        if [ -d "${_P_INC}" ]; then
            cp -r "${_P_INC}/"* ${COMBINED_HEADERS} || return $?
        else
            echo "Platform ${p} has not been built"
            return 1
        fi
    done
    for h in ${PLATFORM_SPECIFIC_HEADERS}; do
        echo "Combining header '${h}'..."
        if [ -f "${COMBINED_HEADERS}/${h}" ]; then
            rm "${COMBINED_HEADERS}/${h}" || return $?
            for p in ${COMBINED_PLATS}; do
                if [ "${p}" == "android" ]; then
                    p="$(find "${OBJDIR_ROOT}" -type d -depth 1 -name "objdir-openssl_*-${p}" -exec basename {} \; | \
                         sort -nr | head -n1 | sed -e 's/^objdir-//g')"
                fi
                _P_INC="${OBJDIR_ROOT}/objdir-${p}/include"
                if [ -f "${_P_INC}/${h}" ]; then
                    cat "${_P_INC}/${h}" >> "${COMBINED_HEADERS}/${h}" || return $?
                fi
            done
        fi
    done
}

do_package() {
    [ -d "${1}" ] || {
        print_usage "Invalid package output directory:" "    \"${1}\""
        exit $?
    }
    
    # Combine the headers (checks that everything is already built)
    do_combine_headers || return $?
    
    # Build the tarball
    BASE="curl-$(cat "${PATH_TO_CURL_DIST}/include/curl/curlver.h" | \
                 sed -nE 's/^#define LIBCURL_VERSION "([0-9]+\.[0-9]+\.[0-9]+)(-.*)?"/\1/p')"
    cp -r "${OBJDIR_ROOT}" "${BASE}" || exit $?
    rm -rf "${BASE}/"*"/build" "${BASE}/logs" || exit $?
    find "${BASE}" -name .DS_Store -exec rm {} \; || exit $?
    tar -zcvpf "${1}/${BASE}.tar.gz" "${BASE}" || exit $?
    rm -rf "${BASE}"
}


# Calculate the path to the curl-dist repository
if [ -d "${1}" ]; then
    cd "${1}"
    PATH_TO_CURL_DIST="$(pwd)"
    cd ->/dev/null
    shift 1
else
    PATH_TO_CURL_DIST="${DEFAULT_CURL_DIST}"
fi

[ -d "${PATH_TO_CURL_DIST}" -a -f "${PATH_TO_CURL_DIST}/configure.ac" -a -f "${PATH_TO_CURL_DIST}/buildconf" ] || {
    print_usage "Invalid cURL directory:" "    \"${PATH_TO_CURL_DIST}\""
    exit $?
}


# Call bootstrap if that's what we specified
if [ "${1}" == "bootstrap" ]; then
    do_bootstrap ${2}
    exit $?
fi

# Call the appropriate function based on target
TARGET="${1}"; shift
case "${TARGET}" in
    "clean")
        do_clean "$@"
        ;;
    "copy-windows")
        do_copy_windows "$@"
        ;;
    "package")
        do_package "$@"
        ;;
    *)
        do_build ${TARGET} "$@"
        ;;
esac
exit $?
