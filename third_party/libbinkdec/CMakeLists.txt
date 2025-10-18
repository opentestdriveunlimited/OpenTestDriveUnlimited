cmake_minimum_required(VERSION 3.10...3.31)

project(
    libbinkdec
    LANGUAGES C CXX
    VERSION 1.0.0.1
    HOMEPAGE_URL "http://homepage.eircom.net/~duncandsl/avp/"
    DESCRIPTION "a bink video decoder library base on FFMPEG")

# ============================================================================
# CPack
# ============================================================================
set(CPACK_PACKAGE_VENDOR "binkdec-Project")
set(CPACK_PACKAGE_DESCRIPTION_FILE ${CMAKE_CURRENT_SOURCE_DIR}/README)
set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_CURRENT_SOURCE_DIR}/COPYING)
set(CPACK_RESOURCE_FILE_README ${CMAKE_CURRENT_SOURCE_DIR}/README)

# ============================================================================
# configuration
# ============================================================================

option(BUILD_SHARED "Enable building binkdec shared library" ON)
option(BUILD_STATIC "Enable building binkdec static library" ON)
option(CREATE_INSTALL "Enable installation of binkdec" ON)
if(WIN32)
    option(INSTALL_COMPAT_DLL "Install a copy as libbinkdec.dll" ON)
endif(WIN32)

get_property(IS_MULTI GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

if(NOT DEFINED CMAKE_BUILD_TYPE AND NOT IS_MULTI)
    message(STATUS "No CMAKE_BUILD_TYPE set -- using Release")
    set(CMAKE_BUILD_TYPE Release)
endif(NOT DEFINED CMAKE_BUILD_TYPE AND NOT IS_MULTI)

include(CMakePackageConfigHelpers)
include(CPack)
include(GNUInstallDirs)

set(CPACK_INCLUDED TRUE)

set(BINKDEC_PC ${CMAKE_BINARY_DIR}/binkdec.pc)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/binkdec.pc.cmakein ${BINKDEC_PC} @ONLY)
include_directories(${CMAKE_BINARY_DIR} ${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/include)

# ============================================================================
# binkdec
# ============================================================================

set(BINKDEC_HDRS
  "${CMAKE_CURRENT_SOURCE_DIR}/include/avfft.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/BinkAudio.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/binkdata.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/BinkDecoder.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/BinkVideo.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/BitReader.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/dct.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/dct32.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/FFmpeg_includes.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/fft-internal.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/fft.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/FileStream.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/HuffmanVLC.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/LogError.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/rdft.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/include/Util.h")

set(BINKDEC_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/avfft.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/BinkAudio.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/BinkDecoder.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/BinkVideo.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/BitReader.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/dct.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/dct32.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/fft.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/FileStream.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/HuffmanVLC.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/LogError.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/mdct.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/rdft.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/Util.cpp")

if(WIN32)
    set(binkdec_static_suffix "s")
    set(CMAKE_DEBUG_POSTFIX "-d")
endif(WIN32)

if(BUILD_SHARED)
    add_library(
        binkdec_dynamic SHARED ${BINKDEC_SRCS} ${BINKDEC_HDRS}
                    $<$<OR:$<BOOL:${WIN32}>,$<BOOL:${CYGWIN}>>:${CMAKE_CURRENT_SOURCE_DIR}/win32/binkdec.def>)
    add_library(BINKDEC::BINKDEC ALIAS binkdec_dynamic)
    target_include_directories(
        binkdec_dynamic
        PUBLIC $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
               $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
               $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

    set(INSTALL_VERSION ${binkdec_VERSION})

    if(NOT CYGWIN)
        set_target_properties(binkdec_dynamic PROPERTIES SOVERSION ${binkdec_VERSION_MAJOR}
                                              VERSION ${INSTALL_VERSION})
    endif(NOT CYGWIN)

    set_target_properties(
        binkdec_dynamic
        PROPERTIES DEFINE_SYMBOL BINKDEC_DLL
                   EXPORT_NAME BINKDEC
                   OUTPUT_NAME libbinkdec
                   RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)
endif(BUILD_SHARED)

if(BUILD_STATIC)
    add_library(binkdec_static STATIC ${BINKDEC_SRCS} ${BINKDEC_HDRS})
    add_library(BINKDEC::BINKDECSTATIC ALIAS binkdec_static)
    target_include_directories(
        binkdec_static
        PUBLIC $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
               $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}>
               $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
    set_target_properties(
        binkdec_static
        PROPERTIES EXPORT_NAME BINKDECSTATIC
                   OUTPUT_NAME binkdec${binkdec_static_suffix}
                   RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)
endif(BUILD_STATIC)

if(CREATE_INSTALL)
    if(BUILD_SHARED)
        install(
            TARGETS binkdec_dynamic
            COMPONENT Runtime
            EXPORT binkdecSharedExport
            RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
            ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
            LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}")
        install(
            EXPORT binkdecSharedExport
            FILE BINKDEC-shared.cmake
            NAMESPACE BINKDEC::
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/binkdec)
        if(INSTALL_COMPAT_DLL)
            install(
                FILES $<TARGET_FILE:binkdec_dynamic>
                COMPONENT Runtime
                RENAME libbinkdec.dll
                DESTINATION "${CMAKE_INSTALL_BINDIR}")
        endif(INSTALL_COMPAT_DLL)

        if(MSVC)
            install(
                FILES $<TARGET_PDB_FILE:binkdec_dynamic>
                COMPONENT Runtime
                DESTINATION ${CMAKE_INSTALL_BINDIR}
                CONFIGURATIONS Debug OR RelWithDebInfo
                OPTIONAL)
        endif(MSVC)
    endif(BUILD_SHARED)

    if(BUILD_STATIC)
        install(
            TARGETS binkdec_static
            COMPONENT Development
            EXPORT binkdecStaticExport
            RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
            ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
            LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}")
        install(
            EXPORT binkdecStaticExport
            FILE BINKDEC-static.cmake
            NAMESPACE BINKDEC::
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/binkdec)

        if(INSTALL_COMPAT_DLL AND MINGW)
            install(
                FILES $<TARGET_FILE:binkdec_static>
                COMPONENT Development
                RENAME libbinkdec.dll.a
                DESTINATION "${CMAKE_INSTALL_LIBDIR}")
        endif(INSTALL_COMPAT_DLL AND MINGW)
    endif(BUILD_STATIC)

    configure_package_config_file(
        ${CMAKE_SOURCE_DIR}/binkdecConfig.cmake.in
        ${CMAKE_BINARY_DIR}/BINKDECConfig.cmake
        INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/binkdec)

    write_basic_package_version_file(
        "${CMAKE_BINARY_DIR}/BINKDECConfigVersion.cmake"
        VERSION "${binkdec_VERSION}"
        COMPATIBILITY AnyNewerVersion)

    install(FILES ${CMAKE_BINARY_DIR}/BINKDECConfig.cmake
                  ${CMAKE_BINARY_DIR}/BINKDECConfigVersion.cmake
            DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/binkdec)
    install(
        FILES ${BINKDEC_HDRS}
        COMPONENT Development
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
    install(
        FILES ${BINKDEC_PC}
        COMPONENT Development
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig")
endif(CREATE_INSTALL)
