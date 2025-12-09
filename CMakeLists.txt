cmake_minimum_required(VERSION 3.18)

# set project name
project(LEMON)

if (NOT DEFINED BIN_DIR)
  set(BIN_DIR bin)
endif (NOT DEFINED BIN_DIR)

# build the lemon binary
add_executable(lemon lemon.c)

install(TARGETS lemon DESTINATION ${BIN_DIR})

# install the templates
install(FILES lempar.c DESTINATION ${BIN_DIR})

# Local Variables:
# tab-width: 8
