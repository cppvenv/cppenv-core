Activation
==========

.. note:: This reference is a work in progress.

Activation is the process of unpacking bundles declared in ``cppenv.yaml``,
verifying their integrity, applying path relocation, and generating
``cppvenv/cppvenv.cmake``.

.. code-block:: bash

   cppenv activate

Steps performed
---------------

1. Read ``cppenv.yaml`` — resolve the bundle list for the current platform.
2. Check the local cache (``~/.cppenv/cppenv.db``) — skip already-cached bundles.
3. Download missing bundles from the configured server.
4. Verify SHA-256 checksums against ``.cppenv-files.sha256``.
5. Unpack into ``cppvenv/``.
6. Apply path relocation — expand ``%BUNDLE_ROOT%`` anchors to the actual
   unpack path, patch rpath entries in shared libraries.
7. Record activation state in ``cppvenv/.cppenv.db``.
8. Generate ``cppvenv/cppvenv.cmake``.

``cppenv build`` calls activate automatically if ``cppvenv/`` is absent,
so a fresh clone only needs one command:

.. code-block:: bash

   cppenv build
