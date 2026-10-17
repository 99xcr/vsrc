--[[
	Voidscope Recolor
	- Pick a colour: your gun AND its beam / shots change to that colour
	- RightShift hides / shows the menu
	- CLIENT-SIDE ONLY: only you see the change

	Optional preselect before running:
		getgenv().VoidscopeColor = "Purple"
]]

print("[Voidscope Recolor] loading...")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local SHOT_WINDOW = 1.0          -- seconds after you fire during which new effects count as your shot
local SHOT_RADIUS = 30           -- studs from you within which a new effect counts as your shot
local OVERLAY_TRANSPARENCY = 0.6 -- only used if the texture tint isn't supported (colour wash)

-- menu look
local BUBBLY_FONT = Enum.Font.FredokaOne
local MENU_OUTLINE = Color3.fromRGB(80, 60, 130)
local BUTTON_OUTLINE = Color3.fromRGB(70, 70, 70)     -- thin outline so the Black button shows on the black menu
local BUTTON_SELECTED = Color3.fromRGB(0, 170, 255)

local COLORS = {
	{ name = "Red",        color = Color3.fromRGB(255, 0, 0) },
	{ name = "Green",      color = Color3.fromRGB(0, 255, 0) },
	{ name = "Black",      color = Color3.fromRGB(0, 0, 0) },
	{ name = "Orange",     color = Color3.fromRGB(255, 128, 0) },
	{ name = "Yellow",     color = Color3.fromRGB(255, 255, 0) },
	{ name = "Blue",       color = Color3.fromRGB(0, 100, 255) },
	{ name = "Purple",     color = Color3.fromRGB(160, 32, 240) },
	{ name = "Cyan",       color = Color3.fromRGB(0, 255, 255) },
	{ name = "Pink",       color = Color3.fromRGB(255, 100, 200) },
}

-- Rainbow: the colours run along the gun (barrel to stock) and slowly flow.
-- Set RAINBOW_SPIN to 0 if you want it to stay still.
local RAINBOW_SPIN = 0.08
local RAINBOW = { name = "Rainbow", color = Color3.fromRGB(255, 80, 200), mode = "rainbow" }
local RAINBOW_KEYS = {}
for i = 0, 6 do
	table.insert(RAINBOW_KEYS, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(0.83 * i / 6, 0.9, 1)))
end
local RAINBOW_SEQUENCE = ColorSequence.new(RAINBOW_KEYS) -- used for beams / trails / particles and the menu button

-- Glass: the gun turns see-through but stays visible (0 = solid, 1 = completely invisible)
local GLASS_TRANSPARENCY = 0.55

-- Glass uses a chrome-pearl metal look. How shiny the metal is (0 = matte, 1 = mirror)
local CHROME_REFLECTANCE = 0.45
-- ...and how strong the optional pink / teal glow lights are (see GLASS_SHEEN below, 0 = no glow)
local SHEEN_BRIGHTNESS = 3
local SHEEN_PINK = Color3.fromRGB(255, 120, 190)
local SHEEN_TEAL = Color3.fromRGB(90, 255, 230)

-- Glass = a see-through chrome-pearl metal. It runs in "pearl" mode with the glass look forced on.
-- GLASS_SHEEN: pink / teal glow lights next to the gun. Off by default (they look odd on
-- see-through metal), set it to true if you want them back.
local GLASS_SHEEN = false
local GLASS = { name = "Glass", color = Color3.fromRGB(255, 255, 255), mode = "pearl", forceGlass = true, sheen = GLASS_SHEEN }

-- Minimise icon: the planet picture the menu collapses into when you press the minimise button
-- (click or tap it to open the menu again, and you can drag it around). The picture is saved as a
-- small file and loaded with getcustomasset, which most executors have. If yours doesn't, a drawn
-- planet is used instead. To use your own image, upload it to Roblox and put its id here,
-- for example "rbxassetid://1234567890"
local MINI_ICON_ASSET = ""
local ICON_SIZE = 52
local ICON_PNG_B64 = "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"

------------------------------------------------------------------------
-- Re-run protection: clean up a previous run first
------------------------------------------------------------------------
local env = (getgenv and getgenv()) or _G
if env.VoidscopeRecolorCleanup then
	pcall(env.VoidscopeRecolorCleanup)
end

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------
local selected = nil -- current entry from COLORS, or nil for default
local shotUntil = 0
local shotCount = 0
local conns = {}
local originals = setmetatable({}, { __mode = "k" }) -- inst -> { prop = originalValue }
local hooked = setmetatable({}, { __mode = "k" })    -- tools we've hooked
local guarded = setmetatable({}, { __mode = "k" })   -- effects / sounds we already listen to
local texWatched = setmetatable({}, { __mode = "k" })
local surfaces = setmetatable({}, { __mode = "k" })  -- meshPart -> SurfaceAppearance we added (the tint)
local overlays = setmetatable({}, { __mode = "k" })  -- meshPart -> Highlight we added (colour wash)
local watchedTargets = setmetatable({}, { __mode = "k" })
local rainbowT = setmetatable({}, { __mode = "k" })       -- part -> 0..1, where it sits along the gun (rainbow / pearl)
local glassed = setmetatable({}, { __mode = "k" })       -- parts currently showing our glass look
local glassGuarded = setmetatable({}, { __mode = "k" })  -- parts we already watch for the game making them solid again
local glassOverlay = false  -- the "See-through" switch: keep the glass look on any colour
local unglassing = false
local chromed = setmetatable({}, { __mode = "k" })       -- meshes currently showing the chrome look
local flatSpread = setmetatable({}, { __mode = "k" })    -- parts of a gun that is a single piece (no end-to-end spread to colour)
local sheens = setmetatable({}, { __mode = "k" })        -- gun part -> the two glow lights we added to it (only if GLASS_SHEEN is on)
local lastSpin = 0
local hipQueued = false
local gui, gunLabel, hipLabel, statusLabel, noteLabel, glassToggleBtn
local buttons = {}

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end

local function setNote(text)
	if noteLabel then noteLabel.Text = text or "" end
end

local function setGunStatus(text)
	if gunLabel then gunLabel.Text = text end
end

local function setHipStatus(text)
	if hipLabel then hipLabel.Text = text end
end

------------------------------------------------------------------------
-- Property helpers (remember originals so Reset can put everything back)
------------------------------------------------------------------------
local function set(inst, prop, value)
	local saved = originals[inst]
	if not saved then
		saved = {}
		originals[inst] = saved
	end
	if saved[prop] == nil then
		local ok, v = pcall(function() return inst[prop] end)
		if ok then saved[prop] = v end
	end
	return (pcall(function() inst[prop] = value end))
