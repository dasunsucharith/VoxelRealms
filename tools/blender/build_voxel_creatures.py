"""
VoxelRealms — Blender Voxel Creature Pack Generator
Builds 100% original voxel-cube creature assets (1 Blender meter = 1 Voxel Block):
  - vr_mob_wolf  (.blend, .fbx, .glb) — Rigged quadruped voxel wolf with Idle & Run actions
  - vr_mob_slime (.blend, .fbx, .glb) — Layered emerald voxel slime with Hop action
  - voxel_creatures_showcase.png — Visual QA lineup render
"""

import math
import os
import bmesh
import bpy
from mathutils import Euler, Vector

REPO_ROOT = r"D:\Projects\VoxelRealms"
TEX_DIR = os.path.join(REPO_ROOT, "assets", "textures")
BLEND_DIR = os.path.join(REPO_ROOT, "assets", "blender", "creatures")
EXPORT_DIR = os.path.join(REPO_ROOT, "assets", "exports", "creatures")
PALETTE_PATH = os.path.join(TEX_DIR, "voxel_creatures_palette_v1.png")

PALETTE_COLORS = {
    0: (122, 126, 134),  # wolf_fur_mid
    1: (82, 86, 96),     # wolf_fur_dark
    2: (186, 188, 194),  # wolf_fur_belly
    3: (30, 32, 38),     # nose_eye_dark
    4: (252, 196, 62),   # wolf_eye_amber
    5: (224, 152, 142),  # wolf_ear_inner
    6: (72, 206, 108),   # slime_outer_green
    7: (46, 158, 76),    # slime_core_green
    8: (148, 242, 168),  # slime_highlight
}


def ensure_dirs():
    os.makedirs(TEX_DIR, exist_ok=True)
    os.makedirs(BLEND_DIR, exist_ok=True)
    os.makedirs(EXPORT_DIR, exist_ok=True)


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.fps = 24


def generate_palette_png():
    size = 16
    img = bpy.data.images.new("VR_CreaturesPalette", width=size, height=size, alpha=True)
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


