-- Variables
local frame = CreateFrame("Frame", "SimpleRestedXPFrame", UIParent)
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER", UIParent, "CENTER", 0, 400)  -- Posición en pantalla
text:SetTextColor(1, 1, 1)  -- Color blanco

-- Función para actualizar el texto
local function UpdateRestedXP()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restedXP = GetXPExhaustion() or 0  -- Si no hay rested, devuelve 0
    
    -- Calculamos el porcentaje
    local restedPercent = (restedXP / maxXP) * 100
    
    -- Mostramos el texto
    text:SetText(string.format("Rested XP: %d / %d (%.1f%%)", restedXP, maxXP, restedPercent))
end

-- Eventos
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UPDATE_EXHAUSTION")

-- Asignamos la función al evento
frame:SetScript("OnEvent", UpdateRestedXP)

-- Slash command para mostrar/ocultar (opcional)
SLASH_RESTEDXP1 = "/restedxp"
SlashCmdList["RESTEDXP"] = function()
    if text:IsShown() then
        text:Hide()
    else
        text:Show()
        UpdateRestedXP()
    end
end