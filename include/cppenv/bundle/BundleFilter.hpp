#pragma once

/**
 * @file BundleFilter.hpp
 * @brief Filter parameters for bundle repository queries.
 * @author Nikola Radovanovic
 *
 * Passed to @c Repository::listBundles() to narrow results.  All fields
 * are optional — an empty string means "no filter on this field".
 *
 * A default-constructed @c BundleFilter matches all bundles.  Use
 * @c BundleFilter::Builder to construct filters with specific fields set:
 * @code{.cpp}
 * auto filter = BundleFilter::Builder{}
 *     .name("zlib")
 *     .platform("linux")
 *     .build();
 * @endcode
 */

#include <string>

namespace cppenv {

/**
 * @brief Immutable filter criteria for bundle list queries.
 *
 * Default construction means "match all bundles".  Use @c Builder to
 * set specific fields — it is the only way to construct a filter with
 * non-empty fields, preventing accidental positional argument mistakes.
 */
class BundleFilter {
public:
    /**
     * @brief Fluent builder for @c BundleFilter.
     *
     * All setter methods return a reference to @c *this so calls can be
     * chained.  Fields not set default to an empty string (no constraint).
     *
     * @code{.cpp}
     * auto filter = BundleFilter::Builder{}
     *     .platform("linux")
     *     .arch("x86_64")
     *     .build();
     * @endcode
     */
    class Builder {
    public:
        /** @brief Filter by bundle name. */
        Builder& name(std::string value)     { m_name     = std::move(value); return *this; }

        /** @brief Filter by version string. */
        Builder& version(std::string value)  { m_version  = std::move(value); return *this; }

        /** @brief Filter by platform string. */
        Builder& platform(std::string value) { m_platform = std::move(value); return *this; }

        /** @brief Filter by architecture string. */
        Builder& arch(std::string value)     { m_arch     = std::move(value); return *this; }

        /** @brief Filter by compiler string. */
        Builder& compiler(std::string value) { m_compiler = std::move(value); return *this; }

        /** @brief Construct the @c BundleFilter from the accumulated fields. */
        BundleFilter build() {
            return BundleFilter{
                std::move(m_name),
                std::move(m_version),
                std::move(m_platform),
                std::move(m_arch),
                std::move(m_compiler)
            };
        }

    private:
        std::string m_name;     /**< Accumulated name filter. */
        std::string m_version;  /**< Accumulated version filter. */
        std::string m_platform; /**< Accumulated platform filter. */
        std::string m_arch;     /**< Accumulated architecture filter. */
        std::string m_compiler; /**< Accumulated compiler filter. */
    };

    /** @brief Friend declaration so @c Builder::build() can call the private constructor. */
    friend class Builder;

    /**
     * @brief Default constructor — matches all bundles.
     *
     * All filter fields are empty, meaning no constraints are applied.
     * Use @c Builder to construct a filter with specific fields set.
     */
    BundleFilter() = default;

    /** @brief Filter by bundle name. Empty string means no constraint. */
    const std::string& name()     const { return m_name; }

    /** @brief Filter by version string. Empty string means no constraint. */
    const std::string& version()  const { return m_version; }

    /** @brief Filter by platform string. Empty string means no constraint. */
    const std::string& platform() const { return m_platform; }

    /** @brief Filter by architecture string. Empty string means no constraint. */
    const std::string& arch()     const { return m_arch; }

    /** @brief Filter by compiler string. Empty string means no constraint. */
    const std::string& compiler() const { return m_compiler; }

private:
    /**
     * @brief Private constructor — used exclusively by @c Builder::build().
     *
     * Forcing construction through @c Builder prevents callers from setting
     * specific fields without named setters, eliminating positional argument mistakes.
     */
    BundleFilter(std::string name,
                 std::string version,
                 std::string platform,
                 std::string arch,
                 std::string compiler)
        : m_name{std::move(name)}
        , m_version{std::move(version)}
        , m_platform{std::move(platform)}
        , m_arch{std::move(arch)}
        , m_compiler{std::move(compiler)}
    {}

    const std::string m_name;     /**< Bundle name filter. */
    const std::string m_version;  /**< Version filter. */
    const std::string m_platform; /**< Platform filter. */
    const std::string m_arch;     /**< Architecture filter. */
    const std::string m_compiler; /**< Compiler filter. */
};

} // namespace cppenv
