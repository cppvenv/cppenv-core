Getting Started
===============

.. note:: This guide is a work in progress.

Prerequisites
-------------

- CMake 3.20 or newer
- A C++17-capable compiler (GCC 11+, Clang 14+, MSVC 2019+)
- Perl (required by OpenSSL's configure script)
- pkg-config

Building documentation requires additional tools:

- Python 3 with ``pip install -r docs/requirements-docs.txt``
- Graphviz (for class and call graphs) — ``brew install graphviz`` on macOS,
  ``apt install graphviz`` on Debian/Ubuntu

Building cppenv-core standalone
--------------------------------

cppenv-core is primarily used as a git submodule inside ``cppenv`` and
``cppenv-server``. It can also be built standalone, which is useful during
development of the shared library itself.

.. code-block:: bash

   git clone https://github.com/cppvenv/cppenv-core
   cd cppenv-core
   cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
   cmake --build build

All third-party dependencies (fmt, spdlog, yaml-cpp, libarchive, OpenSSL,
SQLite) are downloaded and built automatically into ``deps/``.

Skipping the PostgreSQL client
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When building through ``cppenv-server``, the PostgreSQL client (libpq) is
compiled by default. For lightweight dev or CI builds that only need SQLite:

.. code-block:: bash

   cmake -B build -DCPPENV_ENABLE_POSTGRES=OFF

Force-rebuilding dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you need to reset to a clean dependency state:

.. code-block:: bash

   cmake -B build -DBUILD_DEPS=ON
   cmake --build build

This removes ``deps/bin``, ``deps/include``, ``deps/lib``, ``deps/share``
and the FetchContent cache before rebuilding every dependency from source.

Pre-caching tarballs for offline builds
-----------------------------------------

Dependencies are resolved in order: local tarball first, upstream download
as fallback. To pre-cache for offline or faster CI builds:

.. code-block:: bash

   mkdir -p deps/
   wget -O deps/fmt-12.1.0.tar.gz \
       https://github.com/fmtlib/fmt/archive/refs/tags/12.1.0.tar.gz
   # ... (see Dependencies.cmake for the full list)
