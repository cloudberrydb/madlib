# ------------------------------------------------------------------------------
# Find PostgreSQL binary, include directories, version information, etc.
# ------------------------------------------------------------------------------
#
# == Using PostgreSQL (primary form)
#  find_package(PostgreSQL)
#
# == Alternative form
#  find_package(DBMS_X_Y)
#  where there is a file "FindDBMS_X_Y.cmake" with content
#  --8<--
#  set(_FIND_PACKAGE_FILE "${CMAKE_CURRENT_LIST_FILE}")
#  include("${CMAKE_CURRENT_LIST_DIR}/FindPostgreSQL.cmake")
#  -->8--
#
# This module sets the following variables, where PKG_NAME will be "PostgreSQL"
# when the primary form above is used, and PKG_NAME will be "DBMS_X_Y" if
# the alternative form above is used.
#
#  PKG_NAME - uppercased package name, as decuded from the current file name
#      (see below)
#  ${PKG_NAME}_FOUND - set to true if headers and binary were found
#  ${PKG_NAME}_LIB_DIR - PostgreSQL library directory
#  ${PKG_NAME}_SHARE_DIR - PostgreSQL share directory
#  ${PKG_NAME}_PKGLIB_DIR - PostgreSQL package library directory
#  ${PKG_NAME}_CLIENT_INCLUDE_DIR - client include directory
#  ${PKG_NAME}_SERVER_INCLUDE_DIR - server include directory
#  ${PKG_NAME}_EXECUTABLE - path to postgres binary
#  ${PKG_NAME}_VERSION_MAJOR - major version number
#  ${PKG_NAME}_VERSION_MINOR - minor version number
#  ${PKG_NAME}_VERSION_PATCH - patch version number
#  ${PKG_NAME}_VERSION_STRING - version number as a string (ex: "9.1.2")
#  ${PKG_NAME}_ARCHITECTURE - DBMS architecture (ex: "x86_64")
#
# This package locates pg_config and uses it to determine all other paths. If
# ${PKG_NAME}_PG_CONFIG is defined, then the search steps will be omitted.
#
# Distributed under the BSD-License.

# According to
# http://www.cmake.org/files/v2.8/CMakeChangeLog-2.8.3
# the form of find_package_handle_standard_args we are using requires
# cmake >= 2.8.3
cmake_minimum_required(VERSION 2.8.3 FATAL_ERROR)

# Set defaults that can be overridden by files that include this file:
if(NOT DEFINED _FIND_PACKAGE_FILE)
    set(_FIND_PACKAGE_FILE "${CMAKE_CURRENT_LIST_FILE}")
endif(NOT DEFINED _FIND_PACKAGE_FILE)
if(NOT DEFINED _NEEDED_PG_CONFIG_PACKAGE_NAME)
    set(_NEEDED_PG_CONFIG_PACKAGE_NAME "PostgreSQL")
endif(NOT DEFINED _NEEDED_PG_CONFIG_PACKAGE_NAME)
if(NOT DEFINED _PG_CONFIG_VERSION_NUM_MACRO)
    set(_PG_CONFIG_VERSION_NUM_MACRO "PG_VERSION_NUM")
endif(NOT DEFINED _PG_CONFIG_VERSION_NUM_MACRO)
if(NOT DEFINED _PG_CONFIG_VERSION_MACRO)
    set(_PG_CONFIG_VERSION_MACRO "PG_VERSION")
endif(NOT DEFINED _PG_CONFIG_VERSION_MACRO)

# Set:
# - PACKAGE_FILE_NAME to the package name, as deduced from the current file
#   name, which is of form "FindXXXX.cmake".
# - PKG_NAME to the uppercased ${PACKAGE_FILE_NAME}
# - PACKAGE_FIND_VERSION to the requested version "X.Y", as decuded from
#   ${PACKAGE_FILE_NAME}. It will remain undefined if ${PACKAGE_FILE_NAME} does
#   not have a version suffix of form "_X_Y".
get_filename_component(_CURRENT_FILE_NAME "${_FIND_PACKAGE_FILE}" NAME)
string(REGEX REPLACE "Find([^.]+)\\..*" "\\1" PACKAGE_FIND_NAME
    "${_CURRENT_FILE_NAME}")
string(TOUPPER ${PACKAGE_FIND_NAME} PKG_NAME)
if("${PACKAGE_FIND_NAME}" MATCHES "^Find[a-zA-Z]+_.+$")
    string(REGEX REPLACE "^Find[a-zA-Z]+_(.+)$" "\\1" PACKAGE_FIND_VERSION_UNDERSCORE
        "${PACKAGE_FIND_NAME}")
    string(REPLACE "_" "." PACKAGE_FIND_VERSION "${PACKAGE_FIND_VERSION_UNDERSCORE}")
endif()

