local function print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(msg)
end

local function GetPlayerHealthPerc()
  return UnitHealth("player")/UnitHealthMax("player")*100
end

local function ParseHealers(args, healers) -- SR data
  args = args.."#" -- add # so last argument will be matched as well
  local pattern = "(%w+)#"
  local idx = 1
  local rw_text = "Healer rotation: "
  for healer in string.gfind(args, pattern) do
    healers[idx] = healer
    idx = idx+1
    rw_text = rw_text..healer.." -> "
  end
  SendChatMessage(rw_text, "RAID_WARNING")
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
local boss_alerts = ""
local healers = {}
SLASH_KIKIALERTS1 = "/kikialerts"
SlashCmdList["KIKIALERTS"] = function(msg)
  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
  -- local _, _, cmd = string.find(msg, "%s?(.*)")
  print(msg)
  if (msg == "" or msg == nil) then
    print("/kikialerts wow")
    print("/kikialerts headshot")
    print("/kikialerts cena")
    print("/kikialerts quakef")
    print("/kikialerts quakem")
    print("/kikialerts loatheb Kikidora#Slewdem#...")
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
  elseif cmd == "loatheb" then
    if boss_alerts == "loatheb" then
      boss_alerts = ""
      print("Loatheb alerts deactivated.")
    else
      boss_alerts = "loatheb"
      healers = {}
      ParseHealers(args, healers)
      print("Loatheb alerts activated.")
    end
  end
end

local sounds = {
    wow = {path="Interface\\AddOns\\Kikialerts\\wow\\", amount=16},
    headshot = {path="Interface\\AddOns\\Kikialerts\\headshot\\", amount=4},
    cena = {path="Interface\\AddOns\\Kikialerts\\cena\\", amount=1},
    quakef = {path="Interface\\AddOns\\Kikialerts\\quakef\\", amount=15},
    quakem = {path="Interface\\AddOns\\Kikialerts\\quakem\\", amount=25}
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
  if event == "UNIT_HEALTH" then
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
    -- Your %s crits %s for %d %s damage.
    -- Your %s crits %s for %d.
    -- You crit %s for %d.
    -- You crit %s for %d %s damage.
    -- Your %s critically heals you for %d.
    -- %s's %s critically heals you for %d.
    if string.find(arg1, " crit ") or string.find(arg1, " crits ") or string.find(arg1, " critically ") then
      local idx = math.random(1, sounds[Kikialerts_profile]["amount"])
      PlaySoundFile(sounds[Kikialerts_profile]["path"]..idx..".mp3")
    end
  end
end)

------------------------------
-- Loatheb Healing Rotation --
------------------------------
local player_name = UnitName("player")
local parser_loatheb = CreateFrame("Frame")
local unitIDs = {"player"} -- unitID player
for i=2,5 do unitIDs[i] = "party"..i-1 end -- unitIDs party
for i=6,45 do unitIDs[i] = "raid"..i-5 end -- unitIDs raid
local unitIDs_cache = {} -- init unitIDs_cache[name] = unitID
-- DETECT HEALS
parser_loatheb:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
parser_loatheb:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
parser_loatheb:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")

-- parser_loatheb:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
-- parser_loatheb:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
parser_loatheb:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
-- parser_loatheb:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
-- parser_loatheb:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")

local function MakeGfindReady(template) -- changes global string to fit gfind pattern
  template = gsub(template, "%%s", "(.+)") -- % is escape: %%s = %s raw
  return gsub(template, "%%d", "(%%d+)")
end

local combatlog_patterns = {} -- parser for combat log, order = {source, attack, target, value, school}, if not presenst = nil; parse order matters!!
-- ####### HEAL SOURCE:ME TARGET:OTHER
combatlog_patterns[1] = {string=MakeGfindReady(HEALEDCRITSELFOTHER), order={nil, 1, 2, 3, nil}, kind="heal"} -- Your %s critically heals %s for %d. (parse before Your %s heals %s for %d.)
combatlog_patterns[2] = {string=MakeGfindReady(HEALEDSELFOTHER), order={nil, 1, 2, 3, nil}, kind="heal"} -- Your %s heals %s for %d.
-- combatlog_patterns[9] = {string=MakeGfindReady(PERIODICAURAHEALSELFOTHER), order={nil, 3, 1, 2, nil}, kind="heal"} -- %s gains %d health from your %s.
-- ####### HEAL SOURCE:OTHER TARGET:OTHER
combatlog_patterns[3] = {string=MakeGfindReady(HEALEDCRITOTHEROTHER), order={1, 2, 3, 4, nil}, kind="heal"} -- %s's %s critically heals %s for %d.
combatlog_patterns[4] = {string=MakeGfindReady(HEALEDOTHEROTHER), order={1, 2, 3, 4, nil}, kind="heal"} -- %s's %s heals %s for %d.
-- combatlog_patterns[12] = {string=MakeGfindReady(PERIODICAURAHEALOTHEROTHER), order={3, 4, 1, 2, nil}, kind="heal"} -- %s gains %d health from %s's %s.

local function GetUnitID(unitIDs_cache, unitIDs, name)
  if unitIDs_cache[name] and UnitName(unitIDs_cache[name]) == name then
    return unitIDs_cache[name]
  end
  for _,unitID in pairs(unitIDs) do
    if UnitName(unitID) == name then
      unitIDs_cache[name] = unitID
      return unitID
    end
  end
end

local function EOHeal(unitIDs_cache, unitIDs, value, target)
  local unitID = GetUnitID(unitIDs_cache, unitIDs, target)
  print(target)
  print(unitID)
  local eheal = 0
  local oheal = 0
  if unitID then
    eheal = math.min(UnitHealthMax(unitID) - UnitHealth(unitID), value)
    oheal = value-eheal
  end
  return eheal, oheal
end

local idx_healer = 1
-- add timer for debuff (heal hits + 60s)
parser_loatheb:SetScript("OnEvent", function()
  if boss_alerts=="loatheb" then
    print(player_name..arg1)
    local pars = {}

    for _,combatlog_pattern in ipairs(combatlog_patterns) do
      for par_1, par_2, par_3, par_4, par_5 in string.gfind(arg1, combatlog_pattern.string) do
        pars = {par_1, par_2, par_3, par_4, par_5}
        local source = pars[combatlog_pattern.order[1]]
        local spell = pars[combatlog_pattern.order[2]]
        local target = pars[combatlog_pattern.order[3]]
        local value = pars[combatlog_pattern.order[4]]
        local school = pars[combatlog_pattern.order[5]]

        -- Default values, e.g. for "You hit xyz for 15"
        if not source then
          source = player_name
        end
        if not spell then
          spell = "Hit"
        end
        if not target then
          target = player_name
        end
        if not value then
          value = 0
        end
        if not school then
          school = "physical"
        end
        if source == healers[idx_healer] then
          local eheal, oheal = EOHeal(unitIDs_cache, unitIDs, value, target)
          local rw_text = source.." used "..spell.." to heal "..target.." for "..eheal.." (+"..oheal..")"
          
          math.mod(window.cycle + 1, 5)
          SendChatMessage(rw_text, "RAID_WARNING")
        else
          SendChatMessage(source.." fucked it :(", "RAID_WARNING")
        end
      end
    end
  end
end)