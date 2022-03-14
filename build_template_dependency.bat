@echo off
::		Custom Build Script 2.1
::
::       Custom library support
::
::     Set Compiler Settings Here


:: Compiler Specification And Build Settings
set CPP=c++
set GPP=g++
set GCC=gcc
set OUTPUT=program.exe
set DEBUGMODE=0
set COMMANDLINE=1

set VERBOSE=0

set REBUILD_SOURCE_DIRECTORIES=1
set REBUILD_SOURCE_LIBRARIES=0
set ASYNC_BUILD=1

:: Configure Source For Compiling And Additional Custom Library Directories / Names
set SOURCE_DIRECTORIES=src
set INCLUDE_DIRECTORIES=include
set LIBRARY_DIRECTORIES=
set LIBRARY_NAMES=


:: Additional Compiler Flags And Configuration Settings
set CPP_COMPILER_FLAGS=-std=c++20
set C_COMPILER_FLAGS=
set OBJECT_DIRECTORY=.objs

:: Advanced / Extra Command Line Settings For Building / Linking
set ADDITIONAL_INCLUDEDIRS=
set ADDITIONAL_LIBRARIES=-static-libstdc++ -static-libgcc
set ADDITIONAL_LIBDIRS=


::------Not working------
set LINK_ONLY=0
::------------

:: Custom Library Support Directory Names
set LIBRARY_DIRECTORY_NAME=lib\windows
set INCLUDE_DIRECTORY_NAME=include
set SOURCE_DIRECTORY_NAME=src

:: Single File Compilation
set SINGLE_FILE=%1

:: ---------- Build Script Start -----------

cls
:: Force current directory to program directory

echo Starting Build Process...

pushd "%~dp0"

setlocal enabledelayedexpansion

:: Find The Single File To Remove When Targeting A Build File
if not [%SINGLE_FILE%] == [] (

	set REBUILD_SOURCE_DIRECTORIES=0
	set REBUILD_SOURCE_LIBRARIES=0
	set _DELETE=*%SINGLE_FILE%.o
	
	echo Cleanup %SINGLE_FILE%...

	(for %%D in (%SOURCE_DIRECTORIES%) do (
		del /S /Q "%%D\%OBJECT_DIRECTORY%\!_DELETE!" 2>nul
	))

	(for %%D in (%LIBRARY_SOURCE_DIRECTORIES%) do (
		del /S /Q "%%D\%OBJECT_DIRECTORY%\!_DELETE!" 2>nul
	))
)

:: Configure Raw MinGW Command Line From Custom Settings
(for %%D in (%INCLUDE_DIRECTORIES%) do (
	set ADDITIONAL_INCLUDEDIRS=!ADDITIONAL_INCLUDEDIRS! -I%%D
))

:: Source directories are separated for libraries
set LIBRARY_SOURCE_DIRECTORIES=

(for %%D in (%LIBRARY_DIRECTORIES%) do (
	set ADDITIONAL_INCLUDEDIRS=!ADDITIONAL_INCLUDEDIRS! -I%%D\!INCLUDE_DIRECTORY_NAME!
	set LIBRARY_SOURCE_DIRECTORIES=!LIBRARY_SOURCE_DIRECTORIES! %%D\!SOURCE_DIRECTORY_NAME!
	set ADDITIONAL_LIBDIRS=!ADDITIONAL_LIBDIRS! -L%%D\!LIBRARY_DIRECTORY_NAME!
))

(for %%D in (%LIBRARY_NAMES%) do (
	set ADDITIONAL_LIBRARIES=!ADDITIONAL_LIBRARIES! -l%%D
))

:: Debugging Info
:: echo %ADDITIONAL_INCLUDEDIRS%
:: echo %ADDITIONAL_LIBDIRS%
:: echo %ADDITIONAL_LIBRARIES%
:: echo %SOURCE_DIRECTORIES%
::----------------------


echo Cleaning Up Old Application...
taskkill /F /IM %OUTPUT%
del %OUTPUT% 2>nul
taskkill /F /IM "ld.exe" 2>nul

if %LINK_ONLY% GTR 0 (
	goto linker
)

if %DEBUGMODE% GTR 0 (
	set DEBUG_INFO=-ggdb -g
) else (
	set DEBUG_INFO=-s
)

if %ASYNC_BUILD% GTR 0 (
	set WAIT=
) else (
	set WAIT=/WAIT
)

set OBJECT_DIRS=

