local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local TAG = "HawkinsSensorDoor"
local SENSOR_INTERVAL = 0.1
local COLORS = {
	Closed = Color3.fromRGB(89, 210, 183),
	Opening = Color3.fromRGB(73, 176, 255),
	Open = Color3.fromRGB(74, 230, 135),
	Closing = Color3.fromRGB(240, 177, 69),
	Fault = Color3.fromRGB(235, 72, 72),
}

local records = {}

local function setDoorState(record, state)
	record.state = state
	record.model:SetAttribute("DoorState", state)
	record.model:SetAttribute("LastTransitionTime", workspace:GetServerTimeNow())
end

local function setIndicator(record, color)
	for _, lightPart in ipairs(record.lights) do
		if lightPart.Parent then
			lightPart.Color = color
		end
	end
end

local function setPanelCollision(record, enabled)
	for _, panel in ipairs(record.collisionPanels) do
		if panel.Parent then
			panel.CanCollide = enabled
		end
	end
end

local function cancelTransition(record)
	if record.leadConnection then
		record.leadConnection:Disconnect()
		record.leadConnection = nil
	end
	for _, tween in ipairs(record.activeTweens) do
		tween:Cancel()
	end
	table.clear(record.activeTweens)
end

local function livingCharacters()
	local characters = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local rootPart = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if character and humanoid and rootPart and humanoid.Health > 0 then
			table.insert(characters, character)
		end
	end
	return characters
end

local function isOccupied(record, characters)
	if #characters == 0 or not record.zone.Parent then
		return false
	end
	record.overlapParams.IncludeInstances = characters
	local hits = workspace:GetPartBoundsInBox(record.zone.CFrame, record.zone.Size, record.overlapParams)
	for _, hit in ipairs(hits) do
		local character = hit:FindFirstAncestorOfClass("Model")
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid and humanoid.Health > 0 then
			return true
		end
	end
	return false
end

local function playSound(record, soundName, playbackSpeed)
	local sound = record.header:FindFirstChild(soundName)
	if sound and sound:IsA("Sound") then
		sound:Stop()
		sound.PlaybackSpeed = playbackSpeed or 1
		sound:Play()
	end
end

local function animateDoor(record, opening)
	record.token += 1
	local transitionToken = record.token
	cancelTransition(record)
	setPanelCollision(record, false)

	local duration = record.model:GetAttribute("OpenTime") or 0.72
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	local targetAttribute = if opening then "OpenCFrame" else "ClosedCFrame"
	setDoorState(record, if opening then "Opening" else "Closing")
	setIndicator(record, if opening then COLORS.Opening else COLORS.Closing)
	playSound(record, "DoorMotor", if opening then 1.05 else 0.86)
	if opening then
		playSound(record, "SensorChime", 1.08)
	end

	for _, movingPart in ipairs(record.movingParts) do
		local target = movingPart:GetAttribute(targetAttribute)
		if typeof(target) == "CFrame" then
			local tween = TweenService:Create(movingPart, tweenInfo, { CFrame = target })
			table.insert(record.activeTweens, tween)
		end
	end

	local leadTween = record.activeTweens[1]
	if not leadTween then
		setDoorState(record, "Fault")
		setIndicator(record, COLORS.Fault)
		warn("[HawkinsDoorController] No moving parts for " .. record.model:GetFullName())
		return
	end

	local connection
	connection = leadTween.Completed:Connect(function(playbackState)
		if connection then
			connection:Disconnect()
		end
		if record.leadConnection == connection then
			record.leadConnection = nil
		end
		if transitionToken ~= record.token or playbackState ~= Enum.PlaybackState.Completed then
			return
		end
		table.clear(record.activeTweens)

		if opening then
			setDoorState(record, "Open")
			setIndicator(record, COLORS.Open)
		else
			-- Final anti-crush check: a player entering on the last tween frame
			-- immediately reverses the panels before collision is restored.
			if isOccupied(record, livingCharacters()) then
				record.lastOccupied = os.clock()
				animateDoor(record, true)
				return
			end
			for _, movingPart in ipairs(record.movingParts) do
				local closedCFrame = movingPart:GetAttribute("ClosedCFrame")
				if typeof(closedCFrame) == "CFrame" then
					movingPart.CFrame = closedCFrame
				end
			end
			setPanelCollision(record, true)
			setDoorState(record, "Closed")
			setIndicator(record, COLORS.Closed)
		end
	end)
	record.leadConnection = connection

	for _, tween in ipairs(record.activeTweens) do
		tween:Play()
	end
end

local function setupDoor(door)
	if records[door] or not door:IsA("Model") then
		return
	end
	local zone = door:FindFirstChild("SensorZone")
	local header = door:FindFirstChild("Header")
	if not zone or not zone:IsA("BasePart") or not header or not header:IsA("BasePart") then
		warn("[HawkinsDoorController] Incomplete sensor door: " .. door:GetFullName())
		return
	end

	local record = {
		model = door,
		zone = zone,
		header = header,
		movingParts = {},
		collisionPanels = {},
		lights = {},
		activeTweens = {},
		leadConnection = nil,
		overlapParams = OverlapParams.new(),
		state = "Closed",
		token = 0,
		lastOccupied = 0,
	}
	record.overlapParams.MaxParts = 128
	record.overlapParams.RespectCanCollide = false

	for _, child in ipairs(door:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("DoorLeaf") then
			for _, movingPart in ipairs(child:GetDescendants()) do
				if movingPart:IsA("BasePart") then
					table.insert(record.movingParts, movingPart)
					if movingPart:GetAttribute("BuildRole") == "DoorPanel" then
						table.insert(record.collisionPanels, movingPart)
					end
				end
			end
		end
	end
	for _, descendant in ipairs(door:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("DoorLight") then
			table.insert(record.lights, descendant)
		end
	end

	if #record.movingParts == 0 or #record.collisionPanels ~= 2 then
		setIndicator(record, COLORS.Fault)
		warn("[HawkinsDoorController] Invalid leaf configuration: " .. door:GetFullName())
		return
	end

	for _, movingPart in ipairs(record.movingParts) do
		local closedCFrame = movingPart:GetAttribute("ClosedCFrame")
		if typeof(closedCFrame) == "CFrame" then
			movingPart.CFrame = closedCFrame
		end
	end
	setPanelCollision(record, true)
	setDoorState(record, "Closed")
	setIndicator(record, COLORS.Closed)
	records[door] = record
end

local function cleanupDoor(door)
	local record = records[door]
	if not record then
		return
	end
	record.token += 1
	cancelTransition(record)
	records[door] = nil
end

for _, door in ipairs(CollectionService:GetTagged(TAG)) do
	setupDoor(door)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(setupDoor)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(cleanupDoor)

local readyCount = 0
for _ in pairs(records) do
	readyCount += 1
end
print(string.format("[HawkinsDoorController] Ready: %d sensor doors", readyCount))

while task.wait(SENSOR_INTERVAL) do
	local now = os.clock()
	local characters = livingCharacters()
	for door, record in pairs(records) do
		if not door.Parent then
			cleanupDoor(door)
			continue
		end
		local occupied = isOccupied(record, characters)
		door:SetAttribute("SensorOccupied", occupied)
		if occupied then
			record.lastOccupied = now
			if record.state == "Closed" or record.state == "Closing" then
				animateDoor(record, true)
			end
		elseif record.state == "Open" then
			local closeDelay = door:GetAttribute("CloseDelay") or 1.25
			if now - record.lastOccupied >= closeDelay then
				animateDoor(record, false)
			end
		end
	end
end
