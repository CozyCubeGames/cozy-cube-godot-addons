# Cozy Cube Godot Addons
These Godot addons were made for internal use by Cozy Cube Games for the upcoming VR game, 🐧Penguin Festival🐧. They are provided for public use as-is, free of charge. If you find these addons useful, please consider supporting us by wishlisting or sharing our game 🙏: https://bit.ly/penguinfeststeam

# Disclaimers
- Cozy Cube Games will _not_ be providing any support for these addons. Issues will be addressed if/when they directly impact the development of Penguin Festival. API and functionality are also subject to change at any time based on the needs of the Penguin Festival project. Use them at your own risk. Feel free to fork / revert / stop updating as needed.
- These addons are currently used in Penguin Festival, which is on Godot `4.4.1`. They might work in other versions of Godot, but they are not actively being tested for compatibility.

# Basic Instructions
- Take any addons you need from here and put them in the addons folder of your Godot project.

## Addon List

- **7-Segment Display**
  - Adds a `SevenSegmentDisplay` node and `SevenSegmentDigitMesh` for rendering a sequence of 7-segment characters (3D). See example scene for details.
- **Area Lights**
  - Provides an `AreaLight3D` class to simulate a quad surface that emits baked lighting. For use with `LightmapGI`. Works by creating a grid of `SpotLight3D`. Provides higher quality results than using an equivalent emissive surface. Check out the examples scene.
- **Control Proxies**
  - Provides a `ControlProxy3D` node for acting as a 3D visual/input proxy for a 2D `Control`.
- **Doodle Texture**
  - Provides a `DoodleTexture` resource that you can doodle on in the inspector. Good for placeholder textures. Only works when you inspect the `DoodleTexture`. If the texture is a nested child resource, right-click on the property and click Edit to inspect the texture itself. Use left mouse button to draw, right mouse button to erase.
- **Editor Relays**
  - Provides an `EditorRelay` node that facilitates communications between the editor and the running game. Check out the example scene.
- **Gizmo Presets**
  - Allows quickly setting visibility of all gizmo types according to preconfigured presets. You can access this new feature at the bottom of Godot's Gizmos menu.
- **Light Shafts**
  - Provides a `LightShaft3D` node which automatically generates a light shaft mesh given an outline path and a light source reference. Check out the examples scene.
- **Lines & Trails 3D**
  - 3D lines and trails for Godot.
- **Manual MultiMesh**
  - Adds a `ManualMultiMeshInstance3D` node which allows for manually specifying instance transforms/properties via child nodes. See example scene for details.
- **More Viewport Options**
  - Adds more options to the 3D editor viewport menu (the one accessed by clicking the button in the top left of each 3D viewport).
- **Nine Patch Mesh**
  - Provides a `NinePatchMesh` mesh resource which can be sliced in a manner similar to the 2D `NinePatchRect`. `TwentySevenPatchMesh` adds another resizable dimension.
- **Parallel Scene Views**
  - Allows displaying other scenes in the secondary 3D viewports. Just use the little button in the 3D view's top menu bar. Changes in current scene are only synced into parallel scenes upon save.
- **Preview 2D**
  - Allows previewing the 2D viewport directly inside the 3D viewport in the editor.
- **Procedural Texture Baker**
  - Allows baking any `Texture2D` in-place into a `PortableCompressedTexture2D`. Access via the context menu for any `Texture2D`.
- **Synced Collision Shape 3D**
  - Adds a `SyncedCollisionShape3D` node which automatically syncs a collision shape to a source `MeshInstance3D`. Intended mainly for authoring purposes in editor. Can be invoked at runtime programmatically.
- **Tile Path 3D**
  - A system for creating paths by placing tiles along a spline. See examples scene for info.
- **Transform Clusters**
  - Allows you to cluster `Node3D` nodes together so that they move in unison when any of them move. Intended for convenience in the editor, but also works at runtime.