:: Delete objects from object directories / populate object directories array
(for %%D in (%SOURCE_DIRECTORIES%) do (
	if %REBUILD_SOURCE_DIRECTORIES% GTR 0 (
		del /S /Q "%%D\%OBJECT_DIRECTORY%\*.o" 2>nul
	)
	set OBJECT_DIRS=!OBJECT_DIRS! %%D\!OBJECT_DIRECTORY!
))

(for %%D in (%LIBRARY_SOURCE_DIRECTORIES%) do (
	if %REBUILD_SOURCE_LIBRARIES% GTR 0 (
		del /S /Q "%%D\%OBJECT_DIRECTORY%\*.o" 2>nul
	)
	set OBJECT_DIRS=!OBJECT_DIRS! %%D\!OBJECT_DIRECTORY!
))

:: Create Object Directory Structure
(for %%D in (%SOURCE_DIRECTORIES%) do (
	if exist %%D\ (
		if not exist %%D\%OBJECT_DIRECTORY% (
			echo Creating Object Directory Structure...
			mkdir %%D\%OBJECT_DIRECTORY%
		)
	)
))
(for %%D in (%LIBRARY_SOURCE_DIRECTORIES%) do (
	if exist %%D\ (
		if not exist %%D\%OBJECT_DIRECTORY% (
			echo Creating Object Directory Structure...
			mkdir %%D\%OBJECT_DIRECTORY%
		)
	)
))

echo Begin Building...

(for %%D in (%LIBRARY_SOURCE_DIRECTORIES%) do (
	echo Building Library Files For %%D...
	if exist %%D\ (
		call :compile_function %%D cpp %CPP% "%CPP_COMPILER_FLAGS%"
		call :compile_function %%D c %GCC% "%C_COMPILER_FLAGS%"
	) else (
		echo Skipping non-existent directory...
	)
))

(for %%D in (%SOURCE_DIRECTORIES%) do (
	echo Building Source Files For %%D...
	if exist %%D\ (
		call :compile_function %%D cpp %CPP% "%CPP_COMPILER_FLAGS%"
		call :compile_function %%D c %GCC% "%C_COMPILER_FLAGS%"
	) else (
		echo Skipping non-existent directory...
	)
))

goto loop

:: ---------- Compiler Function -----------
::	SourceDirctory FileExtention Compiler CompilerFlags
:compile_function
	set OBJ_DIR=%1\%OBJECT_DIRECTORY%
	for /R %1 %%F in (*.%2) do (
		if not exist !OBJ_DIR!\%~n3_%%~nF.o (
			echo Building %~n3_%%~nF.o
			start /B %WAIT% "%%~nF.o" %3 %ADDITIONAL_INCLUDEDIRS% %~4 %DEBUG_INFO% -c %%F -o !OBJ_DIR!\%~n3_%%~nF.o

			if %VERBOSE% GTR 0 (
				echo %3 %ADDITIONAL_INCLUDEDIRS% %~4 %DEBUG_INFO% -c %%F -o !OBJ_DIR!\%~n3_%%~nF.o
			)
		)
	)
goto close
::--------------------------------------

:: Wait for building process to finish
:loop
set /A count=0
for /f %%G in ('tasklist ^| find /c "%CPP%"') do ( set /A count+=%%G )
for /f %%G in ('tasklist ^| find /c "%GCC%"') do ( set /A count+=%%G )
for /f %%G in ('tasklist ^| find /c "%GPP%"') do ( set /A count+=%%G )

if %count%==0 (
	goto linker
) else (
	timeout /t 2 /nobreak>nul
	goto loop
)

:linker

set "files="

:: Find All Object Files
(for %%D in (%OBJECT_DIRS%) do (
	if exist %%D\ (
		for /f "delims=" %%A in ('dir /b /a-d "%%D\*.o" ') do set "files=!files! %%D\%%A"
	)
))

:link
echo Linking Executable...

if %COMMANDLINE% GTR 0 (
	set MWINDOWS=
) else (
	set MWINDOWS=-mwindows
)

if %VERBOSE% GTR 0 (
	echo %GPP% %ADDITIONAL_LIBDIRS% -o %OUTPUT% %files% %ADDITIONAL_LIBRARIES% %MWINDOWS%
)

%GPP% %ADDITIONAL_LIBDIRS% -o %OUTPUT% %files% %ADDITIONAL_LIBRARIES% %MWINDOWS%

:finish
if exist .\%OUTPUT% (
	echo Build Success!
) else (
	echo Build Failed!
)


:: This control is for batch processing functions to return
:close