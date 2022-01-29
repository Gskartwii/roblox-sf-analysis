--!strict

local Figure = script.Parent :: Model
local Torso = Figure:WaitForChild("Torso") :: Part
local RightShoulder = Torso:WaitForChild("Right Shoulder") :: Motor6D
local LeftShoulder = Torso:WaitForChild("Left Shoulder") :: Motor6D
local RightHip = Torso:WaitForChild("Right Hip") :: Motor6D
local LeftHip = Torso:WaitForChild("Left Hip") :: Motor6D
local Neck = Torso:WaitForChild("Neck") :: Motor6D
local Humanoid = Figure:WaitForChild("Humanoid") :: Humanoid
local animator = Humanoid:WaitForChild("Animator") :: Animator
local pose = "Standing"

local jumpMaxLimbVelocity = 0.75

local currentAnim = ""
local currentAnimInstance: Animation? = nil
local currentAnimTrack: AnimationTrack? = nil
local currentAnimKeyframeHandler = nil
local currentAnimSpeed = 1.0
local state = "old"

local animTable = {}

type AnimationData = { id: string, weight: number }
local animNames: { [string]: { [number]: AnimationData } } = { 
	idle = 	{	
		{ id = "http://www.roblox.com/asset/?id=180435571", weight = 9 },
		{ id = "http://www.roblox.com/asset/?id=180435792", weight = 1 }
	},
	walk = 	{ 	
		{ id = "http://www.roblox.com/asset/?id=180426354", weight = 10 } 
	}, 
	run = 	{
		{ id = "run.xml", weight = 10 } 
	}, 
	jump = 	{
		{ id = "http://www.roblox.com/asset/?id=125750702", weight = 10 } 
	}, 
	fall = 	{
		{ id = "http://www.roblox.com/asset/?id=180436148", weight = 10 } 
	}, 
	climb = {
		{ id = "http://www.roblox.com/asset/?id=180436334", weight = 10 } 
	}, 
	sit = 	{
		{ id = "http://www.roblox.com/asset/?id=178130996", weight = 10 } 
	},	
	toolnone = {
		{ id = "http://www.roblox.com/asset/?id=182393478", weight = 10 } 
	},
	toolslash = {
		{ id = "http://www.roblox.com/asset/?id=129967390", weight = 10 } 
		--				{ id = "slash.xml", weight = 10 } 
	},
	toollunge = {
		{ id = "http://www.roblox.com/asset/?id=129967478", weight = 10 } 
	},
	wave = {
		{ id = "http://www.roblox.com/asset/?id=128777973", weight = 10 } 
	},
	point = {
		{ id = "http://www.roblox.com/asset/?id=128853357", weight = 10 } 
	},
	dance1 = {
		{ id = "http://www.roblox.com/asset/?id=182435998", weight = 10 }, 
		{ id = "http://www.roblox.com/asset/?id=182491037", weight = 10 }, 
		{ id = "http://www.roblox.com/asset/?id=182491065", weight = 10 } 
	},
	dance2 = {
		{ id = "http://www.roblox.com/asset/?id=182436842", weight = 10 }, 
		{ id = "http://www.roblox.com/asset/?id=182491248", weight = 10 }, 
		{ id = "http://www.roblox.com/asset/?id=182491277", weight = 10 } 
	},
	dance3 = {
		{ id = "http://www.roblox.com/asset/?id=182436935", weight = 10 }, 
		{ id = "http://www.roblox.com/asset/?id=182491368", weight = 10 }, 
		{ id = "http://www.roblox.com/asset/?id=182491423", weight = 10 } 
	},
	laugh = {
		{ id = "http://www.roblox.com/asset/?id=129423131", weight = 10 } 
	},
	cheer = {
		{ id = "http://www.roblox.com/asset/?id=129423030", weight = 10 } 
	},
}
local dances = {"dance1", "dance2", "dance3"}

