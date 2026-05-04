#pragma once

/**
 * @file SqliteRepository.hpp
 * @brief SQLite-backed repository implementation.
 * @author Nikola Radovanovic
 *
 * Implements @c Repository using SQLite via sqlite_orm.  Suitable for
 * local CLI use and self-hosted single-server deployments where a full
 * PostgreSQL setup is not warranted.
 *
 * The database file path is supplied at construction.  The schema is
 * created automatically on first use if the file does not exist.
 */

#include "Repository.hpp"

#include <filesystem>
#include <string>
#include <vector>

namespace cppenv {

/**
 * @brief SQLite-backed bundle metadata repository.
 *
 * Uses sqlite_orm for type-safe schema mapping.  The database file is
 * created at the supplied path if it does not already exist.
 */
class SqliteRepository : public Repository {
public:
    /**
     * @brief Construct a SQLite repository.
     * @param dbPath  Path to the SQLite database file.
     *                Created automatically if it does not exist.
     * @throws DatabaseException if the database cannot be opened or the
     *         schema cannot be created.
     */
    explicit SqliteRepository(std::filesystem::path dbPath);

    bool                       bundleExists(const BundleId& id)                    const override;
    BundleRecord               findBundle(const BundleId& id)                      const override;
    std::vector<BundleRecord>  listBundles(const BundleFilter& filter)             const override;
    void                       saveBundle(const BundleRecord& record)                    override;
    void                       deleteBundle(const BundleId& id)                         override;

private:
    const std::filesystem::path m_dbPath; /**< Path to the SQLite database file. */
};

} // namespace cppenv
