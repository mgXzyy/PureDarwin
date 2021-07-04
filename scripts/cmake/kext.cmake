function(add_kext_bundle name)
    cmake_parse_arguments(SL "KERNEL_PRIVATE" "MACOSX_VERSION_MIN;INFO_PLIST" "" ${ARGN})

    if(SL_MACOSX_VERSION_MIN)
        add_darwin_shared_library(${name} MODULE MACOSX_VERSION_MIN ${SL_MACOSX_VERSION_MIN})
    else()
        add_darwin_shared_library(${name} MODULE)
    endif()

    set_property(TARGET ${name} PROPERTY PREFIX "")
    set_property(TARGET ${name} PROPERTY SUFFIX "")

    target_compile_definitions(${name} PRIVATE TARGET_OS_OSX KERNEL)
    target_compile_options(${name} PRIVATE -fapple-kext)
    target_link_options(${name} PRIVATE -fapple-kext)
    target_link_options(${name} PRIVATE "LINKER:-bundle")
    target_link_options(${name} PRIVATE "SHELL:-undefined dynamic_lookup")

    if(SL_KERNEL_PRIVATE)
        target_compile_definitions(${name} PRIVATE KERNEL_PRIVATE)
        target_link_libraries(${name} PRIVATE xnu_kernel_private_headers)
    endif()

    target_link_libraries(${name} PRIVATE xnu_kernel_headers AvailabilityHeaders)

    set_property(TARGET ${name} PROPERTY BUNDLE TRUE)
    set_property(TARGET ${name} PROPERTY BUNDLE_EXTENSION kext)

    if(SL_INFO_PLIST)
        get_filename_component(SL_INFO_PLIST ${SL_INFO_PLIST} ABSOLUTE)
        set_property(TARGET ${name} PROPERTY MACOSX_BUNDLE_INFO_PLIST ${SL_INFO_PLIST})
    else()
        message(SEND_ERROR "INFO_PLIST argument must be provided to add_darwin_kext()")
    endif()
endfunction()

function(add_kmod_info target)
    cmake_parse_arguments(KEXT "" "IDENTIFIER;VERSION;REALMAIN;ANTIMAIN" "" ${ARGN})

    if(NOT KEXT_IDENTIFIER)
        get_property(KEXT_IDENTIFIER TARGET ${target} PROPERTY MACOSX_BUNDLE_GUI_IDENTIFIER)
    endif()
    if(NOT KEXT_IDENTIFIER)
        message(SEND_ERROR "MACOSX_BUNDLE_GUI_IDENTIFIER is not set on kext target ${target}")
        return()
    endif()

    if(NOT KEXT_VERSION)
        get_property(KEXT_VERRSION TARGET ${target} PROPERTY MACOSX_BUNDLE_BUNDLE_VERSION)
    endif()
    if(NOT KEXT_VERSION)
        message(SEND_ERROR "MACOSX_BUNDLE_BUNDLE_VERSION is not set on kext target ${target}")
        return()
    endif()

    if(NOT KEXT_REALMAIN)
        set(KEXT_REALMAIN "0")
    endif()
    if(NOT KEXT_ANTIMAIN)
        set(KEXT_ANTIMAIN "0")
    endif()

    configure_file(${PUREDARWIN_SOURCE_DIR}/scripts/cmake/templates/kmod_info.c ${CMAKE_CURRENT_BINARY_DIR}/kmod_info.c)
    target_sources(${target} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/kmod_info.c)
    target_link_libraries(${target} PRIVATE libkmod)
endfunction()
