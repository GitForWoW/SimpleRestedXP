-- Variables
local frame = CreateFrame("Frame", "RestedXPDisplayFrame", UIParent)
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetTextColor(0.8, 0.8, 1)  -- Color azul claro

-- Configuración guardada (SavedVariables)
RestedXPPos = RestedXPPos or { x = 0, y = -50 }  -- Posición por defecto

-- Función para actualizar el texto
local function UpdateRestedXP()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restedXP = GetXPExhaustion() or 0
    local restedPercent = (restedXP / maxXP) * 100
    
    text:SetText(string.format("Rested XP: %d / %d (%.1f%%)", restedXP, maxXP, restedPercent))
end

-- Función para cargar la posición guardada
local function LoadPosition()
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", RestedXPPos.x, RestedXPPos.y)
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
end

-- Hacer el marco movible
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() frame:StartMoving() end)
frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    local _, _, _, x, y = frame:GetPoint()
    RestedXPPos.x = x
    RestedXPPos.y = y
end)

-- Eventos
frame:RegisterEvent("PLAYER_XP_UPDATE")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UPDATE_EXHAUSTION")
frame:SetScript("OnEvent", UpdateRestedXP)

-- Cargar posición al iniciar
LoadPosition()

-- Slash commands
SLASH_RESTEDXP1 = "/restedxp"
SlashCmdList["RESTEDXP"] = function(cmd)
    cmd = cmd:lower()
    
    if cmd == "lock" then
        frame:SetMovable(not frame:IsMovable())
        print("RestedXP: Movimiento " .. (frame:IsMovable() and "|cFF00FF00desbloqueado|r" and "|cFFFF0000bloqueado|r"))
    elseif cmd == "reset" then
        RestedXPPos = { x = 0, y = -50 }
        LoadPosition()
        print("RestedXP: Posición reiniciada.")
    else
        if text:IsShown() then
            text:Hide()
        else
            text:Show()
            UpdateRestedXP()
        end
    end
end

-- Mensaje de ayuda al cargar
print("|cFF00FFFFRestedXPDisplay cargado!|r")
print("|cFFFFFF00/restedxp|r - Muestra/oculta el texto")
print("|cFFFFFF00/restedxp lock|r - Bloquea/desbloquea movimiento")
print("|cFFFFFF00/restedxp reset|r - Reinicia la posición")