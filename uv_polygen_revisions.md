
## UV POLYGEN REVISIONS & RELEASES

###  v 1.0  :  2014-07-04

- Initial release (JRH)


###  v 1.1  :  2014-07-21

- Added dictionary to store inputs.


###  v 1.1a :  2014-11-06

- Re-worked mesh, polygon, and face creation.


###  v 1.2  :  2014-11-09

- Added offset surfaces.


###  v 2.0  :  2015-06-17 (DAR)

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


###  v 2.1  :  2015-06-18 (DAR)

- #1 SketchUp versions running Ruby 1.8 choke on ||= used to initialize constants.
  - Change all "||=" to "="
  - Suppress "already initialized constant" warnings at top of "polygen.rb"
  - Restore $VERBOSE at bottom  of "polygen.rb"

- #2 Decreased heading sizes by one for "README.md" and revsions markdown file.

- #3 "uv_polygen_calc.rb" - Strip "=" in first position of eval strings:
  - modified methods: float(), int(), and node() accordingly.

- #4 "uv_polygen_calc.rb" - Undefine methods not working.
  - Updated the safety code to convert String methodname arrays to symbol
    methodname arrays when running Ruby 1.8.
  - Used a simple `is_a?(String)` test on the 1st position in the arrays,
    and use `map!` to convert all the members if the string test is true.

- #5 PR & Merge commit


###  v 2.2  :  2015-06-20 (DAR)

- #6 "uv_polygen_calc.rb" - NoMethodError: undefined method `clear' for NilClass
  - ~ line 395: in ensure clause: calling clear on array references failing. 
    - Removed all calls to clear, and just set all array references to nil.
  - ~ line 387: Added line `keep = priv = meths = nil` to `class<<self` block.

- #7 "uv_polygen_calc.rb" - uninitialized constant String in class Calc
  - Added to PROXY CONSTANTS sub-section of CONSTANTS section:
    `String = ::String` for Ruby 2.x+ only. (Oversight from issue #4.)
  - Added at end of UNDEFINE METHODS section, just before call to GC:
    a Ruby 2.x conditional block that undefines the local String constant.

- #8 "uv_polygen_calc.rb" - Regular Expressions float() & int() functions:
  - Fixed the regular expressions in the float() function, so that evaluation
    or conversion occurs properly.
    - Used [0-9_] & [0-9] as the numeric character classes.
    - Used [^0-9_] as the non-numeric character class.
    - Used /\A(\=|\(|\+?[^0-9_]+|\-?[^0-9_]+)/i to match the non-digit
      beginning strings that need to be evaluated.
  - In the else "conversion" clause:
    - Add more debug messages.
	- Added clause tp prepend starting underscore with "0".
	- Simplified logical decisions and decreased the number of regular
      expressions matching. IE, sequential if blocks rather than complex
	  nested if .. elsif .. else ... end etc.
  - Rewrote int() method to just call float() method, then round the result
    to an integer.
    - This way, we leverage all the work we did in the float() method with
      regular expressions & logical branching, etc.
    - Added debug messages.

- # 9 PR & Merge commit

