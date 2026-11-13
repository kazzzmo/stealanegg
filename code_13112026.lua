local IGNORED_SCREEN_GUIS = {
	BananaDynamicIsland = true,
	FiggyDynamicIsland = true,
	RobloxGui = true,
	TopBarApp = true,
	TouchGui = true,
	Chat = true,
	BubbleChat = true,
	ExperienceChat = true,
	BackpackGui = true,
	PlayerList = true,
	InGameMenu = true,
	PurchasePrompt = true,
	TeleportGui = true,
}
local EXECUTOR_KEYWORDS = {
	"delta", "deltax", "deltaicon", "deltalogo", "executor", "rgui", "mobilegui",
	"codex", "arceus", "fluxus", "hydrogen", "vega", "trigon", "evon", "krnl",
	"synapse", "scripthub", "script hub", "autoexecute", "rconsole", "executor",
	"keysystem", "key system", "exec", "executoricon", "executorlogo",
}
local function getUiRoots()
	local roots, seen = {}, {}
	local function add(r)
		if r and not seen[r] then
			seen[r] = true
			table.insert(roots, r)
		end
	end
	pcall(function() add(CoreGui) end)
	if gethui then pcall(function() add(gethui()) end) end
	if get_hidden_gui then pcall(function() add(get_hidden_gui()) end) end
	if gethiddenui then pcall(function() add(gethiddenui()) end) end
	if LocalPlayer then
		add(LocalPlayer:FindFirstChildOfClass("PlayerGui"))
	end
	return roots
end
local function getViewportWidth()
	local cam = Workspace and Workspace.CurrentCamera
	if cam and cam.ViewportSize and cam.ViewportSize.X > 0 then
		return cam.ViewportSize.X
	end
	return 1000
end
local function getViewportHeight()
	local cam = Workspace and Workspace.CurrentCamera
	if cam and cam.ViewportSize and cam.ViewportSize.Y > 0 then
		return cam.ViewportSize.Y
	end
	return 600
end
local function getEffectiveBoxSize(guiObj)
	if not guiObj then return 0, 0 end
	local aw, ah = guiObj.AbsoluteSize.X, guiObj.AbsoluteSize.Y
	if aw >= 16 and ah >= 16 then
		return aw, ah
	end
	local okS, sz = pcall(function() return guiObj.Size end)
	if okS and sz and sz.X and sz.Y then
		local ox, oy = sz.X.Offset or 0, sz.Y.Offset or 0
		if ox >= 16 and oy >= 16 then
			return ox, oy
		end
	end
	return aw, ah
end
local function isInsideLargeWindowFrame(obj)
	if not obj then return false end
	local vpW = getViewportWidth()
	local ox = obj.AbsolutePosition.X
	if ox >= 40 and ox <= vpW * 0.18 then
		return false
	end
	if State.FiggyMainWindow and (obj == State.FiggyMainWindow or obj:IsDescendantOf(State.FiggyMainWindow)) then
		return true
	end
	local p = obj.Parent
	while p and not p:IsA("ScreenGui") do
		if p:IsA("GuiObject") then
			local pw, ph = getEffectiveBoxSize(p)
			if pw >= 320 and ph >= 220 and p.AbsolutePosition.X > vpW * 0.16 then
				local bgT = p.BackgroundTransparency or 0
				if bgT < 0.90 then
					return true
				end
			end
		end
		p = p.Parent
	end
	return false
end
local function isFiggyWindowGui(gui)
	if not gui then return false end
	if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then return false end
	local gName = gui.Name or ""
	if IGNORED_SCREEN_GUIS[gName] or gName:find("^Old_") then return false end
	if gui:GetAttribute("__VerifiedFiggyWindowGui") == true then return true end
	local okD, desc = pcall(function() return gui:GetDescendants() end)
	if not okD or type(desc) ~= "table" then return false end
	local hasScriptEditor = false
	local hasFiggyMarker = false
	for _, d in ipairs(desc) do
		if d:IsA("TextBox") then
			local bt = d.Text or ""
			if #bt > 120 or string.find(bt, "loadstring", 1, true) then
				hasScriptEditor = true
			end
		elseif d:IsA("TextLabel") or d:IsA("TextButton") then
			local t = (d.Text or ""):match("^%s*(.-)%s*$") or ""
			if t == "Figgy Hub" or t == "Tomato Hub" or t == "FrostyFig"
				or t == "Steal an Egg" or t == "Cướp Trứng" or t == "Steal An Egg"
				or t == "WHAT'S NEW" or t == "CÓ GÌ MỚI"
				or t == "AUTO STEAL" or t == "TỰ ĐỘNG CƯỚP TRỨNG"
				or t == "This session" or t == "Phiên chơi này"
				or t:find("^v%d+%.%d+")
				or t:find("^QUICK BAR %d+$") or t:find("^THANH NHANH %d+$")
			then
				hasFiggyMarker = true
			end
		end
	end
	if hasFiggyMarker and not hasScriptEditor then
		gui:SetAttribute("__VerifiedFiggyWindowGui", true)
		gui:SetAttribute("__IsExecutorGui", false)
		return true
	end
	return false