# If ${PKG_NAME}_PG_CONFIG is defined, then the search steps will be omitted.
if(NOT DEFINED ${PKG_NAME}_PG_CONFIG)
    find_program(${PKG_NAME}_PG_CONFIG pg_config
        HINTS ${_SEARCH_PATH_HINTS}
    )
endif(NOT DEFINED ${PKG_NAME}_PG_CONFIG)

if(${PKG_NAME}_PG_CONFIG)
    execute_process(COMMAND ${${PKG_NAME}_PG_CONFIG} --includedir-server
        OUTPUT_VARIABLE ${PKG_NAME}_SERVER_INCLUDE_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    execute_process(COMMAND ${${PKG_NAME}_PG_CONFIG} --includedir
        OUTPUT_VARIABLE ${PKG_NAME}_CLIENT_INCLUDE_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
endif(${PKG_NAME}_PG_CONFIG)

if(${PKG_NAME}_PG_CONFIG AND ${PKG_NAME}_SERVER_INCLUDE_DIR)
    set(${PKG_NAME}_VERSION_MAJOR 0)
    set(${PKG_NAME}_VERSION_MINOR 0)
    set(${PKG_NAME}_VERSION_PATCH 0)

    set(CONFIG_FILE ${${PKG_NAME}_SERVER_INCLUDE_DIR}/pg_config.h)

    if(EXISTS ${CONFIG_FILE})
        # Read and parse postgres version header file for version number
        if(${CMAKE_COMPILER_IS_GNUCC})
            # If we know the compiler, we can do something that is a little
            # smarter: Dump the definitions only.
            execute_process(
                COMMAND ${CMAKE_C_COMPILER} -E -dD ${CONFIG_FILE}
                OUTPUT_VARIABLE _PG_CONFIG_HEADER_CONTENTS
            )
        else(${CMAKE_COMPILER_IS_GNUCC})
            file(READ ${CONFIG_FILE} _PG_CONFIG_HEADER_CONTENTS)
        endif(${CMAKE_COMPILER_IS_GNUCC})

		# Get PACKAGE_NAME
		if (_PG_CONFIG_HEADER_CONTENTS MATCHES "#define PACKAGE_NAME \".*\"")
          string(REGEX REPLACE
			".*#define PACKAGE_NAME \"([^\"]+)\".*" "\\1"
			_PACKAGE_NAME "${_PG_CONFIG_HEADER_CONTENTS}")
		else(_PG_CONFIG_HEADER_CONTENTS MATCHES "#define PACKAGE_NAME \".*\"")
          message(FATAL_ERROR "Unable to locate PACKAGE_NAME in \"${CONFIG_FILE}\".")
		endif(_PG_CONFIG_HEADER_CONTENTS MATCHES "#define PACKAGE_NAME \".*\"")

		# Get VERSION_NUM
		if (_PG_CONFIG_HEADER_CONTENTS MATCHES "#define ${_PG_CONFIG_VERSION_NUM_MACRO} ([0-9]+).*")
          string(REGEX REPLACE
            ".*#define ${_PG_CONFIG_VERSION_NUM_MACRO} ([0-9]+).*" "\\1"
            ${PKG_NAME}_VERSION_NUM "${_PG_CONFIG_HEADER_CONTENTS}")
		else(_PG_CONFIG_HEADER_CONTENTS MATCHES "#define ${_PG_CONFIG_VERSION_NUM_MACRO} ([0-9]+).*")
		  set(${PKG_NAME}_VERSION_NUM "unknown")
		endif(_PG_CONFIG_HEADER_CONTENTS MATCHES "#define ${_PG_CONFIG_VERSION_NUM_MACRO} ([0-9]+).*")

        if(${PKG_NAME}_VERSION_NUM MATCHES "^[0-9]+$")
            math(EXPR ${PKG_NAME}_VERSION_MAJOR "${${PKG_NAME}_VERSION_NUM} / 10000")
            math(EXPR ${PKG_NAME}_VERSION_MINOR "(${${PKG_NAME}_VERSION_NUM} % 10000) / 100")
            math(EXPR ${PKG_NAME}_VERSION_PATCH "${${PKG_NAME}_VERSION_NUM} % 100")
            # cbdb only set major version
            set(${PKG_NAME}_VERSION_STRING "${${PKG_NAME}_VERSION_MAJOR}")
        else(${PKG_NAME}_VERSION_NUM MATCHES "^[0-9]+$")
            # Macro with version number was not found. We use the version string
            # macro as a fallback. Example when this is used: Greenplum < 4.1
            # does not have a GP_VERSION_NUM macro, but only GP_VERSION.

			# Get VERSION
			if (_PG_CONFIG_HEADER_CONTENTS MATCHES "#define ${_PG_CONFIG_VERSION_MACRO} ([0-9]+).*")
			  string(REGEX REPLACE
				".*#define ${_PG_CONFIG_VERSION_MACRO} ([0-9]+).*" "\\1"
				${PKG_NAME}_VERSION_STRING "${_PG_CONFIG_HEADER_CONTENTS}")
              string(REGEX REPLACE "([0-9]+).*" "\\1"
                ${PKG_NAME}_VERSION_MAJOR "${${PKG_NAME}_VERSION_STRING}")
              string(REGEX REPLACE "[0-9]+\\.([0-9]+).*" "\\1"
                ${PKG_NAME}_VERSION_MINOR "${${PKG_NAME}_VERSION_STRING}")
              string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+).*" "\\1"
                ${PKG_NAME}_VERSION_PATCH "${${PKG_NAME}_VERSION_STRING}")

			else(_PG_CONFIG_HEADER_CONTENTS MATCHES "#define ${_PG_CONFIG_VERSION_MACRO} ([0-9]+).*")
			  set(${PKG_NAME}_VERSION_STRING "unknown")
			endif(_PG_CONFIG_HEADER_CONTENTS MATCHES "#define ${_PG_CONFIG_VERSION_MACRO} ([0-9]+).*")

        endif(${PKG_NAME}_VERSION_NUM MATCHES "^[0-9]+$")
    else(EXISTS ${CONFIG_FILE})
        message(FATAL_ERROR "Found pg_config (\"${${PKG_NAME}_PG_CONFIG}\"), "
              "but pg_config.h file not present in the "
              "server include dir (${${PKG_NAME}_SERVER_INCLUDE_DIR}).")
    endif(EXISTS ${CONFIG_FILE})

    if(_PACKAGE_NAME STREQUAL "${_NEEDED_PG_CONFIG_PACKAGE_NAME}")
        if((NOT DEFINED PACKAGE_FIND_VERSION) OR
            (PACKAGE_FIND_VERSION VERSION_EQUAL
            "${${PKG_NAME}_VERSION_MAJOR}.${${PKG_NAME}_VERSION_MINOR}"))

            execute_process(COMMAND ${${PKG_NAME}_PG_CONFIG} --bindir
                OUTPUT_VARIABLE ${PKG_NAME}_EXECUTABLE
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )
            set(${PKG_NAME}_EXECUTABLE "${${PKG_NAME}_EXECUTABLE}/postgres")

            execute_process(COMMAND ${${PKG_NAME}_PG_CONFIG} --libdir
                OUTPUT_VARIABLE ${PKG_NAME}_LIB_DIR
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )

            execute_process(COMMAND ${${PKG_NAME}_PG_CONFIG} --sharedir
                OUTPUT_VARIABLE ${PKG_NAME}_SHARE_DIR
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )

            execute_process(COMMAND ${${PKG_NAME}_PG_CONFIG} --pkglibdir
                OUTPUT_VARIABLE ${PKG_NAME}_PKGLIB_DIR
                OUTPUT_STRIP_TRAILING_WHITESPACE
            )

            architecture(${PKG_NAME}_ARCHITECTURE)
        else()
		  if(${PACKAGE_FIND_VERSION})
            message(FATAL_ERROR "Found \"${${PKG_NAME}_PG_CONFIG}\", "
              "but it belongs to ${_PACKAGE_NAME} ${${PKG_NAME}_VERSION_STRING} "
              "where ${_NEEDED_PG_CONFIG_PACKAGE_NAME} ${PACKAGE_FIND_VERSION} "
			  "was requested.")
		  endif(${PACKAGE_FIND_VERSION})
        endif()
    else(_PACKAGE_NAME STREQUAL "${_NEEDED_PG_CONFIG_PACKAGE_NAME}")
	  if(${PACKAGE_FIND_VERSION})
        # There are DBMSs derived from PostgreSQL that also contain pg_config.
        # So there might be many pg_config installed on a system.
        message(FATAL_ERROR "Found \"${${PKG_NAME}_PG_CONFIG}\", "
          "but it belongs to ${_PACKAGE_NAME} "
          "where ${_NEEDED_PG_CONFIG_PACKAGE_NAME} ${PACKAGE_FIND_VERSION} "
		  "was requested.")
	  endif(${PACKAGE_FIND_VERSION})
    endif(_PACKAGE_NAME STREQUAL "${_NEEDED_PG_CONFIG_PACKAGE_NAME}")
endif(${PKG_NAME}_PG_CONFIG AND ${PKG_NAME}_SERVER_INCLUDE_DIR)


# Checks 'REQUIRED', 'QUIET' and versions. Note that the first parameter is
# passed in original casing.
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(${PACKAGE_FIND_NAME}
    REQUIRED_VARS
        ${PKG_NAME}_EXECUTABLE
        ${PKG_NAME}_CLIENT_INCLUDE_DIR
        ${PKG_NAME}_SERVER_INCLUDE_DIR
    VERSION_VAR
        "${_PACKAGE_NAME} ${PKG_NAME}_VERSION_STRING"
)
