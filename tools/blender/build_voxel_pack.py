"""
VoxelRealms — Master Blender Voxel Asset Pack Generator
Generates 100% original voxel-cube assets following docs/ASSET_PIPELINE.md:
  - 1 Blender meter = 1 Voxel Block (4 Roblox studs / 1 Unity unit)
  - Shared 16x16 nearest-neighbor color palette (assets/textures/voxel_palette_v1.png)
  - Exports .blend sources + .fbx (embedded texture for Roblox & Unity) + .glb backups
  - Renders a visual QA showcase sheet (assets/exports/voxel_pack_showcase.png)
"""

import math
import os
import bmesh
import bpy
from mathutils import Euler, Vector

REPO_ROOT = r"D:\Projects\VoxelRealms"
TEX_DIR = os.path.join(REPO_ROOT, "assets", "textures")
BLEND_DIR = os.path.join(REPO_ROOT, "assets", "blender")
EXPORT_DIR = os.path.join(REPO_ROOT, "assets", "exports")
PALETTE_PATH = os.path.join(TEX_DIR, "voxel_palette_v1.png")

# Curated Dawnlands-inspired Voxel Color Swatches (index -> linear-friendly sRGB 0..255)
PALETTE_COLORS = {
    0: (238, 198, 162),  # skin_base
    1: (214, 168, 132),  # skin_shade
    2: (82, 54, 38),     # hair_brown
    3: (58, 38, 26),     # hair_dark
    4: (30, 34, 42),     # eye_dark
    5: (242, 245, 250),  # eye_white
    6: (56, 132, 210),   # tunic_blue (Architect starter look)
    7: (42, 98, 166),    # tunic_blue_dark
    8: (108, 72, 44),    # leather_belt
    9: (224, 182, 74),   # buckle_gold
    10: (68, 76, 92),    # pants_slate
    11: (52, 40, 34),    # boots_dark
    12: (126, 82, 48),   # wood_bark
    13: (96, 60, 34),    # wood_bark_dark
    14: (184, 138, 86),  # wood_handle
    15: (152, 108, 64),  # wood_handle_shade
    16: (52, 118, 56),   # pine_dark
    17: (68, 146, 70),   # pine_mid
    18: (92, 174, 86),   # pine_bright
    19: (104, 110, 118), # stone_dark
    20: (136, 142, 150), # stone_mid
    21: (168, 174, 182), # stone_light
    22: (196, 132, 78),  # iron_ore_copper
    23: (226, 172, 112), # iron_ore_highlight
    24: (218, 64, 42),   # flame_red
    25: (245, 136, 38),  # flame_orange
    26: (252, 218, 78),  # flame_yellow
    27: (46, 42, 44),    # charcoal_ash
    28: (206, 214, 224), # metal_blade_light
    29: (146, 156, 168), # metal_blade_dark
}


def ensure_dirs():
    for sub in ["characters", "tools", "props", "environment", "creatures"]:
        os.makedirs(os.path.join(BLEND_DIR, sub), exist_ok=True)
        os.makedirs(os.path.join(EXPORT_DIR, sub), exist_ok=True)
    os.makedirs(TEX_DIR, exist_ok=True)


def generate_palette_png():
    """Creates a crisp 16x16 pixel palette PNG (256 swatches max)."""
    size = 16
    img = bpy.data.images.new("VR_VoxelPalette", width=size, height=size, alpha=True)
    pixels = [0.0] * (size * size * 4)

    for idx, (r, g, b) in PALETTE_COLORS.items():
        x = idx % size
        y = idx // size
        base = (y * size + x) * 4
        pixels[base + 0] = r / 255.0
        pixels[base + 1] = g / 255.0
        pixels[base + 2] = b / 255.0
        pixels[base + 3] = 1.0

    img.pixels = pixels
    img.filepath_raw = PALETTE_PATH
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)
    print(f"[Palette] Saved {PALETTE_PATH}")


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.fps = 24


