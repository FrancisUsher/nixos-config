cmake_minimum_required(VERSION 3.12)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(PkgConfig REQUIRED)

file(READ "${CMAKE_SOURCE_DIR}/VERSION" VERSION_RAW)
string(STRIP ${VERSION_RAW} VERSION)

project(
	imgborders
	VERSION ${VERSION}
)

set(CMAKE_CXX_STANDARD 23)

add_compile_definitions(VERSION="${VERSION}")

include_directories(.)
file(GLOB_RECURSE SRCFILES "*.cpp")
add_library(imgborders SHARED ${SRCFILES})

pkg_check_modules(deps REQUIRED IMPORTED_TARGET
	hyprland
	libdrm
	pixman-1
	pangocairo
)
target_link_libraries(imgborders PRIVATE rt PkgConfig::deps)

install(TARGETS imgborders)
