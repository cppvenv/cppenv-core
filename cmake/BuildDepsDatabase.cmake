#[=======================================================================[.rst:
BuildDepsDatabase
-----------------

Database backend dependency builders for ``cppenv-core``.

Each function encapsulates the build options and install quirks for one
backend. Adding a new backend (MySQL, MariaDB, etc.) means adding one
function here and one call in the appropriate ``Dependencies.cmake`` —
nothing else changes.

.. note::
   Functions in this module are candidates for the future cppenv recipe
   system (``cppenv-bundles``). They serve as reference implementations
   of the backend-specific build pattern that recipes will generalise.

#]=======================================================================]

include_guard(GLOBAL)

include(${CMAKE_CURRENT_LIST_DIR}/BuildDepsCore.cmake)

#[=======================================================================[.rst:
.. cmake:command:: build_postgres_cli

   Builds only the PostgreSQL client components required by ``libpqxx``.
   Unlike a full PostgreSQL build, only three subtrees are installed:

   - ``src/bin`` — client tools (``psql``, ``pg_dump``, etc.)
   - ``src/include`` — public headers
   - ``src/interfaces`` — ``libpq`` client library

   The full server, contrib modules, and documentation are skipped,
   keeping the install footprint minimal.

   .. code-block:: cmake

      build_postgres_cli(
          NAME        <name>
          VERSION     <version>
          HASH        <SHA256=hex>
          URL         <url>
          [PKG_NAME   <pkg-config-name>]
          [BUILD_OPTS <configure-arg>...]
      )

   ``NAME``
      Dependency name — typically ``libpq``.

   ``VERSION``
      PostgreSQL version string, e.g. ``15.4``.

   ``HASH``
      SHA256 checksum in the form ``SHA256=<hex>``.

   ``URL``
      Upstream PostgreSQL source tarball URL.

   ``PKG_NAME``
      pkg-config name — typically ``PostgreSQL``.
      Defaults to ``NAME`` if not specified.

   ``BUILD_OPTS``
      Arguments passed to the ``./configure`` script,
      e.g. ``--with-ssl=openssl --with-zlib``.

   .. note::
      Sets ``PostgreSQL_INCLUDE_DIR`` and ``PostgreSQL_LIBRARY_DIR``
      cache variables so that a subsequent ``find_package(PostgreSQL)``
      or ``libpqxx`` build locates the locally built client library.

   Example
   ^^^^^^^

   .. code-block:: cmake

      build_postgres_cli(
          NAME        libpq
          VERSION     15.4
          PKG_NAME    PostgreSQL
          HASH        SHA256=9f548283...
          URL         https://ftp.postgresql.org/pub/source/v15.4/postgresql-15.4.tar.gz
          BUILD_OPTS
              --with-ssl=openssl
              --with-zlib
      )

