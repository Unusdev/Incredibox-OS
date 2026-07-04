@echo off
if not exist os.img goto :no_os
echo Launching IncredibOS...
"C:\Program Files\qemu\qemu-system-x86_64" -fda os.img
exit /b
:no_os
echo Error: os.img not found! Please run 'build' first.
pause