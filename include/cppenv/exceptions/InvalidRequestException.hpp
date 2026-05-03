#pragma once

/**
 * @file InvalidRequestException.hpp
 * @brief Exception thrown when a request contains invalid parameters.
 * @author Nikola Radovanovic
 */

#include "Exception.hpp"

namespace cppenv {

/**
 * @brief Thrown when a request fails validation.
 *
 * Maps to HTTP 400 in the server layer. Thrown by both the HTTP handler
 * (malformed path parameters) and the domain layer (failed invariant checks).
 */
class InvalidRequestException : public Exception {
public:
    /**
     * @brief Construct an invalid-request exception.
     * @param publicMessage  Caller-safe description of the validation failure.
     * @param internalDetail Full context for logging.
     */
    InvalidRequestException(std::string publicMessage, std::string internalDetail)
        : Exception(Code::InvalidRequest, std::move(publicMessage), std::move(internalDetail))
    {}
};

} // namespace cppenv
