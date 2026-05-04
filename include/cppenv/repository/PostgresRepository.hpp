#pragma once

/**
 * @file PostgresRepository.hpp
 * @brief PostgreSQL-backed repository implementation.
 * @author Nikola Radovanovic
 *
 * Implements @c Repository using libpqxx.  Intended for team and production
 * deployments where concurrent access, connection pooling, and transactional
 * guarantees are required.
 *
 * The connection string is supplied at construction and follows the standard
 * libpq format (e.g. @c "host=localhost dbname=cppenv user=cppenv password=...").
 */

#include "Repository.hpp"

#include <string>
#include <vector>

namespace cppenv {

/**
 * @brief PostgreSQL-backed bundle metadata repository.
 *
 * Uses libpqxx for all database access.  A connection is established at
 * construction and held for the lifetime of the object — one instance per
 * server thread is the expected usage pattern.
 */
class PostgresRepository : public Repository {
public:
    /**
     * @brief Construct a PostgreSQL repository.
     * @param connectionString  libpq connection string.
     * @throws DatabaseException if the connection cannot be established or
     *         the schema cannot be verified.
     */
    explicit PostgresRepository(std::string connectionString);

    bool                       bundleExists(const BundleId& id)                    const override;
    BundleRecord               findBundle(const BundleId& id)                      const override;
    std::vector<BundleRecord>  listBundles(const BundleFilter& filter)             const override;
    void                       saveBundle(const BundleRecord& record)                    override;
    void                       deleteBundle(const BundleId& id)                         override;

private:
    const std::string m_connectionString; /**< libpq connection string. */
};

} // namespace cppenv
