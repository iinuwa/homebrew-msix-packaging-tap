class MsixPackaging < Formula
  desc "MSIX SDK"
  homepage "https://github.com/microsoft/msix-packaging"
  url "https://github.com/microsoft/msix-packaging/archive/efeb9dad695a200c2beaddcba54a52c8320bd135.tar.gz"
  sha256 "87e038dd3eaec84d03d40b2b81ca4eab7ae1610fe917eae4e130f5d7e321236e"
  license "MIT"

  depends_on "cmake" => :build
  depends_on "llvm" => :build
  depends_on "ninja" => :build

  patch :DATA

  def install
    osx_arch = if Hardware::CPU.arm64?
      "arm64"
    else
      "x86_64"
    end

    builddir = "build"
    system "cmake",
      "-S", ".",
      "-B", builddir,
      "-DXML_PARSER=xerces",
      "-DSKIP_BUNDLES=off",
      "-DASAN=off",
      "-DUSE_VALIDATION_PARSER=on",
      "-DMSIX_PACK=on",
      "-DMSIX_SAMPLES=off",
      "-DMSIX_TESTS=on",
      "-DCMAKE_OSX_ARCHITECTURES=#{osx_arch}",
      "-DCMAKE_TOOLCHAIN_FILE=../cmake/macos.cmake",
      "-DUSE_MSIX_SDK_ZLIB=on",
      "-DMACOS=on",
      *std_cmake_args
    system "cmake", "--build", builddir
    system "cmake", "--install", builddir
  end

  test do
    # Test that makemsix is executable and shows help
    assert_match "usage:", shell_output("#{bin}/makemsix --help", 1)
  end
end

__END__
diff --git a/src/makemsix/CMakeLists.txt b/src/makemsix/CMakeLists.txt
index cc68cc7f..19997f4d 100644
--- a/src/makemsix/CMakeLists.txt
+++ b/src/makemsix/CMakeLists.txt
@@ -24,3 +24,21 @@ target_include_directories(${PROJECT_NAME} PRIVATE ${MSIX_BINARY_ROOT}/src/msix)
 
 add_dependencies(${PROJECT_NAME} msix)
 target_link_libraries(${PROJECT_NAME} msix)
+
+# Set RPATH for finding libmsix at runtime
+if(APPLE)
+    set_target_properties(${PROJECT_NAME} PROPERTIES
+        BUILD_RPATH "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
+        INSTALL_RPATH "@loader_path/../lib"
+    )
+elseif(UNIX)
+    set_target_properties(${PROJECT_NAME} PROPERTIES
+        BUILD_RPATH "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
+        INSTALL_RPATH "$ORIGIN/../lib"
+    )
+endif()
+
+# Install the makemsix executable
+install(TARGETS ${PROJECT_NAME}
+    RUNTIME DESTINATION bin
+)
diff --git a/src/msix/CMakeLists.txt b/src/msix/CMakeLists.txt
index 6ed53241..d30698ca 100644
--- a/src/msix/CMakeLists.txt
+++ b/src/msix/CMakeLists.txt
@@ -388,3 +388,11 @@ if(OpenSSL_FOUND)
         target_link_libraries(${PROJECT_NAME} PRIVATE crypto)
     endif()
 endif()
+
+# Install the library and headers
+install(TARGETS ${PROJECT_NAME}
+    LIBRARY DESTINATION lib
+    ARCHIVE DESTINATION lib
+    RUNTIME DESTINATION bin
+    PUBLIC_HEADER DESTINATION include/msix
+)
--
2.50.1 (Apple Git-155)

diff --git a/CMakeLists.txt b/CMakeLists.txt
index 8a7dabd6..7de1d044 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -148,7 +148,7 @@ if((MACOS) OR (IOS))
         # The "dsymutil" program will create the dSYM dir for us.
         # Strangely it takes in the executable and not the object
         # files even though it's the latter that contain the debug info.
-        # Thus it will only work if the object files are still sitting around.        
+        # Thus it will only work if the object files are still sitting around.
         find_program(DSYMUTIL_PROGRAM dsymutil)
         if (DSYMUTIL_PROGRAM)
         set(CMAKE_C_LINK_EXECUTABLE
@@ -178,10 +178,10 @@ endif()
 # Mac needed variables
 # [TODO: adapt as needed]
 set(CMAKE_MACOSX_RPATH ON)
-#set(CMAKE_SKIP_BUILD_RPATH FALSE)
-#set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
-#set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
-#set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
+set(CMAKE_SKIP_BUILD_RPATH FALSE)
+set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
+set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
+set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
 
 add_subdirectory(lib)
 message(STATUS "libs processed")
--
2.50.1 (Apple Git-155)
