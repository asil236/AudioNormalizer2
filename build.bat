@echo off
echo Building Unreal Audio Normalizer...

:: Check if required files exist
if not exist "main.py" (
    echo Error: main.py not found
    pause
    exit /b 1
)

if not exist "icon.ico" (
    echo Warning: icon.ico not found - executable will have default icon
)

if not exist "README.md" (
    echo Warning: README.md not found - help will show fallback content
)

:: Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed or not in PATH
    pause
    exit /b 1
)

:: Install dependencies
echo Installing dependencies...
pip install -r requirements.txt
pip install pyinstaller

:: Download FFmpeg if not present
if not exist "ffmpeg.exe" (
    echo Downloading FFmpeg...
    echo Please wait, this may take a few minutes...
    
    :: Try to download FFmpeg using curl (available in Windows 10+)
    curl -L "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -o "ffmpeg.zip"
    
    if exist "ffmpeg.zip" (
        echo Extracting FFmpeg...
        :: Use built-in Windows tar command (available in Windows 10+)
        tar -xf "ffmpeg.zip"
        
        :: Find and copy the executables
        for /d %%i in (ffmpeg-master-*) do (
            if exist "%%i\bin\ffmpeg.exe" (
                copy "%%i\bin\ffmpeg.exe" "."
                copy "%%i\bin\ffprobe.exe" "."
                echo FFmpeg extracted successfully
                goto :ffmpeg_done
            )
        )
        
        echo Error: Could not extract FFmpeg properly
        echo Trying alternative method...
        
        :: Fallback: try PowerShell method
        powershell -Command "& {
            try {
                Expand-Archive -Path 'ffmpeg.zip' -DestinationPath '.' -Force
                $ffmpegDir = Get-ChildItem -Directory -Name 'ffmpeg-master-*' | Select-Object -First 1
                if ($ffmpegDir) {
                    Copy-Item \"$ffmpegDir\bin\ffmpeg.exe\" -Destination '.' -Force
                    Copy-Item \"$ffmpegDir\bin\ffprobe.exe\" -Destination '.' -Force
                    Write-Host 'FFmpeg copied successfully'
                }
            } catch {
                Write-Host 'PowerShell extraction failed: ' $_.Exception.Message
            }
        }"
        
        :ffmpeg_done
        :: Clean up
        if exist "ffmpeg.zip" del "ffmpeg.zip"
        for /d %%i in (ffmpeg-master-*) do rmdir /s /q "%%i" 2>nul
    ) else (
        echo Error: Failed to download FFmpeg
        echo You can manually download FFmpeg and place ffmpeg.exe and ffprobe.exe in this folder
        echo Download from: https://github.com/BtbN/FFmpeg-Builds/releases
        pause
        exit /b 1
    )
)

:: Verify FFmpeg exists
if not exist "ffmpeg.exe" (
    echo Error: ffmpeg.exe not found
    echo Building without FFmpeg support (MP3 files may not work properly)
    
    :: Build without FFmpeg
    echo Building executable without FFmpeg...
    pyinstaller --clean --onefile --windowed ^
      --add-data "README.md;." ^
      --icon "icon.ico" ^
      --hidden-import=pydub ^
      --hidden-import=pyloudnorm ^
      --hidden-import=numpy ^
      --hidden-import=pygame ^
      --hidden-import=PyQt5 ^
      --name "UnrealAudioNormalizer" ^
      main.py
) else (
    if not exist "ffprobe.exe" (
        echo Warning: ffprobe.exe not found, only ffmpeg.exe will be included
    )
    
    :: Build with FFmpeg
    echo Building executable with FFmpeg support...
    if exist "ffprobe.exe" (
        pyinstaller --clean --onefile --windowed ^
          --add-binary "ffmpeg.exe;." ^
          --add-binary "ffprobe.exe;." ^
          --add-data "README.md;." ^
          --icon "icon.ico" ^
          --hidden-import=pydub ^
          --hidden-import=pyloudnorm ^
          --hidden-import=numpy ^
          --hidden-import=pygame ^
          --hidden-import=PyQt5 ^
          --name "UnrealAudioNormalizer" ^
          main.py
    ) else (
        pyinstaller --clean --onefile --windowed ^
          --add-binary "ffmpeg.exe;." ^
          --add-data "README.md;." ^
          --icon "icon.ico" ^
          --hidden-import=pydub ^
          --hidden-import=pyloudnorm ^
          --hidden-import=numpy ^
          --hidden-import=pygame ^
          --hidden-import=PyQt5 ^
          --name "UnrealAudioNormalizer" ^
          main.py
    )
)

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Build completed successfully!
    echo ========================================
    echo Executable is located at: dist\UnrealAudioNormalizer.exe
    if exist "ffmpeg.exe" (
        echo FFmpeg support: ENABLED
    ) else (
        echo FFmpeg support: DISABLED ^(MP3 support limited^)
    )
    echo.
) else (
    echo.
    echo ========================================
    echo Build failed!
    echo ========================================
    echo Check the error messages above for details.
    echo.
)

pause