end
local function isDeltaOrExecutorGui(gui)
	if not gui then return false end
	if gui:GetAttribute("__VerifiedFiggyWindowGui") == true then return false end
	local gName = string.lower(gui.Name or "")
	for _, kw in ipairs(EXECUTOR_KEYWORDS) do
		if string.find(gName, kw, 1, true) then
			gui:SetAttribute("__IsExecutorGui", true)
			return true
		end
	end
	if isFiggyWindowGui(gui) then
		gui:SetAttribute("__IsExecutorGui", false)
		return false
	end
	local okD, desc = pcall(function() return gui:GetDescendants() end)
	if not okD or type(desc) ~= "table" then return false end
	local vpW = getViewportWidth()
	for _, d in ipairs(desc) do
		if d:IsA("TextBox") then
			local bt = d.Text or ""
			if #bt > 120 or string.find(bt, "loadstring", 1, true) then
				gui:SetAttribute("__IsExecutorGui", true)
				return true
			end
		elseif (d:IsA("ImageButton") or d:IsA("TextButton")) and not isInsideLargeWindowFrame(d) then
			local dx = d.AbsolutePosition.X
			local dy = d.AbsolutePosition.Y
			local dw, dh = getEffectiveBoxSize(d)
			if dx > vpW * 0.18 and dx < vpW * 0.75 and dy >= 30 and dy <= 320 and dw >= 24 and dw <= 72 and dh >= 24 and dh <= 72 then
				gui:SetAttribute("__IsExecutorGui", true)
				return true
			end
		end
	end
	return false