end

local function colorsClose(a, b)
	return math.abs(a.R - b.R) < 0.01 and math.abs(a.G - b.G) < 0.01 and math.abs(a.B - b.B) < 0.01
end

local function seqIsColor(seq, color)
	for _, kp in ipairs(seq.Keypoints) do
		if not colorsClose(kp.Value, color) then return false end
	end
	return true
end

local function isEffect(inst)
	return inst:IsA("Beam") or inst:IsA("Trail") or inst:IsA("ParticleEmitter")
end

------------------------------------------------------------------------
-- Rainbow / pearl: which colour does each part of the gun get?
------------------------------------------------------------------------
local function partsUnder(root)
	local list = {}
	if root:IsA("BasePart") then table.insert(list, root) end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then table.insert(list, d) end
	end
	return list
end

-- gives every visible part a number from 0 to 1 for where it sits along the gun's longest
-- direction, so the colours run along the barrel whichever way the gun is facing
local function mapRainbow(parts)
	if not (selected and (selected.mode == "rainbow" or selected.mode == "pearl")) then return end

	local seen = {}
	for _, p in ipairs(parts) do
		if p.Transparency < 1 then table.insert(seen, p) end
	end
	if #seen == 0 then return end

	local ref = seen[1]
	for _, p in ipairs(seen) do
		if p.Size.Magnitude > ref.Size.Magnitude then ref = p end
	end

	local pts = {}
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = Vector3.new(-math.huge, -math.huge, -math.huge)
	for i, p in ipairs(seen) do
		local v = ref.CFrame:PointToObjectSpace(p.Position)
		pts[i] = v
		lo = Vector3.new(math.min(lo.X, v.X), math.min(lo.Y, v.Y), math.min(lo.Z, v.Z))
		hi = Vector3.new(math.max(hi.X, v.X), math.max(hi.Y, v.Y), math.max(hi.Z, v.Z))
	end

	local ext = hi - lo
	local axis = "X"
	if ext.Y > ext[axis] then axis = "Y" end
	if ext.Z > ext[axis] then axis = "Z" end
	local range = ext[axis]

	for i, p in ipairs(seen) do
		if range > 0.05 then
			rainbowT[p] = (pts[i][axis] - lo[axis]) / range
			flatSpread[p] = nil
		else
			rainbowT[p] = 0.5
			flatSpread[p] = true
		end
	end
	return ref
end

-- the colour a given thing should be right now
local function colorFor(inst)
	local mode = selected and selected.mode
	if mode == "rainbow" then
		local t = rainbowT[inst] or ((os.clock() * 0.6) % 1)
		return Color3.fromHSV((0.65 - t * 0.9 + os.clock() * RAINBOW_SPIN) % 1, 0.9, 1)
	elseif mode == "pearl" then
		-- clean white. If the gun is made of several parts they get a faint pink / teal sheen end to end
		local t = rainbowT[inst]
		if not t or flatSpread[inst] then return Color3.fromRGB(238, 238, 244) end
		return Color3.fromHSV(0.5 + t * 0.42, 0.16, 0.95)
	end
	return selected and selected.color or Color3.new(1, 1, 1)
end

-- lets the rainbow flow along the gun
connect(RunService.Heartbeat, function()
	if RAINBOW_SPIN == 0 or not (selected and selected.mode == "rainbow") then return end
	local now = os.clock()
	if now - lastSpin < 0.05 then return end
	lastSpin = now
	for mp in pairs(rainbowT) do
		local sa = surfaces[mp]
		if sa and sa.Parent then
			pcall(function() sa.Color = colorFor(mp) end)
		end
	end
end)

------------------------------------------------------------------------
-- Tinting the gun
-- A MeshPart's own Color is ignored once it has a texture, so we wrap the gun's
-- original texture in a SurfaceAppearance and tint THAT.
------------------------------------------------------------------------
local function removeOverlay(mp)
	local hl = overlays[mp]
	if hl then
		pcall(function() hl:Destroy() end)
		overlays[mp] = nil
	end
end

local function setOverlay(mp, color, transparency)
	local hl = overlays[mp]
	if not hl or not hl.Parent then
		-- a copy of an already-washed gun carries its overlay along: reuse it instead of stacking another
		local existing = mp:FindFirstChild("VSOverlay")
		if existing and existing:IsA("Highlight") then
			hl = existing
			hl.Adornee = mp
		else
			hl = Instance.new("Highlight")
			hl.Name = "VSOverlay"
			hl.Adornee = mp
			hl.OutlineTransparency = 1
			hl.DepthMode = Enum.HighlightDepthMode.Occluded
			hl.Parent = mp
		end
		overlays[mp] = hl
	end
	hl.FillColor = color
	hl.FillTransparency = transparency
end

-- returns "ok", "notex" (mesh has no texture yet) or "fail" (not supported here)
local function setSurfaceTint(mp, color, flat)
	local tex
	pcall(function() tex = mp.TextureID end)
	if type(tex) ~= "string" or tex == "" then
		return "notex"
	end

	local sa = surfaces[mp]
	if not sa or not sa.Parent then
		-- a copy of an already-tinted gun carries its tint layer along: reuse it instead of stacking another
		local existing = mp:FindFirstChild("VSSurface")
		if existing and existing:IsA("SurfaceAppearance") then
			sa = existing
			surfaces[mp] = sa
		else
			sa = Instance.new("SurfaceAppearance")
			sa.Name = "VSSurface"
			if not pcall(function() sa.ColorMap = tex end) then
				sa:Destroy()
				return "fail"
			end
			sa.Parent = mp
			surfaces[mp] = sa
		end
	end
	-- normally keep the tint layer pointed at the mesh's current texture (the game may have swapped it).
	-- in flat mode the texture is blanked so the gun becomes a plain colour
	pcall(function()
		local want = flat and "" or tex
		if sa.ColorMap ~= want then sa.ColorMap = want end
	end)

	if not pcall(function() sa.Color = color end) then
		pcall(function() sa:Destroy() end)
		surfaces[mp] = nil
		return "fail"
	end
	return "ok"
end

-- Chrome look = shiny white metal with the texture taken off, so the faceted mesh catches the light
-- like chrome (and the silver rings come out silver too)
local function removeSurface(mp)
	local sa = surfaces[mp]
	if sa then
		pcall(function() sa:Destroy() end)
		surfaces[mp] = nil
	end
	local existing = mp:FindFirstChild("VSSurface")
	if existing then pcall(function() existing:Destroy() end) end
