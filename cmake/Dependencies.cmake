#[=======================================================================[.rst:
Dependencies
------------

Declares and builds all third-party dependencies for ``cppenv-core``.

This is the only file that needs editing when adding, removing, or
upgrading a dependency. Build machinery lives in ``BuildDepsCore`` and
``BuildDepsSpecial`` — do not duplicate it here.

Tarballs are resolved in this order:

1. Local file at ``${PROJECT_SOURCE_DIR}/deps/<name>-<version>.tar.gz``
2. Downloaded from the upstream URL declared below

Pre-caching tarballs
^^^^^^^^^^^^^^^^^^^^

For offline builds or faster CI, pre-download tarballs into ``deps/``:

.. code-block:: bash

   mkdir -p deps/
   wget -O deps/fmt-10.2.1.tar.gz \
       https://github.com/fmtlib/fmt/archive/refs/tags/10.2.1.tar.gz
   wget -O deps/spdlog-1.12.0.tar.gz \
       https://github.com/gabime/spdlog/archive/refs/tags/v1.12.0.tar.gz
   wget -O deps/json-3.11.2.tar.gz \
       https://github.com/nlohmann/json/archive/refs/tags/v3.11.2.tar.gz
   wget -O deps/cli11-2.6.2.tar.gz \
       https://github.com/CLIUtils/CLI11/archive/refs/tags/v2.6.2.tar.gz
   wget -O deps/yaml-cpp-0.9.0.tar.gz \
       https://github.com/jbeder/yaml-cpp/archive/refs/tags/yaml-cpp-0.9.0.tar.gz
   wget -O deps/libarchive-3.7.2.tar.gz \
       https://github.com/libarchive/libarchive/archive/refs/tags/v3.7.2.tar.gz

CMake options
^^^^^^^^^^^^^

``BUILD_DEPS``
   Set to ``ON`` to force a clean rebuild of all dependencies.
   Removes ``deps/bin``, ``deps/include``, ``deps/lib``, ``deps/share``
   and the FetchContent cache before rebuilding.

   .. code-block:: bash

      cmake -DBUILD_DEPS=ON ..

#]=======================================================================]

include_guard(GLOBAL)

include(BuildDepsCore)

option(BUILD_DEPS "Force rebuild of all dependencies" OFF)

if(BUILD_DEPS)
    message(STATUS "[cppenv] BUILD_DEPS=ON — cleaning deps/ and FetchContent cache")
    file(REMOVE_RECURSE ${PROJECT_SOURCE_DIR}/deps/bin)
    file(REMOVE_RECURSE ${PROJECT_SOURCE_DIR}/deps/include)
    file(REMOVE_RECURSE ${OUTPUT_LIB_DIR})
    file(REMOVE_RECURSE ${PROJECT_SOURCE_DIR}/deps/share)
    file(REMOVE_RECURSE ${PROJECT_SOURCE_DIR}/build/_deps)
endif()

#set(ENV{PKG_CONFIG_PATH} "${OUTPUT_LIB_DIR}/pkgconfig")
#list(APPEND CMAKE_PREFIX_PATH  "${OUTPUT_LIB_DIR}/cmake")
#list(APPEND CMAKE_INCLUDE_PATH "${PROJECT_SOURCE_DIR}/deps/include")

# ---------------------------------------------------------------------------
# fmt — string formatting library, required by spdlog
# ---------------------------------------------------------------------------
build_dep_cmake(
    NAME        fmt
    VERSION     10.2.1
    HASH        SHA256=1250e4cc58bf06ee631567523f48848dc4596133e163f02615c97f78bab6c811
    URL         https://github.com/fmtlib/fmt/archive/refs/tags/10.2.1.tar.gz
    BUILD_OPTS
        -DBUILD_SHARED_LIBS=ON
        -DFMT_TEST=OFF
)

# ---------------------------------------------------------------------------
# spdlog — structured logging with multiple sinks
# Built against the external fmt installed above (SPDLOG_FMT_EXTERNAL=ON)
# ---------------------------------------------------------------------------
build_dep_cmake(
    NAME        spdlog
    VERSION     1.12.0
    HASH        SHA256=4dccf2d10f410c1e2feaff89966bfc49a1abb29ef6f08246335b110e001e09a9
    URL         https://github.com/gabime/spdlog/archive/refs/tags/v1.12.0.tar.gz
    BUILD_OPTS
        -DSPDLOG_BUILD_SHARED=ON
        -DSPDLOG_BUILD_PIC=ON
        -DSPDLOG_BUILD_EXAMPLE=OFF
        -DSPDLOG_FMT_EXTERNAL=ON
)

