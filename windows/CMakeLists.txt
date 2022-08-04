cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "flutter_tts")
project(${PROJECT_NAME} LANGUAGES CXX)
include(FetchContent)

################ NuGet intall begin ################
FetchContent_Declare(nuget
  URL "https://dist.nuget.org/win-x86-commandline/v6.0.0/nuget.exe"
  URL_HASH SHA256=04eb6c4fe4213907e2773e1be1bbbd730e9a655a3c9c58387ce8d4a714a5b9e1
  DOWNLOAD_NO_EXTRACT true
)

find_program(NUGET_EXE NAMES nuget)
if(NOT NUGET_EXE)
  message("Nuget.exe not found, trying to download or use cached version.")
  FetchContent_MakeAvailable(nuget)
  set(NUGET_EXE ${nuget_SOURCE_DIR}/nuget.exe)
endif()

exec_program(${NUGET_EXE}
    ARGS install "Microsoft.Windows.CppWinRT" -Version 	2.0.210503.1 -ExcludeVersion -OutputDirectory ${CMAKE_BINARY_DIR}/packages)
################ NuGet install end ################

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_tts_plugin")

add_library(${PLUGIN_NAME} SHARED
  "flutter_tts_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin
set(flutter_tts_bundled_libraries
  ""
  PARENT_SCOPE
################ NuGet import begin ################
set_target_properties(${PLUGIN_NAME} PROPERTIES VS_PROJECT_IMPORT
  ${CMAKE_BINARY_DIR}/packages/Microsoft.Windows.CppWinRT/build/native/Microsoft.Windows.CppWinRT.props
)

target_link_libraries(${PLUGIN_NAME} PRIVATE
  ${CMAKE_BINARY_DIR}/packages/Microsoft.Windows.CppWinRT/build/native/Microsoft.Windows.CppWinRT.targets
)
################ NuGet import end ################

)
