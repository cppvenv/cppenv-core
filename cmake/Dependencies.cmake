#[=======================================================================[.rst:
Dependencies
------------

Declares and builds all third-party dependencies for ``cppenv-core``.

This is the only file that needs editing when adding, removing, or
upgrading a dependency. Build machinery lives in ``BuildDepsCore`` and
``BuildDepsDatabase`` — do not duplicate it here.

Tarballs are resolved in this order:

1. Local file at ``${PROJECT_SOURCE_DIR}/deps/<name>-<version>.tar.gz``
2. Downloaded from the upstream URL declared below

Pre-caching tarballs
^^^^^^^^^^^^^^^^^^^^

For offline builds or faster CI, pre-download tarballs into ``deps/``:

.. code-block:: bash

   mkdir -p deps/
   wget -O deps/fmt-12.1.0.tar.gz \
       https://github.com/fmtlib/fmt/archive/refs/tags/12.1.0.tar.gz
   wget -O deps/spdlog-1.17.0.tar.gz \
       https://github.com/gabime/spdlog/archive/refs/tags/v1.17.0.tar.gz
   wget -O deps/json-3.12.0.tar.gz \
       https://github.com/nlohmann/json/archive/refs/tags/v3.12.0.tar.gz
   wget -O deps/cli11-2.6.2.tar.gz \
       https://github.com/CLIUtils/CLI11/archive/refs/tags/v2.6.2.tar.gz
   wget -O deps/yaml-cpp-0.9.0.tar.gz \
       https://github.com/jbeder/yaml-cpp/archive/refs/tags/yaml-cpp-0.9.0.tar.gz
   wget -O deps/libarchive-3.8.7.tar.gz \
       https://github.com/libarchive/libarchive/archive/refs/tags/v3.8.7.tar.gz

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

include(${CMAKE_CURRENT_LIST_DIR}/BuildDepsDatabase.cmake)

option(BUILD_DEPS "Force rebuild of all dependencies" OFF)

if(BUILD_DEPS)
    message(STATUS "[cppenv] BUILD_DEPS=ON — cleaning deps/ and FetchContent cache")
    file(REMOVE_RECURSE ${PROJECT_SOURCE_DIR}/deps/bin)
    file(REMOVE_RECURSE ${PROJECT_SOURCE_DIR}/deps/include)
    file(REMOVE_RECURSE ${OUTPUT_LIB_DIR})
    file(REMOVE_RECURSE ${PROJECT_SOURCE_DIR}/deps/share)
    file(REMOVE_RECURSE ${PROJECT_SOURCE_DIR}/build/_deps)
endif()

# ---------------------------------------------------------------------------
# fmt — string formatting library, required by spdlog
# ---------------------------------------------------------------------------
build_dep_cmake(
    NAME        fmt
    VERSION     12.1.0
    HASH        SHA256=ea7de4299689e12b6dddd392f9896f08fb0777ac7168897a244a6d6085043fea
    URL         https://github.com/fmtlib/fmt/archive/refs/tags/12.1.0.tar.gz
    BUILD_OPTS
        -DBUILD_SHARED_LIBS=ON
        -DFMT_TEST=OFF
)

# ---------------------------------------------------------------------------
# spdlog — structured logging with multiple sinks
# Built against the external fmt installed above (SPDLOG_FMT_EXTERNAL=ON)
# spdlog 1.17.0 bundles fmt 12.1.0 internally — using SPDLOG_FMT_EXTERNAL
# ensures it links against our pinned fmt instead of its own copy.
# ---------------------------------------------------------------------------
build_dep_cmake(
    NAME        spdlog
    VERSION     1.17.0
    HASH        SHA256=d8862955c6d74e5846b3f580b1605d2428b11d97a410d86e2fb13e857cd3a744
    URL         https://github.com/gabime/spdlog/archive/refs/tags/v1.17.0.tar.gz
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
    VERSION     3.12.0
    PKG_NAME    nlohmann_json
    HASH        SHA256=4b92eb0c06d10683f7447ce9406cb97cd4b453be18d7279320f7b2f025c10187
    URL         https://github.com/nlohmann/json/archive/refs/tags/v3.12.0.tar.gz
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
# openssl — TLS for HTTPS bundle downloads, server connections, and
# bundle signature verification. libarchive and libpq also link against it,
# so it must be declared before both.
# ---------------------------------------------------------------------------
build_openssl(
    NAME        openssl
    VERSION     3.6.2
    PKG_NAME    openssl
    HASH        SHA256=aaf51a1fe064384f811daeaeb4ec4dce7340ec8bd893027eee676af31e83a04f
    URL         https://github.com/openssl/openssl/releases/download/openssl-3.6.2/openssl-3.6.2.tar.gz
    BUILD_OPTS
        shared
        no-tests
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
    VERSION     3.8.7
    HASH        SHA256=bc942030fe7cb30e04eed31bd5f63c38cdfd712315b303e91b64e58f05db2346
    URL         https://github.com/libarchive/libarchive/archive/refs/tags/v3.8.7.tar.gz
    USE_PKGCONFIG
    BUILD_OPTS
        -DBUILD_SHARED_LIBS=ON
        -DENABLE_TEST=OFF
        -DENABLE_TAR=OFF
        -DENABLE_CPIO=OFF
        -DENABLE_CAT=OFF
        -DENABLE_ZLIB=ON
        -DENABLE_OPENSSL=ON
        -DENABLE_LIBXML2=OFF
        -DENABLE_EXPAT=OFF
        -DENABLE_PCREPOSIX=OFF
        -DENABLE_LibGCC=OFF
        -DENABLE_LZMA=OFF
        -DENABLE_BZip2=OFF
        -DENABLE_LZ4=OFF
        -DENABLE_ZSTD=OFF
)

# ---------------------------------------------------------------------------
# sqlite3 — embedded relational store for user-level (~/.cppenv/cppenv.db)
# and project-level (cppvenv/.cppenv.db) databases, accessed via sqlite_orm.
# FTS5 is enabled for full-text search.
# ---------------------------------------------------------------------------
build_sqlite3(
    NAME        sqlite3
    VERSION     3.53.0
    PKG_NAME    sqlite3
    HASH        SHA256=851e9b38192fe2ceaa65e0baa665e7fa06230c3d9bd1a6a9662d02380d73365a
    URL         https://www.sqlite.org/2026/sqlite-autoconf-3530000.tar.gz
)

file(REMOVE_RECURSE "${PROJECT_SOURCE_DIR}/deps/share")
