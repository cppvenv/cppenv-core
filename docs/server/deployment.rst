Deployment
==========

.. note:: This guide is a work in progress.

cppenv-server is a single statically-linked binary. There is no runtime
dependency on Python, Node, or a JVM.

Quick start
-----------

.. code-block:: bash

   ./cppenv-server --config /etc/cppenv/server.yaml

Configuration
-------------

.. code-block:: yaml

   database:
     backend: sqlite          # sqlite | postgres
     path: /var/lib/cppenv/cppenv.db   # sqlite only

   storage:
     backend: local           # local | s3
     path: /var/lib/cppenv/bundles     # local only

   server:
     host: 0.0.0.0
     port: 8080
