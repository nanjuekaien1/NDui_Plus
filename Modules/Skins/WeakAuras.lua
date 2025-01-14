local _, ns = ...
local B, C, L, DB, P = unpack(ns)
local S = P:GetModule("Skins")

local _G = getfenv(0)
local select, pairs, type = select, pairs, type

local function reskinChildButton(frame)
	if not frame then return end

	for i = 1, frame:GetNumChildren() do
		local child = select(i, frame:GetChildren())
		if child:GetObjectType() == 'Button' and child.Text then
			B.Reskin(child)
		end
	end
end

local function RemoveBorder(frame)
	for _, region in pairs {frame:GetRegions()} do
		local texture = region.GetTexture and region:GetTexture()
		if texture and texture ~= "" and type(texture) == "string" and texture:find("Quickslot2") then
			region:SetTexture("")
		end
	end
end

local function ReskinWAOptions()
	local frame = _G.WeakAurasOptions
	if not frame or frame.styled then return end

	B.StripTextures(frame)
	B.SetBD(frame)
	B.ReskinInput(frame.filterInput, 18)
	B.Reskin(_G.WASettingsButton)

	-- Minimize, Close Button
	for i = 1, frame:GetNumChildren() do
		local child = select(i, frame:GetChildren())
		local numRegions = child:GetNumRegions()
		local numChildren = child:GetNumChildren()

		if numRegions == 3 and numChildren == 1 and child.PixelSnapDisabled then
			B.StripTextures(child)

			local button = child:GetChildren()
			local texturePath = button.GetNormalTexture and button:GetNormalTexture():GetTexture()
			if texturePath and type(texturePath) == "string" and texturePath:find("CollapseButton") then
				B.Reskin(button)
				button.SetNormalTexture = B.Dummy
				button.SetPushedTexture = B.Dummy
				button:SetSize(18, 18)
				button:ClearAllPoints()
				button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -6)

				local tex = button:CreateTexture(nil, "ARTWORK")
				tex:SetAllPoints()
				B.SetupArrow(tex, "up")
				button.__texture = tex

				button:SetScript("OnEnter", B.Texture_OnEnter)
				button:SetScript("OnLeave", B.Texture_OnLeave)
				button:HookScript("OnClick",function(self)
					if frame.minimized then
						B.SetupArrow(self.__texture, "down")
					else
						B.SetupArrow(self.__texture, "up")
					end
				end)
			else
				B.ReskinClose(button, frame)
				button:SetSize(18, 18)
			end
		end
	end

	-- Child Groups
	local childGroups = {
		"texturePicker",
		"iconPicker",
		"modelPicker",
		"importexport",
		"texteditor",
		"codereview",
	}

	for _, key in pairs(childGroups) do
		local group = frame[key]
		if group then
			reskinChildButton(group.frame)
		end
	end

	-- IconPicker
	local iconPicker = frame.iconPicker.frame
	if iconPicker then
		for i = 1, iconPicker:GetNumChildren() do
			local child = select(i, iconPicker:GetChildren())
			if child:GetObjectType() == 'EditBox' then
				B.ReskinInput(child, 20)
			end
		end
	end

	-- Right Side Container
	local container = frame.container.content:GetParent()
	if container and container.bg then
		container.bg:Hide()
	end

	-- WeakAurasSnippets
	local snippets = _G.WeakAurasSnippets
	B.StripTextures(snippets)
	B.SetBD(snippets)
	reskinChildButton(snippets)

	-- MoverSizer
	local moversizer = frame.moversizer
	B.CreateBD(moversizer, 0)

	local index = 1
	for i = 1, moversizer:GetNumChildren() do
		local child = select(i, moversizer:GetChildren())
		local numChildren = child:GetNumChildren()

		if numChildren == 2 and child:IsClampedToScreen() then
			local button1, button2 = child:GetChildren()
			if index == 1 then
				B.ReskinArrow(button1, "up")
				B.ReskinArrow(button2, "down")
			else
				B.ReskinArrow(button1, "left")
				B.ReskinArrow(button2, "right")
			end
			index = index + 1
		end
	end

	-- TipPopup
	for i = 1, frame:GetNumChildren() do
		local child = select(i, frame:GetChildren())
		if child:GetFrameStrata() == "FULLSCREEN" and child.PixelSnapDisabled and child.backdropInfo then
			B.StripTextures(child)
			B.SetBD(child)

			for j = 1, child:GetNumChildren() do
				local child2 = select(j, child:GetChildren())
				if child2:GetObjectType() == "EditBox" then
					B.ReskinInput(child2, 18)
				end
			end
			break
		end
	end

	frame.styled = true
end

function S:WeakAuras()
	if not IsAddOnLoaded("WeakAuras") then return end

	local WeakAuras = _G.WeakAuras
	if not WeakAuras then return end

	-- WeakAurasTooltip
	reskinChildButton(_G.WeakAurasTooltipImportButton:GetParent())
	B.ReskinRadio(_G.WeakAurasTooltipRadioButtonCopy)
	B.ReskinRadio(_G.WeakAurasTooltipRadioButtonUpdate)

	local index = 1
	local check = _G["WeakAurasTooltipCheckButton"..index]
	while check do
		B.ReskinCheck(check)
		index = index + 1
		check = _G["WeakAurasTooltipCheckButton"..index]
	end

	-- Remove Aura Border (Credit: ElvUI_WindTools)
	if WeakAuras.RegisterRegionOptions then
		local origRegisterRegionOptions = WeakAuras.RegisterRegionOptions

		WeakAuras.RegisterRegionOptions = function(name, createFunction, icon, displayName, createThumbnail, ...)
			if type(icon) == "function" then
				local OldIcon = icon
				icon = function()
					local f = OldIcon()
					RemoveBorder(f)
					return f
				end
			end

			if type(createThumbnail) == "function" then
				local OldCreateThumbnail = createThumbnail
				createThumbnail = function()
					local f = OldCreateThumbnail()
					RemoveBorder(f)
					return f
				end
			end

			return origRegisterRegionOptions(name, createFunction, icon, displayName, createThumbnail, ...)
		end
	end

	-- WeakAurasOptions
	local count = 0
	local function loadFunc(event, addon)
		if addon == "WeakAurasOptions" then
			hooksecurefunc(WeakAuras, "ShowOptions", ReskinWAOptions)
			count = count + 1
		end

		if addon == "WeakAurasTemplates" then
			if WeakAuras.CreateTemplateView then
				local origCreateTemplateView = WeakAuras.CreateTemplateView
				WeakAuras.CreateTemplateView = function(...)
					local group = origCreateTemplateView(...)
					reskinChildButton(group.frame)

					return group
				end
			end
			count = count + 1
		end

		if count >= 2 then
			B:UnregisterEvent(event, loadFunc)
		end
	end
	B:RegisterEvent("ADDON_LOADED", loadFunc)
end

S:RegisterSkin("WeakAuras", S.WeakAuras)