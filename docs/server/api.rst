REST API
========

.. note:: This reference is a work in progress.

Authentication
--------------

Endpoints are divided into two roles:

- **Consumer** — search and download bundles. Read-only.
- **Builder** — Consumer + publish bundles, delete bundles, manage users.

Endpoints
---------

.. list-table::
   :header-rows: 1
   :widths: 10 40 20

   * - Method
     - Path
     - Role
   * - GET
     - ``/health``
     - Public
   * - GET
     - ``/bundles``
     - Consumer
   * - GET
     - ``/bundles/{name}/{version}/{platform}/{arch}/{compiler}``
     - Consumer
   * - GET
     - ``/bundles/{name}/{version}/{platform}/{arch}/{compiler}/download``
     - Consumer
   * - POST
     - ``/bundles``
     - Builder
   * - DELETE
     - ``/bundles/{id}``
     - Builder
   * - POST
     - ``/compose``
     - Builder
   * - GET
     - ``/compose/{job_id}``
     - Builder
   * - GET
     - ``/index.yaml``
     - Consumer
   * - GET
     - ``/users``
     - Builder
   * - POST
     - ``/users``
     - Builder
   * - PUT
     - ``/users/{id}``
     - Builder
   * - DELETE
     - ``/users/{id}``
     - Builder
