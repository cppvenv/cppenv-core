#pragma once

/**
 * @file NotFoundException.hpp
 * @brief Exception thrown when a requested resource does not exist.
 * @author Nikola Radovanovic
 */

#include "Exception.hpp"

namespace cppenv {

/**
 * @brief Thrown when a requested resource cannot be found.
 *
 * Maps to HTTP 404 in the server layer. The public message is fixed to a
 * safe generic string; pass full context in @c internalDetail for logging.
 */
class NotFoundException : public Exception {
public:
    /**
     * @brief Construct a not-found exception.
     * @param publicMessage  Caller-safe description of what was not found.
     * @param internalDetail Full context for logging (query, identifiers, etc.).
     */
    NotFoundException(std::string publicMessage, std::string internalDetail)
        : Exception(Code::NotFound, std::move(publicMessage), std::move(internalDetail))
    {}
};

} // namespace cppenv
