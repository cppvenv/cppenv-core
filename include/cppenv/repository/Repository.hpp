#pragma once

/**
 * @file Repository.hpp
 * @brief Abstract base class for all repository (database) backends.
 * @author Nikola Radovanovic
 *
 * Defines the minimal database interface shared by both the CLI and the
 * server.  The CLI uses @c SqliteRepository for its local bundle cache;
 * the server supports both SQLite (small/self-hosted) and PostgreSQL
 * (team/production), switched via config.
 *
 * Repository is intentionally storage-agnostic — it manages bundle metadata
 * only.  The actual bundle archives live in @c Storage.
 */

#include <cppenv/bundle/BundleId.hpp>
#include <cppenv/bundle/BundleRecord.hpp>
#include <cppenv/bundle/BundleFilter.hpp>
#include <cppenv/exception/DatabaseException.hpp>
#include <cppenv/exception/NotFoundException.hpp>

#include <vector>

namespace cppenv {

/**
 * @brief Abstract base for repository (database) backends.
 *
 * All methods throw @c DatabaseException on backend errors and
 * @c NotFoundException when a requested bundle does not exist.
 */
class Repository {
public:
    virtual ~Repository() = default;

    /**
     * @brief Check whether a bundle record exists.
     * @param id  Bundle to look up.
     * @return    @c true if a record exists, @c false otherwise.
     * @throws DatabaseException on backend error.
     */
    virtual bool bundleExists(const BundleId& id) const = 0;

    /**
     * @brief Fetch a single bundle record by identity.
     * @param id  Bundle to look up.
     * @return    The matching bundle record.
     * @throws NotFoundException  if no matching record exists.
     * @throws DatabaseException  on backend error.
     */
    virtual BundleRecord findBundle(const BundleId& id) const = 0;

    /**
     * @brief List bundle records matching the given filter.
     *
     * Empty filter fields are ignored — passing a default-constructed
     * @c BundleFilter returns all records.
     *
     * @param filter  Field-level filter criteria.
     * @return        All matching bundle records, in unspecified order.
     * @throws DatabaseException on backend error.
     */
    virtual std::vector<BundleRecord> listBundles(const BundleFilter& filter) const = 0;

    /**
     * @brief Persist a new bundle record.
     * @param record  Full metadata to store.
     * @throws DatabaseException on backend error or if the record already exists.
     */
    virtual void saveBundle(const BundleRecord& record) = 0;

    /**
     * @brief Remove a bundle record.
     * @param id  Bundle to delete.
     * @throws NotFoundException  if no matching record exists.
     * @throws DatabaseException  on backend error.
     */
    virtual void deleteBundle(const BundleId& id) = 0;

protected:
    /**
     * @brief Protected constructor — prevents direct instantiation.
     *
     * Only subclasses may construct.  There is no shared state to initialise;
     * the constructor exists solely to enforce this constraint.
     */
    Repository() = default;
};

} // namespace cppenv
