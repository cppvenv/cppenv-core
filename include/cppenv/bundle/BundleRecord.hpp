#pragma once

/**
 * @file BundleRecord.hpp
 * @brief Metadata record for a stored bundle.
 * @author Nikola Radovanovic
 *
 * Returned by @c Repository query methods.  Carries the full bundle
 * identity plus server-side metadata recorded at publish time.
 */

#include <string>

namespace cppenv {

/**
 * @brief Immutable metadata record for a stored bundle.
 *
 * Combines the bundle identity fields with server-side metadata
 * (@c sha256, @c uploadedAt) recorded when the bundle was published.
 * Immutable after construction — obtain a new record from the repository
 * rather than modifying an existing one.
 */
class BundleRecord {
public:
    /**
     * @brief Construct a bundle record.
     * @param name        Bundle name (e.g. @c "zlib").
     * @param version     Semantic version string (e.g. @c "1.3.1").
     * @param platform    Target platform (e.g. @c "linux").
     * @param arch        Target architecture (e.g. @c "x86_64").
     * @param compiler    Compiler family + major version (e.g. @c "gcc13").
     * @param sha256      SHA-256 digest of the bundle archive.
     * @param uploadedAt  ISO-8601 timestamp of when the bundle was published.
     */
    BundleRecord(std::string name,
                 std::string version,
                 std::string platform,
                 std::string arch,
                 std::string compiler,
                 std::string sha256,
                 std::string uploadedAt)
        : m_name{std::move(name)}
        , m_version{std::move(version)}
        , m_platform{std::move(platform)}
        , m_arch{std::move(arch)}
        , m_compiler{std::move(compiler)}
        , m_sha256{std::move(sha256)}
        , m_uploadedAt{std::move(uploadedAt)}
    {}

    /** @brief Bundle name. */
    const std::string& name()       const { return m_name; }

    /** @brief Semantic version string. */
    const std::string& version()    const { return m_version; }

    /** @brief Target platform string. */
    const std::string& platform()   const { return m_platform; }

    /** @brief Target architecture string. */
    const std::string& arch()       const { return m_arch; }

    /** @brief Compiler family + major version string. */
    const std::string& compiler()   const { return m_compiler; }

    /** @brief SHA-256 digest of the bundle archive. */
    const std::string& sha256()     const { return m_sha256; }

    /** @brief ISO-8601 timestamp of when the bundle was published. */
    const std::string& uploadedAt() const { return m_uploadedAt; }

private:
    const std::string m_name;       /**< Bundle name. */
    const std::string m_version;    /**< Semantic version string. */
    const std::string m_platform;   /**< Target platform string. */
    const std::string m_arch;       /**< Target architecture string. */
    const std::string m_compiler;   /**< Compiler family + major version. */
    const std::string m_sha256;     /**< SHA-256 digest of the bundle archive. */
    const std::string m_uploadedAt; /**< ISO-8601 publish timestamp. */
};

} // namespace cppenv
