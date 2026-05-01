CMake Integration
=================

.. note:: This guide is a work in progress.

``cppvenv.cmake``
-----------------

After ``cppenv activate``, a ``cppvenv/cppvenv.cmake`` file is generated
in the project root. Include it at the top of your ``CMakeLists.txt``:

.. code-block:: cmake

   include(cppvenv/cppvenv.cmake OPTIONAL)

The generated file sets ``CMAKE_PREFIX_PATH`` and other variables so that
``find_package(zlib)`` and similar calls locate the activated bundles
automatically.

This file is never hand-edited — it is fully regenerated on every ``activate``.
