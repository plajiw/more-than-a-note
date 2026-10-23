cmake_minimum_required(VERSION 3.24)
project(more_than_a_note LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Must come before any BUILD_TESTING check so the option exists on the first configure.
include(CTest)

add_library(notebook_model core/model/notebook.cpp)
target_include_directories(notebook_model PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/core/model)

option(BUILD_DESKTOP "Build the Qt desktop application" ON)
if(BUILD_DESKTOP)
    find_package(Qt6 6.8 COMPONENTS Core Gui Quick Qml QuickControls2 Sql Svg)
    if(NOT Qt6_FOUND)
        message(FATAL_ERROR
            "Qt 6.8+ was not found. Point CMAKE_PREFIX_PATH at your Qt install "
            "(e.g. -DCMAKE_PREFIX_PATH=C:/Qt/6.8.3/msvc2022_64) or configure with "
            "-DBUILD_DESKTOP=OFF to build only the core library and its tests.")
    endif()
    qt_standard_project_setup(REQUIRES 6.8)
    qt_add_executable(more_than_a_note
        apps/desktop/main.cpp
        apps/desktop/notebook_store.cpp
        apps/desktop/notebook_store.h
    )
    set_target_properties(more_than_a_note PROPERTIES
        WIN32_EXECUTABLE TRUE
        MACOSX_BUNDLE TRUE
    )
    set_source_files_properties(apps/desktop/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)
    set_source_files_properties(apps/desktop/ui/Theme.qml PROPERTIES
        QT_RESOURCE_ALIAS Theme.qml
        QT_QML_SINGLETON_TYPE TRUE
    )
    set_source_files_properties(apps/desktop/ui/Icon.qml PROPERTIES QT_RESOURCE_ALIAS Icon.qml)
    set_source_files_properties(apps/desktop/ui/Gallery.qml PROPERTIES QT_RESOURCE_ALIAS Gallery.qml)
    qt_add_qml_module(more_than_a_note
        URI MoreThanANote
        VERSION 1.0
        QML_FILES
            apps/desktop/Main.qml
            apps/desktop/ui/Theme.qml
            apps/desktop/ui/Icon.qml
            apps/desktop/ui/Gallery.qml
    )

    # Fonts and icons are embedded so the app looks the same on every machine.
    # Their licenses live next to them in apps/desktop/assets.
    file(GLOB_RECURSE asset_files CONFIGURE_DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/apps/desktop/assets/fonts/*.ttf
        ${CMAKE_CURRENT_SOURCE_DIR}/apps/desktop/assets/icons/*.svg
    )
    qt_add_resources(more_than_a_note "assets"
        PREFIX "/"
        BASE ${CMAKE_CURRENT_SOURCE_DIR}/apps/desktop/assets
        FILES ${asset_files}
    )
    target_link_libraries(more_than_a_note PRIVATE
        notebook_model Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml Qt6::QuickControls2 Qt6::Sql Qt6::Svg
    )

    # `cmake --install` produces a self-contained folder: the app plus the Qt
    # libraries, plugins (including the SQLite driver) and QML modules it uses.
    include(GNUInstallDirs)
    install(TARGETS more_than_a_note
        BUNDLE DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
    # On Linux the app uses the distro's Qt packages; a portable Linux bundle
    # (AppImage/Flatpak) is a separate step.
    if(WIN32 OR APPLE)
        qt_generate_deploy_qml_app_script(
            TARGET more_than_a_note
            OUTPUT_SCRIPT deploy_script
        )
        install(SCRIPT ${deploy_script})
    endif()

    # windeployqt copies Qt and the compiler runtime only. A MinGW Qt (e.g. MSYS2)
    # also depends on third-party DLLs (ICU, zstd, freetype...) that live next to
    # the compiler, so copy whatever the deployed binaries still need from there.
    if(MINGW)
        get_filename_component(mingw_bin_dir "${CMAKE_CXX_COMPILER}" DIRECTORY)
        install(CODE "
            if(POLICY CMP0207)
                cmake_policy(SET CMP0207 NEW)
            endif()
            set(bin_dir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\")
            file(GLOB_RECURSE deployed \"\${bin_dir}/*.exe\" \"\${bin_dir}/*.dll\")
            file(GET_RUNTIME_DEPENDENCIES
                EXECUTABLES \${deployed}
                RESOLVED_DEPENDENCIES_VAR resolved
                UNRESOLVED_DEPENDENCIES_VAR unresolved
                DIRECTORIES \"${mingw_bin_dir}\" \"\${bin_dir}\"
                PRE_EXCLUDE_REGEXES \"^api-ms-\" \"^ext-ms-\"
                POST_INCLUDE_REGEXES \"^${mingw_bin_dir}/\"
                POST_EXCLUDE_REGEXES \".*\"
            )
            foreach(dll IN LISTS resolved)
                get_filename_component(name \"\${dll}\" NAME)
                if(NOT EXISTS \"\${bin_dir}/\${name}\")
                    file(COPY \"\${dll}\" DESTINATION \"\${bin_dir}\")
                endif()
            endforeach()
        ")
    endif()

    set(CPACK_PACKAGE_NAME more-than-a-note)
    set(CPACK_PACKAGE_VERSION 0.1.0)
    if(WIN32)
        set(CPACK_GENERATOR ZIP)
    else()
        set(CPACK_GENERATOR TGZ)
    endif()
    include(CPack)
    if(BUILD_TESTING)
        add_executable(notebook_store_tests
            tests/notebook_store_tests.cpp
            apps/desktop/notebook_store.cpp
            apps/desktop/notebook_store.h
        )
        target_include_directories(notebook_store_tests PRIVATE apps/desktop)
        target_link_libraries(notebook_store_tests PRIVATE Qt6::Core Qt6::Sql)
        add_test(NAME notebook_store_tests COMMAND notebook_store_tests)
    endif()
endif()

if(BUILD_TESTING)
    add_executable(notebook_model_tests tests/notebook_model_tests.cpp)
    target_link_libraries(notebook_model_tests PRIVATE notebook_model)
    add_test(NAME notebook_model_tests COMMAND notebook_model_tests)
endif()
