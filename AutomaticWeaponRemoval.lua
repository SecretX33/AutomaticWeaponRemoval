local AWR = CreateFrame("frame")

-- Configurations
local sendMessageOnChatWhenControlled       = true     -- default is true
local channelToSendMessage                  = "SAY"    -- valid options are SAY, YELL, RAID, RAID_WARNING, PARTY
local messageToBeSentWhenControlled         = "I got controlled, CC me NOW!!!"
local showAddonMessageForWeaponRemoval      = true     -- default is true
local addonMessageForWeaponRemoval          = "Lady casted control on you, removing weapons."

local turnAddonOnEvenIfClassIsNotSelected    = true     -- default is true
local removeOnlyBowIfHunter                  = false    -- default is false
local removePaladinRFAfterControlsEnd        = true     -- default is true, the addon won't remove RF if player is protection paladin even if this is set "true"
local removeDivinePleaAfterControlsEndIfHoly = true     -- default is true, the idea is to be able to fully heal someone (or yourself) after dominate mind fades because usually you are low on HP then that happens, so be able to heal 100% is better than 50%

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
   ["WARLOCK_Affliction"]  = false,      -- default is false
   ["WARLOCK_Demonology"]  = false,      -- default is false
   ["WARLOCK_Destruction"] = false,      -- default is false
}
-- End of Configurations


-- Don't touch anything below
local wrDebug              = false       -- AWR debug messages
local DOMINATE_MIND_ID     = 71289       -- Lady's Mind Control ability
local DOMINATE_MIND        = GetSpellLink(DOMINATE_MIND_ID)
local RIGHTEOUS_FURY_ID    = 25780
local RIGHTEOUS_FURY       = GetSpellLink(RIGHTEOUS_FURY_ID)
local DIVINE_PLEA_ID       = 54428
local DIVINE_PLEA          = GetSpellLink(DIVINE_PLEA_ID)
local DIVINE_SACRIFICE_ID  = 64205
local DIVINE_SACRIFICE     = GetSpellLink(DIVINE_SACRIFICE_ID)

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
   if(msg~=nil) then print(addonPrefix:format(msg)) end
end

local function say(msg)
   if(msg~=nil) then SendChatMessage(msg, channelToSendMessage) end
end

-- Not using these functions yet
--[[local function getSpellName(spellID)
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

local function getICCDifficultyIndexAsString(index)
   if index==nil then send("'index' parameter came nil inside function to get instance as name, report this."); return ""; end

   if index==1 then return "10-man normal"
   elseif index==2 then return "25-man normal"
   elseif index==3 then return "10-man heroic"
   elseif index==4 then return "25-man heroic"
   else send("Report this, unexpected value came as parameter inside function that convert difficultyIndex to the string equivalent, the value passed is \'" .. tostring(index) .. "\'.")
   end
end ]]--

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

      if showAddonMessageForWeaponRemoval and (GetTime() > (sentAddonMessageTime + 5)) then -- GetTime comparison here is preventing sending same message two times in a row, a "just in case" check
         send(addonMessageForWeaponRemoval)
         sentAddonMessageTime = GetTime()
      end
   elseif wrDebug then send("class is not selected for weapon removal.") end
end

local function onDominateMindCast()
   if sendMessageOnChatWhenControlled and (GetTime() > (sentChatMessageTime + 5)) then -- GetTime comparison here is preventing sending same message two times in a row, a "just in case" check
      say(messageToBeSentWhenControlled)
      sentChatMessageTime = GetTime()
   end
   removeWeapons()
end

local function onDominateMindFade()
   if playerSpec==nil then playerSpec = getPlayerSpec() end

   if playerClass=="PALADIN" then
      if playerSpec~="Protection" and removePaladinRFAfterControlsEnd then CancelUnitBuff("player", RIGHTEOUS_FURY) end
      if playerSpec=="Holy" and removeDivinePleaAfterControlsEndIfHoly then CancelUnitBuff("player", DIVINE_PLEA) end
      CancelUnitBuff("player", DIVINE_SACRIFICE)
   end
end

