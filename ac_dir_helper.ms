-- little script which automatically creates/removes LookAt constraints
-- more information at https://ascobash.wordpress.com/2016/02/04/dir_-helper-for-3ds-max/

fn GetSubject obj = (
	local name = obj.name
	local subjectName = substring name 5 (name.count - 4)
	execute ("$'" + subjectName + "'")
)

fn CreateProperController subAnim = (
	local result = Euler_XYZ()
	result.x_rotation = subAnim.x_rotation
	result.y_rotation = subAnim.y_rotation
	result.z_rotation = subAnim.z_rotation
	result.axisOrder = subAnim.axisOrder
	result
)

fn RemoveLookAtConstraints = (
	for obj in $'DIR_'* do (
		local subject = GetSubject obj
		if (subject == undefined) or
			((subject.rotation.controller as string) != "Controller:Rotation_List") or
			(subject.rotation.controller.count != 2) or
			((subject.rotation.controller[1] as string) != "SubAnim:Euler_XYZ") or 
			((subject.rotation.controller[2] as string) != "SubAnim:LookAt_Constraint") then continue
		subject.rotation.controller = CreateProperController subject.rotation.controller[1]
	)
)

fn CreateLookAtConstraints = (
	for obj in $'DIR_'* do (
		local subject = GetSubject obj
		if (subject == undefined) or
			((subject.rotation.controller as string) != "Controller:Euler_XYZ") then continue
		
		local subjectLookAtConstraint = LookAt_Constraint()
		subjectLookAtConstraint.appendTarget obj 100
		subjectLookAtConstraint.StoUP_axis = 1 -- Y AXIS
		
		local subjectRotationList = Rotation_List()
		subject.rotation.controller = subjectRotationList
		subjectRotationList.available.controller = subjectLookAtConstraint
	)
)

rollout AcDirHelper "AC DIR_ Helper" width:300 (
	group "LookAt Constraints" (
		button lookAt_create "Create"
		button lookAt_remove "Remove"
	)
	
	on lookAt_create pressed do (
		CreateLookAtConstraints()
	)
	
	on lookAt_remove pressed do (
		RemoveLookAtConstraints()
	)
	
	group "Springs Helper" (
		dropdownList springsHelper_top_bone "Top Bone:"
		dropdownList springsHelper_bottom_bone "Bottom Bone:"
		editText springsHelper_sides "Number of Sides:"
		editText springsHelper_topVerticeId "Top Vertice ID:"
		editText springsHelper_bottomVerticeId "Bottom Vertice ID:"
		button springsHelper_start ""
	)
	
	fn springsHelper_BlockUI = (
		springsHelper_top_bone.items = #()
		springsHelper_bottom_bone.items = #()
		springsHelper_top_bone.Enabled = false
		springsHelper_bottom_bone.Enabled = false
		springsHelper_start.Enabled = false
		springsHelper_sides.Enabled = false
		springsHelper_topVerticeId.Enabled = false
		springsHelper_bottomVerticeId.Enabled = false
	)
	
	fn springsHelper_UpdateUI  = (
		if ($ == undefined or $.modifiers == undefined) then (
			springsHelper_start.text = "Select an Object"
			springsHelper_BlockUI()
		) else (			
			skinModifier = ModPanel.GetCurrentObject()
			if ClassOf(skinModifier) == Skin then (
				global boneNames = for i=1 to (SkinOps.GetNumberBones skinModifier) 
					collect (SkinOps.GetBoneName skinModifier i 0)
				springsHelper_top_bone.items = boneNames
				springsHelper_bottom_bone.items = boneNames
				if (SkinOps.GetNumberBones skinModifier >= 2) do (
					springsHelper_top_bone.selection = 2
				)
				springsHelper_top_bone.Enabled = true
				springsHelper_bottom_bone.Enabled = true
				springsHelper_start.Enabled = true
				springsHelper_sides.Enabled = true
				springsHelper_topVerticeId.Enabled = true
		        springsHelper_bottomVerticeId.Enabled = true
				springsHelper_sides.text = "6"
				springsHelper_topVerticeId.text = "0"
				springsHelper_bottomVerticeId.text = (SkinOps.GetNumberVertices(skinModifier) - 1) as string
				springsHelper_start.text = "Set Weights"
			) else (
				springsHelper_start.text = "Skin Modifier Required"
				springsHelper_BlockUI()
			)
		)
	)
	
	on springsHelper_start pressed do (
		skinModifier = ModPanel.GetCurrentObject()
		if (skinModifier == undefined or ClassOf(skinModifier) != Skin) then (
			springsHelper_UpdateUI()
		) else (
			if (springsHelper_sides.text == "") then (
				MessageBox("Enter number of sides")
			) else (
				local skinVerts = SkinOps.GetNumberVertices(skinModifier)
				
				local topVerticeId = springsHelper_topVerticeId.text as integer + 1
				local bottomVerticeId = springsHelper_bottomVerticeId.text as integer + 1
				local sides = springsHelper_sides.text  as integer
				
				if (bottomVerticeId < topVerticeId) then (
					MessageBox("Not implemented")
					throw "stop"
				)
				
				local totalVertices = 1 + bottomVerticeId - topVerticeId
				local steps = (totalVertices / sides) as integer - 1
				
				local topBone = springsHelper_top_bone.selection
				local bottomBone = springsHelper_bottom_bone.selection
				
				SkinOps.SetVertexWeights skinModifier topVerticeId topBone 1.0
				SkinOps.SetVertexWeights skinModifier topVerticeId bottomBone 0.0
 				SkinOps.SetVertexWeights skinModifier bottomVerticeId topBone 0.0
 				SkinOps.SetVertexWeights skinModifier bottomVerticeId bottomBone 1.0
				
				for i = 0 to steps do (
					local value = (i as float) / steps
					
					for j = 0 to sides - 1 do (
						local verticeId = topVerticeId + i*sides + j
						SkinOps.SetVertexWeights skinModifier verticeId topBone (1.0 - value)
						SkinOps.SetVertexWeights skinModifier verticeId bottomBone value
					)
				)

				print("OK")
			)
		)
	)
	
    on AcDirHelper open do (
        springsHelper_UpdateUI()
		callbacks.addScript #modPanelSelChanged "AcDirHelper.springsHelper_UpdateUI()" id:#springsHelper_UpdateUI
	)
	
	on AcDirHelper close do (
		callbacks.removeScripts #modPanelSelChanged id:#springsHelper_UpdateUI
	)
)

try( DestroyDialog AcDirHelper )catch( )
CreateDialog AcDirHelper

