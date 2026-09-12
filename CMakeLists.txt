cmake_minimum_required(VERSION 3.16)
project(lingust VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Network
    Sql
    Widgets
    Concurrent
)

qt_standard_project_setup(REQUIRES 6.8)
qt_policy(SET QTP0004 NEW)

# 显式标记 DesignTokens 为 QML Singleton（QTP0004 自动生成可能漏识别）
set_source_files_properties(ui/components/DesignTokens.qml PROPERTIES QT_QML_SINGLETON TRUE)

set(SOURCES
    app/main.cpp
    app/Application.cpp
    app/Application.h
    core/state/AppState.cpp
    core/state/AppState.h
    core/auth/AuthManager.cpp
    core/auth/AuthManager.h
    core/auth/ISecureCredentialStore.h
    core/window/TranslatorWindow.cpp
    core/window/TranslatorWindow.h
    core/translation/TranslationManager.cpp
    core/translation/TranslationManager.h
    core/translation/OfflineDictionary.cpp
    core/translation/OfflineDictionary.h
    providers/ITranslationProvider.h
    providers/gemini/GeminiProvider.cpp
    providers/gemini/GeminiProvider.h
    providers/deepl/DeepLProvider.cpp
    providers/deepl/DeepLProvider.h
    providers/youdao/YoudaoProvider.cpp
    providers/youdao/YoudaoProvider.h
    providers/fallback/FallbackProvider.cpp
    providers/fallback/FallbackProvider.h
    infrastructure/database/DatabaseManager.cpp
    infrastructure/database/DatabaseManager.h
    infrastructure/crash/CrashHandler.cpp
    infrastructure/crash/CrashHandler.h
    infrastructure/crash/SafeExecutor.cpp
    infrastructure/crash/SafeExecutor.h
    core/selection/SelectionManager.cpp
    core/selection/SelectionManager.h
    core/window/TrayManager.cpp
    core/window/TrayManager.h
    core/capture/CaptureManager.cpp
    core/capture/CaptureManager.h
    core/ocr/OcrManager.cpp
    core/ocr/OcrManager.h
    core/media/MediaSessionService.cpp
    core/media/MediaSessionService.h
    providers/lyrics/ILyricsProvider.h
    providers/lyrics/LrclibLyricsProvider.cpp
    providers/lyrics/LrclibLyricsProvider.h
    providers/ocr/IOcrProvider.h
    platform/windows/ocr/WindowsOcrProvider.cpp
    platform/windows/ocr/WindowsOcrProvider.h
    platform/windows/hotkey/HotkeyManager.cpp
    platform/windows/hotkey/HotkeyManager.h
    platform/windows/mousehook/MouseHookManager.cpp
    platform/windows/mousehook/MouseHookManager.h
    platform/windows/media/WindowsMediaManager.cpp
    platform/windows/media/WindowsMediaManager.h
)

qt_add_executable(lingust ${SOURCES})

add_custom_command(TARGET lingust POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/platform/windows/media/SystemMediaBridge.ps1"
        "$<TARGET_FILE_DIR:lingust>/SystemMediaBridge.ps1"
    COMMENT "Copying Windows system media bridge"
)

add_custom_command(TARGET lingust POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/platform/windows/ocr/SystemOcrBridge.ps1"
        "$<TARGET_FILE_DIR:lingust>/SystemOcrBridge.ps1"
    COMMENT "Copying Windows OCR bridge"
)

