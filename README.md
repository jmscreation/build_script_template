# Build Script Template
Fast and easy-to-configure build script for MinGW GCC


## Drop this build script into your project folder and configure the following parameters:

### Compiler Paths
You can specify the compiler executable names here. If your compiler is already installed and the PATH environment is already configured to point to your compiler's bin folder, then you can leave these settings the same.
```
CPP=c++
GPP=g++
GCC=gcc
```

### Output
Here you can configure the program output name, and toggle the compiler debug symbols and command-line application.
```
OUTPUT=program.exe
DEBUGMODE=1
COMMANDLINE=1
```

### Building Settings / Debugging
Here you can enable verbosity to see exactly what the build toolchain is executing to debug your build-chain.

`AUTO_REBUILD` will autmatically find your C/CPP files that have been modified since the last compile timestamp. *There is a known bug that still needs to be resolved, which causes missing builds after 1AM.
Note: This feature only works on NTFS file systems!

You can toggle the rebuilding of your source directories or your library directories.

Async build will compile everything in a parallel mode. Disable this if you are getting lots of compiler errors, as the standard output will overlap with other errors within the compilation units. When building with this feature enabled, the script will make sure not to spawn more build tasks than there are hardware threads available.

If the Link only variable is enabled, the toolchain will skip all compiling and go straight to linking.

```
VERBOSE=0
AUTO_REBUILD=1
REBUILD_SOURCE_DIRECTORIES=1
REBUILD_SOURCE_LIBRARIES=0
ASYNC_BUILD=1
LINK_ONLY=0
```

### Project Directories
Here you will tell the build toolchain where your C/CPP, header, and library files are located.

Source directories are where your main project C/CPP files are located.

Include directories are where your main project header files are located.

Library directories are where your project libraries are located. NOTE: This is not the same as a dynamic or static library. Please see below regarding the Custom Package Library.

Library names are the static libraries or dynamic import libraries you would import, without the compiler syntax. For example, if you wanted to link against the OpenGL library, you would put `LIBRARY_NAMES=opengl32`

```
SOURCE_DIRECTORIES=src
INCLUDE_DIRECTORIES=include
LIBRARY_DIRECTORIES=
LIBRARY_NAMES=
```

### Additional Compiler/Linker Settings
Adding onto `ADDITIONAL_INCLUDEDIRS` will be appended to the compiler flags for every C/CPP file. Only use this if you need to. Otherwise, see the compiler flags section as these are appended AFTER the compiler flags.

Additional libraries are extra linker flags which will be ordered AFTER all library directories have been included, but BEFORE the static linking flags have been added.

Here you can change some of the linking settings. You can add additional linker flags onto ADDITIONAL_LIBDIRS which will be ordered BEFORE any library directories are included.
```
ADDITIONAL_INCLUDEDIRS=
ADDITIONAL_LIBRARIES=-static-libstdc++ -static-libgcc -static
ADDITIONAL_LIBDIRS=
```

Here you can change recursive settings for your include and source directories. This will recursively search all sub-directories in your specified project folders.
```
RECURSIVE_INCLUDES=0
RECURSIVE_SOURCE=0
```

### Additional Compiler Flags
These compiler flags will be appended to the list of compiler flags. This is as close to the build process you can get from the configuration options. Any compiler flag here is globally added to all files compiled.

C and C++ compiler flags are separate. Compiler flags are appended BEFORE the additional included directories.

Object directory is the directory name where object files will be stored.

```
CPP_COMPILER_FLAGS=-std=c++20
C_COMPILER_FLAGS=
OBJECT_DIRECTORY=.objs
```

### Override Custom Library Structure
It's recommended to leave this alone. This is the folder structure of a library package. For more information, see the Custom Package Library section
```
LIBRARY_DIRECTORY_NAME=lib\windows
INCLUDE_DIRECTORY_NAME=include
SOURCE_DIRECTORY_NAME=src
```


## Custom Package Library Folder Structure / Standard

This toolchain follows a specific standard for library and package management.
A library is defined as *A folder which contains the following folders: "include, "src", "lib" and may optionally contain a file named "dependency.txt"*

Each folder is used for the following purposes:
- _include_ Included as a header file search directory when compiling all C/CPP files
- _src_ Searches and compiles all C/CPP files in this directory
- _lib/windows_ Included as a static/dynamic import library search directory when linking all object files. An additional folder denoting the operating system is also used for cross-compatibility support.


This is helpful when managing a large quantity of custom libraries. When using this standardized structure on github along with the [Dependency Tracker](https://github.com/jmscreation/dependency-tracker), you can easily manage many libraries from your own github repos.

A quick setup looks like this:

- Create `dependency.txt` with the first line set to `#DEPENDENCIES`
- Each additional line in the `dependency.txt` file will contain the github url to your repository followed by whitespace followed by the repository branch name. Example: `https://github.com/jmscreation/libz		main` will point to the `libz` package under the `main` branch.
- Configure your build script and set the `LIBRARY_DIRECTORIES` to point to the libraries you will be including in your project. Example: `LIBRARY_DIRECTORIES=libraries/libz-main` will add the `libz` library under the `main` branch to your build toolchain.
- Link any static libraries that might come with the package. Example: `LIBRARY_NAMES=zlib64` will link the 64bit `zlib` static library from the `libraries/libz-main/lib/windows` directory.

Example `dependency.txt`
```
#DEPENDENCIES
https://github.com/jmscreation/libz		main
```
Partial Example `build.bat`
```
SOURCE_DIRECTORIES=src
INCLUDE_DIRECTORIES=include
LIBRARY_DIRECTORIES=libraries/libz-main
LIBRARY_NAMES=zlib64
```

## Extra Options

Currently there aren't many extra features at the moment.

You can pass a single parameter into the build script which will be used to build a single file instead of rebuilding the project.
If you wish to re-build only a specific file, pass the filename without the file extension to the build script argument 1.

Example:
Working on `main.cpp`, and need to rebuild.

`build.bat main` will find any `main.o` file and delete it, thereafter running the build process. The build process will build any missing object files and will compile `main.cpp`

### ----------------------------------------------------

This project is free to use forever.

This build script is still a work in progress, and more features will eventually be added.

### Links:

[Dependency Tracker](https://github.com/jmscreation/dependency-tracker)

[ZLIB Library In Example](https://github.com/jmscreation/libz)
