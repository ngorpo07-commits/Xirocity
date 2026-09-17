local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudCrosshair"] = true,
	["CHudDamageIndicator"] = true,
	["CHudGeiger"] = true,
	["CHudSquadStatus"] = true,
	["CHudTrain"] = true,
	["CHudZoom"] = true,
	["CHudSuitPower"] = true,
	["CHUDQuickInfo"] = true,
	["CHudHistoryResource"] = true,
}

local gordon_hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudCrosshair"] = true,
	["CHudSuitPower"] = true,
}

hook.Add("HUDShouldDraw", "homigrad", function(name)
	if hide[name] or lply.PlayerClassName and lply.PlayerClassName == "Gordon" and gordon_hide[name] then
		return false
	end
end)
hook.Add("HUDDrawTargetID", "homigrad", function()
	return false
end)

hook.Add("DrawDeathNotice", "homigrad", function()
	return false
end)

hook.Add("HUDWeaponPickedUp", "HidePickedStuff", function(wep)
	if IsValid(lply) and lply.PlayerClassName and lply.PlayerClassName == "Gordon" then
		return
	end
	return false
end)

hook.Add("HUDAmmoPickedUp", "HidePickedStuff", function(ammoname, amt)
	if IsValid(lply) and lply.PlayerClassName and lply.PlayerClassName == "Gordon" then
		return
	end
	return false
end)

hook.Add("HUDItemPickedUp", "HidePickedStuff", function(itemname)
	if IsValid(lply) and lply.PlayerClassName and lply.PlayerClassName == "Gordon" then
		return
	end
	return false
end)

hook.Add("HUDDrawPickupHistory", "HidePickedStuff", function()
	if IsValid(lply) and lply.PlayerClassName and lply.PlayerClassName == "Gordon" then
		return
	end
	return false
end)

local hg_font_default = "Lora"
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", hg_font_default, true, false, "Изменить шрифт интерфейса")
local hg_oldradialmenu = ConVarExists("hg_oldradialmenu") and GetConVar("hg_oldradialmenu") or CreateClientConVar("hg_oldradialmenu", "1", true, false, "Использовать старый стиль радиального меню", 0, 1)

-- Принудительно включаем старый стиль
RunConsoleCommand("hg_oldradialmenu", "1")

if hg_font:GetString() != hg_font_default then
	RunConsoleCommand("hg_font", hg_font_default)
end

local font = function()
    return hg_font_default
end

surface.CreateFont("HomigradFont", {
	font = font(),
	size = ScreenScale(10),
	weight = 1100,
	outline = false
})

surface.CreateFont("ScoreboardPlayer", {
	font = font(),
	size = ScreenScale(7),
	weight = 1100,
	outline = false
})

surface.CreateFont("HomigradFontBig", {
	font = font(),
	size = ScreenScale(12),
	weight = 1100,
	outline = false,
	shadow = true
})

surface.CreateFont("HomigradFontMedium", {
	font = font(),
	size = ScreenScale(8),
	weight = 1100,
	outline = false,
})

surface.CreateFont("HomigradFontRadialOld", {
	font = font(),
	size = ScreenScale(11),
	weight = 1100,
	outline = false,
})

surface.CreateFont("HomigradFontRadialCenter", {
	font = font(),
	size = ScreenScale(14),
	weight = 1100,
	outline = false,
})

surface.CreateFont("HomigradFontLarge", {
	font = font(),
	size = ScreenScale(15),
	weight = 1100,
	outline = false
})

surface.CreateFont("HomigradFontGigantoNormous", {
	font = font(),
	size = ScreenScale(25),
	weight = 1100,
	outline = false,
	shadow = false
})

surface.CreateFont("HomigradFontSmall", {
	font = font(),
	size = 17,
	weight = 1100,
	outline = false
})

surface.CreateFont("HomigradFontVSmall", {
	font = font(),
	size = 12,
	weight = 400,
	outline = false
})