end
local function cleanupPreviousOverlaysAndDeduplicate()
	local figgyGuis = {}
	local vpW = getViewportWidth()
	local vpH = getViewportHeight()
	for _, root in ipairs(getUiRoots()) do
		local okCh, children = pcall(function() return root:GetChildren() end)
		if okCh and type(children) == "table" then
			for _, gui in ipairs(children) do
				local gName = gui.Name or ""
				if gName ~= "BananaDynamicIsland" and gName ~= "FiggyDynamicIsland" then
					local isExec = isDeltaOrExecutorGui(gui)
					local isFiggy = (not isExec) and isFiggyWindowGui(gui)
					pcall(function()
						for _, d in ipairs(gui:GetDescendants()) do
							local isOverlay = (d.Name == "BananaCatOverlay" or d.Name == "BananaCatExactOverlay" or d.Name == "BananaCatFixedOverlay" or d.Name == "BananaCatCircleAvatar" or d.Name == "GoldBadgeInnerDisc" or d.Name == "BananaCatBadgeImage" or d.Name == "BananaCatInnerSprite")
							if isOverlay then
								local par = d.Parent
								local isWrongCentralAttachment = false
								if par and par:IsA("GuiObject") and not isInsideLargeWindowFrame(par) then
									local pX = par.AbsolutePosition.X
									local pY = par.AbsolutePosition.Y
									local isProtectedOnion = (State.OnionButton ~= nil and par == State.OnionButton)
										or (State.RightOnionDone ~= nil and par == State.RightOnionDone)
										or (par:GetAttribute("__RightOnionDone") ~= nil)
										or (State.HeaderBadgeFrame ~= nil and par == State.HeaderBadgeFrame)
									if not isProtectedOnion then
										local inOnionBand = (pX >= vpW * 0.02 and pX <= vpW * 0.20 and pY >= 70 and pY <= vpH * 0.82)
										if State.OnionButton ~= nil then
											isWrongCentralAttachment = true
										elseif not inOnionBand then
											isWrongCentralAttachment = true
										end
									end
								end
								if isExec or isWrongCentralAttachment then
									d:Destroy()
									if par then
										par:SetAttribute("__RestoredOrig", true)
										if par:IsA("ImageLabel") or par:IsA("ImageButton") then
											par.ImageTransparency = 0
											par.BackgroundTransparency = 0
											local origImg = par:GetAttribute("__OrigImageAsset")
											if origImg and origImg ~= "" then par.Image = origImg end
										elseif par:IsA("Frame") then
											par.BackgroundTransparency = 0
										end
										local forcedCorner = par:FindFirstChild("BananaCatForcedCorner")
										if forcedCorner then
											forcedCorner:Destroy()
										end
										for _, sib in ipairs(par:GetDescendants()) do
											sib:SetAttribute("__RestoredOrig", true)
											if sib:IsA("ImageLabel") or sib:IsA("ImageButton") then
												sib.ImageTransparency = 0
												local origImg = sib:GetAttribute("__OrigImageAsset")
												if origImg and origImg ~= "" then sib.Image = origImg end
											elseif sib:IsA("UIStroke") and sib.Name ~= "LuxuryGoldCircleStroke" then
												sib.Transparency = 0
												sib.Enabled = true
											end
										end
									end
								end
							elseif not isFiggy and d:IsA("UIStroke") and (d.Name == "LuxuryGoldCircleStroke" or d.Name == "LuxuryGoldStroke") then
								local grad = d:FindFirstChild("LuxuryGoldGradient")
								if grad then grad:Destroy() end
								local isScaled = false
								pcall(function()
									if d.StrokeSizingMode == Enum.StrokeSizingMode.ScaledSize then
										isScaled = true
									end
								end)
								if isScaled then
									d.Name = "UIStroke"
									d.Thickness = 0.06
									d.Color = Color3.fromRGB(42, 30, 38)
									d.Transparency = 0
								end
							end
						end
					end)
					if isFiggy then
						table.insert(figgyGuis, gui)
					end
				end
			end
		end
	end
	if #figgyGuis > 1 then
		for i = 2, #figgyGuis do
			pcall(function()
				figgyGuis[i].Enabled = false
				figgyGuis[i]:Destroy()
			end)
		end
	end
	return figgyGuis[1]
end
local SOUND_CONFIG = {
	open   = { id = "rbxassetid://6895079853", vol = 0.56, spd = 1.06 },
	close  = { id = "rbxassetid://6895079853", vol = 0.45, spd = 0.88 },
	logo   = { id = "rbxassetid://6895079853", vol = 0.62, spd = 1.14 },
	tap    = { id = "rbxassetid://6026984224", vol = 0.48, spd = 1.14 },
	action = { id = "rbxassetid://4590662766", vol = 0.54, spd = 1.08 },
}
local function getCachedSound(kind)
	local key = kind or "tap"
	local cfg = SOUND_CONFIG[key] or SOUND_CONFIG.tap
	local snd = State.CachedSounds[key]
	if not (snd and snd.Parent) then
		snd = Instance.new("Sound")
		snd.Name = "BananaGoldSfx_" .. key
		snd.SoundId = cfg.id
		snd.Volume = cfg.vol
		snd.PlaybackSpeed = cfg.spd
		snd.Parent = SoundService
		State.CachedSounds[key] = snd
	end
	return snd
end
task.defer(function()
	pcall(function()
		for k in pairs(SOUND_CONFIG) do
			getCachedSound(k)
		end
	end)
end)
local lastSoundClock = 0
local function playUiSound(kind)
	if not State.SoundEnabled then return end
	local now = os.clock()
	if kind == "tap" and (now - lastSoundClock < 0.045) then return end
	lastSoundClock = now
	pcall(function()
		local snd = getCachedSound(kind or "tap")
		snd.TimePosition = 0
		if SoundService.PlayLocalSound then
			pcall(function() SoundService:PlayLocalSound(snd) end)
		end
		pcall(function() snd:Play() end)
	end)
