#pragma once

/**
 * @file Bundle.hpp
 * @brief Convenience header — includes all bundle types.
 * @author Nikola Radovanovic
 *
 * Include this header to pull in every bundle class in one line.
 * Prefer including individual bundle headers in headers that only
 * need one type — include this only in translation units that use
 * the full set.
 */

#include <cppenv/bundle/BundleId.hpp>
#include <cppenv/bundle/BundleRecord.hpp>
#include <cppenv/bundle/BundleFilter.hpp>