local w, h

hook.Add("HUDPaint", "homigrad-dev", function()
	if engine.ActiveGamemode() ~= "sandbox" then return end
	w, h = ScrW(), ScrH()
end)

function draw.CirclePart(x, y, radius, seg, parts, pos)
	local cir = {}
	table.insert(cir, { x = x, y = y, u = 0.5, v = 0.5 })

	for i = 0, seg do
		local a = math.rad((i / seg) * -360 / parts - pos * 360 / parts) + math.pi
		table.insert(cir, {
			x = x + math.sin(a) * radius,
			y = y + math.cos(a) * radius,
			u = math.sin(a) / 2 + 0.5,
			v = math.cos(a) / 2 + 0.5
		})
	end

	render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	surface.DrawPoly(cir)
	render.PopFilterMin()
end

if IsValid(MENUPANELHUYHUY) then
	MENUPANELHUYHUY:Remove()
	MENUPANELHUYHUY = nil
end

hg.radialOptions = hg.radialOptions or {}
local colBlack = Color(0, 0, 0, 152)
local colOption = Color(40, 0, 55, 152)
local colWhite = Color(255, 255, 255, 255)
local colWhiteTransparent = Color(176, 40, 40, 100)
local colTransparent = Color(0, 0, 0, 0)
local matHuy = Material("vgui/white")
local vecXY = Vector(0, 0)
local vecDown = Vector(0, 1)
local isMouseIntersecting = false
local isMouseOnRadial = false
local current_option = 1
local current_option_select = 1
local hook_Run = hook.Run

local incoentCol = Color(128,0,0)
local taitorCol = Color(155,0,0)

local menuPanel
local colBack = Color(0,0,0)
local surface, draw, hook, IsColor, IsValid, math, input = surface, draw, hook, IsColor, IsValid, math, input

local oldRadialSliceColor = Color(26, 26, 30, 170)
local oldRadialHoverColor = Color(230, 230, 235, 95)
local oldRadialTextColor = Color(245, 245, 245, 255)
local oldRadialTextRadiusMul = 0.76
local oldRadialIconSizeMul = 0.05
local oldRadialLabelGap = 0.008

local function NormalizeRadialText(txt)
	txt = string.lower((txt or ""):gsub("\n", " "))
	txt = txt:gsub("[^%w%s]", "")
	txt = txt:gsub("%s+", " ")
	return string.Trim(txt)
end

local function GetRadialText(option)
	local txt = option and option[2]
	if isfunction(txt) then
		txt = txt(option)
	end
	return txt or ""
end

local function GetRadialIcon(option)
	if isfunction(option[5]) then
		local mat = option[5](option)
		if mat and type(mat) == "IMaterial" then return mat end
	end
	if option[5] and type(option[5]) == "IMaterial" then
		return option[5]
	end
	return nil
end

local function DrawOldRadialLabel(centerX, centerY, angleRad, radius, text, icon, scaleMul)
	local baseX = centerX + math.sin(angleRad) * radius * oldRadialTextRadiusMul
	local baseY = centerY + math.cos(angleRad) * radius * oldRadialTextRadiusMul
	local iconSize = ScrH() * oldRadialIconSizeMul * scaleMul
	local textY = baseY

	if icon then
		surface.SetMaterial(icon)
		surface.SetDrawColor(oldRadialTextColor)
		surface.DrawTexturedRect(baseX - iconSize * 0.5, baseY - iconSize - ScrH() * oldRadialLabelGap * scaleMul, iconSize, iconSize)
		textY = textY + iconSize * 0.1
	end

	draw.DrawText(text, "HomigradFontRadialOld", baseX, textY, oldRadialTextColor, TEXT_ALIGN_CENTER)
end

