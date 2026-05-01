Bundle Format
=============

.. note:: This reference is a work in progress.

A cppenv bundle is a versioned, pre-built, platform-specific C++ package
distributed as a ``.tar.gz`` archive.

Layout
------

.. code-block:: text

   zlib-1.3.1-linux-x86_64-gcc13/
   ├── manifest.yaml              ← human-readable metadata
   ├── .cppenv-files.sha256       ← full file integrity manifest (machine-generated)
   ├── .cppenv-relocate.yaml      ← path relocation instructions
   ├── bin/
   ├── lib/
   ├── include/
   └── share/                     ← test assets, resources

``manifest.yaml``
~~~~~~~~~~~~~~~~~

Human-readable metadata committed by the bundle publisher. Contains name,
version, platform, compiler, and dependency declarations. Deliberately kept
small — file lists live in ``.cppenv-files.sha256``, not here.

``.cppenv-files.sha256``
~~~~~~~~~~~~~~~~~~~~~~~~

Machine-generated SHA-256 integrity manifest listing every file in the
bundle. Verified by the client during activation. Never hand-edited.

``.cppenv-relocate.yaml``
~~~~~~~~~~~~~~~~~~~~~~~~~

Pre-computed path relocation instructions. At publish time, absolute paths
are replaced with ``%BUNDLE_ROOT%`` anchors. This file lists which files
contain text paths, which have rpath entries, and which should be skipped.
Computing this at publish time (not at activate time) keeps activation fast.
