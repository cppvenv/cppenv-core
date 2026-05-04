#pragma once

/**
 * @file InternalException.hpp
 * @brief Exception thrown on unexpected internal failures.
 * @author Nikola Radovanovic
 */

#include "Exception.hpp"

namespace cppenv {

/**
 * @brief Thrown when an unexpected internal error occurs.
 *
 * Maps to HTTP 500 in the server layer. The public message is always a
 * fixed generic string — internal error details must never reach callers.
 * Pass full context in @c internalDetail for log diagnostics.
 */
class InternalException : public Exception {
public:
    /**
     * @brief Construct an internal exception.
     * @param internalDetail Full context for logging — never sent to callers.
     */
    explicit InternalException(std::string internalDetail)
        : Exception(Code::InternalError, "An internal error occurred", std::move(internalDetail))
    {}
};

} // namespace cppenv