local function CreateRadialMenu(options_arg, bAutoClose)
	local sizeX, sizeY = ScrW(), ScrH()
	hg.radialOptions = {}
	local paining = lply.organism and lply.organism.pain and (lply.organism.pain > 100 or lply.organism.brain > 0.2) or false
	
	if !options_arg then
		local functions = hook.GetTable()["radialOptions"]
		for i, func in SortedPairs(functions) do
			func()
		end
	end

	local options1 = options_arg or hg.radialOptions
	hg.radialOptions = options1
	
	if IsValid(MENUPANELHUYHUY) then
		MENUPANELHUYHUY:Remove()
		MENUPANELHUYHUY = nil
	end

	local scrH, scrW = ScrH(), ScrW()

	MENUPANELHUYHUY = vgui.Create("DPanel")
	menuPanel = MENUPANELHUYHUY
	menuPanel:SetPos(scrW / 2 - sizeX / 2, scrH / 2 - sizeY / 2)
	menuPanel:SetSize(sizeX, sizeY)
	menuPanel:MakePopup()
	menuPanel:SetKeyBoardInputEnabled(false)
	menuPanel:SetAlpha(0)
	menuPanel:AlphaTo(255, 0.2)
	menuPanel.bAutoClose = bAutoClose
	if !options_arg then input.SetCursorPos(sizeX / 2, sizeY / 2) end

	function menuPanel:Close()
		if not IsValid(menuPanel) then return end
		menuPanel:AlphaTo(0,0.1,0,function()
			if IsValid(menuPanel) then
				menuPanel:Remove()
				menuPanel = nil
			end
		end)
	end

	local thinkwait = 0
	if !options_arg then
		menuPanel.Think = function()
			if menuPanel:GetAlpha() < 255 then return end
			if thinkwait > CurTime() then return end
			thinkwait = CurTime() + 0.25
			table.Empty(hg.radialOptions)
			local functions = hook.GetTable()["radialOptions"]
			
			for i, func in SortedPairs(functions) do
				func()
			end
		end
	end
	
	local sizePan = 0
	local optionSelected = {}
	menuPanel.Paint = function(self, w, h)
		local x, y = input.GetCursorPos()
		local centerX, centerY = w / 2, h / 2
		x = x - centerX
		y = y - centerY
		
		local options = {}
		if paining then
			options[#options + 1] = {function() RunConsoleCommand("hg_phrase") end, ""}
		else
			options = options1
		end

		sizePan = LerpFT(menuPanel:GetAlpha() > 100 and 0.05 or 0.25, sizePan, (menuPanel:GetAlpha() / 255))
		local viewLerp = Lerp(math.ease.OutExpo(sizePan), 0, 1)
		local optionCount = #options
		local distance = math.sqrt(x ^ 2 + y ^ 2)
		local partDeg = optionCount > 0 and (360 / optionCount) or 360

		vecXY.x = x
		vecXY.y = y
		local deg = (vecXY:GetNormalized() - vecDown):Angle()
		deg = math.NormalizeAngle((deg[2] - 180) * 2) + 180

		for num, option in ipairs(options) do
			local oldNum = num - 1
			local r = scrH * (options_arg ~= nil and 0.4 or 0.45) * viewLerp
			isMouseOnRadial = distance <= r and distance > 4
			isMouseIntersecting = isMouseOnRadial and deg > oldNum * partDeg and deg < (oldNum + 1) * partDeg
			if isMouseIntersecting then current_option = oldNum + 1 end

			optionSelected[oldNum] = optionSelected[oldNum] or 0
			optionSelected[oldNum] = LerpFT(0.1, optionSelected[oldNum], isMouseIntersecting and 1 or 0)

			if option[3] then
				surface.SetMaterial(matHuy)
				surface.SetDrawColor(oldRadialSliceColor)
				draw.CirclePart(centerX, centerY, r, 40, optionCount, oldNum)
				local count = #option[4]
				local selectedPart = count - (math.floor((r - distance) / (r / count)))
				current_option_select = math.Clamp(selectedPart, 1, count)

				for i, opt in pairs(option[4]) do
					local selected = current_option_select == i
					surface.SetMaterial(matHuy)
					surface.SetDrawColor((selected and isMouseIntersecting) and oldRadialHoverColor or colTransparent)
					draw.CirclePart(centerX, centerY, r * (i / count), 40, optionCount, oldNum)
					local a = -partDeg * oldNum - partDeg / 2
					a = math.rad(a) + math.pi

					if paining then
						math.randomseed(math.Round(CurTime() / 5 + oldNum + i, 0))
						opt = ""
						math.randomseed(os.time())
					end

					draw.DrawText(opt, "HomigradFontRadialOld", centerX + math.sin(a) * r * (i / count - 0.5 / count), centerY + math.cos(a) * r * (i / count - 0.5 / count), oldRadialTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			else
				surface.SetMaterial(matHuy)
				if option[6] and IsColor(option[6]) then
					if option[7] and IsColor(option[7]) then
						surface.SetDrawColor(option[7]:Lerp(option[6], 1 - optionSelected[oldNum]))
					else
						surface.SetDrawColor(oldRadialHoverColor:Lerp(option[6], 1 - optionSelected[oldNum]))
					end
				else
					if option[7] and IsColor(option[7]) then
						surface.SetDrawColor(option[7]:Lerp(oldRadialSliceColor, 1 - optionSelected[oldNum]))
					else
						surface.SetDrawColor(oldRadialHoverColor:Lerp(oldRadialSliceColor, 1 - optionSelected[oldNum]))
					end
				end

				draw.CirclePart(centerX, centerY, r * (1 + 0.1 * optionSelected[oldNum]), 30, optionCount, oldNum)
				local a = -partDeg * oldNum - partDeg / 2
				a = math.rad(a) + math.pi

				local txt = GetRadialText(option)
				local icon = GetRadialIcon(option)
				if paining then
					math.randomseed(math.Round(CurTime() / 5 + oldNum, 0))
					txt = hg.get_status_message(lply)
					math.randomseed(os.time())
				end
				DrawOldRadialLabel(centerX, centerY, a, r, txt, icon, viewLerp)
			end
		end

		if !paining then
			draw.SimpleText(lply:GetPlayerName(),"HomigradFontGigantoNormous",scrW * 0.0215* viewLerp,scrH * 0.042, colBack, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText( ( (lply.role and lply.role.name) or ""),"HomigradFontGigantoNormous" ,scrW * 0.0215 * viewLerp,scrH * 0.098, colBack, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			local col = lply:GetPlayerColor():ToColor()
			draw.SimpleText(lply:GetPlayerName(),"HomigradFontGigantoNormous",scrW * 0.02 * viewLerp,scrH * 0.04, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText( ( (lply.role and lply.role.name) or ""),"HomigradFontGigantoNormous" ,scrW * 0.02 * viewLerp,scrH * 0.095, lply.role and lply.role.color or incoentCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
end

local function PressRadialMenu(mouseClick)
	local options = hg.radialOptions
	hook_Run("RadialMenuPressed")

	local needed_mouseclick
	if IsValid(menuPanel) and options[current_option] and isMouseOnRadial then
		local func = options[current_option][1]
		if isfunction(func) then needed_mouseclick = func(mouseClick, current_option_select) end
	end

	if needed_mouseclick != -1 and IsValid(menuPanel) and mouseClick != (needed_mouseclick or 2) and not menuPanel.bAutoClose then
		menuPanel:Close()
	end
end

hg.CreateRadialMenu = CreateRadialMenu
hg.PressRadialMenu = PressRadialMenu

hook.Add("HG_OnOtrub", "resetshit", function(ply)
	if ply == lply then
		hook_Run("RadialMenuPressed")

		if IsValid(menuPanel) then
			menuPanel:Close()
		end
	end
end)

hook.Add("PlayerBindPress", "PlayerBindPressExample2huy", function(ply, bind, pressed)
	if string.find(bind, "+menu") then
		if (lply.organism and lply.organism.otrub) then
			return (bind == "+menu") or nil
		end

		if (bind == "+menu") then
			if pressed and !IsValid(MENUPANELHUYHUY) then
				CreateRadialMenu()
			else
				PressRadialMenu(1)
			end
		else
			if lply:IsAdmin() then return end
		end

		return true
	end
end)

local firstTime = true
local firstTime2 = true
local firstTime3 = true
local firstTime4 = true
local firstTime5 = true
local firstTime6 = true

hook.Add("Think", "hg-radial-menu", function()
	if (lply.organism and lply.organism.otrub) then
		if IsValid(menuPanel) then
			hook_Run("RadialMenuPressed")
			menuPanel:Close()
		end
		return
	end

	if input.IsMouseDown(MOUSE_LEFT) then
		if firstTime2 then firstTime2 = false end
		firstTime3 = true
	else
		if firstTime3 then
			firstTime3 = false
			PressRadialMenu(1)
		end
		firstTime2 = true
	end

	if input.IsMouseDown(MOUSE_RIGHT) then
		if firstTime5 then firstTime5 = false end
		firstTime6 = true
	else
		if firstTime6 then
			firstTime6 = false
			PressRadialMenu(2)
		end
		firstTime5 = true
	end
end)

local function dropWeapon()
	RunConsoleCommand("drop")
end

hook.Add("radialOptions", "77", function()
	local organism = lply.organism or {}
	if not organism.otrub and IsValid(lply:GetActiveWeapon()) and lply:GetActiveWeapon():GetClass() ~= "weapon_hands_sh" then
		local tbl = {dropWeapon, "Выбросить оружие"}
		hg.radialOptions[#hg.radialOptions + 1] = tbl
	end
end)

-- Перевод жестов для внутреннего списка
local gestureTranslations = {
	["wave"] = "Помахать",
	["salute"] = "Отдать честь",
	["halt"] = "Стой",
	["group"] = "В группу",
	["forward"] = "Вперед",
	["disagree"] = "Несогласен",
	["becon"] = "Ко мне",
	["point"] = "Указать",
	["fuck you"] = "Иди нахуй",
	["thumb_up"] = "Палец вверх"
}

local randomGestures = {
	"wave",
	"salute",
	"halt",
	"group",
	"forward",
	"disagree",
	"becon",
	{"point", function() RunConsoleCommand("hg_hand_gesture", "point") end},
	{"fuck you", function() RunConsoleCommand("hg_hand_gesture", "fuckyou") end},
	{"thumb_up", function() RunConsoleCommand("hg_hand_gesture" , "thumb_up") end},
}

hook.Add("radialOptions", "7", function()
    local ply = LocalPlayer()
    local organism = ply.organism or {}

    if ply:Alive() and not organism.otrub and hg.GetCurrentCharacter(ply) == ply then
        if ply.GetPlayerClass and ply:GetPlayerClass() and ply:GetPlayerClass().CanUseGestures ~= nil and not ply:GetPlayerClass().CanUseGestures then return end
		local tbl = {function(mouseClick)
			if mouseClick == 1 then
				RunConsoleCommand("act", randomGestures[math.random(#randomGestures)])
				if (ply.NextFoley or 0) < CurTime() then
					ply:EmitSound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav", 55)
					ply.NextFoley = CurTime() + 1
				end
			else
				local commands = {}
				for i, str in ipairs(randomGestures) do
					local rawName = istable(str) and str[1] or str
					local displayName = gestureTranslations[rawName] or string.NiceName(rawName)
					
					commands[i] = {
						[1] = function()
							if istable(str) then
								str[2]()
							else
								RunConsoleCommand("act", str)
								if (ply.NextFoley or 0) < CurTime() then
									ply:EmitSound("player/clothes_generic_foley_0" .. math.random(5) .. ".wav", 55)
									ply.NextFoley = CurTime() + 1
								end
							end
						end,
						[2] = displayName
					}
				end
				CreateRadialMenu(commands)
			end
		end, "Сделать жест\nПКМ - Меню"}
        hg.radialOptions[#hg.radialOptions + 1] = tbl
    end
end)

hook.Add("HUDPaint","Identifier",function()
	if lply.organism and lply.organism.otrub then return end
	if !lply:Alive() then return end
	if lply:GetNetVar("disappearance", nil) then return end 
	
	local trace = hg.eyeTrace(lply)
	if not trace then return end

	local Size = math.max(math.min(1 - trace.Fraction, 1), 0.1)
	local x, y = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y

	if trace.Hit and (trace.Entity:IsRagdoll() or trace.Entity:IsPlayer()) then
		if trace.Entity.PlayerClassName == "sc_infiltrator" then return end
		if trace.Entity:GetNetVar("disappearance", nil) then return end

		draw.NoTexture()

		local col = trace.Entity:GetPlayerColor():ToColor()
		col.a = 255 * Size * 1.5

		local coloutline = (col.r < 50 and col.g < 50 and col.b < 50) and Color(100,100,100) or Color(0,0,0)
		coloutline.a = 255 * Size * 1

		draw.DrawText(trace.Entity:GetPlayerName() or "", "HomigradFontLarge", x + 1, y + 31, coloutline, TEXT_ALIGN_CENTER)
		draw.DrawText(trace.Entity:GetPlayerName() or "", "HomigradFontLarge", x, y + 30, col, TEXT_ALIGN_CENTER)
	end
end)

local hg_hints = ConVarExists("hg_hints") and GetConVar("hg_hints") or CreateClientConVar("hg_hints", "1", true, false, "Включить подсказки UI")
local HintBackgroundColor = Color( 0, 0, 0, 200 )

hook.Add("HUDPaint","EntHints",function()
	if not hg_hints:GetBool() then return end 
	if lply.organism and lply.organism.otrub then return end
	if !lply:Alive() then return end
	
	local trace = hg.eyeTrace(lply)
	if not trace then return end

	HintBackgroundColor.a = LerpFT(0.1, HintBackgroundColor.a, (IsValid(trace.Entity) and trace.Entity.HudHintMarkup) and 200 or 0)
	hg.BasicHudHint(trace.Entity, trace, hint)
end)

function hg.BasicHudHint(ent, trace)
	hint = (IsValid(ent) and ent.HudHintMarkup) or hint
	if not hint then return end

	local x, y = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
	y = y + 100

	draw.RoundedBox(2, x - hint:GetWidth() / 2 - 2.5, y - 2.5, hint:GetWidth() + 5, hint:GetHeight() + 5, HintBackgroundColor)
	hint:Draw(x, y, TEXT_ALIGN_CENTER, nil, 175 * (HintBackgroundColor.a / 200), TEXT_ALIGN_CENTER)

	if ent.AdditionalInfoFunc then
		local str = ent.AdditionalInfoFunc()
		local w, h = surface.GetTextSize(str)
		surface.SetFont("ZCity_Tiny")
		surface.SetTextColor(color_white)
		surface.SetTextPos(x - w * 0.5, y + hint:GetHeight() + h)
		surface.DrawText(str)
	end
end

if game.SinglePlayer() then
	hook.Add("HUDPaint","Exit the singleplayer",function()
		draw.SimpleText("Z-City не предназначен для одиночной игры. В меню выбора карты смените ОДИНОЧНУЮ ИГРУ (зеленая кнопка справа вверху) на 2 игроков или больше.", "HomigradFontMedium", ScrW() / 2, ScrH() / 2, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Многие функции не будут работать, и исправления для одиночной игры ВЫПУСКАТЬСЯ НЕ БУДУТ.", "HomigradFontMedium", ScrW() / 2, ScrH() * 7 / 12, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end)
end