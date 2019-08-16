@ECHO OFF
TITLE Sublime Text Portable Tool
SET PATH=%b2eincfilepath%;%PATH%

SET VERSION=v1.3.1

SET FILE_ICON_MENU=icon_menu_st.ico
SET FILE_ICON_ASSOCIATED=icon_associated_st.ico
SET FILE_ICON_EXECUTABLE=icon_executable_st.ico

:: used as a proxy to subl.exe for hijacking notepad.exe?
IF /I [%1] == ["C:\Windows\system32\NOTEPAD.EXE"] GOTO debuggerProxy


:menu
ECHO Sublime Text Portable Tool %VERSION% by Jack Cherng ^<jfcherng@gmail.com^>
ECHO ------------------------------------------------------------------------------
ECHO.
ECHO   Operations:
ECHO   1: Add "Open with Sublime Text" to context menu (%FILE_ICON_MENU%)
ECHO   2: Remove "Open with Sublime Text" from context menu
ECHO   3: Add file associations (ext_st.txt, %FILE_ICON_ASSOCIATED%)
ECHO   4: Remove file associations
ECHO   5: Set Sublime Text as the default text editor (hijack notepad.exe)
ECHO   6: Restore notepad.exe as the default text editor
ECHO   7: Change the icon of sublime_text.exe (%FILE_ICON_EXECUTABLE%)
ECHO   8: Exit
ECHO.
ECHO   Some notes:
ECHO   1. Put this .exe file with sublime_text.exe.
ECHO   2. Write file exetensions in ext_st.txt line by line
ECHO.
ECHO ------------------------------------------------------------------------------
ECHO.


:check_sublime_text_exist
IF EXIST "sublime_text.exe" (
    GOTO prepareFiles
) ELSE (
    ECHO Cannot find "sublime_text.exe"...
    PAUSE >NUL
    EXIT
)


:prepareFiles
FOR %%f IN (
    "%FILE_ICON_ASSOCIATED%"
    "%FILE_ICON_EXECUTABLE%"
    "%FILE_ICON_MENU%"
) DO (
    IF NOT EXIST "%%f" copy "%b2eincfilepath%\%%f" . >NUL
)
GOTO begin


:begin
SET /p u="What are you going to do? "
IF "%u%" == "1" GOTO regMenu
IF "%u%" == "2" GOTO unregMenu
IF "%u%" == "3" GOTO sublime_text_file
IF "%u%" == "4" GOTO un_sublime_text_file
IF "%u%" == "5" GOTO set_sublime_default_editor
IF "%u%" == "6" GOTO unset_sublime_default_editor
IF "%u%" == "7" GOTO change_program_icon
IF "%u%" == "8" EXIT
GOTO begin


:regMenu
:: for files
reg add "HKCR\*\shell\Sublime Text" /ve /d "Open with Sublime Text" /f
reg add "HKCR\*\shell\Sublime Text" /v "Icon" /d "%CD%\%FILE_ICON_MENU%" /f
reg add "HKCR\*\shell\Sublime Text\command" /ve /d "%CD%\sublime_text.exe ""%%1""" /f
:: for directories
reg add "HKCR\Directory\shell\Sublime Text" /ve /d "Open with Sublime Text" /f
reg add "HKCR\Directory\shell\Sublime Text" /v "Icon" /d "%CD%\%FILE_ICON_MENU%" /f
reg add "HKCR\Directory\shell\Sublime Text\command" /ve /d "%CD%\subl.exe ""%%1""" /f
:: for directories background
reg add "HKCR\Directory\Background\shell\Sublime Text" /ve /d "Open with Sublime Text" /f
reg add "HKCR\Directory\Background\shell\Sublime Text" /v "Icon" /d "%CD%\%FILE_ICON_MENU%" /f
reg add "HKCR\Directory\Background\shell\Sublime Text\command" /ve /d "%CD%\subl.exe ""%%V""" /f
ECHO.
ECHO Done: add "Open with Sublime Text" to context menu
ECHO.
GOTO begin


:unregMenu
:: for files
reg delete "HKCR\*\shell\Sublime Text" /f
:: for directories
reg delete "HKCR\Directory\shell\Sublime Text" /f
:: for directories background
reg delete "HKCR\Directory\Background\shell\Sublime Text" /f
ECHO.
ECHO Done: remove "Open with Sublime Text" from context menu
ECHO.
GOTO begin


:sublime_text_file
IF NOT EXIST "ext_st.txt" (
    ECHO.
    ECHO Cannot find "ext_st.txt"...
    ECHO.
    GOTO begin
)

reg add "HKCR\sublime_text_file" /ve /d "Sublime Text file" /f
reg add "HKCR\sublime_text_file\DefaultIcon" /ve /d "%CD%\%FILE_ICON_ASSOCIATED%" /f
reg add "HKCR\sublime_text_file\shell\open\command" /ve /d "%CD%\sublime_text.exe ""%%1""" /f
FOR /F "eol=;" %%e IN (ext_st.txt) DO (
    :: ECHO %%e
    reg query "HKCR\.%%e" > NUL || reg add "HKCR\.%%e" /f
    FOR /f "skip=2 tokens=1,2,* delims= " %%a IN ('reg query "HKCR\.%%e" /ve') DO (
        IF NOT "%%c" == "sublime_text_file" (
            reg add "HKCR\.%%e" /v "sublime_text_backup" /d "%%c" /f
        )
    )
    assoc .%%e=sublime_text_file
)
ECHO.
ECHO Done: add file associations
ECHO.
GOTO begin


:un_sublime_text_file
IF NOT EXIST "ext_st.txt" (
    ECHO.
    ECHO Cannot find "ext_st.txt"...
    ECHO.
    GOTO begin
)

reg delete "HKCR\sublime_text_file" /f
FOR /F "eol=;" %%e IN (ext_st.txt) DO (
    :: ECHO %%e
    reg query "HKCR\.%%e" /v "sublime_text_backup" > NUL || reg add "HKCR\.%%e" /ve /f
    FOR /f "skip=2 tokens=1,2,* delims= " %%a IN ('reg query "HKCR\.%%e" /v "sublime_text_backup"') DO (
        reg add "HKCR\.%%e" /ve /d "%%c" /f
        reg delete "HKCR\.%%e" /V "sublime_text_backup" /f
    )
)
ECHO.
ECHO Done: remove file associations
ECHO.
GOTO begin


:set_sublime_default_editor
:: set self-executable to be the proxy (Debugger)
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" /v "Debugger" /t REG_SZ /d "%CD%\%~nx0" /f
ECHO.
ECHO Done: set Sublime Text as the default text editor
ECHO.
GOTO begin


:unset_sublime_default_editor
reg delete "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\notepad.exe" /f
ECHO.
ECHO Done: use notepad.exe as the default text editor
ECHO.
GOTO begin


:change_program_icon
rcedit.exe "sublime_text.exe" --set-icon "%FILE_ICON_EXECUTABLE%"
:: try to clean icon cache
ie4uinit.exe -ClearIconCache 2>NUL
DEL /F /A %USERPROFILE%\AppData\Local\IconCache.db 2>NUL
ECHO.
ECHO Done: change the icon of sublime_text.exe
ECHO.
GOTO begin


:debuggerProxy
SET _tail=%*
:: get everything after %1 as _tail
CALL SET _tail=%%_tail:*%1=%%
:: the first char must be an extra space so remove it
SET _tail=%_tail:~1%

ECHO Used as notepad.exe debugger...
ECHO.
ECHO %_tail%
ECHO.
"%~dp0\sublime_text.exe" "%_tail%"
EXIT
