#[=======================================================================[.rst:
BuildDepsCore
-------------

Reusable functions for building CMake and Autotools dependencies.
Included automatically by ``Dependencies.cmake`` — do not include directly.

All dependencies are installed under ``${PROJECT_SOURCE_DIR}/deps/`` using
``lib/`` (never ``lib64/``) as the library directory.

Dependencies are located in this order:

1. Check if already installed under ``deps/``
2. Check for local tarball at ``deps/<name>-<version>.tar.gz``
3. Download from upstream URL if not found locally

.. note::
   Sets ``CMAKE_INSTALL_LIBDIR`` to ``lib`` globally — overrides any
   distro-specific ``lib64`` defaults from ``GNUInstallDirs``.

#]=======================================================================]

include_guard(GLOBAL)

cmake_policy(SET CMP0169 OLD)

include(FetchContent)
find_package(PkgConfig REQUIRED)

set(CMAKE_INSTALL_LIBDIR "lib" CACHE STRING "Library install directory" FORCE)
set(OUTPUT_LIB_DIR "${PROJECT_SOURCE_DIR}/deps/lib")

# PKG_CONFIG_LIBDIR replaces the default search path entirely so pkg-config
# cannot find system or Homebrew packages and mistake them for our pinned
# versions. PKG_CONFIG_PATH would only prepend to the defaults, leaving
# system paths reachable — causing false "already installed" hits on deps
# like openssl or libarchive that exist on the host machine.
set(ENV{PKG_CONFIG_LIBDIR} "${OUTPUT_LIB_DIR}/pkgconfig")
list(PREPEND CMAKE_PREFIX_PATH  "${OUTPUT_LIB_DIR}/cmake")
list(PREPEND CMAKE_INCLUDE_PATH "${PROJECT_SOURCE_DIR}/deps/include")

include(ProcessorCount)
ProcessorCount(NCPUS)
if(NCPUS EQUAL 0)
    set(NCPUS 4)
endif()

#[=======================================================================[.rst:
.. cmake:command:: _cppenv_run_cmd

   Internal helper.

   ``execute_process`` swallows non-zero exit codes by default, so a failed
   configure or ``make`` would happily produce a broken install and surface
   only as a link error later. This wrapper aborts the configure step at
   the actual point of failure with a labelled error message.

   .. code-block:: cmake

      _cppenv_run_cmd(<step_name> <command> [<args>...])

#]=======================================================================]
function(_cppenv_run_cmd STEP_NAME)
    cmake_parse_arguments(_CMD "" "WORKING_DIRECTORY" "" ${ARGN})

    if(_CMD_WORKING_DIRECTORY)
        set(_WORKING_DIR WORKING_DIRECTORY ${_CMD_WORKING_DIRECTORY})
    else()
        set(_WORKING_DIR "")
    endif()

    execute_process(
        COMMAND         ${_CMD_UNPARSED_ARGUMENTS}
        ${_WORKING_DIR}
        RESULT_VARIABLE _RESULT
    )
    if(NOT _RESULT EQUAL "0")
        message(FATAL_ERROR "[cppenv] ${STEP_NAME} failed with exit code ${_RESULT}")
    else()
        message(STATUS "[cppenv] ${STEP_NAME} succeeded")
    endif()
endfunction()

#[=======================================================================[.rst:
.. cmake:command:: build_dep_cmake

   Builds and installs a CMake-based dependency into ``deps/``.
   Skips silently if the dependency is already installed.

   .. code-block:: cmake

      build_dep_cmake(
          NAME        <name>
          VERSION     <version>
          HASH        <SHA256=hex>
          URL         <url>
          [PKG_NAME   <pkg-config-name>]
          [BUILD_OPTS <cmake-arg>...]
          [USE_PKGCONFIG]
      )

   ``NAME``
      Dependency name. Used for FetchContent, find_package, and the
      local tarball filename (``deps/<name>-<version>.tar.gz``).

   ``VERSION``
      Version string. Used for pkg-config version checks and tarball lookup.

   ``HASH``
      SHA256 checksum in the form ``SHA256=<hex>``. Verified against both
      local tarballs and downloaded archives.

   ``URL``
      Upstream download URL. Used only when no local tarball is found.

   ``PKG_NAME``
      pkg-config or ``find_package`` module name when it differs from
      ``NAME``. Defaults to ``NAME`` if not specified.

   ``BUILD_OPTS``
      Additional CMake cache arguments passed to the configure step,
      e.g. ``-DBUILD_SHARED_LIBS=ON``.

   ``USE_PKGCONFIG``
      When set, uses ``pkg_search_module`` for both the pre-build check
      and post-install verification instead of ``find_package``.

   Example
   ^^^^^^^

   .. code-block:: cmake

      build_dep_cmake(
          NAME        fmt
          VERSION     10.1.1
          HASH        SHA256=78b8c0a72b1c35e4443a7e308df52498252d1cefc2b08c9a97bc9ee6cfe61f8b
          URL         https://github.com/fmtlib/fmt/archive/refs/tags/10.1.1.tar.gz
          BUILD_OPTS
              -DBUILD_SHARED_LIBS=ON
              -DFMT_TEST=OFF
      )

