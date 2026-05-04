#pragma once

/**
 * @file Storage.hpp
 * @brief Abstract base class for all storage backends.
 * @author Nikola Radovanovic
 *
 * Defines the minimal filesystem interface shared by both the CLI and the
 * server.  The CLI uses @c LocalStorage exclusively — it never talks to
 * remote storage directly.  The server adds backends (e.g. @c S3Storage)
 * on top of this base.
 *
 * Storage is intentionally bundle-agnostic — it operates on opaque string
 * keys and raw byte streams.  Bundle-specific logic (manifest parsing,
 * sha256 verification, path relocation) belongs in the @c cppenv::bundles
 * layer above.
 */

#include <cppenv/exceptions/StorageException.hpp>

#include <istream>
#include <memory>
#include <string>

namespace cppenv {

/**
 * @brief Abstract base for storage backends.
 *
 * Keys are opaque path-like strings (e.g.
 * @c "zlib/1.3.1/linux/x86_64/gcc13/bundle.tar.gz").
 * The caller is responsible for constructing meaningful keys — the backend
 * stores and retrieves bytes without interpreting them.
 *
 * All methods throw @c StorageException on failure.
 */
class Storage {
public:
    virtual ~Storage() = default;

    /**
     * @brief Check whether a key exists in the store.
     * @param key  Opaque path-like identifier.
     * @return     @c true if the key exists, @c false otherwise.
     * @throws StorageException on I/O error.
     */
    virtual bool exists(const std::string& key) const = 0;

    /**
     * @brief Open a key for reading.
     * @param key  Opaque path-like identifier.
     * @return     Stream positioned at the beginning of the stored content.
     * @throws StorageException if the key does not exist or cannot be read.
     */
    virtual std::unique_ptr<std::istream> read(const std::string& key) const = 0;

    /**
     * @brief Write data to a key, creating or replacing it.
     * @param key   Opaque path-like identifier.
     * @param data  Stream to read from until EOF.
     * @throws StorageException on I/O error.
     */
    virtual void write(const std::string& key, std::istream& data) = 0;

    /**
     * @brief Remove a key from the store.
     * @param key  Opaque path-like identifier.
     * @throws StorageException if the key does not exist or cannot be removed.
     */
    virtual void remove(const std::string& key) = 0;

protected:
    /**
     * @brief Protected constructor — prevents direct instantiation.
     *
     * Only subclasses may construct.  There is no shared state to initialise;
     * the constructor exists solely to enforce this constraint.
     */
    Storage() = default;
};

} // namespace cppenv