function AWR:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, srcGUID, srcName, srcFlags, destGUID, destName, destFlags, spellID, spellName, ...)
   if srcName ~= UnitName("player") and destName ~= UnitName("player") then return end -- The event if NOT from the player, so that is not relevant

   -- If Lady cast Dominate Mind on player
   if spellID == DOMINATE_MIND_ID and (event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED") and destName == UnitName("player") then
      if wrDebug then send("Lady just casted " .. GetSpellLink(DOMINATE_MIND_ID) .. " on the player.") end
      onDominateMindCast()

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
      checkIfAddonShouldBeEnabled()
   end
end

-- Called when player enters combat
-- Used here to double check if we have what spec player is, and if not then we call getPlayerSpec to get what spec player is beforehand, yet another "just in case" code that if lady casts dominate mind addon maybe won't have time to query what class player is before the control affects the player
function AWR:PLAYER_REGEN_DISABLED()
   if self.db.enabled and playerSpec==nil then
      playerSpec = getPlayerSpec()
   end
end

local function regForAllEvents()
   if(AWR==nil) then send("frame is nil inside function that register for all events function, report this"); return; end
   if wrDebug then send("addon is now listening to all combatlog events.") end

   AWR:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   AWR:RegisterEvent("PLAYER_REGEN_ENABLED")
   AWR:RegisterEvent("PLAYER_REGEN_DISABLED")
   AWR:RegisterEvent("PLAYER_TALENT_UPDATE")
   AWR:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
   --AWR:RegisterEvent("UPDATE_INSTANCE_INFO")
end

local function unregFromAllEvents()
   if(AWR==nil) then send("frame is nil inside function that unregister all events function, report this"); return; end
   if wrDebug then send("addon is no longer listening to combatlog events.") end

   local instanceName = GetInstanceInfo()
   AWR:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   AWR:UnregisterEvent("PLAYER_REGEN_ENABLED")
   AWR:UnregisterEvent("PLAYER_REGEN_DISABLED")
   AWR:UnregisterEvent("PLAYER_TALENT_UPDATE")
   if instanceName~="Icecrown Citadel" then AWR:UnregisterEvent("PLAYER_DIFFICULTY_CHANGED") end -- Even if the addon unregister from all events, if player is inside ICC 10-man normal its difficulty may still change to heroic
   --AWR:UnregisterEvent("UPDATE_INSTANCE_INFO")
end

function AWR:PLAYER_DIFFICULTY_CHANGED()
   if self.db.enabled then checkIfAddonShouldBeEnabled() end
end

--[[function AWR:UPDATE_INSTANCE_INFO()
   if wrDebug and not gotRaidInfo then
      send("UPDATE_INSTANCE_INFO called")

      local lockTimeLeft,_,encountersTotal,bossesKilled = GetInstanceLockTimeRemaining()
      local isLKKilled = select(3,GetInstanceLockTimeRemainingEncounter(12))

      send("Time until lock period ends is " .. tostring(lockTimeLeft) .. ".")
      send("The total number of bosses within this instance is " .. tostring(encountersTotal) .. ".")
      send("The number of bosses killed within this instance is " .. tostring(bossesKilled) .. ".")
      send("return from GetInstanceLockTimeRemainingEncounter is " .. tostring(isLKKilled))

      if (bossesKilled~=0 or isLKKilled~=nil) then gotRaidInfo = true end
   end
end]]--

--local function isLadyDead()
--   local instanceName = GetInstanceInfo()
--   if instanceName~="Icecrown Citadel" then return true end  -- If we are not inside ICC, this function will return false so the addon will disable itself
--
--   -- [API_GetInstanceLockTimeRemaining] returns info about current instance, index 4 is encountersComplete, or how many bosses are already dead
--   local bossesKilled = select(4, GetInstanceLockTimeRemaining())
--
--   if bossesKilled~=nil then
--      if wrDebug then send("for this instance, bossesKilled value is " .. bossesKilled) end
--      if bossesKilled > 2 then return true end
--   end
--   return false
--end

-- Utility function since API_GetInstanceLockTimeRemaining is broken, this is a workaround to get instance details for current ICC
-- return ID, index
--[[local function getICCRaidInfo(difficultyIndex)
   local numsaved = GetNumSavedInstances()
   if numsaved > 0 then
      for i = 1, numsaved do
         local instanceName,id,_,diff,locked = GetSavedInstanceInfo(i)
         if instanceName=="Icecrown Citadel" and locked and diff==difficultyIndex then return id, numsaved end
      end
   end
   return 0, 0  -- Neutral return if current lock for the given difficulty (difficultyIndex) was found
end

local function getNumberICCBossesKilled(difficultyIndex)
   local id, index = getICCRaidInfo(difficultyIndex)

   if id ~=0 then
      local bossesKilled = select(12, GetSavedInstanceInfo(index))
      if bossesKilled~=nil then return bossesKilled end
   end
   return 0
end

local function isLadyNextEncounter()
   local instanceName,_,difficultyIndex = GetInstanceInfo()
   if instanceName~="Icecrown Citadel" then return false end  -- If we are not inside ICC, this function will return false so the addon will disable itself

   -- [API_GetInstanceLockTimeRemaining] returns info about current instance, index 4 is encountersComplete, or how many bosses are already dead
   -- BROKEN API
   local bossesKilled = select(4, GetInstanceLockTimeRemaining())
   --local bossesKilled = getNumberICCBossesKilled(difficultyIndex)

   if bossesKilled~=nil then
      if wrDebug then send("for this instance, bossesKilled value is " .. bossesKilled) end
      if bossesKilled == 1 then return true end  -- If Lord Marrowgar is dead
   end
   return false
end]]--

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
   -- BROKEN API, applying temporary fix, the addon will remain active in ICC because I cannot get the number of bossesKilled within the instance
   --if AWR.db.enabled and ((instanceName == "Icecrown Citadel" and (difficultyIndex > 1 or isHeroic) and not isLadyDead()) or wrDebug) then
   if AWR.db.enabled and ((instanceName == "Icecrown Citadel" and (difficultyIndex > 1 or isHeroic)) or wrDebug) then
      regForAllEvents()
   else
      unregFromAllEvents()
   end
end

function AWR:PLAYER_TALENT_UPDATE()
   playerSpec = getPlayerSpec()
   --if wrDebug then send("you have changed your build to " .. playerSpec) end
end

function AWR:PLAYER_ENTERING_WORLD()
   if playerSpec==nil then playerSpec = getPlayerSpec() end
   checkIfAddonShouldBeEnabled()
end

local function isAddonEnabledForPlayerClass()
   if(playerClass==nil) then send("playerClass came null inside function to check if addon should be enabled for class, report this"); return; end

   -- If the key is for our class and if it's value is true then return true, else return false
   for key, value in pairs(removeFor) do
      if string.match(key, playerClass) and value then
         return true
      end
   end
   return false
end

-- Slash commands functions
-- /awr toggle, on, off
local function slashCommandToggleAddon(state)
   if not AWR.db.enabled or state == "on" then
      AWR.db.enabled = true
      checkIfAddonShouldBeEnabled()
      send("|cff00ff00on|r")
   elseif AWR.db.enabled or state == "off" then
      AWR.db.enabled = false
      checkIfAddonShouldBeEnabled()
      send("|cffff0000off|r")
   end
end

-- /awr status
local function slashCommandStatus()
   if not AWR.db.enabled then send(AWR_REASON_ADDONISOFF)
   else
      local instanceName,_,difficultyIndex,_,_,isHeroic = GetInstanceInfo()
      --local bossesKilled = select(4, GetInstanceLockTimeRemaining())
      --local bossesKilled = getNumberICCBossesKilled(difficultyIndex)

      if instanceName~="Icecrown Citadel" then send(AWR_REASON_NOTINICC)
      elseif (difficultyIndex==1 and isHeroic==0) then send(AWR_REASON_RAIDDIFFICULTY)
      else send(AWR_REASON_INSIDEICC)
      --elseif (bossesKilled~=nil and bossesKilled==0) then send(AWR_REASON_LORDWASNOTKILLED)
      --elseif (bossesKilled~=nil and bossesKilled>2) then send(AWR_REASON_LADYISDEAD)
      --elseif isLadyNextEncounter() then send(AWR_REASON_LADYISNEXT) end
      --else send(AWR_REASON_LADYISNEXT)   -- Temp fix while I don't find why API_GetInstanceLockTimeRemaining is returning "0 false 0 0" even while inside ICC
      end
   end
end

function AWR:ADDON_LOADED(addon)
   if addon ~= "AutomaticWeaponRemoval" then return end

   playerClass = select(2,UnitClass("player"))  -- Get player class
   if not turnAddonOnEvenIfClassIsNotSelected and not isAddonEnabledForPlayerClass() then
      if wrDebug then send("addon is not enabled for " .. playerClass .. ", disabling the addon.") end
      self:UnregisterEvent("ADDON_LOADED")
      return
   elseif wrDebug then send("addon is enabled for " .. playerClass .. ", nice!")
   end

   groupTalentsLib = LibStub("LibGroupTalents-1.0")   -- Importing LibGroupTalents so I can use it later by using groupTalentsLib variable
   AWRDB = AWRDB or { enabled = true }  -- DB just stores if addon is turned on or off
   self.db = AWRDB
   SLASH_AUTOMATICWEAPONREMOVAL1 = "/awr"
   SLASH_AUTOMATICWEAPONREMOVAL2 = "/automaticweaponremoval"

   SlashCmdList.AUTOMATICWEAPONREMOVAL = function(cmd)
      if(cmd=="help" or cmd=="") then
         send(AWR_HELP1)
         send(AWR_HELP2)
         send(AWR_HELP3)
      elseif(cmd=="toggle") then slashCommandToggleAddon()
      elseif(cmd=="on") then slashCommandToggleAddon("on")
      elseif(cmd=="off") then slashCommandToggleAddon("off")
      elseif(cmd=="status") then slashCommandStatus()
      elseif(cmd=="debug") and wrDebug then
         --send("this icc have " .. getNumberICCBossesKilled(4) .. " bosses killed")
         --send("is lady next boss? " .. tostring(isLadyNextEncounter()))
      end
   end
   self:RegisterEvent("PLAYER_ENTERING_WORLD")
   self:UnregisterEvent("ADDON_LOADED")
end

AWR:RegisterEvent("ADDON_LOADED")