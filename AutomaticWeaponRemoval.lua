local AWR = CreateFrame("frame")

-- Configurations
local sendMessageOnChatWhenControlled       = true     -- default is true
local channelToSendMessage                  = "SAY"    -- valid options are SAY, YELL, RAID, RAID_WARNING, PARTY
local messageToBeSentWhenControlled         = "I got controlled, CC me NOW!!!"
local showAddonMessageForWeaponRemoval      = true     -- default is true
local addonMessageForWeaponRemoval          = "Lady casted control on you, removing weapons."

local removeOnlyBowIfHunter                 = false    -- default is false
local removePaladinRFAfterControlsEnd       = true     -- default is true, the addon won't remove RF if player is protection paladin even if this is set "true"
local removeDivinePleaAfterControlledIfHoly = true     -- default is true, the idea is to be able to fully heal someone (or yourself) after dominate mind fades because usually you are low on HP then that happens, so be able to heal 100% is better than 50%

local removeFor = {
   -- Hunter
   ["HUNTER_BeastMastery"] = true,       -- default is true
   ["HUNTER_Marksmanship"] = true,       -- default is true
   ["HUNTER_Survival"]     = true,       -- default is true
   -- Death Knight
   ["DEATHKNIGHT_Blood"]   = true,       -- default is true
   ["DEATHKNIGHT_Frost"]   = true,       -- default is true
   ["DEATHKNIGHT_Unholy"]  = true,       -- default is true
   -- Paladin
   ["PALADIN_Holy"]        = false,      -- default is false
   ["PALADIN_Protection"]  = true,       -- default is true
   ["PALADIN_Retribution"] = true,       -- default is true
   -- Warrior
   ["WARRIOR_Arms"]        = true,       -- default is true
   ["WARRIOR_Fury"]        = true,       -- default is true
   ["WARRIOR_Protection"]  = true,       -- default is true
   -- Druid
   ["DRUID_Balance"]       = false,      -- default is false
   ["DRUID_Feral"]         = true,       -- default is true
   ["DRUID_Restoration"]   = false,      -- default is false
   -- Rogue
   ["ROGUE_Assassination"] = true,       -- default is true
   ["ROGUE_Combat"]        = true,       -- default is true
   ["ROGUE_Subtlety"]      = true,       -- default is true
   -- Shaman
   ["SHAMAN_Elemental"]    = false,      -- default is false
   ["SHAMAN_Enhancement"]  = true,       -- default is true
   ["SHAMAN_Restoration"]  = false,      -- default is false
   -- Priest
   ["PRIEST_Discipline"]   = false,      -- default is false
   ["PRIEST_Holy"]         = false,      -- default is false
   ["PRIEST_Shadow"]       = false,      -- default is false
   -- Mage
   ["MAGE_Arcane"]         = false,      -- default is false
   ["MAGE_Fire"]           = false,      -- default is false
   ["MAGE_Frost"]          = false,      -- default is false
   -- Warlock
   ["MAGE_Arcane"]         = false,      -- default is false
   ["MAGE_Fire"]           = false,      -- default is false
   ["MAGE_Frost"]          = false,      -- default is false
}
-- /run print(select(2,UnitClass("player")))

-- Don't touch anything below
local wrDebug              = false       -- AWR debug messages
local DOMINATE_MIND_ID     = 71289       -- Lady's Mind Control ability
local DOMINATE_MIND        = GetSpellLink(71289)
local RIGHTEOUS_FURY_ID    = 25780
local RIGHTEOUS_FURY       = GetSpellLink(25780)
local DIVINE_PLEA_ID       = 54428
local DIVINE_PLEA          = GetSpellLink(54428)
local DIVINE_SACRIFICE_ID  = 64205
local DIVINE_SACRIFICE     = GetSpellLink(64205)

local playerClass
local playerSpec
local sentChatMessageTime  = 0       -- Last time the messageToBeSentWhenControlled were sent
local sentAddonMessageTime = 0       -- Last time the addonMessageForWeaponRemoval were sent

local groupTalentsLib
local addonPrefix = "|cff2f6af5AWR:|r %s"

-- Upvalues
local UnitInRaid, UnitAffectingCombat = UnitInRaid, UnitAffectingCombat
local GetSpellLink, UnitAffectingCombat, format = GetSpellLink, UnitAffectingCombat, string.format

