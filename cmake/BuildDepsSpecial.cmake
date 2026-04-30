#[=======================================================================[.rst:
BuildDepsSpecial
----------------

Special-case dependency builders for packages that do not fit the
standard CMake or Autotools patterns in ``BuildDepsCore``.

.. note::
   Functions in this module are candidates for the future cppenv recipe
   system (``cppenv-bundles``). They serve as reference implementations
   of the selective-install pattern that recipes will generalise.

#]=======================================================================]

include_guard(GLOBAL)

include(BuildDepsCore)

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

    _cppenv_fetch_and_populate(${DEP_NAME} ${DEP_VERSION} ${DEP_HASH} ${DEP_URL})

    set(DEP_SRC_DIR ${${DEP_NAME}_SOURCE_DIR})

    set(ENV{CC}  ${CMAKE_C_COMPILER})
    set(ENV{CXX} ${CMAKE_CXX_COMPILER})

    # PostgreSQL's configure script wires up the entire source tree, including
    # server, contrib modules, and pgAdmin. Configuring is cheap; the cost we
    # avoid is below in the install step.
    _cppenv_run_cmd("${DEP_NAME} configure"
        ${DEP_SRC_DIR}/configure
        --prefix=${PROJECT_SOURCE_DIR}/deps
        ${DEP_BUILD_OPTS}
        --libdir=${OUTPUT_LIB_DIR}
        WORKING_DIRECTORY ${DEP_SRC_DIR}
    )

    unset(ENV{CC})
    unset(ENV{CXX})

#    include(ProcessorCount)
#    ProcessorCount(NCPUS)
#    if(NCPUS EQUAL 0)
#        set(NCPUS 4)
#    endif()

    # libpqxx (used by cppenv-server) only links against libpq and its public
    # headers. A full `make install` would also build and copy the postgres
    # backend, contrib extensions, and locale data — well over 100MB of
    # binaries we never use, plus several minutes of extra build time.
    # These three subtrees are the minimum surface needed by the client.
    _cppenv_run_cmd("${DEP_NAME} install bin"
        make -j${NCPUS} -C src/bin install
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
    # Setting them explicitly guarantees the locally built libpq is picked up
    # even on machines that have a system PostgreSQL installed.
    set(PostgreSQL_INCLUDE_DIR
        "${PROJECT_SOURCE_DIR}/deps/include"
        CACHE PATH "PostgreSQL include directory" FORCE)
    set(PostgreSQL_LIBRARY_DIR
        "${OUTPUT_LIB_DIR}"
        CACHE PATH "PostgreSQL lib directory" FORCE)

    pkg_search_module(${DEP_PKG_NAME} IMPORTED_TARGET ${DEP_PKG_NAME}=${DEP_VERSION})

    message(STATUS "[cppenv] ${DEP_NAME}-${DEP_VERSION}: done")
endfunction()
