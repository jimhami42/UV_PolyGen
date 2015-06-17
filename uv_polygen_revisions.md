

# UV POLYGEN REVISIONS & RELEASES

##  v 1.0  :  2014-07-04

- Initial release (JRH)


##  v 1.1  :  2014-07-21

- Added dictionary to store inputs.


##  v 1.1a :  2014-11-06

- Re-worked mesh, polygon, and face creation.


##  v 1.2  :  2014-11-09

- Added offset surfaces.


##  v 2.0  :  2015-06-17 (DAR)

- Ruby Best Practices Overhaul.
  - Proper Author / Plugin module nesting.
  - Split functionality into separate files.
  - All files have an encoding "magic comment."
  - Revisions rewritten as markdown (for GitHub repo.)
  - Re-packaged as a SketchupExtension compatible plugin.
  - All model changes are now within undo operation(s).
  - Plugin settings saved in registry (Win) / plist (Mac).
  - Model level attribute dictionary now named:
      "Jimhami42_UVPolyGen" (old dictionaries replaced.)

- Added Guidepoint at Origin menu toggle
  - Added on the current Layer (in free edition.)

- Added Scale (default) menu toggle
  - This is applied to ALL last saved parameters,
    so is used on the next new mesh parameter inputbox.
  - This then is suggested for ALL new meshes ...
      (but can be overridden on individual meshes.)
      When overridden, the mesh's individual saved
      parameters get the overridden setting.
  - Override on mesh does not change global default.
 
- Added new Calc class to provide a safe code instance in
  which to do mathematical calculations. 
  - The Math library module is mixed in, making constants
    like PI, E and trigonometry functions local.
  - If the user untoggled autoscale, then they can use the
    scale() function in their input formulae, to get the
	scale factor for the model units.
  - If autoscale is left ON, then x, y and z are scaled
    to the model units.
  
- Added a "Retry" prompt to reset parameters upon cancel.
  - When the user cancels the inputbox, in free edition,
    they are presented with a query to Retry or Cancel.
	The retry resets the input fields and redisplays the
	parameter inputbox. Useful if the entries get so far
	out of whack that the user is confused. They can then
	just reset rather than cancel completely and have to
	restart the command via the menus (or shortcut key.)

- Overhauled the post-input parameter handling. Values
  are validated, and upon error, the parameter inputbox
  is redisplayed with an error message in the caption bar,
  along with a parameter number, where the error happened.
  
- Added parameter dictionary to each mesh group.
  - Used by Pro Only Modify command.
	
* Forked code for UV-PolyGen-Pro edition.

