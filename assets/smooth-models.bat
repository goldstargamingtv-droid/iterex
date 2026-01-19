@echo off
title Meshy Model Smoother
color 0A

echo.
echo ==========================================
echo    MESHY MODEL SMOOTHER
echo    (Cleans + Smooths Surfaces)
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

:: Create Python script with smoothing
(
echo import bpy
echo import sys
echo import bmesh
echo.
echo argv = sys.argv
echo argv = argv[argv.index("--"^) + 1:]
echo input_file = argv[0]
echo output_file = argv[1]
echo.
echo print(f"Processing: {input_file}"^)
echo.
echo # Clear scene
echo bpy.ops.wm.read_factory_settings(use_empty=True^)
echo.
echo # Import GLB
echo bpy.ops.import_scene.gltf(filepath=input_file^)
echo.
echo # Process each mesh
echo for obj in [o for o in bpy.context.scene.objects if o.type == 'MESH']:
echo     bpy.ops.object.select_all(action='DESELECT'^)
echo     obj.select_set(True^)
echo     bpy.context.view_layer.objects.active = obj
echo.
echo     # Apply transforms
echo     bpy.ops.object.transform_apply(location=True, rotation=True, scale=True^)
echo.
echo     # Enter edit mode
echo     bpy.ops.object.mode_set(mode='EDIT'^)
echo     bpy.ops.mesh.select_all(action='SELECT'^)
echo.
echo     # Clean up
echo     bpy.ops.mesh.remove_doubles(threshold=0.0001^)
echo     bpy.ops.mesh.delete_loose(use_verts=True, use_edges=True, use_faces=False^)
echo     bpy.ops.mesh.normals_make_consistent(inside=False^)
echo.
echo     # Smooth vertices - reduces surface bumps (3 iterations^)
echo     for i in range(3^):
echo         bpy.ops.mesh.vertices_smooth(factor=0.5^)
echo.
echo     # Back to object mode
echo     bpy.ops.object.mode_set(mode='OBJECT'^)
echo.
echo     # Center origin
echo     bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_VOLUME', center='MEDIAN'^)
echo     obj.location = (0, 0, 0^)
echo.
echo     # Smooth shading with auto-smooth for sharp edges
echo     bpy.ops.object.shade_smooth(^)
echo.
echo     # Enable auto-smooth to preserve sharp edges
echo     if hasattr(obj.data, 'use_auto_smooth'^):
echo         obj.data.use_auto_smooth = True
echo         obj.data.auto_smooth_angle = 1.0472  # 60 degrees
echo.
echo # Export
echo bpy.ops.export_scene.gltf(filepath=output_file, export_format='GLB', use_selection=False, export_apply=True^)
echo print(f"Saved: {output_file}"^)
) > "%TEMP%\smooth_cleanup.py"

:: Process each GLB file
set COUNT=0
for %%f in (*.glb) do (
    echo %%f | findstr /i "_smooth.glb" >nul
    if errorlevel 1 (
        echo %%f | findstr /i "_clean.glb" >nul
        if errorlevel 1 (
            set /a COUNT+=1
            echo.
            echo Processing: %%f
            "%BLENDER%" --background --python "%TEMP%\smooth_cleanup.py" -- "%%~ff" "%%~dpnf_smooth.glb"
            if exist "%%~dpnf_smooth.glb" (
                echo SUCCESS: %%~nf_smooth.glb created
            ) else (
                echo FAILED: %%f
            )
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
