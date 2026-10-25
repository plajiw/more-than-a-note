cmake_minimum_required(VERSION 3.24)
project(more_than_a_note LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(MSVC)
    add_compile_options(/utf-8)
endif()

# Must come before any BUILD_TESTING check so the option exists on the first configure.
include(CTest)

add_library(notebook_model
    core/model/notebook.cpp
    core/model/page_content.cpp
    core/model/page_history.cpp
    core/model/rich_text.cpp
    core/model/content_codec.cpp
    core/model/asset_record.cpp
)
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
        apps/desktop/ink_probe_item.cpp
        apps/desktop/ink_probe_item.h
        apps/desktop/page_editor_adapter.cpp
        apps/desktop/page_editor_adapter.h
        apps/desktop/page_repository.cpp
        apps/desktop/page_repository.h
        apps/desktop/page_test_adapter.cpp
        apps/desktop/page_test_adapter.h
        apps/desktop/notebook_schema.cpp
        apps/desktop/notebook_schema.h
        apps/desktop/notebook_store.cpp
        apps/desktop/notebook_store.h
    )
    target_include_directories(more_than_a_note PRIVATE apps/desktop)
    set_target_properties(more_than_a_note PROPERTIES
        WIN32_EXECUTABLE $<CONFIG:Release>
        MACOSX_BUNDLE TRUE
    )
    # Files under ui/ are published flat in the module, next to Main.qml.
    set(ui_files
        Theme.qml Icon.qml Kbd.qml FocusRing.qml HintToolTip.qml
        IconButton.qml ActionButton.qml FieldButton.qml InputField.qml SearchBox.qml
        AppCheckBox.qml SelectList.qml
        Island.qml ThinScrollBar.qml ScrollArea.qml
        ToolModeButton.qml ToolColorSwatch.qml EditorToolbar.qml EditorProbe.qml
        IndexHeader.qml IndexRow.qml IndexCreate.qml IndexMenu.qml IndexMenuAction.qml
        Gallery.qml
    )
    set(qml_files apps/desktop/Main.qml)
    set_source_files_properties(apps/desktop/Main.qml PROPERTIES QT_RESOURCE_ALIAS Main.qml)
    foreach(file IN LISTS ui_files)
        set_source_files_properties(apps/desktop/ui/${file} PROPERTIES QT_RESOURCE_ALIAS ${file})
        list(APPEND qml_files apps/desktop/ui/${file})
    endforeach()
    set_source_files_properties(apps/desktop/ui/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
    qt_add_qml_module(more_than_a_note
        URI MoreThanANote
        VERSION 1.0
        QML_FILES ${qml_files}
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

    # Windows/macOS install also deploys Qt libraries, plugins and QML modules.
    # The Linux install and TGZ contain the app only and require Qt 6.8+ at runtime.
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
            set(sqlite_plugin \"\${CMAKE_INSTALL_PREFIX}/share/qt6/plugins/sqldrivers/qsqlite.dll\")
            file(GET_RUNTIME_DEPENDENCIES
                EXECUTABLES \${deployed}
                LIBRARIES \"\${sqlite_plugin}\"
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
            apps/desktop/notebook_schema.cpp
            apps/desktop/notebook_schema.h
            apps/desktop/notebook_store.cpp
            apps/desktop/notebook_store.h
        )
        target_include_directories(notebook_store_tests PRIVATE apps/desktop)
        target_link_libraries(notebook_store_tests PRIVATE Qt6::Core Qt6::Sql)
        add_test(NAME notebook_store_tests COMMAND notebook_store_tests)

        find_package(Qt6 6.8 REQUIRED COMPONENTS QuickTest Test)
        qt_add_executable(workspace_quick_tests
            tests/workspace_quick_tests.cpp
            apps/desktop/ink_probe_item.cpp
            apps/desktop/ink_probe_item.h
            apps/desktop/page_editor_adapter.cpp
            apps/desktop/page_editor_adapter.h
            apps/desktop/page_repository.cpp
            apps/desktop/page_repository.h
            apps/desktop/page_test_adapter.cpp
            apps/desktop/page_test_adapter.h
            apps/desktop/notebook_schema.cpp
            apps/desktop/notebook_schema.h
            apps/desktop/notebook_store.cpp
            apps/desktop/notebook_store.h
        )
        target_include_directories(workspace_quick_tests PRIVATE apps/desktop)
        target_compile_definitions(workspace_quick_tests PRIVATE
            QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/tests/qml")
        qt_add_qml_module(workspace_quick_tests
            URI MoreThanANote
            VERSION 1.0
            OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/testqml/MoreThanANote
            NO_CACHEGEN
            QML_FILES ${qml_files}
        )
        qt_add_resources(workspace_quick_tests "assets"
            PREFIX "/"
            BASE ${CMAKE_CURRENT_SOURCE_DIR}/apps/desktop/assets
            FILES ${asset_files}
        )
        target_link_libraries(workspace_quick_tests PRIVATE
            notebook_model Qt6::Core Qt6::Gui Qt6::Quick Qt6::QuickTest
            Qt6::Qml Qt6::QuickControls2 Qt6::Sql Qt6::Svg Qt6::Test
        )
        add_test(NAME workspace_quick_tests COMMAND workspace_quick_tests)
        set_tests_properties(workspace_quick_tests PROPERTIES
            ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software")

        add_executable(notebook_schema_tests
            tests/notebook_schema_tests.cpp
            apps/desktop/notebook_schema.cpp
            apps/desktop/notebook_schema.h
        )
        target_include_directories(notebook_schema_tests PRIVATE apps/desktop)
        target_compile_definitions(notebook_schema_tests PRIVATE
            MTN_V1_FIXTURE_PATH="${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures/notebook_v1.sql")
        target_link_libraries(notebook_schema_tests PRIVATE notebook_model Qt6::Core Qt6::Sql)
        add_test(NAME notebook_schema_tests COMMAND notebook_schema_tests)

        add_executable(page_repository_tests
            tests/page_repository_tests.cpp
            apps/desktop/page_repository.cpp
            apps/desktop/page_repository.h
            apps/desktop/notebook_schema.cpp
            apps/desktop/notebook_schema.h
        )
        target_include_directories(page_repository_tests PRIVATE apps/desktop)
        target_compile_definitions(page_repository_tests PRIVATE
            MTN_V1_FIXTURE_PATH="${CMAKE_CURRENT_SOURCE_DIR}/tests/fixtures/notebook_v1.sql")
        target_link_libraries(page_repository_tests PRIVATE notebook_model Qt6::Core Qt6::Sql)
        add_test(NAME page_repository_tests COMMAND page_repository_tests)
    endif()
endif()

if(BUILD_TESTING)
    add_executable(notebook_model_tests tests/notebook_model_tests.cpp)
    target_link_libraries(notebook_model_tests PRIVATE notebook_model)
    add_test(NAME notebook_model_tests COMMAND notebook_model_tests)

    add_executable(page_content_tests tests/page_content_tests.cpp)
    target_link_libraries(page_content_tests PRIVATE notebook_model)
    add_test(NAME page_content_tests COMMAND page_content_tests)

    add_executable(page_history_tests tests/page_history_tests.cpp)
    target_link_libraries(page_history_tests PRIVATE notebook_model)
    add_test(NAME page_history_tests COMMAND page_history_tests)

    add_executable(content_codec_tests tests/content_codec_tests.cpp)
    target_link_libraries(content_codec_tests PRIVATE notebook_model)
    add_test(NAME content_codec_tests COMMAND content_codec_tests)
endif()
