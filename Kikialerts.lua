local function print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(msg)
end

local function GetPlayerHealthPerc()
  return UnitHealth("player")/UnitHealthMax("player")*100
end

-- load profile from SavedVariables
local settings = CreateFrame("Frame")
settings:RegisterEvent("ADDON_LOADED")
settings:SetScript("OnEvent", function()
  if (event == "ADDON_LOADED") and (arg1 == "Kikialerts") then
    if Kikialerts_profile == nil then
      Kikialerts_profile = "wow"
    end
  end
end)

-- slash commands
SLASH_KIKIALERTS1 = "/kikialerts"
SlashCmdList["KIKIALERTS"] = function(msg)
  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
  if (msg == "" or msg == nil) then
    print("/kikialerts wow")
    print("/kikialerts headshot")
    print("/kikialerts cena")
    print("/kikialerts quakef")
    print("/kikialerts quakem")
    print("/kikialerts perimeter")
  elseif cmd == "wow" then
    Kikialerts_profile = "wow"
    print("Selected Profile: wow")
  elseif cmd == "headshot" then
    Kikialerts_profile = "headshot"
    print("Selected Profile: headshot")
  elseif cmd == "cena" then
    Kikialerts_profile = "cena"
    print("Selected Profile: cena")
  elseif cmd == "quakef" then
    Kikialerts_profile = "quakef"
    print("Selected Profile: quakef")
  elseif cmd == "quakem" then
    Kikialerts_profile = "quakem"
    print("Selected Profile: quakem")
  elseif cmd == "perimeter" then
    Kikialerts_profile = "perimeter"
    print("Selected Profile: perimeter")
  end
end

local sounds = {
    wow = {path="Interface\\AddOns\\Kikialerts\\wow\\", amount=16},
    headshot = {path="Interface\\AddOns\\Kikialerts\\headshot\\", amount=4},
    cena = {path="Interface\\AddOns\\Kikialerts\\cena\\", amount=1},
    quakef = {path="Interface\\AddOns\\Kikialerts\\quakef\\", amount=15},
    quakem = {path="Interface\\AddOns\\Kikialerts\\quakem\\", amount=25},
    perimeter = {path="Interface\\AddOns\\Kikialerts\\perimeter\\", amount=1}
}
local player_health_perc_prev = 100

local parser_sounds = CreateFrame("Frame")
-- DETECT CRITS
parser_sounds:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
parser_sounds:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
parser_sounds:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
parser_sounds:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
-- DETECT LOW HP
parser_sounds:RegisterEvent("UNIT_HEALTH")

parser_sounds:SetScript("OnEvent", function()
  if (Kikialerts_profile ~= "perimeter") and (event == "UNIT_HEALTH") then
    if arg1 == "player" then
      local player_health_perc = GetPlayerHealthPerc()
      if (player_health_perc_prev > 10) and (player_health_perc < 10) then
        PlaySoundFile("Interface\\AddOns\\Kikialerts\\grim\\2.mp3")
      elseif (player_health_perc_prev > 20) and (player_health_perc < 20) then
        PlaySoundFile("Interface\\AddOns\\Kikialerts\\grim\\1.mp3")
      end
      player_health_perc_prev = player_health_perc
    end
  elseif arg1 then
    if Kikialerts_profile == "perimeter" then
      -- You gain Last Stand. AURAADDEDSELFHELPFUL = "You gain %s."; -- Combat log text for aura events
      -- You gain Shield Wall.
      if (arg1 == "You gain Last Stand.") or (arg1 == "You gain Shield Wall.") then
        PlaySoundFile(sounds["perimeter"]["path"].."1.mp3")
      end

      -- Your %s crits %s for %d %s damage.
      -- Your %s crits %s for %d.
      -- You crit %s for %d.
      -- You crit %s for %d %s damage.
      -- Your %s critically heals you for %d.
      -- %s's %s critically heals you for %d.
    elseif string.find(arg1, " crit ") or string.find(arg1, " crits ") or string.find(arg1, " critically ") then
      local idx = math.random(1, sounds[Kikialerts_profile]["amount"])
      PlaySoundFile(sounds[Kikialerts_profile]["path"]..idx..".mp3")
    end
  end
end)