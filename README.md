 ============================================================================
  DETAILS:

  Name        :  UV Polygen

  Description :  U-V Polygon Mesh Generator Plugin with Offset Surfaces.

  Menu Item   :  Extensions > U-V PolyGen

  Date        :  2014-07-04 - original release of v1.0

  License     :  MIT License

 ----------------------------------------------------------------------------
  COPYRIGHT(S):

  (C) 2014 by Jim Hamilton (Jimhami42 at GitHub.com)
  (C) 2015 by Daniel A. Rathbun

 ----------------------------------------------------------------------------
  DISCLAIMER OF WARRANTY:

  THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

 ----------------------------------------------------------------------------
  TERMS OF USE:

  Released under the MIT License, which basically says:
    Permission granted to freely use this code as long as these terms and 
    the copyright lines are included in any derivative work(s). ~JRH

 ============================================================================


## UV POLYGEN FREE

### Features

- 'Guidepoint at Origin' menu toggle
  - Adds a guidepoint at the mesh origin, on the current Layer (in free edition.)

- 'Scale to Model Unit' menu toggle
  - Scales the resulting mesh to the model unit.
  - This is applied to ALL last saved parameters,
    so is used on the next new mesh parameter inputbox.
  - This then is suggested for ALL new meshes ...
      (but can be overridden on individual meshes.)
      When overridden, the mesh's individual saved
      parameters get the overridden setting.
  - Override on mesh does not change global default.
 
  
### Entering Parameters

- U and V Ranges, along with the Steps are considered unitless.

- If the input begins with a numeric, then the input will be converted to a float or an integer.

- Mathematical expressions can be used for most numerical parameters.
  - If the input does not start with a numeric, or it begins with '=', then it with be evaluated as an expression.
  - The Math library module is mixed in, making constants like PI, E and trigonometry functions local.
  - E can be accessed as e, and PI can be accessed as Pi or pi.
  - Other numeric methods have added local function wrappers:
    - abs(num), ceil(num), deg(num), floor(num), rad(num), round(num,places), trunc(num)
	- deg(), aliased as deg2rad() [*SketchUp uses radians internally]
	- rad(), aliased as rad2deg()
  - If the user untoggled autoscale, then they can use the scale function in their input formulae, to get the scale factor for the model units. (The scale function has no arguments.)
  - If autoscale is left ON, then x, y and z are scaled to the model units.

- "Retry" prompt to reset parameters upon cancel.
  - When the user cancels the inputbox, in free edition, they are presented with a query to Retry or Cancel. The retry resets the input fields and redisplays the parameter inputbox. Useful if the entries get so far out of whack that the user is confused. They can then just reset rather than cancel completely and have to restart the command via the menus (or shortcut key.)

- Parameter values are validated, and upon error, the parameter inputbox is redisplayed with an error message in the caption bar, along with a parameter number, where the error happened.
  

