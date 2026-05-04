#pragma once

/**
 * @file BundleId.hpp
 * @brief Immutable value object that uniquely identifies a bundle.
 * @author Nikola Radovanovic
 *
 * All fields are mandatory — there are no optional components in a
 * bundle identifier.  The constructor validates that no field is empty so
 * callers can rely on a constructed @c BundleId always being well-formed.
 *
 * Lives in cppenv-core so both the CLI and the server can use it without
 * depending on each other.
 *
 * Typical construction:
 * @code{.cpp}
 * auto id = BundleId{"zlib", "1.3.1", "linux", "x86_64", "gcc13"};
 * @endcode
 */

#include <cppenv/exception/InvalidRequestException.hpp>

#include <string>

namespace cppenv {

/**
 * @brief Uniquely identifies a bundle by its mandatory components.
 *
 * Immutable after construction.  Pass by value or const reference — never
 * mutate.  The HTTP handler validates incoming request parameters and returns
 * 400 before constructing a @c BundleId; the constructor is an unconditional
 * safety net that enforces the invariant regardless of the call site.
 */
class BundleId {
public:
    /**
     * @brief Construct a bundle identifier.
     * @param name      Bundle name (e.g. @c "zlib").
     * @param version   Semantic version string (e.g. @c "1.3.1").
     * @param platform  Target platform (e.g. @c "linux").
     * @param arch      Target architecture (e.g. @c "x86_64").
     * @param compiler  Compiler family + major version (e.g. @c "gcc13").
     * @throws cppenv::InvalidRequestException if any field is empty.
     */
    BundleId(std::string name,
             std::string version,
             std::string platform,
             std::string arch,
             std::string compiler)
        : m_name{std::move(name)}
        , m_version{std::move(version)}
        , m_platform{std::move(platform)}
        , m_arch{std::move(arch)}
        , m_compiler{std::move(compiler)}
    {
        // Validate after move — empty string after move is still detectable.
        // Each field has an independent message so the caller knows exactly
        // which component was missing without inspecting all fields.
        if (m_name.empty())     throw cppenv::InvalidRequestException("Bundle name is required",     "BundleId constructed with empty name");
        if (m_version.empty())  throw cppenv::InvalidRequestException("Bundle version is required",  "BundleId constructed with empty version");
        if (m_platform.empty()) throw cppenv::InvalidRequestException("Bundle platform is required", "BundleId constructed with empty platform");
        if (m_arch.empty())     throw cppenv::InvalidRequestException("Bundle arch is required",     "BundleId constructed with empty arch");
        if (m_compiler.empty()) throw cppenv::InvalidRequestException("Bundle compiler is required", "BundleId constructed with empty compiler");
    }

    /** @brief Bundle name. */
    const std::string& name()     const { return m_name; }

    /** @brief Semantic version string. */
    const std::string& version()  const { return m_version; }

    /** @brief Target platform string. */
    const std::string& platform() const { return m_platform; }

    /** @brief Target architecture string. */
    const std::string& arch()     const { return m_arch; }

    /** @brief Compiler family + major version string. */
    const std::string& compiler() const { return m_compiler; }

private:
    const std::string m_name;     /**< Bundle name. */
    const std::string m_version;  /**< Semantic version string. */
    const std::string m_platform; /**< Target platform string. */
    const std::string m_arch;     /**< Target architecture string. */
    const std::string m_compiler; /**< Compiler family + major version. */
};

} // namespace cppenv
