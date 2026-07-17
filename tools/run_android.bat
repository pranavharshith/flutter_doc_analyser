@echo off
REM Reliable flutter run when the project lives on OneDrive.
set JAVA_HOME=C:\Program Files\Java\jdk-17
set PATH=%JAVA_HOME%\bin;C:\src\flutter\bin;%PATH%
set GRADLE_PROJECT_CACHE_DIR=%LOCALAPPDATA%\flutter_doc_analyser_gradle
cd /d "%~dp0.."
flutter run %*