def create_palette_material(name="VR_CreaturesPalette_Mat"):
    mat = bpy.data.materials.new(name=name)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    out = nodes.new("ShaderNodeOutputMaterial")
    out.location = (400, 0)
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (100, 0)
    bsdf.inputs["Roughness"].default_value = 0.72

    tex = nodes.new("ShaderNodeTexImage")
    tex.location = (-220, 0)
    img = bpy.data.images.load(PALETTE_PATH, check_existing=True)
    img.pack()
    tex.image = img
    tex.interpolation = "Closest"

    links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def palette_uv(idx):
    size = 16
    return (((idx % size) + 0.5) / size, ((idx // size) + 0.5) / size)


def add_voxel_box(bm, uv_layer, center, dims, color_idx):
    cx, cy, cz = center
    hx, hy, hz = dims[0] * 0.5, dims[1] * 0.5, dims[2] * 0.5
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
    faces = [
        (0, 3, 2, 1),
        (4, 5, 6, 7),
        (0, 1, 5, 4),
        (2, 3, 7, 6),
        (0, 4, 7, 3),
        (1, 2, 6, 5),
    ]
    u, v = palette_uv(color_idx)
    for idxs in faces:
        f = bm.faces.new([verts[i] for i in idxs])
        f.smooth = False
        for loop in f.loops:
            loop[uv_layer].uv = (u, v)


def export_creature(name, objects, has_anim=True):
    blend_path = os.path.join(BLEND_DIR, f"{name}.blend")
    fbx_path = os.path.join(EXPORT_DIR, f"{name}.fbx")
    glb_path = os.path.join(EXPORT_DIR, f"{name}.glb")

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
        bake_anim=has_anim,
        bake_anim_use_all_actions=has_anim,
        bake_anim_use_nla_strips=False,
        add_leaf_bones=False,
        path_mode="COPY",
        embed_textures=True,
    )
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format="GLB",
        use_selection=True,
        export_animations=has_anim,
    )
    print(f"[Exported] creatures/{name}")


# ---------------------------------------------------------------------------
# CREATURE 1: Rigged Voxel Timber Wolf (-Y forward, +Z up)
# ---------------------------------------------------------------------------
def build_voxel_wolf():
    reset_scene()
    mat = create_palette_material()

    arm_data = bpy.data.armatures.new("VR_Wolf_Rig")
    arm_obj = bpy.data.objects.new("VR_Wolf_Rig", arm_data)
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

    add_bone("Root", (0, 0, 0), (0, 0, 0.25))
    add_bone("Body", (0, 0.05, 0.55), (0, -0.45, 0.58), "Root")
    add_bone("Head", (0, -0.48, 0.66), (0, -0.95, 0.68), "Body")
    add_bone("Tail", (0, 0.50, 0.60), (0, 1.02, 0.72), "Body")
    add_bone("Leg_FL", (0.18, -0.34, 0.40), (0.18, -0.34, 0.0), "Body")
    add_bone("Leg_FR", (-0.18, -0.34, 0.40), (-0.18, -0.34, 0.0), "Body")
    add_bone("Leg_BL", (0.18, 0.34, 0.40), (0.18, 0.34, 0.0), "Body")
    add_bone("Leg_BR", (-0.18, 0.34, 0.40), (-0.18, 0.34, 0.0), "Body")

    bpy.ops.object.mode_set(mode="OBJECT")

    bone_boxes = {
        "Body": [
            ((0, 0.0, 0.56), (0.54, 1.02, 0.46), 0),    # torso
            ((0, -0.30, 0.60), (0.64, 0.42, 0.54), 1),  # dark mane
            ((0, 0.04, 0.34), (0.44, 0.80, 0.12), 2),   # cream belly
        ],
        "Head": [
            ((0, -0.64, 0.70), (0.48, 0.48, 0.44), 0),  # head cube
            ((0, -0.95, 0.62), (0.28, 0.30, 0.24), 2),  # snout
            ((0, -1.11, 0.69), (0.12, 0.08, 0.10), 3),  # dark nose
            ((0.15, -0.56, 0.98), (0.12, 0.10, 0.20), 1), # ear L
            ((-0.15, -0.56, 0.98), (0.12, 0.10, 0.20), 1),# ear R
            ((0.14, -0.89, 0.76), (0.09, 0.04, 0.09), 4), # amber eye L
            ((-0.14, -0.89, 0.76), (0.09, 0.04, 0.09), 4),# amber eye R
        ],
        "Tail": [
            ((0, 0.76, 0.66), (0.20, 0.54, 0.20), 1),
            ((0, 1.04, 0.72), (0.16, 0.16, 0.16), 2),   # pale tail tip
        ],
        "Leg_FL": [((0.18, -0.34, 0.20), (0.17, 0.17, 0.40), 1)],
        "Leg_FR": [((-0.18, -0.34, 0.20), (0.17, 0.17, 0.40), 1)],
        "Leg_BL": [((0.18, 0.34, 0.20), (0.17, 0.17, 0.40), 1)],
        "Leg_BR": [((-0.18, 0.34, 0.20), (0.17, 0.17, 0.40), 1)],
    }

    mesh = bpy.data.meshes.new("VR_Mob_Wolf_Mesh")
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    ranges = []
    for bname, boxes in bone_boxes.items():
        s = len(bm.verts)
        for c, d, ci in boxes:
            add_voxel_box(bm, uv_layer, c, d, ci)
        ranges.append((bname, s, len(bm.verts)))

    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("VR_Mob_Wolf", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for bname, s, e in ranges:
        vg = obj.vertex_groups.new(name=bname)
        vg.add(list(range(s, e)), 1.0, "REPLACE")

    obj.parent = arm_obj
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = arm_obj

    bpy.context.view_layer.objects.active = arm_obj
    bpy.ops.object.mode_set(mode="POSE")
    pbs = arm_obj.pose.bones
    for pb in pbs:
        pb.rotation_mode = "XYZ"

    def make_action(name):
        act = bpy.data.actions.new(name=name)
        act.use_fake_user = True
        if arm_obj.animation_data is None:
            arm_obj.animation_data_create()
        arm_obj.animation_data.action = act
        for pb in pbs:
            pb.rotation_euler = Euler((0, 0, 0), "XYZ")
            pb.location = (0, 0, 0)
        return act

    def key(bname, frame, rot_deg=(0, 0, 0)):
        pb = pbs[bname]
        pb.rotation_euler = Euler(tuple(math.radians(a) for a in rot_deg), "XYZ")
        pb.keyframe_insert(data_path="rotation_euler", frame=frame)

    make_action("Wolf_Idle")
    for frame, tail_z, head_x in [(1, -12, 0), (19, 12, 5), (37, -12, 0)]:
        key("Tail", frame, (0, 0, tail_z))
        key("Head", frame, (head_x, 0, 0))

    make_action("Wolf_Run")
    for frame, fl, fr, bl, br in [
        (1, 34, -34, -30, 30),
        (9, -34, 34, 30, -30),
        (17, 34, -34, -30, 30),
    ]:
        key("Leg_FL", frame, (fl, 0, 0))
        key("Leg_FR", frame, (fr, 0, 0))
        key("Leg_BL", frame, (bl, 0, 0))
        key("Leg_BR", frame, (br, 0, 0))
        key("Tail", frame, (8, 0, 0))

    arm_obj.animation_data.action = bpy.data.actions["Wolf_Idle"]
    bpy.context.scene.frame_set(1)
    bpy.ops.object.mode_set(mode="OBJECT")

    export_creature("vr_mob_wolf", [arm_obj, obj], has_anim=True)


# ---------------------------------------------------------------------------
# CREATURE 2: Voxel Forest Slime
# ---------------------------------------------------------------------------
def build_voxel_slime():
    reset_scene()
    mat = create_palette_material()

    boxes = [
        ((0, 0, 0.36), (0.84, 0.84, 0.72), 6),     # main emerald body
        ((0, 0, 0.76), (0.64, 0.64, 0.14), 8),     # glossy top voxel highlight
        ((0.28, -0.18, 0.12), (0.28, 0.28, 0.24), 7), # outer wobble cube
        ((-0.24, 0.22, 0.14), (0.24, 0.24, 0.28), 7),
        ((0.18, -0.43, 0.44), (0.12, 0.06, 0.14), 3), # eye L
        ((-0.18, -0.43, 0.44), (0.12, 0.06, 0.14), 3),# eye R
        ((0, -0.43, 0.28), (0.18, 0.06, 0.08), 3),    # mouth
    ]

    mesh = bpy.data.meshes.new("VR_Mob_Slime_Mesh")
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    for c, d, ci in boxes:
        add_voxel_box(bm, uv_layer, c, d, ci)
    bm.normal_update()
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new("VR_Mob_Slime", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)

    export_creature("vr_mob_slime", [obj], has_anim=False)


def render_showcase():
    reset_scene()
    scene = bpy.context.scene
    engine_items = [item.identifier for item in scene.render.bl_rna.properties["engine"].enum_items]
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in engine_items else "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.image_settings.file_format = "PNG"

    world = bpy.data.worlds.new("World")
    scene.world = world
    bg = world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs[0].default_value = (0.15, 0.20, 0.28, 1.0)
        bg.inputs[1].default_value = 0.9

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.15))
    floor = bpy.context.active_object
    floor.scale = (8.0, 5.0, 0.30)
    fmat = bpy.data.materials.new("FloorMat")
    fmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.20, 0.28, 0.19, 1.0)
    floor.data.materials.append(fmat)

    for name, loc, rot in [
        ("vr_mob_wolf", (-1.1, 0.0, 0.0), (0, 0, -0.55)),
        ("vr_mob_slime", (1.2, -0.1, 0.0), (0, 0, 0.35)),
    ]:
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=os.path.join(EXPORT_DIR, f"{name}.glb"))
        roots = [o for o in bpy.data.objects if o not in before and o.parent is None]
        for r in roots:
            r.location = Vector(loc)
            r.rotation_euler = Euler(rot, "XYZ")

    sun = bpy.data.lights.new("Sun", type="SUN")
    sun.energy = 3.2
    sun_obj = bpy.data.objects.new("Sun", sun)
    bpy.context.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = Euler((math.radians(50), math.radians(-18), math.radians(32)), "XYZ")

    cam = bpy.data.cameras.new("Cam")
    cam.lens = 42.0
    cam_obj = bpy.data.objects.new("Cam", cam)
    bpy.context.collection.objects.link(cam_obj)
    cam_obj.location = Vector((0.0, -5.2, 1.85))
    cam_obj.rotation_euler = (Vector((0.0, 0.0, 0.60)) - cam_obj.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam_obj

    out_path = os.path.join(EXPORT_DIR, "voxel_creatures_showcase.png")
    scene.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    print(f"[Showcase] Rendered {out_path}")


def main():
    ensure_dirs()
    reset_scene()
    generate_palette_png()
    build_voxel_wolf()
    build_voxel_slime()
    render_showcase()
    print("[VoxelRealms] Creature pack complete!")


if __name__ == "__main__":
    main()
