local DURATION   = 4      
local TARGET_FOV = 40     
local SLOW_SCALE = 0.35   

if SERVER then
    util.AddNetworkString("rem_clearround")

    local startSys

    local function TimeScaleThink()
        local e = SysTime() - (startSys or 0)
        local scale

        if e >= DURATION then
            game.SetTimeScale(1)
            hook.Remove("Think", "rem_clearround_timescale")
            return
        elseif e < 0.4 then
            scale = Lerp(e / 0.4, 1, SLOW_SCALE)
        elseif e < DURATION - 1.5 then
            scale = SLOW_SCALE
        else
            scale = Lerp((e - (DURATION - 1.5)) / 1.5, SLOW_SCALE, 1)
        end

        game.SetTimeScale(scale)
    end

    hook.Add("ZB_EndRound", "rem_clearround", function()
        net.Start("rem_clearround")
            net.WriteFloat(CurTime()) -- Передаем точное время старта
        net.Broadcast()

        startSys = SysTime()
        hook.Add("Think", "rem_clearround_timescale", TimeScaleThink)
    end)

    return
end

-- ==========================================
-- CLIENT SIDE
-- ==========================================

surface.CreateFont("Rem_ClearRound", {
    font      = "Kenyan Coffee Rg",
    size      = math.floor(ScrH() * 0.18),
    weight    = 700,
    antialias = true,
    extended  = true,
})

-- Запасной стандартный шрифт на случай, если Kenyan Coffee не установлен
surface.CreateFont("Rem_ClearRound_Fallback", {
    font      = "Trebuchet MS",
    size      = math.floor(ScrH() * 0.18),
    weight    = 800,
    antialias = true,
    extended  = true,
})

local hg_fov = ConVarExists("hg_fov") and GetConVar("hg_fov")

local active   = false
local startTime = 0
local channel  = nil

local function PlayClearSound()
    if IsValid(channel) then
        channel:Stop()
        channel = nil
    end

    sound.PlayFile("sound/rem_clearround.wav", "", function(chan, errId)
        if IsValid(chan) then
            channel = chan
            chan:SetVolume(1)
            chan:Play()
        else
            surface.PlaySound("rem_clearround.wav")
        end
    end)
end

net.Receive("rem_clearround", function()
    active    = true
    startTime = CurTime() -- Синхронизированный таймер
    PlayClearSound()
end)

local function FovFraction(e)
    if e < 0.35 then
        return math.ease.OutQuad(e / 0.35)
    elseif e < 0.7 then
        return 1
    elseif e < DURATION then
        return 1 - math.ease.InOutSine((e - 0.7) / (DURATION - 0.7))
    end
    return 0
end

hook.Add("HG_CalcView", "rem_clearround_fov", function(ply, origin, angles, fova)
    if not active then return end
    if not istable(fova) then return end

    local frac = FovFraction(CurTime() - startTime)
    if frac <= 0 then return end

    local base = hg_fov and math.Clamp(hg_fov:GetFloat(), 75, 100) or 90
    fova[1] = fova[1] + (TARGET_FOV - base) * frac
end)

hook.Add("Think", "rem_clearround_tick", function()
    if not active then return end

    local e = CurTime() - startTime

    if IsValid(channel) then
        local vol = e < 1 and 1 or math.Clamp(1 - (e - 1) / (DURATION - 1), 0, 1)
        channel:SetVolume(vol)
    end

    if e >= DURATION then
        active = false
        if IsValid(channel) then
            channel:Stop()
            channel = nil
        end
    end
end)


hook.Add("HUDPaint", "rem_clearround_hud", function()
    if not active then return end

    local e = CurTime() - startTime
    if e >= DURATION then return end

    -- Alpha
    local a = 1
    if e < 0.3 then
        a = e / 0.3
    elseif e > DURATION - 1 then
        a = math.Clamp((DURATION - e) / 1, 0, 1)
    end
    local alpha = math.floor(a * 255)

    
    local offsetY = 0
    if e < 0.25 then
        offsetY = (1 - math.ease.OutBack(e / 0.25)) * -100 -- Эффект вылета сверху вниз
    elseif e > DURATION - 0.8 then
        local exitProgress = (e - (DURATION - 0.8)) / 0.8
        offsetY = -math.ease.InQuad(exitProgress) * 80 -- Улет вверх
    else
        offsetY = math.sin((e - 0.25) * 4) * 6 -- Плавная пульсация вверх-вниз
    end

    local x = ScrW() * 0.5
    local y = (ScrH() * 0.5) + offsetY
    local outline = math.max(2, math.floor(ScrH() * 0.004))

    -- Отрисовка с запасным шрифтом
    draw.SimpleTextOutlined(
        "КОНЕЦ..", "Rem_ClearRound", x, y,
        Color(0, 0, 0, alpha),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
        outline, Color(255, 255, 255, alpha)
    )
end)