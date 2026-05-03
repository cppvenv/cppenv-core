#pragma once

/**
 * @file json.hpp
 * @brief Type alias for the JSON library used throughout cppenv.
 * @author Nikola Radovanovic
 *
 * All cppenv code uses @c cppenv::json_t instead of @c nlohmann::json
 * directly. If the JSON library is ever swapped, only this header changes.
 */

#include <nlohmann/json.hpp>

namespace cppenv {

/** @brief Alias for the JSON value type used throughout cppenv. */
using json_t = nlohmann::json;

} // namespace cppenv
