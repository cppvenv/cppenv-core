#pragma once

/**
 * @file StorageException.hpp
 * @brief Exception thrown on storage backend failures.
 * @author Nikola Radovanovic
 */

#include "Exception.hpp"

namespace cppenv {

/**
 * @brief Thrown when a storage operation fails.
 *
 * Covers both local filesystem and S3-compatible backends. The internal
 * detail should include the OS or SDK error for log diagnostics.
 */
class StorageException : public Exception {
public:
    /**
     * @brief Construct a storage exception.
     * @param publicMessage  Caller-safe description.
     * @param internalDetail Full backend error detail for logging.
     */
    StorageException(std::string publicMessage, std::string internalDetail)
        : Exception(Code::StorageError, std::move(publicMessage), std::move(internalDetail))
    {}
};

} // namespace cppenv
