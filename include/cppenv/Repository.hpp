#pragma once

/**
 * @file Repository.hpp
 * @brief Convenience header — includes all repository types.
 * @author Nikola Radovanovic
 *
 * Include this header to pull in every repository class in one line.
 * Prefer including individual repository headers in headers that only
 * need one type — include this only in translation units that use
 * the full set.
 */

#include <cppenv/repository/Repository.hpp>
#include <cppenv/repository/SqliteRepository.hpp>
#include <cppenv/repository/PostgresRepository.hpp>