#]=======================================================================]
function(build_dep_cmake)
    cmake_parse_arguments(
        DEP
        "USE_PKGCONFIG"
        "NAME;PKG_NAME;VERSION;HASH;URL"
        "BUILD_OPTS"
        ${ARGN}
    )

    if(NOT DEP_NAME OR NOT DEP_VERSION OR NOT DEP_HASH OR NOT DEP_URL)
        message(FATAL_ERROR "[cppenv] build_dep_cmake: NAME, VERSION, HASH and URL are required")
    endif()

    if(NOT DEP_PKG_NAME)
        set(DEP_PKG_NAME ${DEP_NAME})
    endif()

    if(DEP_USE_PKGCONFIG)
        pkg_search_module(${DEP_PKG_NAME} QUIET IMPORTED_TARGET ${DEP_NAME}=${DEP_VERSION})
    else()
        find_package(${DEP_PKG_NAME} ${DEP_VERSION} EXACT QUIET
            PATHS "${OUTPUT_LIB_DIR}/cmake"
            NO_DEFAULT_PATH
        )
    endif()

    if(${DEP_PKG_NAME}_FOUND)
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: already installed, skipping")
        return()
    endif()

    message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: building...")

    # resolve source — local tarball first, download fallback
    set(LOCAL_TARBALL "${PROJECT_SOURCE_DIR}/deps/${DEP_NAME}-${DEP_VERSION}.tar.gz")
    if(EXISTS "${LOCAL_TARBALL}")
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: using local tarball")
        set(_FETCH_URL "file://${LOCAL_TARBALL}")
    else()
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: downloading...")
        set(_FETCH_URL "${DEP_URL}")
    endif()

    FetchContent_Declare(${DEP_NAME}
        URL      ${_FETCH_URL}
        URL_HASH ${DEP_HASH}
        DOWNLOAD_EXTRACT_TIMESTAMP ON
    )

    FetchContent_GetProperties(${DEP_NAME})
    if(NOT ${DEP_NAME}_POPULATED)
        FetchContent_Populate(${DEP_NAME})
    endif()

    _cppenv_run_cmd("${DEP_NAME} configure"
        ${CMAKE_COMMAND}
        ${DEP_BUILD_OPTS}
        -DCMAKE_INSTALL_PREFIX=${PROJECT_SOURCE_DIR}/deps
        -DCMAKE_INSTALL_LIBDIR=lib
        -DCMAKE_PREFIX_PATH=${OUTPUT_LIB_DIR}/cmake
#        -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
        -DCMAKE_BUILD_TYPE=Release
        ${${DEP_NAME}_SOURCE_DIR}
        WORKING_DIRECTORY ${${DEP_NAME}_BINARY_DIR}
    )

    _cppenv_run_cmd("${DEP_NAME} build+install"
        ${CMAKE_COMMAND}
        --build ${${DEP_NAME}_BINARY_DIR}
        --target install
        --parallel ${NCPUS}
    )

    if(DEP_USE_PKGCONFIG)
        pkg_search_module(${DEP_PKG_NAME} IMPORTED_TARGET ${DEP_NAME}=${DEP_VERSION})
    else()
        find_package(${DEP_PKG_NAME} ${DEP_VERSION} EXACT
            PATHS "${OUTPUT_LIB_DIR}/cmake"
            NO_DEFAULT_PATH
        )
    endif()

    message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: done")
endfunction()