end

local function chromeMesh(mp, color)
	removeOverlay(mp)
	removeSurface(mp)
	set(mp, "TextureID", "")
	-- a mesh that is already showing the glass look keeps its glass material when it is re-chromed
	-- (clicking Glass again, or the game changing its texture), otherwise it would turn into
	-- see-through metal, which is the ghosty look
	set(mp, "Material", glassed[mp] and Enum.Material.Glass or Enum.Material.Metal)
	set(mp, "Reflectance", CHROME_REFLECTANCE)
	set(mp, "Color", color)
	chromed[mp] = true
end

-- leaving the chrome look: give the mesh its own texture / material back so a normal tint can work
local function unchromeMesh(mp)
	if not chromed[mp] then return end
	chromed[mp] = nil
	local saved = originals[mp]
	if saved then
		pcall(function()
			if saved.Material ~= nil then mp.Material = saved.Material end
			if saved.Reflectance ~= nil then mp.Reflectance = saved.Reflectance end
			if saved.TextureID ~= nil then mp.TextureID = saved.TextureID end
		end)
		saved.Material = nil
		saved.Reflectance = nil
		saved.TextureID = nil
	end
end

-- Optional glow (GLASS_SHEEN): a pink glow from one side and a teal glow from the other, so the different
-- faces of the shiny white metal pick up different colours (the pearl / chrome sheen)
local function removeSheen(part)
	local made = sheens[part]
	if made then
		for _, o in ipairs(made) do
			pcall(function() o:Destroy() end)
		end
		sheens[part] = nil
	end
end

local function addSheen(part)
	if SHEEN_BRIGHTNESS <= 0 then return end
	local existing = sheens[part]
	if existing and existing[1] and existing[1].Parent then return end
	removeSheen(part)

	-- the two thinner directions of the gun are where the lights go, one on each side
	local axes = { { "X", part.Size.X }, { "Y", part.Size.Y }, { "Z", part.Size.Z } }
	table.sort(axes, function(a, b) return a[2] > b[2] end)
	local function along(name, v)
		return Vector3.new(name == "X" and v or 0, name == "Y" and v or 0, name == "Z" and v or 0)
	end
	local offset = along(axes[2][1], axes[2][2] / 2 + 0.8) + along(axes[3][1], axes[3][2] / 2 + 0.8)

	local made = {}
	local specs = { { SHEEN_PINK, offset }, { SHEEN_TEAL, -offset } }
	for _, spec in ipairs(specs) do
		local att = Instance.new("Attachment")
		att.Name = "VSSheen"
		att.Position = spec[2]
		att.Parent = part

		local light = Instance.new("PointLight")
		light.Name = "VSSheen"
		light.Color = spec[1]
		light.Range = 7
		light.Brightness = SHEEN_BRIGHTNESS
		light.Shadows = false
		light.Parent = att

		table.insert(made, att) -- removing the attachment removes its light too
	end
	sheens[part] = made
end

-- the pink / teal glow lights are only for Glass, and only if GLASS_SHEEN is on
local function wantsSheen()
	return selected ~= nil and selected.mode == "pearl" and selected.sheen ~= false
end

local function tintMesh(mp, color)
	if selected ~= nil and selected.mode == "pearl" then
		chromeMesh(mp, color)
		if not wantsSheen() then removeSheen(mp) end
		return
	end
	removeSheen(mp)
	unchromeMesh(mp)

	local result = setSurfaceTint(mp, color)
	if result == "notex" then return end

	if result == "fail" then
		setOverlay(mp, color, OVERLAY_TRANSPARENCY)
		setNote("Texture tint isn't supported here, using a colour overlay.")
	else
		removeOverlay(mp)
	end
end

-- the game may set the texture a moment after the mesh appears, so re-tint when it changes
local function watchTexture(mp)
	if texWatched[mp] then return end
	texWatched[mp] = true
	connect(mp:GetPropertyChangedSignal("TextureID"), function()
		if selected then tintMesh(mp, colorFor(mp)) end
	end)
end

------------------------------------------------------------------------
-- Glass: see-through (but not invisible) gun parts
------------------------------------------------------------------------
-- true when the gun should be see-through: the Glass colour is picked, or See-through is switched on
local function glassWanted()
	return glassOverlay or (selected ~= nil and (selected.mode == "glass" or selected.forceGlass == true))
end

local function glassify(inst)
	set(inst, "Transparency", GLASS_TRANSPARENCY)
	set(inst, "Material", Enum.Material.Glass)
	glassed[inst] = true
end

local function applyGlass(inst)
	if not glassGuarded[inst] then
		glassGuarded[inst] = true
		-- if the game makes a part solid again (e.g. when you equip the gun), make it glass again.
		-- parts the game hides completely are left alone
		connect(inst:GetPropertyChangedSignal("Transparency"), function()
			if not unglassing and glassWanted() and inst.Transparency < GLASS_TRANSPARENCY - 0.01 then
				glassify(inst)
			end
		end)
	end
	if inst.Transparency < GLASS_TRANSPARENCY - 0.01 then
		glassify(inst)
	elseif glassed[inst] and inst.Material ~= Enum.Material.Glass then
		-- already see-through, but something put the material back (re-chroming, the game):
		-- make it glass again instead of leaving see-through metal
		set(inst, "Material", Enum.Material.Glass)
	end
end

-- puts the solid look back (only touches parts that are still showing our glass look)
local function unglassAll()
	unglassing = true
	for inst in pairs(glassed) do
		local saved = originals[inst]
		if saved then
			pcall(function()
				if saved.Transparency ~= nil and inst.Transparency < 0.95 then
					inst.Transparency = saved.Transparency
				end
				if saved.Material ~= nil then inst.Material = saved.Material end
			end)
			saved.Transparency = nil
			saved.Material = nil
		end
		glassed[inst] = nil
	end
	unglassing = false
end

local function restoreAll()
	unglassAll()
	for part in pairs(sheens) do removeSheen(part) end
	for mp in pairs(chromed) do chromed[mp] = nil end
	for inst, saved in pairs(originals) do
		for prop, v in pairs(saved) do
			pcall(function() inst[prop] = v end)
		end
	end
	for k in pairs(originals) do
		originals[k] = nil
	end
	for mp in pairs(overlays) do removeOverlay(mp) end
	for mp, sa in pairs(surfaces) do
		pcall(function() sa:Destroy() end)
		surfaces[mp] = nil
	end
end

