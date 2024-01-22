cmake_minimum_required(VERSION 3.8)

project("win11-toggle-rounded-corners")

set(TARGET_NAME win11-toggle-rounded-corners)

set(CMAKE_CXX_STANDARD 23)

# fix CMAKE_C_COMPILER_ARCHITECTURE_ID for gcc/clang
if (NOT CMAKE_C_COMPILER_ARCHITECTURE_ID)
	if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
		if (CMAKE_C_COMPILER_PREDEFINES_COMMAND)
			set(_COMPILER_PATH ${CMAKE_C_COMPILER_PREDEFINES_COMMAND})
		elseif (CMAKE_CXX_COMPILER_PREDEFINES_COMMAND)
			set(_COMPILER_PATH ${CMAKE_CXX_COMPILER_PREDEFINES_COMMAND})
		endif()
		if ("-m32" IN_LIST _COMPILER_PATH)
			set(CMAKE_C_COMPILER_ARCHITECTURE_ID x86)
		elseif (_COMPILER_PATH MATCHES ".*[/\\\\]([^-]+)-(.+)-(g\\+\\+|gcc|clang|clang\\+\\+)\\..*")
			set(CMAKE_C_COMPILER_ARCHITECTURE_ID ${CMAKE_MATCH_1})
		endif()

		if (NOT CMAKE_C_COMPILER_ARCHITECTURE_ID)
			execute_process(
				COMMAND ${_COMPILER_PATH} -v
				OUTPUT_VARIABLE  _COMPILER_V_OUTPUT
				ERROR_VARIABLE  _COMPILER_V_OUTPUT
			)
			string(REGEX MATCH "Target:[ \\t]*([^ \t\n]*)" GCC_TARGET "${_COMPILER_V_OUTPUT}")
			string(REGEX MATCH "([^-]*)-([^-]*)-(.*)" CMAKE_C_COMPILER_ARCHITECTURE_ID "${CMAKE_MATCH_1}")
			set(CMAKE_C_COMPILER_ARCHITECTURE_ID ${CMAKE_MATCH_1})
			unset(_COMPILER_V_OUTPUT)
		endif()
		unset(_COMPILER_PATH)
	endif()
endif()
string(REGEX REPLACE "[xX]86_64|X64" "x64" CMAKE_C_COMPILER_ARCHITECTURE_ID ${CMAKE_C_COMPILER_ARCHITECTURE_ID})
string(REGEX REPLACE "[iI][1-7]86|X86" "x86" CMAKE_C_COMPILER_ARCHITECTURE_ID ${CMAKE_C_COMPILER_ARCHITECTURE_ID})

if (MSVC)
	option(MSVC_USE_STATIC_CRT "Build target(s) with static crt library" OFF)
	string(TOUPPER ${CMAKE_BUILD_TYPE} _MSVC_BUILD_CONFIG)
	set(_EDX_ESC "[")
	if (MSVC_USE_STATIC_CRT)
		message("-- Using ${_EDX_ESC}34mSTATIC${_EDX_ESC}0m linked CRT (/MT)")
		string(REPLACE "/MD" "/MT" CMAKE_C_FLAGS_${_MSVC_BUILD_CONFIG} ${CMAKE_C_FLAGS_${_MSVC_BUILD_CONFIG}})
		string(REPLACE "/MD" "/MT" CMAKE_CXX_FLAGS_${_MSVC_BUILD_CONFIG} ${CMAKE_CXX_FLAGS_${_MSVC_BUILD_CONFIG}})
	else()
		message("-- Using ${_EDX_ESC}34mDYNAMIC${_EDX_ESC}0m linked CRT (/MD)")
		string(REPLACE "/MT" "/MD" CMAKE_C_FLAGS_${_MSVC_BUILD_CONFIG} ${CMAKE_C_FLAGS_${_MSVC_BUILD_CONFIG}})
		string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_${_MSVC_BUILD_CONFIG} ${CMAKE_CXX_FLAGS_${_MSVC_BUILD_CONFIG}})
	endif()
else()
	set(MSVC_USE_STATIC_CRT)
endif()

# include_directories(<HEADER_PATH>)

# add_link_options(<LINKER_FLAGS>)

# add_compile_options(<COMPILER_FLAGS>)

#function(append value)
#foreach(variable ${ARGN})
#set(${variable} "${${variable}} ${value}" PARENT_SCOPE)
#endforeach(variable)
#endfunction()
#
#option(BUILD_SHARED_LIBS "Build all libraries as shared libraries instead of static" OFF)
#option(LLVM_STATIC_LINK_CXX_STDLIB "Statically link the standard library." OFF)
#option(LLVM_COMPILER_IS_GCC_COMPATIBLE ON)
#option(LLVM_ENABLE_LIBCXX "Use libc++ if available." ON)
#option(LLVM_ENABLE_LIBCXXABI "Use libc++abi when using libc++." ON)
#
#append("-stdlib=libc++ -static"
#	CMAKE_CXX_FLAGS CMAKE_EXE_LINKER_FLAGS CMAKE_SHARED_LINKER_FLAGS
#	CMAKE_MODULE_LINKER_FLAGS)

# Register Zydis dependency.
# Disable build of tools and examples.
option(ZYDIS_BUILD_TOOLS "" OFF)
option(ZYDIS_BUILD_EXAMPLES "" OFF)
add_subdirectory("deps/zydis")

aux_source_directory(./ SOURCE_FILES)
add_executable(${TARGET_NAME} ${SOURCE_FILES})
target_link_libraries(${TARGET_NAME} PRIVATE "Zydis")
#target_include_directories(${TARGET_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/include)

#set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++ -static")
#target_link_libraries(${TARGET_NAME} PRIVATE -stdlib=libc++ -static-libgcc -static-libstdc++)
target_link_libraries(${TARGET_NAME} PRIVATE -static)

add_custom_command(
	TARGET ${TARGET_NAME} POST_BUILD
	COMMAND
	"C:\\Program Files (x86)\\Windows Kits\\10\\bin\\x64\\mt.exe"
	-manifest ${CMAKE_CURRENT_SOURCE_DIR}/uac.manifest
	-outputresource:win11-toggle-rounded-corners.exe\;\#1
	VERBATIM)

# target_link_options(${TARGET_NAME} PRIVATE
# 	"LINKER:/MANIFEST:EMBED"
# 	"LINKER:/MANIFESTINPUT:${CMAKE_CURRENT_SOURCE_DIR}/uac.manifest"
# )

# target_precompile_headers(${TARGET_NAME} PRIVATE pch_header.h)

# target_link_libraries(${TARGET_NAME}
#    <LIB_NAME>
# )

set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR}/output/${CMAKE_C_COMPILER_ID}-${CMAKE_C_COMPILER_ARCHITECTURE_ID}-${CMAKE_BUILD_TYPE})

install(TARGETS ${TARGET_NAME}
	RUNTIME_DEPENDENCIES
	PRE_EXCLUDE_REGEXES "system32/|((api-ms-).*\\.dll)|/usr/|/lib/|/lib64/"
	POST_EXCLUDE_REGEXES "system32/|((api-ms-).*\\.dll)|/usr/|/lib/|/lib64/"
	RUNTIME DESTINATION bin
	LIBRARY DESTINATION lib
	ARCHIVE DESTINATION lib)

# install(FILES ${SOURCE_FILES}
#    DESTINATION src)
