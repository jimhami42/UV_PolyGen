
### UV POLYGEN REVISIONS & RELEASES

####  v 1.0  :  2014-07-04

- Initial release (JRH)


####  v 1.1  :  2014-07-21

- Added dictionary to store inputs.


####  v 1.1a :  2014-11-06

- Re-worked mesh, polygon, and face creation.


####  v 1.2  :  2014-11-09

- Added offset surfaces.


####  v 2.0  :  2015-06-17 (DAR)

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


####  v 2.1  :  2015-06-18 (DAR)

- Issue #1 SketchUp versions running Ruby 1.8 choke on ||= used to initialize constants.
  - Change all "||=" to "="
  - Suppress "already initialized constant" warnings at top of "polygen.rb"
  - Restore $VERBOSE at bottom  of "polygen.rb"

- Issue #2 Decreased heading sizes by one for "README.md" and revsions markdown file.

- Issue #3 "uv_polygen_calc.rb" - Strip "=" in first position of eval strings:
  - modified methods: float(), int(), and node() accordingly.

- Issue #4 "uv_polygen_calc.rb" - Undefine methods not working.
  - Updated the safety code to convert String methodname arrays to symbol
    methodname arrays when running Ruby 1.8.
  - Used a simple `is_a?(String)` test on the 1st position in the arrays,
    and use `map!` to convert all the members if the string test is true.

- Issue #5 PR & Merge commit


####  v 2.2  :  2015-06-20 (DAR)

- Issue #6 "uv_polygen_calc.rb" - NoMethodError: undefined method `clear' for NilClass
  - ~ line 395: in ensure clause: calling clear on array references failing. 
    - Removed all calls to clear, and just set all array references to nil.
  - ~ line 387: Added line `keep = priv = meths = nil` to `class<<self` block.

