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
)

try( DestroyDialog AcDirHelper )catch( )
CreateDialog AcDirHelper