end
local BANANA_CAT_ASSET_ID = "98130280104069"
local BANANA_CAT_LOGO     = "rbxassetid://98130280104069"
local TOMATO_ONION_IMAGE  = "rbxassetid://98130280104069"
local DOWN_ARROW_ICON     = "rbxassetid://6031091004"
local STRETCH_CAT_OFFSET  = Vector2.new(0, 0)
local STRETCH_CAT_SIZE    = Vector2.new(0, 0)
local CIRCLE_CORNER_UDIM  = UDim.new(1, 0)
local SQUARE_CORNER_UDIM  = UDim.new(0.22, 0)
local function isFiggyPurpleColor(col)
	if not col then return false end
	if col.B > 0.24 and col.R > 0.14 and (col.B - col.G) > 0.04 and col.B >= col.R * 0.85 then
		if (col.B - col.G) > 0.05 or (col.R - col.G) > 0.04 then
			return true
		end
	end
	return false
end
local function hasPurpleGradient(obj)
	if not obj then return false end
	local grad = obj:FindFirstChildOfClass("UIGradient")
	if grad and grad.Color and grad.Color.Keypoints then
		for _, kp in ipairs(grad.Color.Keypoints) do
			if isFiggyPurpleColor(kp.Value) then
				return true
			end
		end
	end
	return false
end
local GOLD_METALLIC_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 242, 175)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(222, 176, 66)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(142, 102, 24)),
})
local COIN_SURFACE_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 242, 185)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(234, 190, 86)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(182, 134, 42)),
})
local TITLE_GOLD_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 238, 178)),
	ColorSequenceKeypoint.new(0.55, Color3.fromRGB(236, 198, 96)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(196, 152, 54)),
})
local function applyMetallicGoldGradient(target)
	if not target then return end
	local grad = target:FindFirstChild("LuxuryGoldGradient") or Instance.new("UIGradient")
	grad.Name = "LuxuryGoldGradient"
	grad.Rotation = 45
	grad.Color = GOLD_METALLIC_SEQ
	grad.Parent = target
	return grad
end
local function applyCoinSurfaceGoldGradient(target)
	if not target then return end
	local grad = target:FindFirstChild("CoinSurfaceGoldGrad") or Instance.new("UIGradient")
	grad.Name = "CoinSurfaceGoldGrad"
	grad.Rotation = 65
	grad.Color = COIN_SURFACE_SEQ
	grad.Parent = target
	return grad
end
local function applyGoldGradientToTitle(titleLbl)
	if not titleLbl or titleLbl:FindFirstChild("BananaGoldTitleGrad") then return end
	titleLbl.TextColor3 = GOLD_BRIGHT_TITLE
	titleLbl.TextStrokeTransparency = 1
	local grad = Instance.new("UIGradient")
	grad.Name = "BananaGoldTitleGrad"
	grad.Rotation = 90
	grad.Color = TITLE_GOLD_SEQ
	grad.Parent = titleLbl
end
local function buildFullCatGoldCoin(parentContainer, strokeThickness, zBase, isRoundedSquare)
	local targetCornerRadius = isRoundedSquare and SQUARE_CORNER_UDIM or CIRCLE_CORNER_UDIM
	local innerScale = isRoundedSquare and 0.88 or 0.86
	local innerCornerRadius = isRoundedSquare and UDim.new(0.18, 0) or UDim.new(0.35, 0)
	local coinDisc = parentContainer:FindFirstChild("BananaCatCircleAvatar")
	if not coinDisc then
		coinDisc = Instance.new("Frame")
		coinDisc.Name = "BananaCatCircleAvatar"
		coinDisc.AnchorPoint = Vector2.new(0.5, 0.5)
		coinDisc.Position = UDim2.fromScale(0.5, 0.5)
		coinDisc.Size = UDim2.new(1, 0, 1, 0)
		coinDisc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		coinDisc.BackgroundTransparency = 0
		coinDisc.BorderSizePixel = 0
		coinDisc.ClipsDescendants = true
		coinDisc.Active = false
		coinDisc.ZIndex = zBase or 25
		coinDisc.Parent = parentContainer
		local corner = Instance.new("UICorner")
		corner.CornerRadius = targetCornerRadius
		corner.Parent = coinDisc
		applyCoinSurfaceGoldGradient(coinDisc)
	else
		local corner = coinDisc:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", coinDisc)
		corner.CornerRadius = targetCornerRadius
	end
	local stroke = coinDisc:FindFirstChild("LuxuryGoldCircleStroke") or Instance.new("UIStroke")
	stroke.Name = "LuxuryGoldCircleStroke"
	stroke.Color = GOLD_BORDER_STROKE
	stroke.Thickness = strokeTh
