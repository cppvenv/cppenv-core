cppenv-core
===========

**Shared C++ foundation for the cppenv CLI and server.**

cppenv-core is a git submodule consumed by both ``cppenv`` (the CLI) and
``cppenv-server``. It provides the CMake dependency build system, C++ library
code for bundle handling (manifest parsing, SHA-256 verification, path
relocation), and the database abstraction layer.

.. grid:: 2
   :gutter: 3

   .. grid-item-card:: API Reference
      :link: api/index
      :link-type: doc

      C++ classes, functions, and types — generated from ``///`` Doxygen
      comments in the source headers.

   .. grid-item-card:: CMake Modules
      :link: cmake/index
      :link-type: doc

      ``build_dep_cmake``, ``build_dep_autotools``, ``build_openssl``,
      ``build_sqlite3``, ``build_postgres_cli`` — the dependency build
      functions and how to add new ones.

   .. grid-item-card:: Guides
      :link: guides/index
      :link-type: doc

      Getting started, bundle format internals, CMake integration, and
      the activation workflow.

   .. grid-item-card:: Server
      :link: server/index
      :link-type: doc

      Deployment, REST API reference, self-hosting, and storage backend
      configuration.

.. toctree::
   :hidden:
   :maxdepth: 2

   api/index
   cmake/index
   guides/index
   server/index
