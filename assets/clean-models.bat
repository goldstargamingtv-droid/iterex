@echo off
title Meshy Model Cleaner
color 0A

echo.
echo ==========================================
echo    MESHY MODEL CLEANER
echo ==========================================
echo.

cd /d "C:\Users\tyler\Desktop\siren\TemplatesWebsite\assets"

:: Find Blender
set "BLENDER="
if exist "C:\Program Files\Blender Foundation\Blender 5.0\blender.exe" set "BLENDER=C:\Program Files\Blender Foundation\Blender 5.0\blender.exe"
if exist "C:\Program Files\Blender Foundation\Blender 4.3\blender.exe" set "BLENDER=C:\Program Files\Blender Foundation\Blender 4.3\blender.exe"
if exist "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe" set "BLENDER=C:\Program Files\Blender Foundation\Blender 4.2\blender.exe"
if exist "C:\Program Files\Blender Foundation\Blender 4.1\blender.exe" set "BLENDER=C:\Program Files\Blender Foundation\Blender 4.1\blender.exe"
if exist "C:\Program Files\Blender Foundation\Blender 4.0\blender.exe" set "BLENDER=C:\Program Files\Blender Foundation\Blender 4.0\blender.exe"
if exist "C:\Program Files\Blender Foundation\Blender 3.6\blender.exe" set "BLENDER=C:\Program Files\Blender Foundation\Blender 3.6\blender.exe"

if "%BLENDER%"=="" (
    echo ERROR: Blender not found!
    echo Install Blender from blender.org
    pause
    exit /b 1
)

echo Found Blender: %BLENDER%
echo.
echo Looking for .glb files in:
echo %cd%
echo.

:: Create Python script
echo import bpy > "%TEMP%\cleanup.py"
echo import sys >> "%TEMP%\cleanup.py"
echo argv = sys.argv >> "%TEMP%\cleanup.py"
echo argv = argv[argv.index("--") + 1:] >> "%TEMP%\cleanup.py"
echo input_file = argv[0] >> "%TEMP%\cleanup.py"
echo output_file = argv[1] >> "%TEMP%\cleanup.py"
echo print(f"Processing: {input_file}") >> "%TEMP%\cleanup.py"
echo bpy.ops.wm.read_factory_settings(use_empty=True) >> "%TEMP%\cleanup.py"
echo bpy.ops.import_scene.gltf(filepath=input_file) >> "%TEMP%\cleanup.py"
echo for obj in [o for o in bpy.context.scene.objects if o.type == 'MESH']: >> "%TEMP%\cleanup.py"
echo     bpy.ops.object.select_all(action='DESELECT') >> "%TEMP%\cleanup.py"
echo     obj.select_set(True) >> "%TEMP%\cleanup.py"
echo     bpy.context.view_layer.objects.active = obj >> "%TEMP%\cleanup.py"
echo     bpy.ops.object.transform_apply(location=True, rotation=True, scale=True) >> "%TEMP%\cleanup.py"
echo     bpy.ops.object.mode_set(mode='EDIT') >> "%TEMP%\cleanup.py"
echo     bpy.ops.mesh.select_all(action='SELECT') >> "%TEMP%\cleanup.py"
echo     bpy.ops.mesh.remove_doubles(threshold=0.0001) >> "%TEMP%\cleanup.py"
echo     bpy.ops.mesh.delete_loose(use_verts=True, use_edges=True, use_faces=False) >> "%TEMP%\cleanup.py"
echo     bpy.ops.mesh.normals_make_consistent(inside=False) >> "%TEMP%\cleanup.py"
echo     bpy.ops.mesh.quads_convert_to_tris(quad_method='BEAUTY', ngon_method='BEAUTY') >> "%TEMP%\cleanup.py"
echo     bpy.ops.object.mode_set(mode='OBJECT') >> "%TEMP%\cleanup.py"
echo     bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_VOLUME', center='MEDIAN') >> "%TEMP%\cleanup.py"
echo     obj.location = (0, 0, 0) >> "%TEMP%\cleanup.py"
echo     bpy.ops.object.shade_smooth() >> "%TEMP%\cleanup.py"
echo bpy.ops.export_scene.gltf(filepath=output_file, export_format='GLB', use_selection=False, export_apply=True) >> "%TEMP%\cleanup.py"
echo print(f"Saved: {output_file}") >> "%TEMP%\cleanup.py"

:: Process each GLB file
set COUNT=0
for %%f in (*.glb) do (
    echo %%f | findstr /i "_clean.glb" >nul
    if errorlevel 1 (
        set /a COUNT+=1
        echo.
        echo Processing: %%f
        "%BLENDER%" --background --python "%TEMP%\cleanup.py" -- "%%~ff" "%%~dpnf_clean.glb"
        if exist "%%~dpnf_clean.glb" (
            echo SUCCESS: %%~nf_clean.glb created
        ) else (
            echo FAILED: %%f
        )
    )
)

if %COUNT%==0 (
    echo.
    echo No .glb files found in this folder!
    echo Make sure your Meshy models are in:
    echo %cd%
)

echo.
echo ==========================================
echo    DONE!
echo ==========================================
echo.
pause
