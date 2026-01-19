# ============================================
# BATCH CLEAN MESHY MODELS (No GUI)
# ============================================
#
# SETUP:
# 1. Install Blender (blender.org)
# 2. Put this script + blender-meshy-cleanup.py in same folder
# 3. Drop your .glb files in same folder
# 4. Run: .\clean-models.ps1
#
# Output: *_clean.glb files
#
# ============================================

# Find Blender (common install paths)
$blenderPaths = @(
    "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.1\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 4.0\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 3.6\blender.exe",
    "C:\Program Files\Blender Foundation\Blender 3.5\blender.exe"
)

$blender = $null
foreach ($path in $blenderPaths) {
    if (Test-Path $path) {
        $blender = $path
        break
    }
}

if (-not $blender) {
    Write-Host "ERROR: Blender not found. Install from blender.org" -ForegroundColor Red
    Write-Host "Or edit this script with your Blender path" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found Blender: $blender" -ForegroundColor Green

# Get all GLB files in current directory
$glbFiles = Get-ChildItem -Path "." -Filter "*.glb" | Where-Object { $_.Name -notmatch "_clean\.glb$" }

if ($glbFiles.Count -eq 0) {
    Write-Host "No .glb files found in current directory" -ForegroundColor Yellow
    exit 0
}

Write-Host "`nFound $($glbFiles.Count) model(s) to clean:`n" -ForegroundColor Cyan

# Create the Python script inline (so user only needs this one file)
$pythonScript = @'
import bpy
import bmesh
import sys
import os

# Get input/output from command line args
argv = sys.argv
argv = argv[argv.index("--") + 1:]
input_file = argv[0]
output_file = argv[1]

print(f"\n{'='*50}")
print(f"Processing: {input_file}")
print(f"{'='*50}\n")

# Clear default scene
bpy.ops.wm.read_factory_settings(use_empty=True)

# Import GLB
bpy.ops.import_scene.gltf(filepath=input_file)

# Get all mesh objects
meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']

for obj in meshes:
    print(f"Cleaning: {obj.name}")
    
    # Select and make active
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Apply transforms
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    
    # Edit mode cleanup
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    
    # Remove doubles
    bpy.ops.mesh.remove_doubles(threshold=0.0001)
    
    # Delete loose
    bpy.ops.mesh.delete_loose(use_verts=True, use_edges=True, use_faces=False)
    
    # Recalculate normals
    bpy.ops.mesh.normals_make_consistent(inside=False)
    
    # Triangulate
    bpy.ops.mesh.quads_convert_to_tris(quad_method='BEAUTY', ngon_method='BEAUTY')
    
    # Back to object mode
    bpy.ops.object.mode_set(mode='OBJECT')
    
    # Center origin
    bpy.ops.object.origin_set(type='ORIGIN_CENTER_OF_VOLUME', center='MEDIAN')
    obj.location = (0, 0, 0)
    
    # Smooth shading
    bpy.ops.object.shade_smooth()
    
    # Auto smooth
    if hasattr(obj.data, 'use_auto_smooth'):
        obj.data.use_auto_smooth = True
        obj.data.auto_smooth_angle = 0.523599
    
    # Decimate if too heavy
    face_count = len(obj.data.polygons)
    if face_count > 30000:
        ratio = 30000 / face_count
        print(f"  Decimating: {face_count} -> ~30000 faces")
        mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
        mod.ratio = ratio
        bpy.ops.object.modifier_apply(modifier="Decimate")
    
    print(f"  Done! Faces: {len(obj.data.polygons)}")

# Export
print(f"\nExporting: {output_file}")
bpy.ops.export_scene.gltf(
    filepath=output_file,
    export_format='GLB',
    use_selection=False,
    export_apply=True
)

print(f"\n{'='*50}")
print("COMPLETE!")
print(f"{'='*50}\n")
'@

# Save temp Python script
$tempScript = Join-Path $env:TEMP "meshy_cleanup_temp.py"
$pythonScript | Out-File -FilePath $tempScript -Encoding UTF8

# Process each file
foreach ($file in $glbFiles) {
    $inputPath = $file.FullName
    $outputPath = $file.FullName -replace "\.glb$", "_clean.glb"
    
    Write-Host "Processing: $($file.Name)" -ForegroundColor White
    
    # Run Blender headless
    & $blender --background --python $tempScript -- $inputPath $outputPath
    
    if (Test-Path $outputPath) {
        $originalSize = [math]::Round($file.Length / 1KB, 1)
        $newSize = [math]::Round((Get-Item $outputPath).Length / 1KB, 1)
        Write-Host "  Created: $($file.BaseName)_clean.glb ($originalSize KB -> $newSize KB)" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Could not process $($file.Name)" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Cleanup
Remove-Item $tempScript -ErrorAction SilentlyContinue

Write-Host "`nAll done!" -ForegroundColor Cyan
Write-Host "Clean models have '_clean.glb' suffix" -ForegroundColor Gray

# Keep window open
Write-Host "`nPress any key to close..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
