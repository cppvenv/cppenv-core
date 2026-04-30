# skip if included by someone or running standalone
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    cmake_minimum_required(VERSION 3.20)
    project(cppenv-core LANGUAGES CXX)

    set(CMAKE_CXX_STANDARD          17)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS        OFF)

    set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries")

    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE "RelWithDebInfo" CACHE STRING "Build type" FORCE)
    endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(Dependencies)

#add_library(cppenv-core-warnings INTERFACE)
#target_compile_options(cppenv-core-warnings INTERFACE
#    $<$<CXX_COMPILER_ID:GNU,Clang>:
#    -Wall
#    -Wextra
#    -Wpedantic
#    -Wshadow
#    -Wnon-virtual-dtor
#    -Wold-style-cast
#    -Woverloaded-virtual
#    -Wconversion
#    -Wsign-conversion
#    -Wnull-dereference
#    -Wdouble-promotion
#    -Wformat=2
#    >
#    $<$<CXX_COMPILER_ID:MSVC>:
#    /W4
#    /WX
#    /permissive-
#    /w14640
#    >
#)
#
#add_library(cppenv-core SHARED
#    src/manifest.cpp
#    src/sha256.cpp
#    src/relocate.cpp
#    src/version.cpp
#)
#
#add_library(cppenv::core ALIAS cppenv-core)
#
#target_include_directories(cppenv-core
#    PUBLIC
#    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
#    $<INSTALL_INTERFACE:include>
#    PRIVATE
#    ${CMAKE_CURRENT_SOURCE_DIR}/deps/include
#)
#
#target_link_libraries(cppenv-core
#    PRIVATE
#    cppenv-core-warnings
#)

# ---------------------------------------------------------------------------
# Link against built dependencies once they are confirmed available.
# Commented out until deps/ is populated and headers confirmed working.
# Uncomment incrementally as each dep is verified.
# ---------------------------------------------------------------------------
# target_link_libraries(cppenv-core
#     PUBLIC
#         yaml-cpp
#     PRIVATE
#         fmt
#         spdlog
# )

include(GNUInstallDirs)

#install(TARGETS cppenv-core
#        LIBRARY  DESTINATION ${CMAKE_INSTALL_LIBDIR}
#        ARCHIVE  DESTINATION ${CMAKE_INSTALL_LIBDIR}
#        RUNTIME  DESTINATION ${CMAKE_INSTALL_BINDIR}
#)
#
#install(DIRECTORY include/cppenv
#        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
#)


message(STATUS "")
#message(STATUS "cppenv-core ${PROJECT_VERSION}")
message(STATUS "  Build type   : ${CMAKE_BUILD_TYPE}")
message(STATUS "  C++ standard : ${CMAKE_CXX_STANDARD}")
message(STATUS "  Shared libs  : ${BUILD_SHARED_LIBS}")
message(STATUS "  Install path : ${CMAKE_INSTALL_PREFIX}")
message(STATUS "  Deps path    : ${CMAKE_CURRENT_SOURCE_DIR}/deps")
message(STATUS "")