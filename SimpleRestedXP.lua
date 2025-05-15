-- Variables y configuración
local ADDON_NAME = "SimpleRestedXP"
local DEFAULT_CONFIG = {
    position = { x = 0, y = 400 },
    scale = 1.0,
    enabled = true,
    colorGradient = true,
    showPercent = true,
    showBar = true,
    barWidth = 150,
    barHeight = 15,
    fontsize = 12
}

-- Inicializar la configuración global si no existe
SimpleRestedXPConfig = SimpleRestedXPConfig or DEFAULT_CONFIG

-- Variables para cálculo de ETA
local lastUpdate = 0
local lastRestedXP = 0
local xpPerHour = 0
local isResting = false
local timeToMax = 0

-- Crear el marco principal
local frame = CreateFrame("Frame", "SimpleRestedXPFrame", UIParent)
frame:SetWidth(200)
frame:SetHeight(50)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 400)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")

-- Implementación corregida de las funciones de arrastre
frame:SetScript("OnDragStart", 
    function() 
        frame:StartMoving() 
    end
)

frame:SetScript("OnDragStop", 
    function() 
        frame:StopMovingOrSizing() 
        if SimpleRestedXPConfig and SimpleRestedXPConfig.position then
            local _, _, _, x, y = frame:GetPoint()
            SimpleRestedXPConfig.position.x = x
            SimpleRestedXPConfig.position.y = y
        end
    end
)

-- Fondo del marco (opcional, para facilitar el movimiento)
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(frame)
bg:SetTexture(0, 0, 0, 0.3)
bg:Hide()

-- Texto para mostrar Rested XP
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("TOP", frame, "TOP", 0, 0)
text:SetTextColor(1, 1, 1)

-- Barra de progreso
local bar = CreateFrame("StatusBar", nil, frame)
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -2)
bar:SetWidth(150)
bar:SetHeight(15)
bar:SetStatusBarColor(0.6, 0, 0.6)  -- Color púrpura para XP en descanso

-- Texto en la barra para el porcentaje
local barText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
barText:SetPoint("CENTER", bar, "CENTER", 0, 0)
barText:SetTextColor(1, 1, 1)

-- Borde de la barra
local barBorder = CreateFrame("Frame", nil, bar)
barBorder:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
barBorder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2)
barBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})

-- Función para obtener color según el porcentaje
local function GetColorGradient(percent)
    if percent >= 150 then
        return 0.5, 0, 1  -- Púrpura para 150%+
    elseif percent >= 100 then
        return 0, 0.5, 1  -- Azul para 100-150%
    elseif percent >= 75 then
        return 0, 1, 0.5  -- Verde-azulado para 75-100%
    elseif percent >= 50 then
        return 0, 1, 0    -- Verde para 50-75%
    elseif percent >= 25 then
        return 1, 1, 0    -- Amarillo para 25-50%
    else
        return 1, 0.5, 0  -- Naranja para <25%
    end
end

-- Función para calcular el tiempo restante sin usar el operador %
local function FormatTime(seconds)
    if seconds <= 0 then
        return "0s"
    end
    
    local days = math.floor(seconds / 86400)
    seconds = seconds - (days * 86400)
    
    local hours = math.floor(seconds / 3600)
    seconds = seconds - (hours * 3600)
    
    local minutes = math.floor(seconds / 60)
    
    if days > 0 then
        return days .. "d " .. hours .. "h"
    elseif hours > 0 then
        return hours .. "h " .. minutes .. "m"
    else
        return minutes .. "m"
    end
end