- Issue #7 "uv_polygen_calc.rb" - uninitialized constant String in class Calc
  - Added to PROXY CONSTANTS sub-section of CONSTANTS section:
    `String = ::String` for Ruby 2.x+ only. (Oversight from issue #4.)
  - Added at end of UNDEFINE METHODS section, just before call to GC:
    a Ruby 2.x conditional block that undefines the local String constant.

- Issue #8 "uv_polygen_calc.rb" - Regular Expressions float() & int() functions:
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

- Issue # 9 PR & Merge commit


####  v 2.3  :  2015-07-01 (DAR)


- "uv_polygen_core.rb" - get_parameters() method modifications:

  - Issue #11 : The **offset** value needs scaling to model unit when **autoscale** is true.
    - The **scale** is now applied in the **get_parameters()** method, of the "uv_polygen_core.rb"
      file, if **calc.scale != 1.0 && autoscale == true**

  - Expanded input validation to:
    - Disallow use of **::** scope operator.
	- Disallow calling the most dangerous global methods.
	- Dislallow referring to Ruby Base classes and modules.
	- Disallow **u** and **v** ranges that are zero.
	- Disallow **u** or **v** steps less than 1.
	- Disallow **u** and **v* divisions that are less than SketchUp's internal
  	  tolerance of 0.001", after applying the model unit **scale** factor.
	  - NOTE: Rolledback in v2.4
	- Disallow **u** and **v** divisions that are not finite.
	  (Another test that steps are not zero, resulting in infinite division.)
  

- "uv_polygen.rb" file modifications:

	- Added more error messages to **ERRORTXT** hash to support better parameter input.
	
	- Defined new **units_options()** method to return a reference to the active model's
	  units options provider. [Called from **Calc** class **initialize()**, so that the 
	  **Sketchup** module reference need not be exposed to instances.]

	- Issue #12 : Separated debug settings for main plugin and **Calc** class.
	  - **Calc** class now uses instance debug variables, that mirror module variables,
		that are maintained or changed in the outer plugin module. (Frozen classes cannot
		dynamically change class variables.)
		- JimHami42::UVPolyGen module variables for the **Calc** class:
		  - **@@calc_debug** : subsequent **Calc** instances will set their **@@debug** flag to this.
		  - **@@calc_debug_call** : outputs callstack in **control()** method if **@@calc_debug** is also true.
		  - **@@calc_debug_euro** : toggle decimal separator testing (needs **@@calc_debug** true.)
		  - **@@calc_global** : whether to define a **$calc** instance for testing, at startup.
	  - Cleanup debug module methods in "uv_polygen.rb":
		- Made **debug=()** an alias for **debug()**
		- Defined **debug?** query method.
		- Defined a **reload()** method to override files during testing (more elegantly.)
		- Rewrote **debug()** toggle method so that global **UVPG()** method calls the new 
		  **reload()** method, and that global **UVPG()** method can be defined at anytime,
		  not just when loading UVPolyGen with debug mode already **true**.
		- Defined new **get_calc()** module method to get a **Calc** class instance at any time.
		  If not formally debugging, and not inclined to use a global variable,... then any
		  reference can be used. Say for example a quick test from the console command line:
		  **c = Jimhami42::UVPolyGen::get_calc**


- "uv_polygen_calc.rb" : file modifications:

  - Renamed validation methods:
    - **float()** --> **floatval()**
	- **int()** --> **intval()**
	- [Now will use the former names as a math function names.]
	
  - New math function names and aliases:
    - **float()**, alias **f()**, wrapper for **#to_f**.
    - **int()**, alias **i()** & **trunc()**, wrapper for **#truncate**.
    - **rnd()** alias for **round()**, wrapper for **#round**.

  - New control and validation methods:
    - **control()** : used to control & limit calling of internal methods
	- **fail()** : local wrapper method for **::Kernel::fail()** [may use special local args]
	- **raise()** : local wrapper method for **::Kernel::raise()** [normal or no arguments]
	- **puts()**  : local wrapper method for **::Kernel::puts()**

  - Added __*ignored__ parameter to all methods that are called from outside the class, or
    from the evaluation of inputbox fields.
	- This just collects any unexpected arguments into an array, so as not to cause the
	  raising of an **ArgumentError** (wrong number of arguments) exception.

  - **floatval()** method:
  
    - Issue #13 : Fixed single numeric inputs that began with a decimal separator.
      - They were being passed to the evaluation clause instead of the conversion clause.
	    Fixed the regular expression that decided whether the string began as a numeric or
	    non-numeric.
    - Overhauled the replacing of commas with decimal points regular expression.
    - Removed the replace commas with periods and retry conditional in the **rescue** clause.
      (Not needed as the handling of commas as decimal separator has been overhauled.)

	
- "Jimhami42_uvpolygen.rb" : bumped version number to "2.3"



####  v 2.4  :  2015-07-03 (DAR)

- "uv_polygen_calc.rb" : file modifications:

  - Added an error message to **ERRORTXT** hash to support offset parameter input.

- "uv_polygen_core.rb" : file modifications:

  - get_paramters() method:
    - Issue #15 : Rolledback the 0.001" tolerance test for **ud** & **uv**.
    - Issue #16 : Added 0.001" tolerance test for **offset** when not **0.0**.
	
- "Jimhami42_uvpolygen.rb" : bumped version number to "2.4"



####  v 2.5  :  2015-07-04 (DAR)

- "uv_polygen.rb" : file modifications:

  - Added **@@debug_mesh** module var for debug conditionals that involve fine grained
    debugging of mesh generation.

	
- "uv_polygen_calc.rb" : file modifications:

  - Added **@sym** attribute and **sym()** reader method.
  
  - **Calc** class constructor sets the unit string symbol in **@sym**.
  
  - Fixed **@scale** value for Architectural inches (was getting set to feet.)

  
- "uv_polygen_core.rb" : file modifications:

  - Added **add_polygon_to_mesh()** method with **@@debug_mesh** conditionals
    that will output inspection of point arguments, and index result.
  
  - Modifications to **create_uv_polygen()** method:
      
    - **mesh** reference changed to **@mesh** (used by **add_polygon_to_mesh()**.)
	  
	- all **mesh.add_polygon** calls changed to **add_polygon_to_mesh()** calls.
	  
    - Created local vars: **calced_num_points** and **calced_num_polys**
	  (Were just mathematical expressions in mesh constructor call.)
	  
	- Modified the debug output in **ensure** clause to display both the calculated
	  points and polys (used in the constructor call,) and the actuals after adding
	  all the polygons to the mesh. (Ideally they should each be the same.)
	  
	- Offset boolean test is now **`if offset.nil? || (offset == 0.0)`**.
	  (Was just the numeric test, which might fail with floating point errors.)

  - Modifications to **get_paramters()** method:
  
	- Allow empty string, 'nil', 'none', 'no' & 'null' for offset field.
	 
    - Internally using **nil** as **offset** when set to **0.0**, (or "none" by anyway
 	  allowed string,) in the "Offset" input field.

	- Changed **offset** tolerance test to use absolute offset. (Allows negative offsets.)
	
- "Jimhami42_uvpolygen.rb" : bumped version number to "2.5"