qt_add_qml_module(lingust
    URI Linguist
    VERSION 1.0
    QML_FILES
        ui/Main.qml
        ui/components/GlassSurface.qml
        ui/components/AuroraBorder.qml
        ui/components/TrafficLights.qml
        ui/components/HoverScrollText.qml
        ui/components/MarqueeText.qml
        ui/components/IconButton.qml
        ui/components/LanguageSelector.qml
        ui/pill/PillView.qml
        ui/pill/MusicIslandCard.qml
        ui/card/CardView.qml
        ui/card/WordDetailView.qml
        ui/card/SearchInput.qml
        ui/card/LayoutScalePanel.qml
        ui/card/HistoryView.qml
        ui/card/ScreenshotTranslationView.qml
        ui/card/ScreenshotPreview.qml
        ui/overlay/ScreenCaptureOverlay.qml
        ui/settings/SettingsView.qml
        ui/settings/AccountPanel.qml
    RESOURCES
        ui/components/DesignTokens.qml
        resources/icons/crop.svg
        resources/icons/camera.svg
        resources/icons/pin.svg
        resources/icons/settings.svg
        resources/icons/sliders.svg
        resources/icons/volume.svg
        resources/icons/copy.svg
        resources/icons/check.svg
        resources/icons/search.svg
        resources/icons/close.svg
        resources/icons/maximize.svg
        resources/icons/heart.svg
        resources/icons/history.svg
        resources/icons/swap.svg
        resources/icons/sparkles.svg
        resources/icons/type.svg
        resources/icons/plus.svg
        resources/icons/minus.svg
        resources/icons/eye.svg
        resources/icons/eye-off.svg
        resources/icons/external-link.svg
        resources/icons/rotate-ccw.svg
        resources/icons/music.svg
        resources/icons/play.svg
        resources/icons/pause.svg
        resources/icons/skip-back.svg
        resources/icons/skip-forward.svg
        resources/icons/disc.svg
        resources/icons/user.svg
        resources/icons/mail.svg
        resources/icons/smartphone.svg
        resources/icons/message-circle.svg
        resources/icons/log-out.svg
        resources/icons/shield-check.svg
)

target_link_libraries(lingust PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::Sql
    Qt6::Widgets
    Qt6::Concurrent
)

if(WIN32)
    target_sources(lingust PRIVATE
        platform/windows/window/WindowsResizeSession.cpp
        platform/windows/auth/WindowsCredentialStore.cpp
        platform/windows/auth/WindowsCredentialStore.h
    )
    target_link_libraries(lingust PRIVATE dwmapi gdiplus advapi32)
    target_compile_definitions(lingust PRIVATE WIN32_LEAN_AND_MEAN NOMINMAX UNICODE _UNICODE)

    if(MSVC)
        # MSVC: UTF-8 源码/执行字符集 + 标准 C++ 宏 + 合理警告级别
        target_compile_options(lingust PRIVATE /utf-8 /Zc:__cplusplus /W3 /permissive-)
        # Release: O2 优化; Debug: /Zi 调试信息
        target_compile_options(lingust PRIVATE $<$<CONFIG:Release>:/O2> $<$<CONFIG:Debug>:/Zi>)
    endif()
endif()

# 输出目录
set_target_properties(lingust PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

include(CTest)
if(BUILD_TESTING)
    find_package(Qt6 6.8 REQUIRED COMPONENTS Test)
    qt_add_executable(lingust_input_method_test
        tests/input_method_smoke.cpp
        core/window/TranslatorWindow.cpp
        core/window/TranslatorWindow.h
        core/window/WindowResizeSession.h
    )
    set_target_properties(lingust_input_method_test PROPERTIES WIN32_EXECUTABLE FALSE)
    target_include_directories(lingust_input_method_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(lingust_input_method_test PRIVATE
        Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick
    )
    add_test(NAME input_method_smoke
        COMMAND lingust_input_method_test -platform offscreen
    )

    qt_add_executable(lingust_auth_manager_test
        tests/auth_manager_smoke.cpp
        core/auth/AuthManager.cpp
        core/auth/AuthManager.h
        core/auth/ISecureCredentialStore.h
        infrastructure/database/DatabaseManager.cpp
        infrastructure/database/DatabaseManager.h
    )
    set_target_properties(lingust_auth_manager_test PROPERTIES WIN32_EXECUTABLE FALSE)
    target_include_directories(lingust_auth_manager_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(lingust_auth_manager_test PRIVATE
        Qt6::Core Qt6::Gui Qt6::Network Qt6::Sql Qt6::Test
    )
    add_test(NAME auth_manager_smoke COMMAND lingust_auth_manager_test)

    if(WIN32)
        qt_add_executable(lingust_windows_credential_test
            tests/windows_credential_store_smoke.cpp
            platform/windows/auth/WindowsCredentialStore.cpp
            platform/windows/auth/WindowsCredentialStore.h
            core/auth/ISecureCredentialStore.h
        )
        set_target_properties(lingust_windows_credential_test PROPERTIES WIN32_EXECUTABLE FALSE)
        target_include_directories(lingust_windows_credential_test PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
        target_link_libraries(lingust_windows_credential_test PRIVATE Qt6::Core Qt6::Test advapi32)
        add_test(NAME windows_credential_store_smoke COMMAND lingust_windows_credential_test)
    endif()
endif()
