@echo off
echo Building incredibOS...

"C:\Program Files\NASM\nasm.exe" -f bin boot.asm -o boot.bin
if errorlevel 1 goto :error

"C:\Program Files\NASM\nasm.exe" -f bin kernel.asm -o kernel.bin
if errorlevel 1 goto :error

copy /b boot.bin+kernel.bin os.img >nul

echo.
echo Done! Created os.img
pause
exit /b

:error
echo.
echo Build failed.
pause