-- Existance in this list signifies that it is an emote, the value indicates if it is a looping emote
local emoteNames = { wave = false, point = false, dance1 = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

function configureAnimationSet(name, fileList)
	if (animTable[name] ~= nil) then
		for _, connection in pairs(animTable[name].connections) do
			connection:Disconnect()
		end
	end
	animTable[name] = {
		count = 0,
		totalWeight = 0,
		connections = {},
	}

	-- check for config values
	local config: Instance? = script:FindFirstChild(name)
	if (config ~= nil) then
		table.insert(animTable[name].connections, config.ChildAdded:Connect(function(child) configureAnimationSet(name, fileList) end))
		table.insert(animTable[name].connections, config.ChildRemoved:Connect(function(child) configureAnimationSet(name, fileList) end))
		local idx = 1
		for _, childPart in pairs(config:GetChildren()) do
			if (childPart:IsA("Animation")) then
				table.insert(animTable[name].connections, childPart.Changed:Connect(function(property) configureAnimationSet(name, fileList) end))
				animTable[name][idx] = {}
				animTable[name][idx].anim = childPart
				local weightObject = childPart:FindFirstChild("Weight") :: NumberValue
				if weightObject == nil then
					animTable[name][idx].weight = 1
				else
					animTable[name][idx].weight = weightObject.Value
				end
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
				idx = idx + 1
			end
		end
	end

	-- fallback to defaults
	if (animTable[name].count <= 0) then
		for idx, anim in pairs(fileList) do
			animTable[name][idx] = {
				anim = Instance.new("Animation"),
				weight = anim.weight,
			}
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id
			animTable[name].count = animTable[name].count + 1
			animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
		end
	end
end

-- Setup animation objects
function scriptChildModified(child)
	local fileList = animNames[child.Name]
	if fileList ~= nil then
		configureAnimationSet(child.Name, fileList)
	end	
end

script.ChildAdded:connect(scriptChildModified)
script.ChildRemoved:connect(scriptChildModified)


for name, fileList in pairs(animNames) do 
	configureAnimationSet(name, fileList)
end	

-- ANIMATION

-- declarations
local toolAnim = "None"
local toolAnimTime = 0

local jumpAnimTime = 0
local jumpAnimDuration = 0.3

local toolTransitionTime = 0.1
local fallTransitionTime = 0.3
local jumpMaxLimbVelocity = 0.75

-- functions

function stopAllAnimations()
	local oldAnim = currentAnim

	-- return to idle if finishing an emote
	if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
		oldAnim = "idle"
	end

	currentAnim = ""
	currentAnimInstance = nil
	if currentAnimKeyframeHandler ~= nil then
		currentAnimKeyframeHandler:Disconnect()
	end

	if currentAnimTrack ~= nil then
		currentAnimTrack:Stop()
		currentAnimTrack:Destroy()
		currentAnimTrack = nil
	end
	return oldAnim
end

function setAnimationSpeed(speed)
	if speed ~= currentAnimSpeed then
		currentAnimSpeed = speed
		if currentAnimTrack then
			currentAnimTrack:AdjustSpeed(currentAnimSpeed)
		end
	end
end

function keyFrameReachedFunc(frameName)
	if frameName == "End" then

		local repeatAnim = currentAnim
		-- return to idle if finishing an emote
		if emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false then
			repeatAnim = "idle"
		end

		local animSpeed = currentAnimSpeed
		playAnimation(repeatAnim, 0.0, Humanoid)
		setAnimationSpeed(animSpeed)
	end
end

-- Preload animations
function playAnimation(animName, transitionTime, humanoid) 

	local roll = math.random(1, animTable[animName].totalWeight) 
	local origRoll = roll
	local idx = 1
	while roll > animTable[animName][idx].weight do
		roll = roll - animTable[animName][idx].weight
		idx = idx + 1
	end
	local anim = animTable[animName][idx].anim

	-- switch animation		
	if anim ~= currentAnimInstance then

		if currentAnimTrack ~= nil then
			currentAnimTrack:Stop(transitionTime)
			currentAnimTrack:Destroy()
		end

		currentAnimSpeed = 1.0

		-- load it to the humanoid; get AnimationTrack
		local newAnimTrack = animator:LoadAnimation(anim)
		currentAnimTrack = newAnimTrack
		newAnimTrack.Priority = Enum.AnimationPriority.Core

		-- play the animation
		newAnimTrack:Play(transitionTime)
		currentAnim = animName
		currentAnimInstance = anim :: Animation?

		-- set up keyframe name triggers
		if currentAnimKeyframeHandler ~= nil then
			currentAnimKeyframeHandler:Disconnect()
		end
		currentAnimKeyframeHandler = newAnimTrack.KeyframeReached:Connect(keyFrameReachedFunc)

	end

end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

local toolAnimName = ""
local toolAnimTrack: AnimationTrack? = nil
local toolAnimInstance: Animation? = nil
local currentToolAnimKeyframeHandler = nil

function toolKeyFrameReachedFunc(frameName)
	if frameName == "End" then
		playToolAnimation(toolAnimName, 0.0, Humanoid)
	end
end

function playToolAnimation(animName, transitionTime, humanoid, priority: Enum.AnimationPriority?)	 
	local roll = math.random(1, animTable[animName].totalWeight) 
	local origRoll = roll
	local idx = 1
	while (roll > animTable[animName][idx].weight) do
		roll = roll - animTable[animName][idx].weight
		idx = idx + 1
	end
	local anim = animTable[animName][idx].anim

	if toolAnimInstance ~= anim then
		if toolAnimTrack ~= nil then
			toolAnimTrack:Stop()
			toolAnimTrack:Destroy()
			transitionTime = 0
		end

		-- load it to the humanoid; get AnimationTrack
		local newAnimTrack = animator:LoadAnimation(anim)
		toolAnimTrack = newAnimTrack
		if priority then
			newAnimTrack.Priority = priority
		end

		-- play the animation
		newAnimTrack:Play(transitionTime)
		toolAnimName = animName
		toolAnimInstance = anim

		currentToolAnimKeyframeHandler = newAnimTrack.KeyframeReached:Connect(toolKeyFrameReachedFunc)
	end
end

function stopToolAnimations()
	local oldAnim = toolAnimName

	if currentToolAnimKeyframeHandler ~= nil then
		currentToolAnimKeyframeHandler:Disconnect()
	end

	toolAnimName = ""
	toolAnimInstance = nil
	if toolAnimTrack ~= nil then
		toolAnimTrack:Stop()
		toolAnimTrack:Destroy()
		toolAnimTrack = nil
	end


	return oldAnim
end

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------


function onRunning(speed)
	if state == "new" then
		if speed > 0.01 then
			pose = "Running"
			playAnimation("walk", 0.1, Humanoid)
			if currentAnimInstance and currentAnimInstance.AnimationId == "http://www.roblox.com/asset/?id=180426354" then
				setAnimationSpeed(speed / 14.5)
			end
		else
			if emoteNames[currentAnim] == nil then
				pose = "Standing"
				playAnimation("idle", 0.1, Humanoid)
			end
		end
	else 
		if speed>0 then
			pose = "Running"
		else
			pose = "Standing"
		end
	end
end

function onDied()
	pose = "Dead"
end

function onJumping()
	pose = "Jumping"
	if state == "new" then
		playAnimation("jump", 0.1, Humanoid)
		jumpAnimTime = jumpAnimDuration
	end
end

function onClimbing(speed: number)
	pose = "Climbing"
	if state == "new" then
		playAnimation("climb", 0.1, Humanoid)
		setAnimationSpeed(speed / 12.0)
	end
end

function onGettingUp()
	pose = "GettingUp"
end

function onFreeFall()
	pose = "FreeFall"
	if jumpAnimTime <= 0 and state == "new" then
		playAnimation("fall", fallTransitionTime, Humanoid)
	end
end

function onFallingDown()
	pose = "FallingDown"
end

function onSeated()
	pose = "Seated"
end

function onPlatformStanding()
	pose = "PlatformStanding"
end

function onSwimming(speed)
	if speed > 0 then
		pose = "Running"
	else
		pose = "Standing"
	end
end

function getTool(): Tool?	
	for _, kid in ipairs(Figure:GetChildren()) do
		if kid.ClassName == "Tool" then return kid :: Tool end
	end
	return nil
end

function getToolAnim(tool: Tool): StringValue?
	for _, c in ipairs(tool:GetChildren()) do
		if c.Name == "toolanim" and c.ClassName == "StringValue" then
			return c :: StringValue
		end
	end
	return nil
end

function animateTool()
	if state == "new" then
		if toolAnim == "None" then
			playToolAnimation("toolnone", toolTransitionTime, Humanoid, Enum.AnimationPriority.Idle)
			return
		end

		if toolAnim == "Slash" then
			playToolAnimation("toolslash", 0, Humanoid, Enum.AnimationPriority.Action)
			return
		end

		if toolAnim == "Lunge" then
			playToolAnimation("toollunge", 0, Humanoid, Enum.AnimationPriority.Action)
			return
		end
	else
		if toolAnim == "None" then
			RightShoulder:SetDesiredAngle(1.57)
			return
		end

		if toolAnim == "Slash" then
			RightShoulder.MaxVelocity = 0.5
			RightShoulder:SetDesiredAngle(0)
			return
		end

		if toolAnim == "Lunge" then
			RightShoulder.MaxVelocity = 0.5
			LeftShoulder.MaxVelocity = 0.5
			RightHip.MaxVelocity = 0.5
			LeftHip.MaxVelocity = 0.5
			RightShoulder:SetDesiredAngle(1.57)
			LeftShoulder:SetDesiredAngle(1.0)
			RightHip:SetDesiredAngle(1.57)
			LeftHip:SetDesiredAngle(1.0)
			return
		end
	end
end

function moveSit()
	RightShoulder.MaxVelocity = 0.15
	LeftShoulder.MaxVelocity = 0.15
	RightShoulder:SetDesiredAngle(3.14 /2)
	LeftShoulder:SetDesiredAngle(-3.14 /2)
	RightHip:SetDesiredAngle(3.14 /2)
	LeftHip:SetDesiredAngle(-3.14 /2)
end

local lastTick = 0

local function move_new(time: number)
	local amplitude = 1
	local frequency = 1
	local deltaTime = time - lastTick
	lastTick = time

	local climbFudge = 0
	local setAngles = false

	if jumpAnimTime > 0 then
		jumpAnimTime = jumpAnimTime - deltaTime
	end

	if (pose == "FreeFall" and jumpAnimTime <= 0) then
		playAnimation("fall", fallTransitionTime, Humanoid)
	elseif (pose == "Seated") then
		playAnimation("sit", 0.5, Humanoid)
		return
	elseif (pose == "Running") then
		playAnimation("walk", 0.1, Humanoid)
	elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
		stopAllAnimations()
		amplitude = 0.1
		frequency = 1
		setAngles = true
	end

	if setAngles then
		local desiredAngle = amplitude * math.sin(time * frequency)

		RightShoulder:SetDesiredAngle(desiredAngle + climbFudge)
		LeftShoulder:SetDesiredAngle(desiredAngle - climbFudge)
		RightHip:SetDesiredAngle(-desiredAngle)
		LeftHip:SetDesiredAngle(-desiredAngle)
	end

	-- Tool Animation handling
	local tool = getTool()
	if tool and tool:FindFirstChild("Handle") then
		local animStringValueObject = getToolAnim(tool)

		if animStringValueObject then
			toolAnim = animStringValueObject.Value
			-- message recieved, delete StringValue
			animStringValueObject.Parent = nil
			toolAnimTime = time + .3
		end

		if time > toolAnimTime then
			toolAnimTime = 0
			toolAnim = "None"
		end

		animateTool()		
	else
		stopToolAnimations()
		toolAnimInstance = nil
		toolAnim = "None"
		toolAnimTime = 0
	end
end

function moveJump()
	RightShoulder.MaxVelocity = jumpMaxLimbVelocity
	LeftShoulder.MaxVelocity = jumpMaxLimbVelocity
	RightShoulder:SetDesiredAngle(3.14)
	LeftShoulder:SetDesiredAngle(-3.14)
	RightHip:SetDesiredAngle(0)
	LeftHip:SetDesiredAngle(0)
end


-- same as jump for now

function moveFreeFall()
	RightShoulder.MaxVelocity = jumpMaxLimbVelocity
	LeftShoulder.MaxVelocity = jumpMaxLimbVelocity
	RightShoulder:SetDesiredAngle(3.14)
	LeftShoulder:SetDesiredAngle(-3.14)
	RightHip:SetDesiredAngle(0)
	LeftHip:SetDesiredAngle(0)
end

local function move_old(time: number)
	local amplitude
	local frequency

	if pose == "Jumping" then
		moveJump()
		return
	end

	if pose == "FreeFall" then
		moveFreeFall()
		return
	end

	if pose == "Seated" then
		moveSit()
		return
	end

	local climbFudge = 0

	if pose == "Running" then
		if (RightShoulder.CurrentAngle > 1.5 or RightShoulder.CurrentAngle < -1.5) then
			RightShoulder.MaxVelocity = jumpMaxLimbVelocity
		else			
			RightShoulder.MaxVelocity = 0.15
		end
		if (LeftShoulder.CurrentAngle > 1.5 or LeftShoulder.CurrentAngle < -1.5) then
			LeftShoulder.MaxVelocity = jumpMaxLimbVelocity
		else			
			LeftShoulder.MaxVelocity = 0.15
		end
		amplitude = 1
		frequency = 9
	elseif pose == "Climbing" then
		RightShoulder.MaxVelocity = 0.5 
		LeftShoulder.MaxVelocity = 0.5
		amplitude = 1
		frequency = 9
		climbFudge = 3.14
	else
		amplitude = 0.1
		frequency = 1
	end

	local desiredAngle = amplitude * math.sin(time * frequency)
	RightShoulder:SetDesiredAngle(desiredAngle + climbFudge)
	LeftShoulder:SetDesiredAngle(desiredAngle - climbFudge)
	RightHip:SetDesiredAngle(-desiredAngle)
	LeftHip:SetDesiredAngle(-desiredAngle)

	local tool = getTool()
	if tool then
		local animStringValueObject = getToolAnim(tool)
		if animStringValueObject then
			toolAnim = animStringValueObject.Value
			-- message recieved, delete StringValue
			animStringValueObject.Parent = nil
			toolAnimTime = time + .3
		end

		if time > toolAnimTime then
			toolAnimTime = 0
			toolAnim = "None"
		end
		animateTool()
	else
		toolAnim = "None"
		toolAnimTime = 0
	end
end

local function move(time: number)
	if state == "new" then
		move_new(time)
	else
		move_old(time)
	end
end

-- connect events
Humanoid.Died:Connect(onDied)
Humanoid.Running:Connect(onRunning)
Humanoid.Jumping:Connect(onJumping)
Humanoid.Climbing:Connect(onClimbing)
Humanoid.GettingUp:Connect(onGettingUp)
Humanoid.FreeFalling:Connect(onFreeFall)
Humanoid.FallingDown:Connect(onFallingDown)
Humanoid.Seated:Connect(onSeated)
Humanoid.PlatformStanding:Connect(onPlatformStanding)
Humanoid.Swimming:Connect(onSwimming)

-- setup emote chat hook
game:GetService("Players").LocalPlayer.Chatted:Connect(function(msg)
	if state == "new" then
		local emote = ""
		if msg == "/e dance" then
			emote = dances[math.random(1, #dances)]
		elseif (string.sub(msg, 1, 3) == "/e ") then
			emote = string.sub(msg, 4)
		elseif (string.sub(msg, 1, 7) == "/emote ") then
			emote = string.sub(msg, 8)
		end

		if (pose == "Standing" and emoteNames[emote] ~= nil) then
			playAnimation(emote, 0.1, Humanoid)
		end
	end
	if msg == "/switch new" then
		state = "new"
	elseif msg == "/switch old" then
		state = "old"
		stopAllAnimations()
		stopToolAnimations()
	end
end)

-- main program

-- initialize to idle
if state == "new" then
	playAnimation("idle", 0.1, Humanoid)
end

while Figure.Parent ~= nil do
	local _, time = wait(0.1)
	move(time)
end