#[=======================================================================[.rst:
.. cmake:command:: build_dep_autotools

   Builds and installs an Autotools-based dependency into ``deps/``
   using the standard ``./configure && make install`` workflow.
   Skips silently if the dependency is already installed.

   .. code-block:: cmake

      build_dep_autotools(
          NAME        <name>
          VERSION     <version>
          HASH        <SHA256=hex>
          URL         <url>
          [PKG_NAME   <pkg-config-name>]
          [BUILD_OPTS <configure-arg>...]
      )

   ``NAME``
      Dependency name. Used for FetchContent and the local tarball
      filename (``deps/<name>-<version>.tar.gz``).

   ``VERSION``
      Version string. Used for pkg-config version checks and tarball lookup.

   ``HASH``
      SHA256 checksum in the form ``SHA256=<hex>``.

   ``URL``
      Upstream download URL used as fallback.

   ``PKG_NAME``
      pkg-config name when it differs from ``NAME``.
      Defaults to ``NAME`` if not specified.

   ``BUILD_OPTS``
      Additional arguments passed to the ``./configure`` script,
      e.g. ``--enable-shared --without-perl``.

   .. note::
      ``CC`` and ``CXX`` environment variables are set to
      ``CMAKE_C_COMPILER`` and ``CMAKE_CXX_COMPILER`` for the configure
      step and unset immediately after.

   Example
   ^^^^^^^

   .. code-block:: cmake

      build_dep_autotools(
          NAME        libarchive
          VERSION     3.7.2
          HASH        SHA256=df404eb7...
          URL         https://github.com/libarchive/libarchive/archive/refs/tags/v3.7.2.tar.gz
          BUILD_OPTS
              --libdir=${OUTPUT_LIB_DIR}
              --with-zlib
      )

#]=======================================================================]
function(build_dep_autotools)
    cmake_parse_arguments(
        DEP
        ""
        "NAME;PKG_NAME;VERSION;HASH;URL"
        "BUILD_OPTS"
        ${ARGN}
    )

    if(NOT DEP_NAME OR NOT DEP_VERSION OR NOT DEP_HASH OR NOT DEP_URL)
        message(FATAL_ERROR "[cppenv] build_dep_autotools: NAME, VERSION, HASH and URL are required")
    endif()

    if(NOT DEP_PKG_NAME)
        set(DEP_PKG_NAME ${DEP_NAME})
    endif()

    pkg_search_module(${DEP_PKG_NAME} QUIET IMPORTED_TARGET ${DEP_PKG_NAME}=${DEP_VERSION})
    if(${DEP_PKG_NAME}_FOUND)
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: already installed, skipping")
        return()
    endif()

    message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: building...")

    set(LOCAL_TARBALL "${PROJECT_SOURCE_DIR}/deps/${DEP_NAME}-${DEP_VERSION}.tar.gz")
    if(EXISTS "${LOCAL_TARBALL}")
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: using local tarball")
        set(_FETCH_URL "file://${LOCAL_TARBALL}")
    else()
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: downloading...")
        set(_FETCH_URL "${DEP_URL}")
    endif()

    FetchContent_Declare(${DEP_NAME}
        URL      ${_FETCH_URL}
        URL_HASH ${DEP_HASH}
        DOWNLOAD_EXTRACT_TIMESTAMP ON
    )

    FetchContent_GetProperties(${DEP_NAME})
    if(NOT ${DEP_NAME}_POPULATED)
        FetchContent_Populate(${DEP_NAME})
    endif()

    set(ENV{CC}  ${CMAKE_C_COMPILER})
    set(ENV{CXX} ${CMAKE_CXX_COMPILER})

    execute_process(
        COMMAND         ${${DEP_NAME}_SOURCE_DIR}/configure
        --prefix=${PROJECT_SOURCE_DIR}/deps
        ${DEP_BUILD_OPTS}
        --libdir=${OUTPUT_LIB_DIR}
        WORKING_DIRECTORY ${${DEP_NAME}_SOURCE_DIR}
        RESULT_VARIABLE _RESULT
    )
    if(NOT _RESULT EQUAL "0")
        message(FATAL_ERROR "[cppenv] ${DEP_NAME} configure failed with exit code ${_RESULT}")
    endif()

    unset(ENV{CC})
    unset(ENV{CXX})

    execute_process(
        COMMAND         make -j${NCPUS} install
        WORKING_DIRECTORY ${${DEP_NAME}_SOURCE_DIR}
        RESULT_VARIABLE _RESULT
    )
    if(NOT _RESULT EQUAL "0")
        message(FATAL_ERROR "[cppenv] ${DEP_NAME} build+install failed with exit code ${_RESULT}")
    endif()

    pkg_search_module(${DEP_PKG_NAME} IMPORTED_TARGET ${DEP_PKG_NAME}=${DEP_VERSION})

    message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: done")
endfunction()