------------------------------------------------------------------------
-- Painting anything (gun parts, beams, trails, shot parts...). Returns true if it painted.
------------------------------------------------------------------------
local function paint(inst, color, isShot)
	if inst:IsA("MeshPart") and not isShot then
		set(inst, "Color", color)
		watchTexture(inst)
		tintMesh(inst, color)
		if glassWanted() then applyGlass(inst) end
		return true
	elseif inst:IsA("BasePart") then
		set(inst, "Color", color)
		if glassWanted() and not isShot then applyGlass(inst) end
		if isShot then
			-- shots become a solid glowing colour (black stays plain so it still looks black)
			if inst:IsA("MeshPart") then set(inst, "TextureID", "") end
			set(inst, "MaterialVariant", "")
			if colorsClose(color, Color3.new(0, 0, 0)) then
				set(inst, "Material", Enum.Material.SmoothPlastic)
			else
				set(inst, "Material", Enum.Material.Neon)
			end
		end
		return true
	elseif isEffect(inst) then
		if selected and selected.mode == "rainbow" then
			set(inst, "Color", RAINBOW_SEQUENCE)
		else
			set(inst, "Color", ColorSequence.new(color))
		end
		return true
	elseif inst:IsA("SpecialMesh") then
		if isShot then set(inst, "TextureId", "") end
		set(inst, "VertexColor", Vector3.new(color.R, color.G, color.B))
		return true
	elseif inst:IsA("SurfaceAppearance") then
		if inst.Name == "VSSurface" then return false end
		if isShot or (selected and selected.mode == "pearl") then set(inst, "ColorMap", "") end
		set(inst, "Color", color)
		return true
	elseif inst:IsA("Decal") or inst:IsA("Texture") then
		set(inst, "Color3", color)
		return true
	elseif inst:IsA("Light") then -- PointLight / SpotLight / SurfaceLight
		if inst.Name == "VSSheen" then return false end
		set(inst, "Color", color)
		return true
	elseif inst:IsA("Fire") then
		set(inst, "Color", color)
		set(inst, "SecondaryColor", color)
		return true
	elseif inst:IsA("Sparkles") then
		set(inst, "SparkleColor", color)
		return true
	elseif inst:IsA("Highlight") then
		if inst.Name == "VSOverlay" then return false end
		set(inst, "FillColor", color)
		set(inst, "OutlineColor", color)
		return true
	end
	return false
end

-- if the game puts a beam/trail/particle colour back (e.g. when you fire), put ours back again
local function guardEffect(inst)
	if not isEffect(inst) or guarded[inst] then return end
	guarded[inst] = true
	connect(inst:GetPropertyChangedSignal("Color"), function()
		if not selected then return end
		local fine
		if selected.mode == "rainbow" then
			fine = #inst.Color.Keypoints == #RAINBOW_SEQUENCE.Keypoints
		else
			fine = seqIsColor(inst.Color, colorFor(inst))
		end
		if not fine then
			paint(inst, colorFor(inst), false)
		end
	end)
end

-- paints the whole gun; returns how many beam / trail / particle parts it found in it
local function paintGun(tool)
	if not selected then return 0 end
	local ref = mapRainbow(partsUnder(tool)) -- does nothing unless Rainbow / Glass is picked
	local effects = 0
	for _, d in ipairs(tool:GetDescendants()) do
		if paint(d, colorFor(d), false) and isEffect(d) then
			effects += 1
		end
		guardEffect(d)
	end
	if ref and wantsSheen() then addSheen(ref) end
	return effects
end