def create_palette_material(name="VR_VoxelPalette_Mat"):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (400, 0)

    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (100, 0)
    bsdf.inputs["Roughness"].default_value = 0.78
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.25

    tex = nodes.new("ShaderNodeTexImage")
    tex.location = (-220, 0)
    img = bpy.data.images.load(PALETTE_PATH, check_existing=True)
    img.pack()
    tex.image = img
    tex.interpolation = "Closest"

    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def palette_uv(color_idx):
    size = 16
    x = color_idx % size
    y = color_idx // size
    return ((x + 0.5) / size, (y + 0.5) / size)


def add_voxel_box(bm, uv_layer, center, dims, color_idx):
    """Appends an axis-aligned voxel box to a bmesh and UVs every face to its palette swatch."""
    cx, cy, cz = center
    dx, dy, dz = dims
    hx, hy, hz = dx * 0.5, dy * 0.5, dz * 0.5

    verts = [
        bm.verts.new((cx - hx, cy - hy, cz - hz)),
        bm.verts.new((cx + hx, cy - hy, cz - hz)),
        bm.verts.new((cx + hx, cy + hy, cz - hz)),
        bm.verts.new((cx - hx, cy + hy, cz - hz)),
        bm.verts.new((cx - hx, cy - hy, cz + hz)),
        bm.verts.new((cx + hx, cy - hy, cz + hz)),
        bm.verts.new((cx + hx, cy + hy, cz + hz)),
        bm.verts.new((cx - hx, cy + hy, cz + hz)),
    ]

    face_indices = [
        (0, 3, 2, 1),  # bottom (-Z)
        (4, 5, 6, 7),  # top (+Z)
        (0, 1, 5, 4),  # front (-Y)
        (2, 3, 7, 6),  # back (+Y)
        (0, 4, 7, 3),  # left (-X)
        (1, 2, 6, 5),  # right (+X)
    ]

    u, v = palette_uv(color_idx)
    for idxs in face_indices:
        face = bm.faces.new([verts[i] for i in idxs])
        face.smooth = False
        for loop in face.loops:
            loop[uv_layer].uv = (u, v)


def build_mesh_from_boxes(name, boxes, mat):
    """boxes: list of (center_xyz, dims_xyz, color_idx)"""
    mesh = bpy.data.meshes.new(name + "_Mesh")
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")

    for center, dims, color_idx in boxes:
        add_voxel_box(bm, uv_layer, center, dims, color_idx)

    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def export_asset(category, name, objects, has_animation=False):
    blend_path = os.path.join(BLEND_DIR, category, f"{name}.blend")
    fbx_path = os.path.join(EXPORT_DIR, category, f"{name}.fbx")
    glb_path = os.path.join(EXPORT_DIR, category, f"{name}.glb")

    bpy.ops.wm.save_as_mainfile(filepath=blend_path)

    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]

    bpy.ops.export_scene.fbx(
        filepath=fbx_path,
        use_selection=True,
        apply_scale_options="FBX_SCALE_ALL",
        axis_forward="-Z",
        axis_up="Y",
        bake_anim=has_animation,
        bake_anim_use_all_actions=has_animation,
        bake_anim_use_nla_strips=False,
        bake_anim_step=1.0,
        add_leaf_bones=False,
        path_mode="COPY",
        embed_textures=True,
    )

    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format="GLB",
        use_selection=True,
        export_animations=has_animation,
    )
    print(f"[Exported] {category}/{name} (.blend, .fbx, .glb)")