#[=======================================================================[.rst:
.. cmake:command:: build_openssl

   Builds and installs OpenSSL using its own ``perl Configure`` build system.
   Skips silently if the exact version is already installed.

   OpenSSL ships neither a standard ``./configure`` (Autotools) nor a
   ``CMakeLists.txt``, so ``build_dep_autotools`` and ``build_dep_cmake``
   cannot handle it. The custom build here mirrors the Autotools pattern
   but invokes ``perl Configure`` and limits installation to ``install_sw``
   (libraries, headers, and binaries only — no HTML documentation).

   .. code-block:: cmake

      build_openssl(
          NAME        <name>
          VERSION     <version>
          HASH        <SHA256=hex>
          URL         <url>
          [PKG_NAME   <pkg-config-name>]
          [BUILD_OPTS <Configure-arg>...]
      )

   ``NAME``
      Dependency name — typically ``openssl``.

   ``VERSION``
      OpenSSL version string, e.g. ``3.6.2``.

   ``HASH``
      SHA256 checksum in the form ``SHA256=<hex>``.

   ``URL``
      Upstream OpenSSL source tarball URL.

   ``PKG_NAME``
      pkg-config name. Defaults to ``NAME`` if not specified.

   ``BUILD_OPTS``
      Extra arguments forwarded to ``perl Configure``,
      e.g. ``shared no-tests``.

   Example
   ^^^^^^^

   .. code-block:: cmake

      build_openssl(
          NAME        openssl
          VERSION     3.6.2
          PKG_NAME    openssl
          HASH        SHA256=aaf51a1fe...
          URL         https://github.com/openssl/openssl/releases/download/openssl-3.6.2/openssl-3.6.2.tar.gz
          BUILD_OPTS
              shared
              no-tests
      )

#]=======================================================================]
function(build_openssl)
    cmake_parse_arguments(
        DEP
        ""
        "NAME;PKG_NAME;VERSION;HASH;URL"
        "BUILD_OPTS"
        ${ARGN}
    )

    if(NOT DEP_NAME OR NOT DEP_VERSION OR NOT DEP_HASH OR NOT DEP_URL)
        message(FATAL_ERROR "[cppenv] build_openssl: NAME, VERSION, HASH and URL are required")
    endif()

    if(NOT DEP_PKG_NAME)
        set(DEP_PKG_NAME ${DEP_NAME})
    endif()

    pkg_search_module(${DEP_PKG_NAME} QUIET IMPORTED_TARGET ${DEP_PKG_NAME}=${DEP_VERSION})
    if(${DEP_PKG_NAME}_FOUND)
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: already installed, skipping")
        return()
    endif()

    message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: building...")

    set(LOCAL_TARBALL "${PROJECT_SOURCE_DIR}/deps/${DEP_NAME}-${DEP_VERSION}.tar.gz")
    if(EXISTS "${LOCAL_TARBALL}")
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: using local tarball")
        set(_FETCH_URL "file://${LOCAL_TARBALL}")
    else()
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: downloading...")
        set(_FETCH_URL "${DEP_URL}")
    endif()

    FetchContent_Declare(${DEP_NAME}
        URL      ${_FETCH_URL}
        URL_HASH ${DEP_HASH}
        DOWNLOAD_EXTRACT_TIMESTAMP ON
    )

    FetchContent_GetProperties(${DEP_NAME})
    if(NOT ${DEP_NAME}_POPULATED)
        FetchContent_Populate(${DEP_NAME})
    endif()

    set(ENV{CC}  ${CMAKE_C_COMPILER})
    set(ENV{CXX} ${CMAKE_CXX_COMPILER})

    _cppenv_run_cmd("${DEP_NAME} configure"
        perl ${${DEP_NAME}_SOURCE_DIR}/Configure
        --prefix=${PROJECT_SOURCE_DIR}/deps
        --openssldir=${PROJECT_SOURCE_DIR}/deps/ssl
        --libdir=lib
        ${DEP_BUILD_OPTS}
        WORKING_DIRECTORY ${${DEP_NAME}_SOURCE_DIR}
    )

    unset(ENV{CC})
    unset(ENV{CXX})

    # -j is intentionally absent to prevent parallel jobs race issue
    _cppenv_run_cmd("${DEP_NAME} build+install"
        make install_sw
        WORKING_DIRECTORY ${${DEP_NAME}_SOURCE_DIR}
    )

    pkg_search_module(${DEP_PKG_NAME} IMPORTED_TARGET ${DEP_PKG_NAME}=${DEP_VERSION})

    message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: done")
endfunction()