------------------------------------------------------------------------
-- The gun on your hip / back (the display copy you see when the gun isn't in your hands).
-- Two ways to find it, so it works whatever MMV calls it:
--   1. your character's "DisplayRefGun" object points at it
--   2. any mesh on your character that uses the same mesh/texture as your gun
------------------------------------------------------------------------
local function gunAssetIds()
	local ids = {}
	for tool in pairs(hooked) do
		for _, d in ipairs(tool:GetDescendants()) do
			if d:IsA("MeshPart") then
				local okt, tex = pcall(function() return d.TextureID end)
				if okt and type(tex) == "string" and tex ~= "" then ids[tex] = true end
				local okm, mesh = pcall(function() return d.MeshId end)
				if okm and type(mesh) == "string" and mesh ~= "" then ids[mesh] = true end
			end
		end
	end
	return ids
end

-- what DisplayRefGun points at, as long as it's safe to recolour (never your whole body)
local function hipTarget(char)
	local ref = char:FindFirstChild("DisplayRefGun")
	if not (ref and ref:IsA("ObjectValue")) then return nil end
	local t = ref.Value
	if not t then return nil end
	if t == char or char:IsDescendantOf(t) then return nil end
	if t:IsA("Humanoid") or t:FindFirstChildOfClass("Humanoid") then return nil end
	return t
end

-- parts that show up later inside the display (e.g. when MMV rebuilds it) get painted too
local function watchTarget(target)
	if watchedTargets[target] then return end
	watchedTargets[target] = true
	connect(target.DescendantAdded, function(d)
		task.defer(function()
			if selected and d.Parent then
				paint(d, colorFor(d), false)
			end
		end)
	end)
end

-- paints the hip gun; returns how many parts of it it found
local function paintHip()
	local char = LocalPlayer.Character
	if not (selected and char) then return 0 end

	local done, count = {}, 0
	local function paintOne(d)
		if done[d] then return end
		done[d] = true
		if paint(d, colorFor(d), false) and d:IsA("BasePart") then
			count += 1
		end
	end

	local target = hipTarget(char)
	if target then
		watchTarget(target)
		local targetRef = mapRainbow(partsUnder(target))
		paintOne(target)
		for _, d in ipairs(target:GetDescendants()) do
			paintOne(d)
		end
		if targetRef and wantsSheen() then addSheen(targetRef) end
	end

	local ids = gunAssetIds()
	local matched = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("MeshPart") and not done[d] and not d:FindFirstAncestorOfClass("Tool") then
			local okt, tex = pcall(function() return d.TextureID end)
			local okm, mesh = pcall(function() return d.MeshId end)
			if (okt and tex ~= "" and ids[tex]) or (okm and mesh ~= "" and ids[mesh]) then
				table.insert(matched, d)
			end
		end
	end
	local matchedRef = mapRainbow(matched)
	for _, d in ipairs(matched) do
		paintOne(d)
	end
	if matchedRef and wantsSheen() then addSheen(matchedRef) end
	return count
end

local function refreshHip()
	if not selected then return end
	local n = paintHip()
	if n > 0 then
		setHipStatus("Hip gun: recoloured (" .. n .. " part(s))")
	else
		setHipStatus("Hip gun: not seen yet (put the gun away)")
	end
end

-- several parts can appear in the same moment, so look once for all of them
local function queueHipRefresh()
	if hipQueued then return end
	hipQueued = true
	task.defer(function()
		hipQueued = false
		refreshHip()
	end)
end

local function hookRef(ref)
	if guarded[ref] then return end
	guarded[ref] = true
	connect(ref:GetPropertyChangedSignal("Value"), queueHipRefresh)
end

local function watchCharacter(char)
	if not char then return end
	connect(char.DescendantAdded, function(d)
		if d.Name == "DisplayRefGun" and d:IsA("ObjectValue") then
			hookRef(d)
			queueHipRefresh()
		elseif selected and d:IsA("MeshPart") then
			queueHipRefresh()
		end
	end)
	local ref = char:FindFirstChild("DisplayRefGun")
	if ref and ref:IsA("ObjectValue") then hookRef(ref) end
end

------------------------------------------------------------------------
-- Finding the gun. In MMV the gun is a Tool simply called "Gun" (the Voidscope is a skin on it).
------------------------------------------------------------------------
local function isGun(inst)
	if not inst:IsA("Tool") then return false end
	local n = string.lower(inst.Name)
	return n == "gun" or string.find(n, "voidscope", 1, true) ~= nil
end

-- "you just fired": new effects that appear near you for the next moment are your shot
local function openShotWindow()
	local now = os.clock()
	if now > shotUntil then shotCount = 0 end
	shotUntil = now + SHOT_WINDOW
	task.delay(SHOT_WINDOW + 0.2, function()
		if selected and os.clock() >= shotUntil then
			setNote("Last shot: " .. shotCount .. " extra effect(s) recoloured")
		end
	end)
end

local function watchSound(inst)
	if not inst:IsA("Sound") or guarded[inst] then return end
	local n = string.lower(inst.Name)
	if string.find(n, "shot", 1, true) or string.find(n, "shoot", 1, true)
		or string.find(n, "fire", 1, true) or string.find(n, "alt", 1, true) then
		guarded[inst] = true
		connect(inst.Played, openShotWindow)
	end
end

local function hookGun(tool)
	if hooked[tool] then return end
	hooked[tool] = true
	print("[Voidscope Recolor] found gun: " .. tool:GetFullName())

	local effects = paintGun(tool)
	if selected then
		setGunStatus("Gun: found, " .. effects .. " beam part(s)")
		refreshHip()
	else
		setGunStatus("Gun: found")
	end

	for _, d in ipairs(tool:GetDescendants()) do
		watchSound(d)
	end

	-- the game may build / clone gun visuals when it's equipped, so paint new bits too
	connect(tool.DescendantAdded, function(d)
		guardEffect(d)
		watchSound(d)
		task.defer(function()
			if selected and d.Parent then
				paint(d, colorFor(d), false)
			end
		end)
	end)

	connect(tool.Activated, openShotWindow)
end

local function scan(container)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		if isGun(child) then hookGun(child) end
	end
	connect(container.ChildAdded, function(child)
		if isGun(child) then hookGun(child) end
	end)
end

scan(LocalPlayer.Character)
scan(LocalPlayer:FindFirstChildOfClass("Backpack"))
connect(LocalPlayer.CharacterAdded, scan)
watchCharacter(LocalPlayer.Character)
connect(LocalPlayer.CharacterAdded, watchCharacter)
connect(LocalPlayer.ChildAdded, function(c)
	if c:IsA("Backpack") then scan(c) end
end)

-- fallback in case the game doesn't trigger Tool.Activated / the shot sound
connect(UserInputService.InputBegan, function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		local char = LocalPlayer.Character
		if char then
			for _, child in ipairs(char:GetChildren()) do
				if isGun(child) then
					openShotWindow()
					break
				end
			end
		end
	end
end)

------------------------------------------------------------------------
-- Recolouring the shot (beam / bullet / trail that appears when you fire)
------------------------------------------------------------------------
local function characterOf(inst)
	local m = inst:FindFirstAncestorOfClass("Model")
	while m do
		if m:FindFirstChildOfClass("Humanoid") then return m end
		m = m:FindFirstAncestorOfClass("Model")
	end
	return nil
end

local function partOf(inst)
	if inst:IsA("BasePart") then return inst end
	local p = inst.Parent
	if p and p:IsA("Attachment") then p = p.Parent end
	if p and p:IsA("BasePart") then return p end
	return nil
end

local function nearYou(d)
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return true end

	local points = {}
	local part = partOf(d)
	if part then table.insert(points, part.Position) end
	if d:IsA("Beam") then
		local a0, a1 = d.Attachment0, d.Attachment1
		if a0 then table.insert(points, a0.WorldPosition) end
		if a1 then table.insert(points, a1.WorldPosition) end
	end

	if #points == 0 then return true end -- can't tell where it is, so don't skip it
	for _, p in ipairs(points) do
		if (p - root.Position).Magnitude <= SHOT_RADIUS then return true end
	end
	return false
end

connect(Workspace.DescendantAdded, function(d)
	if not selected then return end
	if os.clock() > shotUntil then return end

	local char = characterOf(d)
	if char then
		-- other players' stuff: leave alone. Your own character: only beams/trails/particles/lights,
		-- never your body, clothes or accessories
		if char ~= LocalPlayer.Character then return end
		if not (isEffect(d) or d:IsA("Light")) then return end
	end

	-- wait a moment so the game can finish setting the new object up, then override it
	task.defer(function()
		if not d.Parent or not selected then return end
		if not nearYou(d) then return end
		if paint(d, colorFor(d), true) then
			guardEffect(d)
			shotCount += 1
		end
	end)
end)

------------------------------------------------------------------------
-- Menu
------------------------------------------------------------------------
local function updateStatus()
	if glassToggleBtn then
		glassToggleBtn.Text = glassOverlay and "See-through: ON" or "See-through: OFF"
		glassToggleBtn.BackgroundColor3 = glassOverlay and Color3.fromRGB(40, 100, 150) or Color3.fromRGB(35, 35, 50)
	end
	if statusLabel then
		statusLabel.Text = selected and ("Selected: " .. selected.name) or "Selected: Default"
	end
	for name, btn in pairs(buttons) do
		local stroke = btn:FindFirstChildOfClass("UIStroke")
		if stroke then
			local on = (selected ~= nil and selected.name == name)
			stroke.Color = on and BUTTON_SELECTED or BUTTON_OUTLINE
			stroke.Thickness = on and 2 or 1
		end
	end
end

local function applyColor(entry)
	selected = entry -- set first, so nothing puts the glass look back while we undo it
	if not glassWanted() then unglassAll() end -- leaving Glass: bring the solid gun back
	if not wantsSheen() then -- no glow lights for this colour: take away any left over
		for part in pairs(sheens) do removeSheen(part) end
	end
	local found, effects = 0, 0
	for tool in pairs(hooked) do
		if tool.Parent then
			found += 1
			effects += paintGun(tool)
		end
	end
	if found == 0 then
		setGunStatus("Gun: not found yet (equip it)")
		setNote("No gun found yet. Equip your gun, then pick the colour again.")
	else
		setGunStatus("Gun: found, " .. effects .. " beam part(s)")
		setNote("")
	end
	refreshHip() -- the gun on your hip / back too
	updateStatus()
end

local function resetColor()
	selected = nil
	glassOverlay = false
	restoreAll()
	setNote("")
	setHipStatus("Hip gun: pick a colour first")
	updateStatus()
end

local function brightness(c)
	return c.R * 0.299 + c.G * 0.587 + c.B * 0.114
end

local function label(frame, order, text, size, color, height)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order
	l.Size = UDim2.new(1, 0, 0, height)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.TextSize = size
	l.TextColor3 = color
	l.TextWrapped = true
	l.Text = text
	l.Parent = frame
	return l
end

------------------------------------------------------------------------
-- Minimise icon image
------------------------------------------------------------------------
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function b64decode(data)
	local lookup = {}
	for i = 1, 64 do
		lookup[string.byte(B64_CHARS, i)] = i - 1
	end
	data = string.gsub(data, "[^%w%+/=]", "")
	local chunks = {}
	for i = 1, #data, 4 do
		local c1, c2, c3, c4 = string.byte(data, i, i + 3)
		local v3 = (c3 and c3 ~= 61) and lookup[c3] or nil
		local v4 = (c4 and c4 ~= 61) and lookup[c4] or nil
		local n = lookup[c1] * 262144 + lookup[c2] * 4096 + (v3 or 0) * 64 + (v4 or 0)
		local b1 = math.floor(n / 65536)
		local b2 = math.floor(n / 256) % 256
		local b3 = n % 256
		if v4 then
			table.insert(chunks, string.char(b1, b2, b3))
		elseif v3 then
			table.insert(chunks, string.char(b1, b2))
		else
			table.insert(chunks, string.char(b1))
		end
	end
	return table.concat(chunks)
end

-- gives back an image id for the planet icon, or nil if this executor can't load files
local function loadIconImage()
	if MINI_ICON_ASSET ~= "" then return MINI_ICON_ASSET end
	local toAsset = getcustomasset or getsynasset
	if not (writefile and toAsset) then return nil end
	local ok, asset = pcall(function()
		local name = "VoidscopePlanet.png"
		writefile(name, b64decode(ICON_PNG_B64))
		return toAsset(name)
	end)
	if ok and type(asset) == "string" and asset ~= "" then
		return asset
	end
	return nil
end

local function buildGui()
	gui = Instance.new("ScreenGui")
	gui.Name = "VoidscopeRecolor"
	gui.ResetOnSpawn = false

	local ok = pcall(function()
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	local WIDTH = 240

	-- window: a black galaxy (dark gradient + stars) with the content on top
	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.Size = UDim2.new(0, WIDTH, 0, 320) -- the height follows the content, see syncHeight below
	frame.Position = UDim2.new(0, 20, 0.3, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1) -- the gradient below does the colouring
	frame.BorderSizePixel = 0
	frame.Active = true
	pcall(function() frame.Draggable = true end)
	frame.Parent = gui

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = MENU_OUTLINE
	frameStroke.Thickness = 1
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Parent = frame

	-- the galaxy is decoration only: if anything in here fails, the menu still works
	local galaxyOk, galaxyErr = pcall(function()
	local sky = Instance.new("UIGradient")
	sky.Rotation = 60
	sky.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(28, 6, 56)),
		ColorSequenceKeypoint.new(0.70, Color3.fromRGB(8, 16, 56)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0)),
	})
	sky.Parent = frame

	local stars = Instance.new("Frame")
	stars.Name = "Stars"
	stars.Size = UDim2.new(1, 0, 1, 0)
	stars.BackgroundTransparency = 1
	stars.ClipsDescendants = true
	stars.ZIndex = 1
	stars.Parent = frame

	local rng = Random.new(1234)
	for i = 1, 55 do
		local size = 1
		local roll = rng:NextNumber()
		if roll < 0.15 then
			size = 3
		elseif roll < 0.5 then
			size = 2
		end
		local star = Instance.new("Frame")
		star.Size = UDim2.new(0, size, 0, size)
		star.Position = UDim2.new(rng:NextNumber(0.03, 0.97), 0, rng:NextNumber(0.02, 0.98), 0)
		star.BorderSizePixel = 0
		if i % 5 == 0 then
			star.BackgroundColor3 = Color3.fromRGB(190, 170, 255)
		elseif i % 7 == 0 then
			star.BackgroundColor3 = Color3.fromRGB(170, 215, 255)
		else
			star.BackgroundColor3 = Color3.new(1, 1, 1)
		end
		star.BackgroundTransparency = rng:NextNumber(0.05, 0.65)
		star.ZIndex = 1
		star.Parent = stars
		if size > 1 then
			Instance.new("UICorner", star).CornerRadius = UDim.new(1, 0)
		end
	end
	end)
	if not galaxyOk then
		warn("[Voidscope Recolor] galaxy background skipped: " .. tostring(galaxyErr))
		frame.BackgroundColor3 = Color3.fromRGB(8, 4, 24)
	end

	-- everything you see and tap lives in here, above the galaxy
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, 0, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.ZIndex = 2
	content.Parent = frame

	local pad = Instance.new("UIPadding", content)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)

	local list = Instance.new("UIListLayout", content)
	list.Padding = UDim.new(0, 5)
	list.SortOrder = Enum.SortOrder.LayoutOrder

	-- keep the galaxy window exactly as tall as its content
	local function syncHeight()
		frame.Size = UDim2.new(0, WIDTH, 0, math.max(content.AbsoluteSize.Y, 40))
	end
	connect(content:GetPropertyChangedSignal("AbsoluteSize"), syncHeight)
	task.defer(syncHeight)

	local order = 0
	local function nextOrder()
		order += 1
		return order
	end

	-- header: title (white, bubbly) + minimise and close buttons (tap-friendly for mobile)
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.LayoutOrder = nextOrder()
	header.Size = UDim2.new(1, 0, 0, 30)
	header.BackgroundTransparency = 1
	header.Parent = content

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -66, 1, 0)
	title.BackgroundTransparency = 1
	title.Font = BUBBLY_FONT
	title.Text = "Voidscope Recolor"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local titleLimit = Instance.new("UITextSizeConstraint")
	titleLimit.MaxTextSize = 20
	titleLimit.Parent = title

	local function headerButton(text, xOffset, bg)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.Position = UDim2.new(1, xOffset, 0.5, 0)
		b.Size = UDim2.new(0, 28, 0, 28)
		b.BackgroundColor3 = bg
		b.BorderSizePixel = 0
		b.Font = BUBBLY_FONT
		b.TextSize = 20
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = text
		b.Parent = header
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		return b
	end

	local minBtn = headerButton("-", -34, Color3.fromRGB(40, 40, 55))
	local closeBtn = headerButton("X", 0, Color3.fromRGB(170, 40, 40))

	-- colour buttons sit in a two-column grid so the menu stays short on phones
	local grid = Instance.new("Frame")
	grid.Name = "Colours"
	grid.LayoutOrder = nextOrder()
	grid.Size = UDim2.new(1, 0, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.BackgroundTransparency = 1
	grid.Parent = content

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0.5, -3, 0, 28)
	gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = grid

	for i, entry in ipairs(COLORS) do
		local btn = Instance.new("TextButton")
		btn.LayoutOrder = i
		btn.BackgroundColor3 = entry.color
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = true
		btn.Font = BUBBLY_FONT
		btn.TextSize = 15
		btn.Text = entry.name
		btn.TextColor3 = brightness(entry.color) > 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		btn.Parent = grid

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		-- thin grey outline normally, blue + thicker when selected (see updateStatus)
		local stroke = Instance.new("UIStroke")
		stroke.Color = BUTTON_OUTLINE
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn

		btn.MouseButton1Click:Connect(function()
			applyColor(entry)
		end)
		buttons[entry.name] = btn
	end

	-- Rainbow: full width, painted with a rainbow gradient (the gradient sits on its own layer so
	-- the text stays white and readable)
	local specialRow = Instance.new("Frame")
	specialRow.Name = "SpecialRow"
	specialRow.LayoutOrder = nextOrder()
	specialRow.Size = UDim2.new(1, 0, 0, 30)
	specialRow.BackgroundTransparency = 1
	specialRow.Parent = content

	local specialLayout = Instance.new("UIListLayout")
	specialLayout.FillDirection = Enum.FillDirection.Horizontal
	specialLayout.Padding = UDim.new(0, 6)
	specialLayout.SortOrder = Enum.SortOrder.LayoutOrder
	specialLayout.Parent = specialRow

	local rainbowHolder = Instance.new("Frame")
	rainbowHolder.Name = "RainbowHolder"
	rainbowHolder.LayoutOrder = 1
	rainbowHolder.Size = UDim2.new(1, 0, 1, 0)
	rainbowHolder.BackgroundTransparency = 1
	rainbowHolder.Parent = specialRow

	local rainbowFill = Instance.new("Frame")
	rainbowFill.Size = UDim2.new(1, 0, 1, 0)
	rainbowFill.BackgroundColor3 = Color3.new(1, 1, 1)
	rainbowFill.BorderSizePixel = 0
	rainbowFill.ZIndex = 1
	rainbowFill.Parent = rainbowHolder
	Instance.new("UICorner", rainbowFill).CornerRadius = UDim.new(0, 6)
	local rainbowGradient = Instance.new("UIGradient")
	rainbowGradient.Color = RAINBOW_SEQUENCE
	rainbowGradient.Parent = rainbowFill

	local rainbowBtn = Instance.new("TextButton")
	rainbowBtn.Size = UDim2.new(1, 0, 1, 0)
	rainbowBtn.BackgroundTransparency = 1
	rainbowBtn.BorderSizePixel = 0
	rainbowBtn.Font = BUBBLY_FONT
	rainbowBtn.TextSize = 16
	rainbowBtn.Text = RAINBOW.name
	rainbowBtn.TextColor3 = Color3.new(1, 1, 1)
	rainbowBtn.TextStrokeColor3 = Color3.new(0, 0, 0)
	rainbowBtn.TextStrokeTransparency = 0.5
	rainbowBtn.ZIndex = 2
	rainbowBtn.Parent = rainbowHolder
	Instance.new("UICorner", rainbowBtn).CornerRadius = UDim.new(0, 6)

	local rainbowStroke = Instance.new("UIStroke")
	rainbowStroke.Color = BUTTON_OUTLINE
	rainbowStroke.Thickness = 1
	rainbowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rainbowStroke.Parent = rainbowBtn

	rainbowBtn.MouseButton1Click:Connect(function()
		applyColor(RAINBOW)
	end)
	buttons[RAINBOW.name] = rainbowBtn

	-- Glass: a see-through looking button, the last cell of the colour grid
	local glassBtn = Instance.new("TextButton")
	glassBtn.LayoutOrder = #COLORS + 1
	glassBtn.BackgroundColor3 = Color3.fromRGB(170, 220, 255)
	glassBtn.BackgroundTransparency = 0.55
	glassBtn.BorderSizePixel = 0
	glassBtn.Font = BUBBLY_FONT
	glassBtn.TextSize = 16
	glassBtn.Text = GLASS.name
	glassBtn.TextColor3 = Color3.new(1, 1, 1)
	glassBtn.TextStrokeColor3 = Color3.new(0, 0, 0)
	glassBtn.TextStrokeTransparency = 0.6
	glassBtn.Parent = grid
	Instance.new("UICorner", glassBtn).CornerRadius = UDim.new(0, 6)

	local glassStroke = Instance.new("UIStroke")
	glassStroke.Color = BUTTON_OUTLINE
	glassStroke.Thickness = 1
	glassStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glassStroke.Parent = glassBtn

	glassBtn.MouseButton1Click:Connect(function()
		applyColor(GLASS)
	end)
	buttons[GLASS.name] = glassBtn

	-- See-through switch: keeps the glass look on whatever colour you pick
	glassToggleBtn = Instance.new("TextButton")
	glassToggleBtn.LayoutOrder = nextOrder()
	glassToggleBtn.Size = UDim2.new(1, 0, 0, 28)
	glassToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	glassToggleBtn.BorderSizePixel = 0
	glassToggleBtn.Font = BUBBLY_FONT
	glassToggleBtn.TextSize = 15
	glassToggleBtn.TextColor3 = Color3.new(1, 1, 1)
	glassToggleBtn.Text = "See-through: OFF"
	glassToggleBtn.Parent = content
	Instance.new("UICorner", glassToggleBtn).CornerRadius = UDim.new(0, 6)
	glassToggleBtn.MouseButton1Click:Connect(function()
		glassOverlay = not glassOverlay
		if selected then
			applyColor(selected) -- repaints with / without the see-through look
		else
			updateStatus()
		end
	end)

	local reset = Instance.new("TextButton")
	reset.LayoutOrder = nextOrder()
	reset.Size = UDim2.new(1, 0, 0, 28)
	reset.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	reset.BorderSizePixel = 0
	reset.Font = BUBBLY_FONT
	reset.TextSize = 15
	reset.TextColor3 = Color3.new(1, 1, 1)
	reset.Text = "Reset to default"
	reset.Parent = content
	Instance.new("UICorner", reset).CornerRadius = UDim.new(0, 6)
	reset.MouseButton1Click:Connect(resetColor)

	label(content, nextOrder(), "RightShift = hide / show", 11, Color3.fromRGB(130, 130, 150), 14)

	-- footer: white, bubbly
	local credit = label(content, nextOrder(), "made by FearVesta", 15, Color3.new(1, 1, 1), 22)
	credit.Font = BUBBLY_FONT
	credit.TextWrapped = false

	local handle = label(content, nextOrder(), "isnp:Kudo", 14, Color3.new(1, 1, 1), 20)
	handle.Font = BUBBLY_FONT
	handle.TextWrapped = false

	-- minimise: the whole menu collapses into a small planet icon. Click / tap the icon to open the
	-- menu again. The icon can be dragged around too.
	local minimised = false
	local imageId = loadIconImage()
	local icon
	if imageId then
		icon = Instance.new("ImageButton")
		icon.Image = imageId
		icon.ScaleType = Enum.ScaleType.Fit
		icon.BackgroundColor3 = Color3.new(0, 0, 0)
		icon.AutoButtonColor = false
	else
		-- no file support here: draw a little planet instead
		icon = Instance.new("TextButton")
		icon.Text = ""
		icon.AutoButtonColor = false
		icon.BackgroundColor3 = Color3.fromRGB(6, 4, 18)

		local planet = Instance.new("Frame")
		planet.AnchorPoint = Vector2.new(0.5, 0.5)
		planet.Position = UDim2.new(0.5, 0, 0.5, 0)
		planet.Size = UDim2.new(0, 28, 0, 28)
		planet.BorderSizePixel = 0
		planet.BackgroundColor3 = Color3.new(1, 1, 1)
		planet.Parent = icon
		Instance.new("UICorner", planet).CornerRadius = UDim.new(1, 0)
		local planetGradient = Instance.new("UIGradient")
		planetGradient.Rotation = 45
		planetGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 90, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 70, 230)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 120, 255)),
		})
		planetGradient.Parent = planet

		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.new(0.5, 0, 0.5, 0)
		ring.Size = UDim2.new(0, 46, 0, 14)
		ring.Rotation = -20
		ring.BackgroundTransparency = 1
		ring.BorderSizePixel = 0
		ring.Parent = icon
		Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		local ringStroke = Instance.new("UIStroke")
		ringStroke.Color = Color3.fromRGB(200, 160, 255)
		ringStroke.Thickness = 3
		ringStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ringStroke.Parent = ring

		local specks = { { 0.15, 0.2 }, { 0.82, 0.18 }, { 0.2, 0.8 }, { 0.85, 0.78 }, { 0.5, 0.08 } }
		for _, p in ipairs(specks) do
			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 2, 0, 2)
			dot.Position = UDim2.new(p[1], 0, p[2], 0)
			dot.BorderSizePixel = 0
			dot.BackgroundColor3 = Color3.new(1, 1, 1)
			dot.Parent = icon
		end
	end
	icon.Name = "MiniIcon"
	icon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	icon.Position = frame.Position
	icon.BorderSizePixel = 0
	icon.Active = true
	icon.Visible = false
	pcall(function() icon.Draggable = true end)
	icon.Parent = gui
	Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 12)

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = MENU_OUTLINE
	iconStroke.Thickness = 1
	iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	iconStroke.Parent = icon

	minBtn.MouseButton1Click:Connect(function()
		minimised = true
		icon.Position = frame.Position -- the icon appears where the menu was
		frame.Visible = false
		icon.Visible = true
	end)

	local pressedAt
	icon.MouseButton1Down:Connect(function()
		pressedAt = icon.AbsolutePosition
	end)
	icon.MouseButton1Click:Connect(function()
		-- a drag also ends in a click, so only open the menu if the icon hasn't moved
		if pressedAt and (icon.AbsolutePosition - pressedAt).Magnitude > 6 then return end
		minimised = false
		frame.Position = icon.Position -- the menu opens where the icon is
		icon.Visible = false
		frame.Visible = true
	end)

	-- close: unloads the script completely (menu gone, gun back to its normal look)
	closeBtn.MouseButton1Click:Connect(function()
		if env.VoidscopeRecolorCleanup then
			pcall(env.VoidscopeRecolorCleanup)
		elseif gui then
			gui:Destroy()
		end
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			local target = minimised and icon or frame -- hides / shows whichever one is out right now
			target.Visible = not target.Visible
		end
	end)
end

local built, buildErr = pcall(buildGui)
if not built then
	warn("[Voidscope Recolor] the menu failed to build: " .. tostring(buildErr))
end
if next(hooked) then
	setGunStatus("Gun: found") -- it was already in your hands before the menu existed
end

-- optional preselect via getgenv().VoidscopeColor
local pre = env.VoidscopeColor
if type(pre) == "string" then
	if string.lower(pre) == "rainbow" then
		applyColor(RAINBOW)
	elseif string.lower(pre) == "glass" then
		applyColor(GLASS)
	else
		for _, entry in ipairs(COLORS) do
			if string.lower(entry.name) == string.lower(pre) then
				applyColor(entry)
				break
			end
		end
	end
end

env.VoidscopeRecolorCleanup = function()
	for _, c in ipairs(conns) do
		pcall(function() c:Disconnect() end)
	end
	restoreAll()
	if gui then gui:Destroy() end
	env.VoidscopeRecolorCleanup = nil
end

print("[Voidscope Recolor] loaded")