# ---------------------------------------------------------------------------
# ASSET 1: Rigged Voxel Humanoid Character (1.8m tall, -Y forward, 3 Actions)
# ---------------------------------------------------------------------------
def build_voxel_character():
    reset_scene()
    mat = create_palette_material()

    # Create Armature
    arm_data = bpy.data.armatures.new("VR_Humanoid_Rig")
    arm_obj = bpy.data.objects.new("VR_Humanoid_Rig", arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm_data.edit_bones

    def add_bone(name, head, tail, parent_name=None):
        b = eb.new(name)
        b.head = Vector(head)
        b.tail = Vector(tail)
        if parent_name:
            b.parent = eb[parent_name]
        return b

    add_bone("Root", (0, 0, 0.0), (0, 0, 0.25))
    add_bone("Hips", (0, 0, 0.78), (0, 0, 0.96), "Root")
    add_bone("Spine", (0, 0, 0.96), (0, 0, 1.18), "Hips")
    add_bone("Chest", (0, 0, 1.18), (0, 0, 1.38), "Spine")
    add_bone("Head", (0, 0, 1.38), (0, 0, 1.80), "Chest")

    # Left/Right Arms (character faces -Y, so +X is character's left, -X is character's right)
    add_bone("UpperArm_L", (0.31, 0, 1.32), (0.31, 0, 1.04), "Chest")
    add_bone("LowerArm_L", (0.31, 0, 1.04), (0.31, 0, 0.76), "UpperArm_L")
    add_bone("Socket_HandL", (0.31, -0.06, 0.78), (0.31, -0.22, 0.78), "LowerArm_L")

    add_bone("UpperArm_R", (-0.31, 0, 1.32), (-0.31, 0, 1.04), "Chest")
    add_bone("LowerArm_R", (-0.31, 0, 1.04), (-0.31, 0, 0.76), "UpperArm_R")
    add_bone("Socket_HandR", (-0.31, -0.06, 0.78), (-0.31, -0.22, 0.78), "LowerArm_R")

    add_bone("Socket_Back", (0, 0.17, 1.22), (0, 0.32, 1.22), "Chest")
    add_bone("Socket_Head", (0, 0, 1.80), (0, 0, 1.95), "Head")

    # Legs
    add_bone("UpperLeg_L", (0.12, 0, 0.78), (0.12, 0, 0.40), "Hips")
    add_bone("LowerLeg_L", (0.12, 0, 0.40), (0.12, 0, 0.0), "UpperLeg_L")

    add_bone("UpperLeg_R", (-0.12, 0, 0.78), (-0.12, 0, 0.40), "Hips")
    add_bone("LowerLeg_R", (-0.12, 0, 0.40), (-0.12, 0, 0.0), "UpperLeg_R")

    bpy.ops.object.mode_set(mode="OBJECT")

    # Build one unified voxel character mesh with strict per-bone vertex groups (crisp rigid voxel skinning)
    bone_boxes = {
        "Hips": [
            ((0, 0, 0.85), (0.46, 0.28, 0.14), 8),   # leather belt
            ((0, -0.15, 0.85), (0.10, 0.04, 0.10), 9),  # gold buckle
            ((0, 0, 0.76), (0.44, 0.26, 0.12), 10),  # pelvis/pants top
        ],
        "Spine": [
            ((0, 0, 1.04), (0.44, 0.26, 0.24), 6),   # lower tunic
            ((0, -0.135, 1.04), (0.12, 0.03, 0.24), 7),  # tunic trim
        ],
        "Chest": [
            ((0, 0, 1.26), (0.48, 0.28, 0.24), 6),   # chest tunic
            ((0, -0.145, 1.26), (0.18, 0.03, 0.20), 7),  # vest detail
            ((0.25, 0, 1.33), (0.14, 0.28, 0.10), 7),  # left shoulder trim
            ((-0.25, 0, 1.33), (0.14, 0.28, 0.10), 7), # right shoulder trim
            ((0, 0.16, 1.22), (0.28, 0.10, 0.26), 8),  # adventurer backpack
            ((0, 0.21, 1.29), (0.22, 0.04, 0.06), 9),  # pack clasp
        ],
        "Head": [
            ((0, 0, 1.58), (0.40, 0.40, 0.40), 0),      # voxel head
            ((0, 0, 1.78), (0.44, 0.44, 0.09), 2),      # hair top
            ((0, 0.19, 1.62), (0.44, 0.08, 0.30), 2),   # hair back
            ((0.20, 0.03, 1.66), (0.06, 0.36, 0.20), 3), # hair side L
            ((-0.20, 0.03, 1.66), (0.06, 0.36, 0.20), 3),# hair side R
            ((0, -0.19, 1.74), (0.42, 0.06, 0.10), 2),  # hair fringe
            # Crisp voxel eyes on -Y face
            ((0.10, -0.205, 1.58), (0.08, 0.02, 0.08), 5),
            ((0.09, -0.212, 1.58), (0.04, 0.02, 0.06), 4),
            ((-0.10, -0.205, 1.58), (0.08, 0.02, 0.08), 5),
            ((-0.09, -0.212, 1.58), (0.04, 0.02, 0.06), 4),
            ((0, -0.205, 1.50), (0.06, 0.02, 0.04), 1),  # voxel nose/mouth accent
        ],
        "UpperArm_L": [
            ((0.32, 0, 1.18), (0.18, 0.20, 0.28), 6),
        ],
        "LowerArm_L": [
            ((0.32, 0, 0.94), (0.16, 0.18, 0.16), 8),   # leather bracer
            ((0.32, 0, 0.80), (0.16, 0.16, 0.14), 0),   # voxel hand
        ],
        "UpperArm_R": [
            ((-0.32, 0, 1.18), (0.18, 0.20, 0.28), 6),
        ],
        "LowerArm_R": [
            ((-0.32, 0, 0.94), (0.16, 0.18, 0.16), 8),  # leather bracer
            ((-0.32, 0, 0.80), (0.16, 0.16, 0.14), 0),  # voxel hand
        ],
        "UpperLeg_L": [
            ((0.12, 0, 0.58), (0.20, 0.22, 0.36), 10),
        ],
        "LowerLeg_L": [
            ((0.12, 0, 0.24), (0.19, 0.21, 0.26), 11),  # voxel boot shaft
            ((0.12, -0.03, 0.06), (0.20, 0.26, 0.12), 11), # voxel boot foot
        ],
        "UpperLeg_R": [
            ((-0.12, 0, 0.58), (0.20, 0.22, 0.36), 10),
        ],
        "LowerLeg_R": [
            ((-0.12, 0, 0.24), (0.19, 0.21, 0.26), 11),
            ((-0.12, -0.03, 0.06), (0.20, 0.26, 0.12), 11),
        ],
    }

    mesh = bpy.data.meshes.new("VR_VoxelCharacter_Mesh")
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    vert_bone_ranges = []

    for bone_name, boxes in bone_boxes.items():
        start_idx = len(bm.verts)
        for center, dims, color_idx in boxes:
            add_voxel_box(bm, uv_layer, center, dims, color_idx)
        end_idx = len(bm.verts)
        vert_bone_ranges.append((bone_name, start_idx, end_idx))

    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()

    char_obj = bpy.data.objects.new("VR_VoxelCharacter", mesh)
    bpy.context.collection.objects.link(char_obj)
    char_obj.data.materials.append(mat)

    for bone_name, start_idx, end_idx in vert_bone_ranges:
        vg = char_obj.vertex_groups.new(name=bone_name)
        vg.add(list(range(start_idx, end_idx)), 1.0, "REPLACE")

    # Parent mesh to armature with Armature modifier
    char_obj.parent = arm_obj
    mod = char_obj.modifiers.new(name="Armature", type="ARMATURE")
    mod.object = arm_obj

    # Animate 3 starter actions: Idle, Walk, Swing
    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    pose_bones = arm_obj.pose.bones
    for pb in pose_bones:
        pb.rotation_mode = "XYZ"

    def reset_pose():
        for pb in pose_bones:
            pb.location = (0, 0, 0)
            pb.rotation_euler = Euler((0, 0, 0), "XYZ")

    def key_bone(bone_name, frame, rot_deg=(0, 0, 0), loc=(0, 0, 0)):
        pb = pose_bones[bone_name]
        pb.location = Vector(loc)
        pb.rotation_euler = Euler(tuple(math.radians(a) for a in rot_deg), "XYZ")
        pb.keyframe_insert(data_path="location", frame=frame)
        pb.keyframe_insert(data_path="rotation_euler", frame=frame)

    def make_action(name):
        act = bpy.data.actions.new(name=name)
        act.use_fake_user = True
        if arm_obj.animation_data is None:
            arm_obj.animation_data_create()
        arm_obj.animation_data.action = act
        reset_pose()
        return act

    # Action 1: Idle (frames 1..49)
    make_action("Idle")
    for frame, chest_x, arm_z, head_y in [
        (1, 0, 3, 0),
        (25, 3, 6, 4),
        (49, 0, 3, 0),
    ]:
        key_bone("Spine", frame, (chest_x, 0, 0))
        key_bone("Head", frame, (-chest_x * 0.5, head_y, 0))
        key_bone("UpperArm_L", frame, (0, 0, arm_z))
        key_bone("UpperArm_R", frame, (0, 0, -arm_z))

    # Action 2: Walk (frames 1..25)
    make_action("Walk")
    walk_keys = [
        (1, 32, -32, 0, 12, -26, 26, 0.03),
        (7, 0, 0, 18, 0, 0, 0, 0.0),
        (13, -32, 32, 12, 0, 26, -26, 0.03),
        (19, 0, 0, 0, 18, 0, 0, 0.0),
        (25, 32, -32, 0, 12, -26, 26, 0.03),
    ]
    for frame, leg_l, leg_r, knee_l, knee_r, arm_l, arm_r, bob in walk_keys:
        key_bone("Hips", frame, (0, 0, 0), (0, bob, 0))
        key_bone("UpperLeg_L", frame, (leg_l, 0, 0))
        key_bone("LowerLeg_L", frame, (knee_l, 0, 0))
        key_bone("UpperLeg_R", frame, (leg_r, 0, 0))
        key_bone("LowerLeg_R", frame, (knee_r, 0, 0))
        key_bone("UpperArm_L", frame, (arm_l, 0, 4))
        key_bone("UpperArm_R", frame, (arm_r, 0, -4))

    # Action 3: Swing (frames 1..19 — chop / mine / attack)
    make_action("Swing")
    swing_keys = [
        (1, 0, 0, 0, 0, 0),
        (6, -12, 18, -115, -25, 20),   # wind-up overhead
        (11, 18, -22, 42, -10, -25),   # strike impact
        (19, 0, 0, 0, 0, 0),           # recover
    ]
    for frame, spine_x, spine_z, arm_r_x, elbow_r_x, arm_l_x in swing_keys:
        key_bone("Spine", frame, (spine_x, 0, spine_z))
        key_bone("UpperArm_R", frame, (arm_r_x, 0, -8))
        key_bone("LowerArm_R", frame, (elbow_r_x, 0, 0))
        key_bone("UpperArm_L", frame, (arm_l_x, 0, 8))

    # Leave resting on Idle frame 1
    arm_obj.animation_data.action = bpy.data.actions["Idle"]
    bpy.context.scene.frame_set(1)
    bpy.ops.object.mode_set(mode="OBJECT")

    export_asset("characters", "vr_char_base_rig", [arm_obj, char_obj], has_animation=True)


# ---------------------------------------------------------------------------
# ASSET 2: Voxel Wood Axe
# ---------------------------------------------------------------------------
def build_voxel_axe():
    reset_scene()
    mat = create_palette_material()
    boxes = [
        # Grip centered at origin (0, 0, 0), handle rising along +Z, blade facing -Y
        ((0, 0, 0.00), (0.08, 0.08, 0.22), 8),   # leather grip wrap
        ((0, 0, 0.34), (0.07, 0.07, 0.52), 14),  # wooden shaft
        ((0, 0, 0.62), (0.09, 0.09, 0.10), 15),  # pommel/head collar
        # Stepped voxel axe blade facing -Y
        ((0, -0.10, 0.54), (0.06, 0.14, 0.16), 29),
        ((0, -0.20, 0.52), (0.04, 0.10, 0.24), 28),
        ((0, -0.26, 0.50), (0.03, 0.05, 0.28), 28),
        ((0, 0.08, 0.55), (0.06, 0.08, 0.10), 29), # rear poll
    ]
    obj = build_mesh_from_boxes("VR_Tool_Axe_Wood", boxes, mat)
    export_asset("tools", "vr_tool_axe_wood", [obj], has_animation=False)


# ---------------------------------------------------------------------------
# ASSET 3: Voxel Stone Pickaxe
# ---------------------------------------------------------------------------
def build_voxel_pickaxe():
    reset_scene()
    mat = create_palette_material()
    boxes = [
        ((0, 0, 0.00), (0.08, 0.08, 0.22), 8),   # leather grip
        ((0, 0, 0.36), (0.07, 0.07, 0.56), 14),  # wooden handle
        ((0, 0, 0.60), (0.11, 0.12, 0.12), 19),  # central stone head hub
        # Front stepped stone pick (-Y)
        ((0, -0.14, 0.59), (0.08, 0.16, 0.10), 20),
        ((0, -0.26, 0.54), (0.07, 0.12, 0.08), 21),
        ((0, -0.34, 0.48), (0.05, 0.08, 0.06), 21),
        # Rear stepped stone pick (+Y)
        ((0, 0.14, 0.59), (0.08, 0.16, 0.10), 20),
        ((0, 0.26, 0.54), (0.07, 0.12, 0.08), 21),
        ((0, 0.34, 0.48), (0.05, 0.08, 0.06), 21),
    ]
    obj = build_mesh_from_boxes("VR_Tool_Pickaxe_Stone", boxes, mat)
    export_asset("tools", "vr_tool_pickaxe_stone", [obj], has_animation=False)


# ---------------------------------------------------------------------------
# ASSET 4: Voxel Campfire (1m x 1m footprint)
# ---------------------------------------------------------------------------
def build_voxel_campfire():
    reset_scene()
    mat = create_palette_material()
    boxes = [
        # Ash bed
        ((0, 0, 0.03), (0.72, 0.72, 0.06), 27),
        # Ring of 8 staggered voxel cobble stones
        ((0.40, 0.00, 0.09), (0.20, 0.24, 0.18), 20),
        ((-0.40, 0.00, 0.09), (0.20, 0.24, 0.18), 19),
        ((0.00, 0.40, 0.09), (0.24, 0.20, 0.18), 21),
        ((0.00, -0.40, 0.09), (0.24, 0.20, 0.18), 20),
        ((0.30, 0.30, 0.08), (0.20, 0.20, 0.16), 19),
        ((-0.30, 0.30, 0.08), (0.20, 0.20, 0.16), 20),
        ((0.30, -0.30, 0.08), (0.20, 0.20, 0.16), 21),
        ((-0.30, -0.30, 0.08), (0.20, 0.20, 0.16), 19),
        # Crossed voxel firewood logs
        ((0.0, 0.0, 0.14), (0.64, 0.14, 0.14), 12),
        ((0.0, 0.0, 0.18), (0.14, 0.64, 0.14), 13),
        ((0.12, -0.10, 0.22), (0.42, 0.12, 0.12), 12),
        # Stepped voxel flame stack
        ((0.0, 0.0, 0.32), (0.30, 0.30, 0.24), 24),
        ((0.04, -0.04, 0.48), (0.22, 0.22, 0.22), 25),
        ((-0.02, 0.02, 0.64), (0.14, 0.14, 0.18), 26),
        ((0.02, 0.0, 0.78), (0.08, 0.08, 0.12), 26),
    ]
    obj = build_mesh_from_boxes("VR_Prop_Campfire", boxes, mat)
    export_asset("props", "vr_prop_campfire", [obj], has_animation=False)


# ---------------------------------------------------------------------------
# ASSET 5: Voxel Pine Tree (~3.8m tall)
# ---------------------------------------------------------------------------
def build_voxel_pine_tree():
    reset_scene()
    mat = create_palette_material()
    boxes = [
        # Trunk & voxel roots
        ((0, 0, 0.90), (0.44, 0.44, 1.80), 12),
        ((0.28, 0, 0.16), (0.24, 0.24, 0.32), 13),
        ((-0.28, 0, 0.14), (0.24, 0.22, 0.28), 13),
        ((0, 0.26, 0.15), (0.22, 0.24, 0.30), 13),
        # 4 stepped voxel pine tiers
        ((0, 0, 1.65), (1.90, 1.90, 0.56), 16),
        ((0, 0, 2.20), (1.50, 1.50, 0.56), 17),
        ((0, 0, 2.75), (1.06, 1.06, 0.56), 17),
        ((0, 0, 3.26), (0.66, 0.66, 0.48), 18),
        ((0, 0, 3.68), (0.32, 0.32, 0.36), 18),
        # Subtle overhanging voxel foliage accents
        ((0.92, 0.36, 1.48), (0.32, 0.32, 0.26), 16),
        ((-0.86, -0.44, 1.50), (0.32, 0.32, 0.26), 16),
        ((0.40, -0.74, 2.04), (0.28, 0.28, 0.24), 17),
    ]
    obj = build_mesh_from_boxes("VR_Env_Pine_Tree", boxes, mat)
    export_asset("environment", "vr_env_pine_tree", [obj], has_animation=False)


# ---------------------------------------------------------------------------
# ASSET 6: Voxel Iron Ore Vein (~1.5m wide x 1.2m tall)
# ---------------------------------------------------------------------------
def build_voxel_iron_vein():
    reset_scene()
    mat = create_palette_material()
    boxes = [
        # Stepped granite rock cluster
        ((0.0, 0.0, 0.32), (1.28, 1.16, 0.64), 19),
        ((0.18, -0.14, 0.78), (0.86, 0.80, 0.44), 20),
        ((-0.14, 0.10, 1.06), (0.50, 0.48, 0.30), 21),
        ((-0.56, 0.22, 0.20), (0.46, 0.46, 0.40), 20),
        ((0.52, 0.30, 0.18), (0.42, 0.42, 0.36), 19),
        # Protruding metallic copper-iron voxel ore cubes
        ((0.56, -0.34, 0.44), (0.28, 0.28, 0.28), 22),
        ((0.64, -0.40, 0.56), (0.16, 0.16, 0.16), 23),
        ((-0.44, -0.46, 0.54), (0.26, 0.26, 0.26), 22),
        ((-0.36, -0.50, 0.64), (0.14, 0.14, 0.14), 23),
        ((0.14, 0.36, 0.86), (0.26, 0.26, 0.26), 22),
        ((0.20, 0.42, 0.96), (0.14, 0.14, 0.14), 23),
        ((-0.08, -0.26, 1.14), (0.20, 0.20, 0.20), 23),
    ]
    obj = build_mesh_from_boxes("VR_Env_Iron_Vein", boxes, mat)
    export_asset("environment", "vr_env_iron_vein", [obj], has_animation=False)


# ---------------------------------------------------------------------------
# SHOWCASE RENDER FOR VISUAL QA
# ---------------------------------------------------------------------------
def render_showcase():
    reset_scene()
    scene = bpy.context.scene

    # Pick available EEVEE engine cleanly across Blender 4.x / 5.x
    engine_items = [item.identifier for item in scene.render.bl_rna.properties["engine"].enum_items]
    if "BLENDER_EEVEE" in engine_items:
        scene.render.engine = "BLENDER_EEVEE"
    elif "BLENDER_EEVEE_NEXT" in engine_items:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    else:
        scene.render.engine = "CYCLES"

    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.image_settings.file_format = "PNG"

    # Bright stylized sky world
    world = bpy.data.worlds.new("ShowcaseWorld")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.16, 0.22, 0.32, 1.0)
        bg.inputs[1].default_value = 0.85

    # Ground plinth
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.15))
    floor = bpy.context.active_object
    floor.scale = (14.0, 6.0, 0.30)
    floor_mat = bpy.data.materials.new("FloorMat")
    floor_mat.use_nodes = True
    floor_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.18, 0.24, 0.18, 1.0)
    floor_mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
    floor.data.materials.append(floor_mat)

    placements = [
        ("environment", "vr_env_pine_tree", (-4.2, 0.6, 0.0), (0, 0, 0.3)),
        ("characters", "vr_char_base_rig", (-1.8, -0.2, 0.0), (0, 0, -0.25)),
        ("tools", "vr_tool_axe_wood", (-0.5, -0.4, 0.35), (0.1, 0.35, -0.4)),
        ("tools", "vr_tool_pickaxe_stone", (0.5, -0.4, 0.35), (0.1, -0.35, 0.4)),
        ("props", "vr_prop_campfire", (2.0, -0.2, 0.0), (0, 0, 0.2)),
        ("environment", "vr_env_iron_vein", (4.0, 0.2, 0.0), (0, 0, -0.35)),
    ]

    for category, name, loc, rot in placements:
        glb_path = os.path.join(EXPORT_DIR, category, f"{name}.glb")
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=glb_path)
        imported = [o for o in bpy.data.objects if o not in before]
        roots = [o for o in imported if o.parent is None]
        for r in roots:
            r.location = Vector(loc)
            r.rotation_euler = Euler(rot, "XYZ")

    # Sun + fill light
    sun_data = bpy.data.lights.new("Sun", type="SUN")
    sun_data.energy = 3.2
    sun_obj = bpy.data.objects.new("Sun", sun_data)
    bpy.context.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = Euler((math.radians(52), math.radians(-18), math.radians(32)), "XYZ")

    fill_data = bpy.data.lights.new("Fill", type="AREA")
    fill_data.energy = 140.0
    fill_data.size = 6.0
    fill_obj = bpy.data.objects.new("Fill", fill_data)
    bpy.context.collection.objects.link(fill_obj)
    fill_obj.location = Vector((-4.5, -6.5, 4.0))
    fill_obj.rotation_euler = Euler((math.radians(65), 0, math.radians(-30)), "XYZ")

    # Camera framed across the entire lineup
    cam_data = bpy.data.cameras.new("ShowcaseCam")
    cam_data.lens = 38.0
    cam_obj = bpy.data.objects.new("ShowcaseCam", cam_data)
    bpy.context.collection.objects.link(cam_obj)
    cam_obj.location = Vector((0.0, -9.8, 3.2))
    direction = Vector((0.0, 0.0, 1.35)) - cam_obj.location
    cam_obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam_obj

    out_path = os.path.join(EXPORT_DIR, "voxel_pack_showcase.png")
    scene.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    print(f"[Showcase] Rendered {out_path}")


def main():
    ensure_dirs()
    reset_scene()
    generate_palette_png()
    build_voxel_character()
    build_voxel_axe()
    build_voxel_pickaxe()
    build_voxel_campfire()
    build_voxel_pine_tree()
    build_voxel_iron_vein()
    render_showcase()
    print("[VoxelRealms] Base Voxel Asset Pack complete!")


if __name__ == "__main__":
    main()
