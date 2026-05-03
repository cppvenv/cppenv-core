#pragma once

/**
 * @file DatabaseException.hpp
 * @brief Exception thrown on database operation failures.
 * @author Nikola Radovanovic
 */

#include "Exception.hpp"

namespace cppenv {

/**
 * @brief Thrown when a database operation fails.
 *
 * Covers both SQLite and PostgreSQL backends. The internal detail should
 * include the backend error message (e.g. sqlite3_errmsg, PQerrorMessage)
 * for log diagnostics; the public message stays generic.
 */
class DatabaseException : public Exception {
public:
    /**
     * @brief Construct a database exception.
     * @param publicMessage  Caller-safe description.
     * @param internalDetail Full backend error detail for logging.
     */
    DatabaseException(std::string publicMessage, std::string internalDetail)
        : Exception(Code::DatabaseError, std::move(publicMessage), std::move(internalDetail))
    {}
};

} // namespace cppenv