AWR:SetScript("OnEvent", function(self, event, ...)
   self[event](self, ...)
end)

-- Utility functions
local function send(msg)
   print(addonPrefix:format(msg))
end

local function say(msg)
   SendChatMessage(msg, channelToSendMessage)
end

local function getSpellName(spellID)
   if spellID==nil then return "" end

   local spellName = GetSpellInfo(spellID)
   if spellName~=nil then return spellName else return "" end
end

local function getBuffExpirationTime(unit, buff)
   if(unit==nil or buff==nil) then return 0 end

   -- /run print(select(7,UnitBuff("player",GetSpellInfo(48518)))-GetTime())
   -- 11.402

   -- "API select" pull all the remaining returns from a given function or API starting from that index, the first valid number is 1
   -- [API_UnitBuff] index 7 is the absolute time (client time) when the buff will expire, in seconds

   local now = GetTime()
   local expirationAbsTime = select(7, UnitBuff(unit, buff))

   if expirationAbsTime~=nil then return (expirationAbsTime - now) end
   return 0
end

local function doesUnitHaveThisBuff(unit, buff)
   if(unit==nil or buff==nil) then return false end

   return UnitBuff(unit,buff)~=nil
end

local function getPlayerSpec()
   -- the function GetUnitTalentSpec from GroupTalentsLib can return a number if the player has not yet seen that class/build, so another "just in case" code, but I'm not sure what if this number means the talent tree number (like 1 for balance, 3 for restoration) or just the spec slot (player has just two slots), I guess I'll have to shoot in the dark here. ;)
   -- I just discovered that this function can also return nil if called when player is logging in (probably because the inspect function doesn't work while logging in), so I added the 'nil' as returning true to circumvent this issue
   local spec = groupTalentsLib:GetUnitTalentSpec(UnitName("player"))
   --if wrDebug then send("queried what spec player is, returned " .. tostring(spec)) end
   return spec
end

-- Logic functions are under here
local function removeWeapons()
   if playerSpec==nil then playerSpec = getPlayerSpec() end

   -- E.G. PALADIN_Retribution
   local playerClassAndSpec = playerClass .. "_" .. playerSpec
   if wrDebug then send("inside function removeWeapon, string classAndSpec is " .. playerClassAndSpec) end

   if removeFor[playerClassAndSpec] then
      if playerClass~="HUNTER" or not removeOnlyBowIfHunter then
         PickupInventoryItem(16)
         PutItemInBackpack()
         PickupInventoryItem(17)
         PutItemInBackpack()
      end
      if playerClass=="HUNTER" then
         PickupInventoryItem(18)
         PutItemInBackpack()
      end

      if showAddonMessageForWeaponRemoval and (GetTime() > (sentAddonMessageTime + 5)) then
         send(addonMessageForWeaponRemoval)
         sentAddonMessageTime = GetTime()
      end
   elseif wrDebug then send("class is not selected for weapon removal.") end
end

local function onDominateMindFade()
   if playerSpec==nil then playerSpec = getPlayerSpec() end

   if playerClass=="PALADIN" then
      if playerSpec~="Protection" and removePaladinRFAfterControlsEnd then CancelUnitBuff("player", RIGHTEOUS_FURY) end
      if playerSpec=="Holy" and removeDivinePleaAfterControlledIfHoly then CancelUnitBuff("player", DIVINE_PLEA) end
      CancelUnitBuff("player", DIVINE_SACRIFICE)
   end
end

function AWR:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, srcGUID, srcName, srcFlags, destGUID, destName, destFlags, spellID, spellName, ...)
   if srcName ~= UnitName("player") and destName ~= UnitName("player") then return end -- The event if NOT from the player, so that is not relevant

   -- If Lady cast Dominate Mind on player
   if spellID == DOMINATE_MIND_ID and (event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED") and destName == UnitName("player") then
      if wrDebug then send("Lady just casted " .. GetSpellLink(DOMINATE_MIND_ID) .. " on the player.") end

      if sendMessageOnChatWhenControlled and (GetTime() > (sentChatMessageTime + 5)) then -- both GetTimes here prevent sending same message two times in a row, a "just in case" check
         say(messageToBeSentWhenControlled)
         sentChatMessageTime = GetTime()
      end
      removeWeapons()

   elseif spellID == DOMINATE_MIND_ID and event == "SPELL_AURA_REMOVED" and destName == UnitName("player") then
      if wrDebug then send(GetSpellLink(DOMINATE_MIND_ID) .. " just faded from the player.") end
      onDominateMindFade()
   end
end

-- Called when player leaves combat
-- Used to zero all variables so the addon logic knows that, when player enters combat again, it's a new fight against a new enemy
function AWR:PLAYER_REGEN_ENABLED()
   if self.db.enabled then
      if wrDebug then send("Addon variables got zeroed because player leave combat.") end
      sentChatMessageTime  = 0
      sentAddonMessageTime = 0
   end
end

local function regForAllEvents()
   if(AWR==nil) then send("frame is nil inside function that register for all events function, report this"); return; end
   if wrDebug then send("addon is now listening to all combatlog events.") end

   AWR:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   AWR:RegisterEvent("PLAYER_REGEN_ENABLED")
   AWR:RegisterEvent("PLAYER_TALENT_UPDATE")
   AWR:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
end

local function unregFromAllEvents()
   if(AWR==nil) then send("frame is nil inside function that unregister all events function, report this"); return; end
   if wrDebug then send("addon is no longer listening to combatlog events.") end

   AWR:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   AWR:UnregisterEvent("PLAYER_REGEN_ENABLED")
   AWR:UnregisterEvent("PLAYER_TALENT_UPDATE")
   AWR:UnregisterEvent("PLAYER_DIFFICULTY_CHANGED")
end

function AWR:PLAYER_DIFFICULTY_CHANGED()
   if self.db.enabled then checkIfAddonShouldBeEnabled() end
end

-- Checks if addon should be enabled, and enable it if isn't enabled, and disable if it should not be enabled
local function checkIfAddonShouldBeEnabled()
   if(AWR==nil) then send("frame came nil inside function that check if this addon should be enabled, report this"); return; end
   -- instanceName is index 1, difficultyIndex is index 3 (return 1 means 10 normal, 2 means 25 normal, 3 means 10 heroic and 4 means 25 heroic), isHeroic is index 6
   -- /run print(GetInstanceInfo())
   -- while in Dalaran it returned Northrend none 1  0 0 false
   -- while inside ICC it returned Icecrown Citadel raid 2 25 Player 25 0 true

   local instanceName,_,difficultyIndex,_,_,isHeroic = GetInstanceInfo()
   --if wrDebug then send("GetInstanceInfo inside checkIfAddonShouldBeEnabled returned " .. GetInstanceInfo()) end

   -- Check if user disabled the addon, if the player is inside ICC, if the ICC is either 25n, 10hc or 25hc and if it's 10 man mode then if it's heroic or not
   if AWR.db.enabled and ((instanceName == "Icecrown Citadel" and (difficultyIndex > 1 or isHeroic)) or wrDebug) then
      regForAllEvents()
   else
      unregFromAllEvents()
   end
end

function AWR:PLAYER_TALENT_UPDATE()
   playerSpec = getPlayerSpec()
   --if wrDebug then send("you have changed your build to " .. playerSpec) end
   checkIfAddonShouldBeEnabled()
   removeWeapons()
end

function AWR:PLAYER_ENTERING_WORLD()
   if playerSpec==nil then playerSpec = getPlayerSpec() end
   checkIfAddonShouldBeEnabled()
end

function AWR:ADDON_LOADED(addon)
   if addon ~= "AutomaticWeaponRemoval" then return end

   playerClass = select(2,UnitClass("player"));  -- Get player class
   groupTalentsLib = LibStub("LibGroupTalents-1.0")   -- Importing LibGroupTalents so I can use it later by using groupTalentsLib variable
   AWRDB = AWRDB or { enabled = true }  -- DB just stores if addon is turned on or off
   self.db = AWRDB
   SLASH_AUTOMATICWEAPONREMOVAL1 = "/awr"
   SLASH_AUTOMATICWEAPONREMOVAL2 = "/automaticweaponremoval"
   SlashCmdList.AUTOMATICWEAPONREMOVAL = function()
      if not self.db.enabled then
         self.db.enabled = true
         checkIfAddonShouldBeEnabled()
         send("|cff00ff00on|r")
      else
         self.db.enabled = false
         checkIfAddonShouldBeEnabled()
         send("|cffff0000off|r")
      end
   end
   self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

AWR:RegisterEvent("ADDON_LOADED")