#]=======================================================================]
function(build_postgres_cli)
    cmake_parse_arguments(
        DEP
        ""
        "NAME;PKG_NAME;VERSION;HASH;URL"
        "BUILD_OPTS"
        ${ARGN}
    )

    if(NOT DEP_NAME OR NOT DEP_VERSION OR NOT DEP_HASH OR NOT DEP_URL)
        message(FATAL_ERROR "[cppenv] build_postgres_cli: NAME, VERSION, HASH and URL are required")
    endif()

    if(NOT DEP_PKG_NAME)
        set(DEP_PKG_NAME ${DEP_NAME})
    endif()

    pkg_search_module(${DEP_PKG_NAME} QUIET IMPORTED_TARGET ${DEP_PKG_NAME}=${DEP_VERSION})
    if(${DEP_PKG_NAME}_FOUND)
        message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: already installed, skipping")
        return()
    endif()

    message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: building PostgreSQL client...")

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

    set(DEP_SRC_DIR ${${DEP_NAME}_SOURCE_DIR})

    set(ENV{CC}       ${CMAKE_C_COMPILER})
    set(ENV{CXX}      ${CMAKE_CXX_COMPILER})
    set(ENV{CPPFLAGS} "-I${PROJECT_SOURCE_DIR}/deps/include")
    set(ENV{LDFLAGS}  "-L${OUTPUT_LIB_DIR}")

    _cppenv_run_cmd("${DEP_NAME} configure"
        ${DEP_SRC_DIR}/configure
        --prefix=${PROJECT_SOURCE_DIR}/deps
        ${DEP_BUILD_OPTS}
        --libdir=${OUTPUT_LIB_DIR}
        WORKING_DIRECTORY ${DEP_SRC_DIR}
    )

    unset(ENV{CC})
    unset(ENV{CXX})
    unset(ENV{CPPFLAGS})
    unset(ENV{LDFLAGS})

    # -j is intentionally absent: parallel jobs race
    _cppenv_run_cmd("${DEP_NAME} install bin"
        make -C src/bin install
        WORKING_DIRECTORY ${DEP_SRC_DIR}
    )

    _cppenv_run_cmd("${DEP_NAME} install include"
        make -j${NCPUS} -C src/include install
        WORKING_DIRECTORY ${DEP_SRC_DIR}
    )

    _cppenv_run_cmd("${DEP_NAME} install interfaces"
        make -j${NCPUS} -C src/interfaces install
        WORKING_DIRECTORY ${DEP_SRC_DIR}
    )

    # FindPostgreSQL.cmake (used transitively by libpqxx's build) prioritises
    # these cache variables over pkg-config and the standard search paths.
    set(PostgreSQL_INCLUDE_DIR
        "${PROJECT_SOURCE_DIR}/deps/include"
        CACHE PATH "PostgreSQL include directory" FORCE)
    set(PostgreSQL_LIBRARY_DIR
        "${OUTPUT_LIB_DIR}"
        CACHE PATH "PostgreSQL lib directory" FORCE)

    pkg_search_module(${DEP_PKG_NAME} IMPORTED_TARGET ${DEP_PKG_NAME}=${DEP_VERSION})

    message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: done")
endfunction()

#[=======================================================================[.rst:
.. cmake:command:: build_sqlite3

   Builds and installs SQLite3 from the official amalgamation source.
   Wraps ``build_dep_autotools`` with the subset of configure flags
   needed by ``sqlite_orm`` and the cppenv client databases.

   .. code-block:: cmake

      build_sqlite3(
          NAME        <name>
          VERSION     <version>
          HASH        <SHA256=hex>
          URL         <url>
          [PKG_NAME   <pkg-config-name>]
          [BUILD_OPTS <configure-arg>...]
      )

   ``NAME``
      Dependency name — typically ``sqlite3``.

   ``VERSION``
      SQLite version string, e.g. ``3.45.3``.

   ``HASH``
      SHA256 checksum in the form ``SHA256=<hex>``.

   ``URL``
      Upstream SQLite amalgamation tarball URL
      (``sqlite-autoconf-<version>.tar.gz``).

   ``PKG_NAME``
      pkg-config name. Defaults to ``NAME`` if not specified.

   ``BUILD_OPTS``
      Extra arguments appended to the ``./configure`` invocation.

   .. note::
      FTS5 is enabled because ``sqlite_orm`` relies on it for full-text
      search. TCL support is auto-detected by the configure script and
      silently skipped if TCL headers are absent — no flag needed.

   Example
   ^^^^^^^

   .. code-block:: cmake

      build_sqlite3(
          NAME        sqlite3
          VERSION     3.45.3
          PKG_NAME    sqlite3
          HASH        SHA256=b2bed4...
          URL         https://www.sqlite.org/2024/sqlite-autoconf-3450300.tar.gz
      )

#]=======================================================================]
function(build_sqlite3)
    cmake_parse_arguments(
        DEP
        ""
        "NAME;PKG_NAME;VERSION;HASH;URL"
        "BUILD_OPTS"
        ${ARGN}
    )

    if(NOT DEP_NAME OR NOT DEP_VERSION OR NOT DEP_HASH OR NOT DEP_URL)
        message(FATAL_ERROR "[cppenv] build_sqlite3: NAME, VERSION, HASH and URL are required")
    endif()

    if(NOT DEP_PKG_NAME)
        set(DEP_PKG_NAME ${DEP_NAME})
    endif()

    build_dep_autotools(
        NAME     ${DEP_NAME}
        VERSION  ${DEP_VERSION}
        PKG_NAME ${DEP_PKG_NAME}
        HASH     ${DEP_HASH}
        URL      ${DEP_URL}
        BUILD_OPTS
            --enable-shared
            --enable-fts5
            ${DEP_BUILD_OPTS}
    )
endfunction()
