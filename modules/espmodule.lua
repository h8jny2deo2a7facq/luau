local espModule = {
	objectCache = {},
	configuration = {
		names = false,
		toolName = false,
		distance = false,
		healthText = false,
		tracers = false,

		nameColor = Color3.fromRGB(255, 255, 255),
		nameOutline = false,
		nameOutlineColor = Color3.fromRGB(1, 1, 1),

		toolNameColor = Color3.fromRGB(255, 255, 255),
		toolNameOutline = false,
		toolNameOutlineColor = Color3.fromRGB(1, 1, 1),

		distanceColor = Color3.fromRGB(255, 255, 255),
		distanceOutline = false,
		distanceOutlineColor = Color3.fromRGB(1, 1, 1),

		healthTextColor = Color3.fromRGB(255, 255, 255),
		healthTextOutline = false,
		healthTextOutlineColor = Color3.fromRGB(1, 1, 1),

		tracerOrigin = "Top",
		tracerColor = Color3.fromRGB(255, 255, 255)
	}
}

local runService = game:GetService("RunService")
local players = game:GetService("Players")

local client = players.LocalPlayer
local camera = workspace.CurrentCamera
local viewportSize = camera.ViewportSize

local newCFrame = CFrame.new
local newVector3 = Vector3.new
local newVector2 = Vector2.new
local tan = math.tan
local rad = math.rad
local floor = math.floor

local tracerOrigins = {
	["Top"] = newVector2(viewportSize.X * 0.5, 0),
	["Bottom"] = newVector2(viewportSize.X * 0.5, viewportSize.Y)
}

local function getToolName(player: Player): string
	local character = player.Character or player.CharacterAdded:Wait()
	local tool = character:FindFirstChildOfClass("Tool")

	if tool then
		return tool.Name
	end

	return "[No Tool]"
end

local function drawObject(objectName: string, properties: table): unknown
	local object = Drawing.new(objectName)

	for index, property in properties do
		object[index] = property
	end

	return object
end

function espModule.getRootPart(player: Player): Instance
	local character = player.Character or player.CharacterAdded:Wait()

	return character and character:FindFirstChild("HumanoidRootPart")
end

function espModule.getHealth(player: Player): number
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character and character:FindFirstChild("Humanoid")

	if humanoid then
		return humanoid.Health
	end
end

function espModule.getScaleFactor(depth: number): number
	local fieldOfView = camera.FieldOfView
	local scaleFactor = 1 / (depth * tan(rad(fieldOfView * 0.5)) * 2) * 100

	return scaleFactor
end

function espModule.getPlayerData(position: Vector3): (Vector2, number, boolean, number)
	local rootPartPosition, onScreen = camera:WorldToViewportPoint(position)
	local scaleFactor = espModule.getScaleFactor(rootPartPosition.Z)
	local distance = (camera.CFrame.Position - position).Magnitude
	local height = floor(60 * scaleFactor)

	return rootPartPosition, distance, onScreen, height
end

function espModule.addObjects(player: Player): void
	local objects = {
		tracer = drawObject("Line", {Transparency = 1}),
		healthText = drawObject("Text", {Transparency = 1, Center = true, Size = 13, Font = 2}),
		name = drawObject("Text", {Transparency = 1, Center = true, Size = 13, Font = 2}),
		distance = drawObject("Text", {Transparency = 1, Center = true, Size = 13, Font = 2}),
		toolName = drawObject("Text", {Transparency = 1, Center = true, Size = 13, Font = 2})
	}

	espModule.objectCache[player] = objects
end

function espModule.removeObjects(player: Player): void
	local objectCache = espModule.objectCache[player]

	if objectCache then
		for index, object in objectCache do
			object:Destroy()
			objectCache[index] = nil
		end

		espModule.objectCache[player] = nil
	end
end

function espModule:Load(): void
	for _, player in players:GetPlayers() do
		if player ~= client then
			espModule.addObjects(player)
		end
	end

	players.PlayerAdded:Connect(function(player)
		espModule.addObjects(player)
	end)

	players.PlayerRemoving:Connect(function(player)
		espModule.removeObjects(player)
	end)

	runService:BindToRenderStep("espRendering", 201, function()
		for player, objects in espModule.objectCache do
			local rootPart = espModule.getRootPart(player)

			if rootPart then
				local rootPartPosition, distance, onScreen, height = espModule.getPlayerData(rootPart.Position)
				local playerHealth = espModule.getHealth(player)
				local toolName = getToolName(player)

				objects.name.Visible = onScreen and espModule.configuration.names
				objects.name.Position = newVector2(rootPartPosition.X, rootPartPosition.Y - height * 0.5 + -30)
				objects.name.Color = espModule.configuration.nameColor
				objects.name.Outline = espModule.configuration.nameOutline
				objects.name.OutlineColor = espModule.configuration.nameOutlineColor
				objects.name.Text = player.Name
				
				objects.toolName.Visible = onScreen and espModule.configuration.toolName
				objects.toolName.Position = newVector2(rootPartPosition.X, rootPartPosition.Y - height * 0.5 + -45)
				objects.toolName.Color = espModule.configuration.toolNameColor
				objects.toolName.Outline = espModule.configuration.toolNameOutline
				objects.toolName.OutlineColor = espModule.configuration.toolNameOutlineColor
				objects.toolName.Text = toolName

				objects.distance.Visible = onScreen and espModule.configuration.distance
				objects.distance.Position = newVector2(rootPartPosition.X, rootPartPosition.Y - height * 0.5 + -15)
				objects.distance.Color = espModule.configuration.distanceColor
				objects.distance.Outline = espModule.configuration.distanceOutline
				objects.distance.OutlineColor = espModule.configuration.distanceOutlineColor
				objects.distance.Text = "[" .. tostring(floor(distance)) .. " Studs]"

				objects.healthText.Visible = onScreen and espModule.configuration.healthText
				objects.healthText.Position = newVector2(rootPartPosition.X + 50, rootPartPosition.Y - height * 0.5 + -5)
				objects.healthText.Color = espModule.configuration.healthTextColor
				objects.healthText.Outline = espModule.configuration.healthTextOutline
				objects.healthText.OutlineColor = espModule.configuration.healthTextOutlineColor
				objects.healthText.Text = playerHealth and tostring(floor(playerHealth)) .. "%"

				objects.tracer.Visible = onScreen and espModule.configuration.tracers
				objects.tracer.Color = espModule.configuration.tracerColor
				objects.tracer.From = tracerOrigins[espModule.configuration.tracerOrigin]
				objects.tracer.To = rootPartPosition
			end
		end
	end)
end

return espModule
