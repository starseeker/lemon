cmake_minimum_required(VERSION 3.18)

# set project name
project(PERPLEX)

include_directories(
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}
  )

if (NOT BIN_DIR)
  set (BIN_DIR bin)
endif (NOT BIN_DIR)
if (NOT DATA_DIR)
  set (DATA_DIR share)
endif (NOT DATA_DIR)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake)

find_package(RE2C REQUIRED)
find_package(LEMON REQUIRED)

set(WD "${CMAKE_CURRENT_BINARY_DIR}/perplex_wd")
file(MAKE_DIRECTORY "${WD}")
add_custom_command(
  OUTPUT ${WD}/parser.out ${WD}/parser.c ${WD}/parser.h
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/parser.y ${WD}/parser.y
  COMMAND ${LEMON_EXECUTABLE} ${WD}/parser.y
  DEPENDS ${LEMON_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/parser.y
  WORKING_DIRECTORY ${WD}
  COMMENT "[LEMON][perplex] Building parser with ${LEMON_EXECUTABLE}"
  )
add_custom_command(
  OUTPUT perplex_parser.c perplex_parser.h
  COMMAND ${CMAKE_COMMAND} -E copy ${WD}/parser.c perplex_parser.c
  COMMAND ${CMAKE_COMMAND} -E copy ${WD}/parser.h perplex_parser.h
  DEPENDS ${WD}/parser.c ${WD}/parser.h
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  )

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/perplex_scanner.c
  COMMAND ${RE2C_EXECUTABLE} -c -o ${CMAKE_CURRENT_BINARY_DIR}/perplex_scanner.c ${CMAKE_CURRENT_SOURCE_DIR}/scanner.re
  DEPENDS ${RE2C_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/scanner.re perplex_parser.c perplex_parser.h
  WORKING_DIRECTORY ${WD}
  COMMENT "[RE2C][perplex] Building scanner with ${RE2C_EXECUTABLE}"
  )

set(perplex_sources
  ${CMAKE_CURRENT_BINARY_DIR}/perplex_parser.c
  ${CMAKE_CURRENT_BINARY_DIR}/perplex_scanner.c
  mbo_getopt.cpp
  perplex.cpp
  )

add_executable(perplex ${perplex_sources})
set_property(TARGET perplex APPEND PROPERTY INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/perplex")

# install the binaries
install(TARGETS perplex DESTINATION ${BIN_DIR})

# install the templates
install(FILES perplex_template.c DESTINATION ${DATA_DIR}/perplex)

# Local Variables:
# tab-width: 8
# mode: cmake
# indent-tabs-mode: t
# End:
# ex: shiftwidth=2 tabstop=8
