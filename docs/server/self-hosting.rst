Self-Hosting
============

.. note:: This guide is a work in progress.

Logging
-------

cppenv-server writes two log streams:

- **Console** — human-readable format for interactive use.
- **File** — JSON format, 50 MB per file, 5 files retained.

The JSON format is intentionally plain so Fluent Bit can forward it to
any observability backend (Datadog, Loki, Elasticsearch, CloudWatch) without
requiring changes to the server binary.

Storage backends
----------------

Local filesystem
~~~~~~~~~~~~~~~~

The default. Bundles are stored as files under the configured ``storage.path``.
Suitable for single-node deployments.

S3-compatible
~~~~~~~~~~~~~

Supports AWS S3, MinIO, and Backblaze B2. Configured with standard
``AWS_ACCESS_KEY_ID`` / ``AWS_SECRET_ACCESS_KEY`` environment variables plus:

.. code-block:: yaml

   storage:
     backend: s3
     bucket: my-cppenv-bundles
     endpoint: https://s3.amazonaws.com   # or MinIO endpoint