-- Función para actualizar el texto y la barra
local function UpdateRestedXP()
    -- Asegurarnos que la configuración existe
    if not SimpleRestedXPConfig then
        SimpleRestedXPConfig = DEFAULT_CONFIG
    end
    
    if not SimpleRestedXPConfig.enabled then
        frame:Hide()
        return
    else
        frame:Show()
    end

    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restedXP = GetXPExhaustion() or 0
    
    -- Calcular si estamos recuperando XP en descanso
    isResting = IsResting()
    
    -- Calculamos los porcentajes
    local restedPercent = (restedXP / maxXP) * 100
    local currentPercent = (currentXP / maxXP) * 100
    
    -- Calculamos la tasa de acumulación de XP en descanso y ETA
    local currentTime = GetTime()
    if currentTime - lastUpdate > 10 then -- Actualizamos cada 10 segundos
        if lastRestedXP > 0 and isResting then
            -- Solo calculamos si estamos en descanso y tenemos un valor previo
            local xpGained = restedXP - lastRestedXP
            if xpGained > 0 then
                local elapsedHours = (currentTime - lastUpdate) / 3600
                xpPerHour = xpGained / elapsedHours
                
                -- XP necesaria para llegar al 150%
                local maxRestedXP = maxXP * 1.5
                local xpNeeded = maxRestedXP - restedXP
                
                if xpPerHour > 0 then
                    timeToMax = xpNeeded / xpPerHour -- tiempo en horas
                    timeToMax = timeToMax * 3600 -- convertir a segundos
                else
                    timeToMax = 0
                end
            end
        end
        
        lastRestedXP = restedXP
        lastUpdate = currentTime
    end
    
    -- Texto a mostrar: solo "Rested XP" en el título
    local displayText = "Rested XP"
    
    -- Aplicar tamaño de fuente y color
    local fontSize = SimpleRestedXPConfig.fontsize or 12 -- Asegurar que no sea nil
    text:SetFont("Fonts\\FRIZQT__.TTF", fontSize)
    
    if SimpleRestedXPConfig.colorGradient then
        local r, g, b = GetColorGradient(restedPercent)
        text:SetTextColor(r, g, b)
        bar:SetStatusBarColor(r, g, b)
    else
        text:SetTextColor(1, 1, 1)
        bar:SetStatusBarColor(0.6, 0, 0.6)
    end
    
    text:SetText(displayText)
    
    -- Actualizar barra - por defecto siempre visible
    SimpleRestedXPConfig.showBar = true
    bar:Show()
    bar:SetWidth(SimpleRestedXPConfig.barWidth)
    bar:SetHeight(SimpleRestedXPConfig.barHeight)
    bar:SetMinMaxValues(0, maxXP)
    bar:SetValue(restedXP)
    
    -- Mostrar la información de XP en la barra (solo porcentaje)
    -- Usar concatenación simple en lugar de string.format para evitar problemas con %
    local barInfo = string.format("%.1f", restedPercent) .. "%"
    
    -- Añadir ETA si estamos descansando y no hemos llegado al máximo
    if isResting and restedPercent < 150 and timeToMax > 0 then
        -- Aseguramos que el tiempo sea razonable (superior a 1 minuto e inferior a 100 días)
        if timeToMax > 60 and timeToMax < 8640000 then
            barInfo = barInfo .. " | Max: " .. FormatTime(timeToMax)
        end
    end
    
    barText:SetText(barInfo)
    barText:Show()
    
    -- Aplicar escala
    frame:SetScale(SimpleRestedXPConfig.scale)
end

-- Función para mostrar el marco de movimiento
local function ToggleMovableFrame()
    if bg:IsShown() then
        bg:Hide()
        frame:SetBackdrop(nil)
        UpdateRestedXP()
    else
        bg:Show()
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            tile = true, tileSize = 16,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        text:SetText("SimpleRestedXP - Click y arrastra para mover")
        barText:Hide()
    end
end

