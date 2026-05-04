#pragma once

/**
 * @file LocalStorage.hpp
 * @brief Local filesystem storage backend.
 * @author Nikola Radovanovic
 *
 * Implements @c Storage on top of the local filesystem.  All keys resolve
 * relative to a root directory supplied at construction.  Intermediate
 * directories are created automatically on @c write so callers do not need
 * to pre-create the directory tree.
 *
 * Used by the CLI for the local bundle cache and by the server when
 * @c storage.backend is set to @c local.
 */

#include "Storage.hpp"

#include <filesystem>
#include <fstream>
#include <string>

namespace cppenv {

/**
 * @brief Stores and retrieves files on the local filesystem.
 *
 * Keys map directly to relative paths under the configured root directory.
 * A key of @c "zlib/1.3.1/linux/x86_64/gcc13/bundle.tar.gz" resolves to
 * @c <root>/zlib/1.3.1/linux/x86_64/gcc13/bundle.tar.gz.
 */
class LocalStorage : public Storage {
public:
    /**
     * @brief Construct a local storage backend.
     * @param root  Root directory under which all keys are stored.
     *              The directory is created if it does not exist.
     * @throws StorageException if the root cannot be created or accessed.
     */
    explicit LocalStorage(std::filesystem::path root);

    /**
     * @brief Check whether a key exists on the filesystem.
     * @param key  Relative path under the root directory.
     * @return     @c true if the file exists, @c false otherwise.
     * @throws StorageException on I/O error.
     */
    bool exists(const std::string& key) const override;

    /**
     * @brief Open a file for reading.
     * @param key  Relative path under the root directory.
     * @return     An open @c ifstream positioned at the beginning of the file.
     * @throws StorageException if the file does not exist or cannot be opened.
     */
    std::unique_ptr<std::istream> read(const std::string& key) const override;

    /**
     * @brief Write a stream to a file, creating or replacing it.
     *
     * Intermediate directories are created automatically so the caller never
     * needs to pre-create the directory tree.
     *
     * @param key   Relative path under the root directory.
     * @param data  Stream to read from until EOF.
     * @throws StorageException on I/O error.
     */
    void write(const std::string& key, std::istream& data) override;

    /**
     * @brief Remove a file from the filesystem.
     * @param key  Relative path under the root directory.
     * @throws StorageException if the file does not exist or cannot be removed.
     */
    void remove(const std::string& key) override;

private:
    /**
     * @brief Resolve a key to its absolute filesystem path.
     *
     * Centralises the root + key concatenation so every method uses the
     * same resolution logic and there is no risk of path escaping the root.
     */
    std::filesystem::path resolve(const std::string& key) const;

    const std::filesystem::path m_root; /**< Root directory for all stored files. */
};

} // namespace cppenv
