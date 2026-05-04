#pragma once

/**
 * @file Exception.hpp
 * @brief Base exception class for all cppenv exceptions.
 * @author Nikola Radovanovic
 *
 * Every exception in the cppenv hierarchy carries two messages:
 * - @c publicMessage  — safe to surface to callers (HTTP response, CLI output).
 * - @c internalDetail — full context for logging; never sent over the wire.
 *
 * Subclasses encode the failure category via @c Code and typically fix the
 * @c publicMessage to a safe default so call sites only supply the detail.
 */

#include <exception>
#include <string>

namespace cppenv {

/**
 * @brief Base class for all cppenv exceptions.
 *
 * Holds a @c Code identifying the failure category, a caller-safe public
 * message, and an internal detail string intended for log output only.
 * @c what() returns the internal detail so spdlog captures it directly.
 */
class Exception : public std::exception {
public:
    /**
     * @brief Failure category.
     *
     * Used by the server layer to map exceptions to HTTP status codes and
     * by the CLI layer to select the appropriate user-facing error format.
     */
    enum class Code {
        NotFound,
        InvalidRequest,
        StorageError,
        DatabaseError,
        InternalError,
    };

    /**
     * @brief Construct with explicit public and internal messages.
     * @param code           Failure category.
     * @param publicMessage  Caller-safe description — may be shown to end users.
     * @param internalDetail Full context for logging — never serialised to callers.
     */
    Exception(Code code, std::string publicMessage, std::string internalDetail)
        : m_code{code}
        , m_publicMessage{std::move(publicMessage)}
        , m_internalDetail{std::move(internalDetail)}
    {}

    /** @brief Returns the failure category. */
    Code code() const { return m_code; }

    /** @brief Returns the internal detail — use for logging, never for caller responses. */
    const char* what() const noexcept override { return m_internalDetail.c_str(); }

    /** @brief Returns the caller-safe public message. */
    const std::string& publicMessage()  const { return m_publicMessage; }

    /** @brief Returns the internal detail string. */
    const std::string& internalDetail() const { return m_internalDetail; }

private:
    const Code        m_code;           /**< Failure category. */
    const std::string m_publicMessage;  /**< Caller-safe message — safe to serialise. */
    const std::string m_internalDetail; /**< Full detail for logging — never sent to callers. */
};

} // namespace cppenv
