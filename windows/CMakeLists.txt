cmake_minimum_required(VERSION 3.14)
if(POLICY CMP0153)
  cmake_policy(SET CMP0153 NEW)
endif()
set(PROJECT_NAME "flutter_tts")
project(${PROJECT_NAME} LANGUAGES CXX)

################ NuGet intall begin ################
find_program(NUGET_EXE NAMES nuget)
if(NOT NUGET_EXE)
	message("NUGET.EXE not found.")
	message(FATAL_ERROR "Please install this executable, and run CMake again.")
endif()

execute_process(
  COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/nuget.exe install -OutputDirectory ${CMAKE_CURRENT_SOURCE_DIR}/packages Microsoft.Windows.CppWinRT -Version 2.0.210312.4
)
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
target_compile_features(${PLUGIN_NAME} PUBLIC cxx_std_20)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

if(MSVC)
    target_compile_options(${PLUGIN_NAME} PRIVATE "/await")
endif()

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