# ---------------------------------------------------------------------------
# nlohmann/json — JSON parsing and generation for manifests and API responses
# ---------------------------------------------------------------------------
build_dep_cmake(
    NAME        json
    VERSION     3.11.2
    PKG_NAME    nlohmann_json
    HASH        SHA256=d69f9deb6a75e2580465c6c4c5111b89c4dc2fa94e3a85fcd2ffcd9a143d9273
    URL         https://github.com/nlohmann/json/archive/refs/tags/v3.11.2.tar.gz
    BUILD_OPTS
        -DJSON_BuildTests=OFF
        -DJSON_Install=ON
        -DCMAKE_INSTALL_DATADIR=${OUTPUT_LIB_DIR}
)

# ---------------------------------------------------------------------------
# CLI11 — command line argument parsing for the cppenv CLI
# ---------------------------------------------------------------------------
build_dep_cmake(
    NAME        cli11
    VERSION     2.6.2
    PKG_NAME    CLI11
    HASH        SHA256=c6ea6b2e5608b3ea8617999bd5f47420c71b2ebdb8dc4767c1034d1da5785711
    URL         https://github.com/CLIUtils/CLI11/archive/refs/tags/v2.6.2.tar.gz
    BUILD_OPTS
        -DCLI11_SINGLE_FILE=OFF
        -DCLI11_BUILD_TESTS=OFF
        -DCLI11_BUILD_DOCS=OFF
        -DCLI11_BUILD_EXAMPLES=OFF
        -DCLI11_BUILD_EXAMPLES_JSON=OFF
        -DCMAKE_INSTALL_DATADIR=${OUTPUT_LIB_DIR}
)

# ---------------------------------------------------------------------------
# yaml-cpp — YAML parsing for bundle manifests and server configuration
# ---------------------------------------------------------------------------
build_dep_cmake(
    NAME        yaml-cpp
    VERSION     0.9.0
    PKG_NAME    yaml-cpp
    HASH        SHA256=25cb043240f828a8c51beb830569634bc7ac603978e0f69d6b63558dadefd49a
    URL         https://github.com/jbeder/yaml-cpp/archive/refs/tags/yaml-cpp-0.9.0.tar.gz
    BUILD_OPTS
        -DYAML_CPP_BUILD_TESTS=OFF
        -DYAML_CPP_BUILD_TOOLS=OFF
        -DYAML_BUILD_SHARED_LIBS=ON
)

# ---------------------------------------------------------------------------
# libarchive — bundle archive creation (.tar.gz) and extraction
#
# Bundles are .tar.gz only by design (see bundle-format spec). libarchive's
# optional formats and encryption layers are disabled to:
#   - keep the build closed under our pinned deps (no system lzo2/nettle)
#   - avoid pulling openssl in just for libarchive's mtree/xar features
#     when we already use openssl directly for HTTPS
#   - shrink binary size and attack surface
# zlib is left enabled because it's the compressor for .tar.gz.
# ---------------------------------------------------------------------------
build_dep_cmake(
    NAME        libarchive
    VERSION     3.7.2
    HASH        SHA256=63b40acff57467f7d3a64981d4bcff60b52f539fae7688aaaaee27a448b10266
    URL         https://github.com/libarchive/libarchive/archive/refs/tags/v3.7.2.tar.gz
    BUILD_OPTS
        -DBUILD_SHARED_LIBS=ON
        -DENABLE_TEST=OFF
        -DENABLE_TAR=OFF
        -DENABLE_CPIO=OFF
        -DENABLE_CAT=OFF
        -DENABLE_ZLIB=ON
        -DENABLE_OPENSSL=OFF
        -DENABLE_LIBXML2=OFF
        -DENABLE_EXPAT=OFF
        -DENABLE_PCREPOSIX=OFF
        -DENABLE_LibGCC=OFF
        -DENABLE_LZMA=OFF
        -DENABLE_BZip2=OFF
        -DENABLE_LZ4=OFF
        -DENABLE_ZSTD=OFF
)

file(REMOVE_RECURSE "${PROJECT_SOURCE_DIR}/deps/share")