-- Crear Panel de Opciones
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "SimpleRestedXPOptions")
    panel.name = ADDON_NAME
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ADDON_NAME .. " Options")
    
    -- Checkbox Activado/Desactivado
    local enabledCB = CreateFrame("CheckButton", "SimpleRestedXPEnabledCB", panel, "UICheckButtonTemplate")
    enabledCB:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    _G[enabledCB:GetName() .. "Text"]:SetText("Habilitar SimpleRestedXP")
    enabledCB:SetChecked(SimpleRestedXPConfig.enabled)
    enabledCB:SetScript("OnClick", function(self)
        SimpleRestedXPConfig.enabled = self:GetChecked()
        UpdateRestedXP()
    end)
    
    -- Checkbox Color Gradiente
    local colorCB = CreateFrame("CheckButton", "SimpleRestedXPColorCB", panel, "UICheckButtonTemplate")
    colorCB:SetPoint("TOPLEFT", enabledCB, "BOTTOMLEFT", 0, -10)
    _G[colorCB:GetName() .. "Text"]:SetText("Usar colores según nivel de XP")
    colorCB:SetChecked(SimpleRestedXPConfig.colorGradient)
    colorCB:SetScript("OnClick", function(self)
        SimpleRestedXPConfig.colorGradient = self:GetChecked()
        UpdateRestedXP()
    end)
    
    -- Checkbox Mostrar Porcentaje
    local percentCB = CreateFrame("CheckButton", "SimpleRestedXPPercentCB", panel, "UICheckButtonTemplate")
    percentCB:SetPoint("TOPLEFT", colorCB, "BOTTOMLEFT", 0, -10)
    _G[percentCB:GetName() .. "Text"]:SetText("Mostrar porcentaje")
    percentCB:SetChecked(SimpleRestedXPConfig.showPercent)
    percentCB:SetScript("OnClick", function(self)
        SimpleRestedXPConfig.showPercent = self:GetChecked()
        UpdateRestedXP()
    end)
    
    -- Checkbox Mostrar Barra
    local barCB = CreateFrame("CheckButton", "SimpleRestedXPBarCB", panel, "UICheckButtonTemplate")
    barCB:SetPoint("TOPLEFT", percentCB, "BOTTOMLEFT", 0, -10)
    _G[barCB:GetName() .. "Text"]:SetText("Mostrar barra de progreso")
    barCB:SetChecked(SimpleRestedXPConfig.showBar)
    barCB:SetScript("OnClick", function(self)
        SimpleRestedXPConfig.showBar = self:GetChecked()
        UpdateRestedXP()
    end)
    
    -- Slider para escala
    local scaleSlider = CreateFrame("Slider", "SimpleRestedXPScaleSlider", panel, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", barCB, "BOTTOMLEFT", 0, -40)
    scaleSlider:SetWidth(200)
    scaleSlider:SetHeight(16)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetValue(SimpleRestedXPConfig.scale)
    _G[scaleSlider:GetName() .. "Low"]:SetText("0.5")
    _G[scaleSlider:GetName() .. "High"]:SetText("2.0")
    _G[scaleSlider:GetName() .. "Text"]:SetText("Escala: " .. SimpleRestedXPConfig.scale)
    
    scaleSlider:SetScript("OnValueChanged", function(self)
        local newScale = math.floor(self:GetValue() * 10 + 0.5) / 10
        _G[self:GetName() .. "Text"]:SetText("Escala: " .. newScale)
        SimpleRestedXPConfig.scale = newScale
        UpdateRestedXP()
    end)
    
    -- Botón para resetear posición
    local resetButton = CreateFrame("Button", "SimpleRestedXPResetButton", panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -20)
    resetButton:SetWidth(140)
    resetButton:SetHeight(22)
    resetButton:SetText("Resetear Posición")
    resetButton:SetScript("OnClick", function(self)
        SimpleRestedXPConfig.position = { x = 0, y = 400 }
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 400)
        UpdateRestedXP()
    end)
    
    -- Botón para posicionar/mover
    local moveButton = CreateFrame("Button", "SimpleRestedXPMoveButton", panel, "UIPanelButtonTemplate")
    moveButton:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -10)
    moveButton:SetWidth(140)
    moveButton:SetHeight(22)
    moveButton:SetText("Mover Pantalla")
    moveButton:SetScript("OnClick", function(self)
        ToggleMovableFrame()
    end)
    
    InterfaceOptions_AddCategory(panel)
    return panel
end

-- Configuración inicial
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UPDATE_EXHAUSTION")
frame:RegisterEvent("PLAYER_UPDATE_RESTING") -- Nuevo evento para detectar descanso
frame:RegisterEvent("ZONE_CHANGED") -- Nuevo evento para detectar cambios de zona

-- Asignamos la función al evento
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Inicializar configuración
        if not SimpleRestedXPConfig then
            SimpleRestedXPConfig = DEFAULT_CONFIG
        else
            -- Actualizar con nuevas opciones que puedan faltar
            for k, v in pairs(DEFAULT_CONFIG) do
                if SimpleRestedXPConfig[k] == nil then
                    SimpleRestedXPConfig[k] = v
                end
            end
        end
        
        -- Forzar que la barra siempre esté visible
        SimpleRestedXPConfig.showBar = true
        
        -- Aplicar posición guardada
        if SimpleRestedXPConfig.position then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER", SimpleRestedXPConfig.position.x, SimpleRestedXPConfig.position.y)
        end
        
        -- Crear panel de opciones
        CreateOptionsPanel()
    end
    
    UpdateRestedXP()
end)

-- Slash commands
SLASH_SIMPLERESTEDXP1 = "/srxp"
SLASH_SIMPLERESTEDXP2 = "/restedxp"
SlashCmdList["SIMPLERESTEDXP"] = function(msg)
    msg = string.lower(msg)
    if msg == "toggle" or msg == "" then
        SimpleRestedXPConfig.enabled = not SimpleRestedXPConfig.enabled
        UpdateRestedXP()
        print("|cFF00FF00SimpleRestedXP|r: " .. (SimpleRestedXPConfig.enabled and "Activado" or "Desactivado"))
    elseif msg == "move" then
        ToggleMovableFrame()
    elseif msg == "reset" then
        SimpleRestedXPConfig = DEFAULT_CONFIG
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 400)
        UpdateRestedXP()
        print("|cFF00FF00SimpleRestedXP|r: Configuración restablecida")
    elseif msg == "config" or msg == "options" then
        InterfaceOptionsFrame_OpenToCategory("SimpleRestedXP")
    else
        print("|cFF00FF00SimpleRestedXP|r: Comandos disponibles:")
        print("   /srxp - Alternar activado/desactivado")
        print("   /srxp move - Alternar modo de movimiento")
        print("   /srxp reset - Resetear a configuración por defecto")
        print("   /srxp config - Abrir panel de configuración")
    end
end