local AWR = CreateFrame("frame")

-- Configurations
local sendMessageOnChatWhenControlled       = true     -- default is true
local channelToSendMessage                  = "YELL"   -- valid options are SAY, YELL, RAID, PARTY
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
local wrDebug          = false       -- AWR debug messages
local DOMINATE_MIND_ID = 71289       -- Lady's Mind Control ability
--local DOMINATE_MIND    = GetSpellInfo(DOMINATE_MIND_ID)
-- General spells
local HEROISM_ID       = UnitFactionGroup("player") == "Horde" and 2825 or 32182   -- Horde = "Bloodlust" / Alliance = "Heroism"
local HEROISM          = GetSpellInfo(HEROISM_ID)
local DEMONIC_PACT_ID  = 48090
local DEMONIC_PACT     = GetSpellInfo(DEMONIC_PACT_ID)
-- Trinket buffs
local trinket_ids = {
   ["SUNDIAL_OF_EXILED"]      = 60064,
   ["MIRROR_OF_TRUTH"]        = 60065,
   ["NEEDLE_SCORPION"]        = 71403,
   ["MARK_OF_SUPREMACY"]      = 67695,
   ["TALISMAN_RESURGENCE"]    = 67684,
   ["DV_N_STR"]               = 67708,
   ["DV_N_AGI"]               = 67703,
   ["DV_HC_STR"]              = 67773,
   ["DV_HC_AGI"]              = 67772,
   ["HERKUML_WAR_TOKEN"]      = 71396,  -- Frost trinket, has haste and stack up to 20 times attack power
   ["MAGHIA_MISGUIDED_QUILL"] = 71579,  -- Frost spell trinket 716 spell / 20 sec
   ["SINDRA_N"]               = 71635,
   ["SINDRA_HC"]              = 71638,
   ["DISLODGED_N"]            = 71601,
   ["DISLODGED_HC"]           = 71644,
   ["PHYLACTERY_N"]           = 71605,
   ["PHYLACTERY_HC"]          = 71636,
   ["CHARRED_N"]              = 75466,
   ["CHARRED_HC"]             = 75473,
   ["SHARPENED_N"]            = 75458,
   ["SHARPENED_HC"]           = 75456,
   ["DBW_N_STR"]              = 71484,
   ["DBW_N_HASTE"]            = 71492,
   ["DBW_N_CRIT"]             = 71491,
   ["DBW_N_AGI"]              = 71485,
   ["DBW_N_ATKPOWER"]         = 71486,
   ["DBW_N_ARP"]              = 71487,
   ["DBW_HC_STR"]             = 71561,
   ["DBW_HC_HASTE"]           = 71560,
   ["DBW_HC_CRIT"]            = 71559,
   ["DBW_HC_AGI"]             = 71556,
   ["DBW_HC_ATKPOWER"]        = 71558,
   ["DBW_HC_ARP"]             = 71557,
   ["WHISPERING_N"]           = 71401,
   ["WHISPERING_HC"]          = 71541,
   ["MURADIN_N"]              = 71570,
   ["MURADIN_HC"]             = 71573,
}
local trinket_before = {
   ["SUNDIAL_OF_EXILED"]      = GetSpellInfo(trinket_ids["SUNDIAL_OF_EXILED"]),
   ["MIRROR_OF_TRUTH"]        = GetSpellInfo(trinket_ids["MIRROR_OF_TRUTH"]),
   ["NEEDLE_SCORPION"]        = GetSpellInfo(trinket_ids["NEEDLE_SCORPION"]),
   ["MARK_OF_SUPREMACY"]      = GetSpellInfo(trinket_ids["MARK_OF_SUPREMACY"]),
   ["TALISMAN_RESURGENCE"]    = GetSpellInfo(trinket_ids["TALISMAN_RESURGENCE"]),
   ["DV_N_STR"]               = GetSpellInfo(trinket_ids["DV_N_STR"]),
   ["DV_N_AGI"]               = GetSpellInfo(trinket_ids["DV_N_AGI"]),
   ["DV_HC_STR"]              = GetSpellInfo(trinket_ids["DV_HC_STR"]),
   ["DV_HC_AGI"]              = GetSpellInfo(trinket_ids["DV_HC_AGI"]),
   ["HERKUML_WAR_TOKEN"]      = GetSpellInfo(trinket_ids["HERKUML_WAR_TOKEN"]),
   ["MAGHIA_MISGUIDED_QUILL"] = GetSpellInfo(trinket_ids["MAGHIA_MISGUIDED_QUILL"]),
   ["SINDRA_N"]               = GetSpellInfo(trinket_ids["SINDRA_N"]),
   ["SINDRA_HC"]              = GetSpellInfo(trinket_ids["SINDRA_HC"]),
   ["DISLODGED_N"]            = GetSpellInfo(trinket_ids["DISLODGED_N"]),
   ["DISLODGED_HC"]           = GetSpellInfo(trinket_ids["DISLODGED_HC"]),
   ["PHYLACTERY_N"]           = GetSpellInfo(trinket_ids["PHYLACTERY_N"]),
   ["PHYLACTERY_HC"]          = GetSpellInfo(trinket_ids["PHYLACTERY_HC"]),
   ["CHARRED_N"]              = GetSpellInfo(trinket_ids["CHARRED_N"]),
   ["CHARRED_HC"]             = GetSpellInfo(trinket_ids["CHARRED_HC"]),
   ["SHARPENED_N"]            = GetSpellInfo(trinket_ids["SHARPENED_N"]),
   ["SHARPENED_HC"]           = GetSpellInfo(trinket_ids["SHARPENED_HC"]),
   ["DBW_N_STR"]              = GetSpellInfo(trinket_ids["DBW_N_STR"]),
   ["DBW_N_HASTE"]            = GetSpellInfo(trinket_ids["DBW_N_HASTE"]),
   ["DBW_N_CRIT"]             = GetSpellInfo(trinket_ids["DBW_N_CRIT"]),
   ["DBW_N_AGI"]              = GetSpellInfo(trinket_ids["DBW_N_AGI"]),
   ["DBW_N_ATKPOWER"]         = GetSpellInfo(trinket_ids["DBW_N_ATKPOWER"]),
   ["DBW_N_ARP"]              = GetSpellInfo(trinket_ids["DBW_N_ARP"]),
   ["DBW_HC_STR"]             = GetSpellInfo(trinket_ids["DBW_HC_STR"]),
   ["DBW_HC_HASTE"]           = GetSpellInfo(trinket_ids["DBW_HC_HASTE"]),
   ["DBW_HC_CRIT"]            = GetSpellInfo(trinket_ids["DBW_HC_CRIT"]),
   ["DBW_HC_AGI"]             = GetSpellInfo(trinket_ids["DBW_HC_AGI"]),
   ["DBW_HC_ATKPOWER"]        = GetSpellInfo(trinket_ids["DBW_HC_ATKPOWER"]),
   ["DBW_HC_ARP"]             = GetSpellInfo(trinket_ids["DBW_HC_ARP"]),
   ["WHISPERING_N"]           = GetSpellInfo(trinket_ids["WHISPERING_N"]),
   ["WHISPERING_HC"]          = GetSpellInfo(trinket_ids["WHISPERING_HC"]),
   ["MURADIN_N"]              = GetSpellInfo(trinket_ids["MURADIN_N"]),
   ["MURADIN_HC"]             = GetSpellInfo(trinket_ids["MURADIN_HC"]),
}
-- Weapon enchant buffs
local weapon_enchant_ids = {
   ["BLACK_MAGIC"] = 59626,
   ["BERSERK"]     = 59620,
}
local weapon_enchant_before = {
   ["BLACK_MAGIC"] = GetSpellInfo(weapon_enchant_ids["BLACK_MAGIC"]),
   ["BERSERK"]     = GetSpellInfo(weapon_enchant_ids["BERSERK"]),
}
-- Item buffs
local item_ids = {
   ["CHAOS_BANE"]         = 73422,     -- Shadowmourne Proc Chaos Bane: 270 strength for 10 seconds
   ["RING_ICC_MELEE"]     = 72412,
   ["RING_ICC_SPELL"]     = 72416,
   ["RING_ICC_HEALER"]    = 72418,
   ["GLOVES_ENGINNER"]    = 54758,
   ["CLOAK_TAILOR_SPELL"] = 55637,
   ["CLOAK_TAILOR_MELEE"] = 55775,
}
local item_before = {
   ["CHAOS_BANE"]         = GetSpellInfo(item_ids["CHAOS_BANE"]),
   ["RING_ICC_MELEE"]     = GetSpellInfo(item_ids["RING_ICC_MELEE"]),
   ["RING_ICC_SPELL"]     = GetSpellInfo(item_ids["RING_ICC_SPELL"]),
   ["RING_ICC_HEALER"]    = GetSpellInfo(item_ids["RING_ICC_HEALER"]),
   ["GLOVES_ENGINNER"]    = GetSpellInfo(item_ids["GLOVES_ENGINNER"]),
   ["CLOAK_TAILOR_SPELL"] = GetSpellInfo(item_ids["CLOAK_TAILOR_SPELL"]),
   ["CLOAK_TAILOR_MELEE"] = GetSpellInfo(item_ids["CLOAK_TAILOR_MELEE"]),
}
-- Hunter spells
local hunter_ids = {
   ["EXPLOIT_WEAKNESS"] = 70728,  -- 2T10 buff: 15% damage for 10 sec for both hunter and pet
   ["STINGER"]          = 71007,  -- 4T10 buff: 20% attack power for 10 sec
   ["BESTIAL_WRATH"]    = 19574,
   ["CULLING_HEARD"]    = 70893,
   ["FURIOUS_HOWL"]     = 64495,
   ["KILL_COMMAND"]     = 34027,
}
local hunter_before = {
   ["EXPLOIT_WEAKNESS"] = GetSpellInfo(hunter_ids["EXPLOIT_WEAKNESS"]),
   ["STINGER"]          = GetSpellInfo(hunter_ids["STINGER"]),
   ["BESTIAL_WRATH"]    = GetSpellInfo(hunter_ids["BESTIAL_WRATH"]),
   ["CULLING_HEARD"]    = GetSpellInfo(hunter_ids["CULLING_HEARD"]),
   ["FURIOUS_HOWL"]     = GetSpellInfo(hunter_ids["FURIOUS_HOWL"]),
   ["KILL_COMMAND"]     = GetSpellInfo(hunter_ids["KILL_COMMAND"]),
}
-- Death Knight spells
local dk_ids = {
   ["ADVANTAGE"]        = 70657,  -- T10 Buff: 3% damage
   ["FALLEN_CRUSADER"]  = 53365,
   ["ANTIMAGIC_SHELL"]  = 53766,
   ["KILLING_MACHINE"]  = 51123,
   ["DEATHCHILL"]       = 49796,
   ["RIME"]             = 59052,
   ["ACCLIMATION"]      = 49200,
   ["DESOLATION"]       = 66803,
   ["VIRULENCE_SIGIL"]  = 67383,
   ["HANGED_MAN_SIGIL"] = 71227,
}
local dk_before = {
   ["ADVANTAGE"]        = GetSpellInfo(dk_ids["ADVANTAGE"]),
   ["FALLEN_CRUSADER"]  = GetSpellInfo(dk_ids["FALLEN_CRUSADER"]),
   ["ANTIMAGIC_SHELL"]  = GetSpellInfo(dk_ids["ANTIMAGIC_SHELL"]),
   ["KILLING_MACHINE"]  = GetSpellInfo(dk_ids["KILLING_MACHINE"]),
   ["DEATHCHILL"]       = GetSpellInfo(dk_ids["DEATHCHILL"]),
   ["RIME"]             = GetSpellInfo(dk_ids["RIME"]),
   ["ACCLIMATION"]      = GetSpellInfo(dk_ids["ACCLIMATION"]),
   ["DESOLATION"]       = GetSpellInfo(dk_ids["DESOLATION"]),
   ["VIRULENCE_SIGIL"]  = GetSpellInfo(dk_ids["VIRULENCE_SIGIL"]),
   ["HANGED_MAN_SIGIL"] = GetSpellInfo(dk_ids["HANGED_MAN_SIGIL"]),
}
-- Paladin spells
local paladin_ids = {
   ["ART_OF_WAR"]          = 59578,
   ["AVENGING_WRATH"]      = 31884,
   ["RIGHTEOUS_FURY"]      = 25780,
   ["VENGEANCE"]           = 20053,
   ["DIVINE_PLEA"]         = 54428,
   ["DIVINE_SACRIFICE"]    = 64205,
   ["VALIANCE_LIBRAM"]     = 67371,
   ["THREE_TRUTHS_LIBRAM"] = 67371,
}
-- do NOT loop here, the cancel for these spells are situational
local paladin_before = {
   ["ART_OF_WAR"]          = GetSpellInfo(paladin_ids["ART_OF_WAR"]),
   ["AVENGING_WRATH"]      = GetSpellInfo(paladin_ids["AVENGING_WRATH"]),
   ["VENGEANCE"]           = GetSpellInfo(paladin_ids["VENGEANCE"]),
   ["VALIANCE_LIBRAM"]     = GetSpellInfo(paladin_ids["VALIANCE_LIBRAM"]),
   ["THREE_TRUTHS_LIBRAM"] = GetSpellInfo(paladin_ids["THREE_TRUTHS_LIBRAM"]),
}
-- do NOT loop here, the cancel for these spells are situational
local paladin_after = {
   ["RIGHTEOUS_FURY"]   = GetSpellInfo(paladin_ids["RIGHTEOUS_FURY"]),
   ["DIVINE_PLEA"]      = GetSpellInfo(paladin_ids["DIVINE_PLEA"]),
   ["DIVINE_SACRIFICE"] = GetSpellInfo(paladin_ids["DIVINE_SACRIFICE"]),
}
-- Warrior spells
local warrior_ids = {
   ["BLOOD_DRINKER"]    = 70855,    -- Warrior T10 DPS proc: 16% attack power
   ["RECKLESSNESS"]     = 1719,
   ["BERSERKER_RAGE"]   = 18499,
   ["DEATH_WISH"]       = 12292,
   ["SWORD_AND_BOARD"]  = 50227,
}
local warrior_before = {
   ["BLOOD_DRINKER"]    = GetSpellInfo(warrior_ids["BLOOD_DRINKER"]),
   ["RECKLESSNESS"]     = GetSpellInfo(warrior_ids["RECKLESSNESS"]),
   ["BERSERKER_RAGE"]   = GetSpellInfo(warrior_ids["BERSERKER_RAGE"]),
   ["DEATH_WISH"]       = GetSpellInfo(warrior_ids["DEATH_WISH"]),
   ["SWORD_AND_BOARD"]  = GetSpellInfo(warrior_ids["SWORD_AND_BOARD"]),
}
-- Druid spells
local druid_ids = {
   ["NATURE_GRACE"]       = 16886,
   ["SOLAR_ECLIPSE"]      = 48517,
   ["LUNAR_ECLIPSE"]      = 48518,
   ["STARFALL"]           = 53201,
   ["OMEN_OF_DOOM"]       = 70721,
   ["BERSERK"]            = 50334,
   ["LUNAR_ECLIPSE_IDOL"] = 71177,
}
local druid_before = {
   ["NATURE_GRACE"]       = GetSpellInfo(druid_ids["NATURE_GRACE"]),
   ["SOLAR_ECLIPSE"]      = GetSpellInfo(druid_ids["SOLAR_ECLIPSE"]),
   ["LUNAR_ECLIPSE"]      = GetSpellInfo(druid_ids["LUNAR_ECLIPSE"]),
   ["STARFALL"]           = GetSpellInfo(druid_ids["STARFALL"]),
   ["OMEN_OF_DOOM"]       = GetSpellInfo(druid_ids["OMEN_OF_DOOM"]),
   ["BERSERK"]            = GetSpellInfo(druid_ids["BERSERK"]),
   ["LUNAR_ECLIPSE_IDOL"] = GetSpellInfo(druid_ids["LUNAR_ECLIPSE_IDOL"]),
}
-- Shaman spells
local shaman_ids = {
   ["ELEMENTAL_DEVASTATION"] = 29180,
   ["IMPROVED_FIRE_NOVA"]    = 16544,
   ["ELEMENTAL_MASTERY"]     = 16166,
   ["ELEMENTAL_RAGE"]        = 70829,    -- 2T10 buff when Enhancement casts Shamanistic Rage: 12% damage / 15 seg
   ["MAELSTROM_POWER"]       = 70831,    -- 4T10 buff when Enhancement gains 5 stacks of Maelstrom Weapon: 20% attack power / 10 seg
   ["FLURRY"]                = 16280,
   ["MAELSTROM_WEAPON"]      = 51532,    -- Enhancement talent to insta-cast a healing spell or Lightning Bolt or Chain Lightning
   ["TIDAL_FORCE"]           = 55198,
   ["NATURE_SWIFTNESS"]      = 16188,
   ["TIDAL_WAVES"]           = 51562,
   ["CALMING_TIDES_TOTEM"]   = 67388,
   ["FURIOUS_TOTEM"]         = 71199,
   ["QUAKING_EARTH_TOTEM"]   = 67391,
}
local shaman_before = {
   ["ELEMENTAL_DEVASTATION"] = GetSpellInfo(shaman_ids["ELEMENTAL_DEVASTATION"]),
   ["IMPROVED_FIRE_NOVA"]    = GetSpellInfo(shaman_ids["IMPROVED_FIRE_NOVA"]),
   ["ELEMENTAL_MASTERY"]     = GetSpellInfo(shaman_ids["ELEMENTAL_MASTERY"]),
   ["ELEMENTAL_RAGE"]        = GetSpellInfo(shaman_ids["ELEMENTAL_RAGE"]),
   ["MAELSTROM_POWER"]       = GetSpellInfo(shaman_ids["MAELSTROM_POWER"]),
   ["FLURRY"]                = GetSpellInfo(shaman_ids["FLURRY"]),
   ["MAELSTROM_WEAPON"]      = GetSpellInfo(shaman_ids["MAELSTROM_WEAPON"]),
   ["TIDAL_FORCE"]           = GetSpellInfo(shaman_ids["TIDAL_FORCE"]),
   ["NATURE_SWIFTNESS"]      = GetSpellInfo(shaman_ids["NATURE_SWIFTNESS"]),
   ["TIDAL_WAVES"]           = GetSpellInfo(shaman_ids["TIDAL_WAVES"]),
   ["CALMING_TIDES_TOTEM"]   = GetSpellInfo(shaman_ids["CALMING_TIDES_TOTEM"]),
   ["FURIOUS_TOTEM"]         = GetSpellInfo(shaman_ids["FURIOUS_TOTEM"]),
   ["QUAKING_EARTH_TOTEM"]   = GetSpellInfo(shaman_ids["QUAKING_EARTH_TOTEM"])
}
local priest_ids = {
   ["SHADOWY_INSIGHT"]     = 61792,
   ["SHADOW_WEAVING"]      = 15258,
   ["IMPROVED_SPIRIT_TAP"] = 59000,
}
local priest_before = {
   ["SHADOWY_INSIGHT"]     = GetSpellInfo(priest_ids["SHADOWY_INSIGHT"]),
   ["SHADOW_WEAVING"]      = GetSpellInfo(priest_ids["SHADOW_WEAVING"]),
   ["IMPROVED_SPIRIT_TAP"] = GetSpellInfo(priest_ids["IMPROVED_SPIRIT_TAP"]),
}
-- Mage spells
local mage_ids = {
   ["MAGE_ARMOR"]          = 43024,
   ["PUSHING_THE_LIMIT"]   = 70753,  -- 2T10 Buff when mage consume Hot Streak/Missile Barrage/Brain Freeze: 12% haste / 5 seg
   ["QUAD_CORE"]           = 70747,  -- 4T10 Buff when mage casts Mirror Image: 18% damage / 30 seg
   ["PRESENCE_OF_MIND"]    = 12043,
   ["ARCANE_POWER"]        = 12042,
   ["INCANTER_ABSORPTION"] = 44394,
   ["MISSILE_BARRAGE"]     = 44401,
   ["ICY_VEINS"]           = 12472,
   ["COMBUSTION"]          = 28682,
   ["HOT_STREAK"]          = 48108,
   ["FINGERS_OF_FROST"]    = 44544,
   ["BRAIN_FREEZE"]        = 57761,
}
local mage_before = {
   ["MAGE_ARMOR"]          = GetSpellInfo(mage_ids["MAGE_ARMOR"]),
   ["PUSHING_THE_LIMIT"]   = GetSpellInfo(mage_ids["PUSHING_THE_LIMIT"]),
   ["QUAD_CORE"]           = GetSpellInfo(mage_ids["QUAD_CORE"]),
   ["PRESENCE_OF_MIND"]    = GetSpellInfo(mage_ids["PRESENCE_OF_MIND"]),
   ["ARCANE_POWER"]        = GetSpellInfo(mage_ids["ARCANE_POWER"]),
   ["INCANTER_ABSORPTION"] = GetSpellInfo(mage_ids["INCANTER_ABSORPTION"]),
   ["MISSILE_BARRAGE"]     = GetSpellInfo(mage_ids["MISSILE_BARRAGE"]),
   ["ICY_VEINS"]           = GetSpellInfo(mage_ids["ICY_VEINS"]),
   ["COMBUSTION"]          = GetSpellInfo(mage_ids["COMBUSTION"]),
   ["HOT_STREAK"]          = GetSpellInfo(mage_ids["HOT_STREAK"]),
   ["FINGERS_OF_FROST"]    = GetSpellInfo(mage_ids["FINGERS_OF_FROST"]),
   ["BRAIN_FREEZE"]        = GetSpellInfo(mage_ids["BRAIN_FREEZE"]),
}
-- Warlock spells
local warlock_ids = {
   --["METAMORPHOSIS"] = 47241,  -- This is not possible because Metamorphosis is considered a shapeshift, like druid forms and so it's a protected API
   ["IMMOLATION_AURA"] = 50589,
   ["DEVIOUS_MINDS"]   = 70840,  -- 4T10 buff: 10% damage
   ["SHADOW_TRANCE"]   = 17941,  -- Insta Shadow Bolt
   ["ERADICATION"]     = 64371,
   ["LIFE_TAP"]        = 63321,
   ["MOLTEN_CORE"]     = 71165,
   ["DECIMATION"]      = 63167,
   ["BACKDRAFT"]       = 54277,
}
local warlock_before = {
   --["METAMORPHOSIS"] = GetSpellInfo(warlock_ids["METAMORPHOSIS"]),
   ["IMMOLATION_AURA"] = GetSpellInfo(warlock_ids["IMMOLATION_AURA"]),
   ["DEVIOUS_MINDS"]   = GetSpellInfo(warlock_ids["DEVIOUS_MINDS"]),
   ["SHADOW_TRANCE"]   = GetSpellInfo(warlock_ids["SHADOW_TRANCE"]),
   ["ERADICATION"]     = GetSpellInfo(warlock_ids["ERADICATION"]),
   ["LIFE_TAP"]        = GetSpellInfo(warlock_ids["LIFE_TAP"]),
   ["MOLTEN_CORE"]     = GetSpellInfo(warlock_ids["MOLTEN_CORE"]),
   ["DECIMATION"]      = GetSpellInfo(warlock_ids["DECIMATION"]),
   ["BACKDRAFT"]       = GetSpellInfo(warlock_ids["BACKDRAFT"]),
}

local validChannels      = {"SAY", "YELL", "RAID", "PARTY"}
local dpsPhysicalClasses = {"HUNTER", "DEATHKNIGHT", "PALADIN_Protection", "PALADIN_Retribution", "WARRIOR", "DRUID_Feral", "ROGUE", "SHAMAN_Enhancement"}
local dpsSpellClasses    = {"DRUID_Balance","SHAMAN_Elemental","PRIEST_Shadow","MAGE","WARLOCK"}
local healerClasses      = {"PALADIN_Holy","DRUID_Restoration","SHAMAN_Restoration","PRIEST_Discipline","PRIEST_Holy"}

local playerClass
local playerSpec
local playerClassAndSpec
local sentChatMessageTime   = 0       -- Last time the messageToBeSentWhenControlled were sent
local sentAddonMessageTime  = 0       -- Last time the addonMessageForWeaponRemoval were sent
local playerControlledCount = 0       -- How many times the player has been controlled by Lady
local weaponsRemovedCount   = 0       -- How many times weapons have been removed by this addon

-- Player current instance info
local instanceName
local instanceDifficultyIndex
local instanceIsHeroic

local groupTalentsLib
local addonVersion

-- Upvalues
local UnitInRaid, UnitAffectingCombat = UnitInRaid, UnitAffectingCombat
local GetSpellLink, UnitAffectingCombat, format = GetSpellLink, UnitAffectingCombat, string.format

AWR:SetScript("OnEvent", function(self, event, ...)
   self[event](self, ...)
end)

-- Utility functions
local function send(msg)
   if(msg~=nil) then print(AWR_ADDON_PREFIX .. msg) end
end

local function sendNoPrefix(msg)
   if(msg~=nil) then print(msg) end
end

local function say(msg)
   if(msg~=nil) then SendChatMessage(msg, channelToSendMessage) end
end

local is_int = function(n)
   return (type(n) == "number") and (math.floor(n) == n)
end

-- [string utils]
local function upperFirst(str)
   if(str==nil) then return "" end
   return (str:gsub("^%l", string.upper))
end

local function upperFirstOnly(str)
   if(str==nil) then return "" end
   return upperFirst(str:lower())
end

-- Remove spaces on start and end of string
local function trim(s)
   return string.match(s,'^()%s*$') and '' or string.match(s,'^%s*(.*%S)')
end

local function removeWords(myString, numberOfWords)
   if (myString~=nil and numberOfWords~=nil) then
      if is_int(numberOfWords) then
         for i=1, numberOfWords do
            myString = string.gsub(myString,"^(%s*%a+)","",1)
         end
         return trim(myString)
      else send("numberOfWords arg came, it's not nil BUT it's also NOT an integer, report this, type = " .. tostring(type(numberOfWords))) end
   end
   return ""
end
-- end of [string utils]

local function doesElementContainsAnyValueFromTable(table, element)
   if table==nil then send("table came nil inside function to check if table contain a value that fits inside an element, report this");return; end
   if element==nil then send("element came nil inside function to check if table contain a value that fits inside an element, report this");return; end

   -- If any value from the table is contained inside the element then return true, aka the table have a value that match fits inside the element
   for _, value in pairs(table) do
      if string.match(element, value) then
         return true
      end
   end
   return false
end

local function tableHasThisEntry(table, entry)
   if table==nil then send("table came nil inside function that check if table has a value, report this");return; end
   if entry==nil then send("entry came nil inside function to check if table has a value, report this");return; end

   for _, value in ipairs(table) do
      if value == entry then
         return true
      end
   end
   return false
end

local function getTableLength(table)
   local count = 0
   for _ in pairs(table) do count = count + 1 end
   return count
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

local function updatePlayerLocal()  -- Update variables with player current instance info
   instanceName,_,instanceDifficultyIndex,_,_,instanceIsHeroic = GetInstanceInfo()
end

local function updatePlayerLocalIfNeeded()
   if(instanceName==nil or instanceDifficultyIndex==nil or instanceIsHeroic==nil) then updatePlayerLocal() end
end

local function updatePlayerSpec()
   -- the function GetUnitTalentSpec from GroupTalentsLib can return a number if the player has not yet seen that class/build, so another "just in case" code, but I'm not sure what if this number means the talent tree number (like 1 for balance, 3 for restoration) or just the spec slot (player has just two slots), I guess I'll have to shoot in the dark here. ;)
   -- I just discovered that this function can also return nil if called when player is logging in (probably because the inspect function doesn't work while logging in)
   local spec = groupTalentsLib:GetUnitTalentSpec(UnitName("player"))
   if spec=="Feral Combat" then spec = "Feral" end  -- We will treat 'Feral Combat' as 'Feral'

   if spec~=nil then
      playerSpec = spec
      AWR.db.spec = spec
   end
end

local function getPlayerSpec()
   if playerSpec==nil then
      updatePlayerSpec()
   end
   return playerSpec or AWR.db.spec
end

local function updatePlayerClassAndSpec()
   updatePlayerSpec()
   if playerSpec~=nil then
      playerClassAndSpec = playerClass .. "_" .. playerSpec  -- E.G. PALADIN_Retribution
   end
end

local function updatePlayerClassAndSpecIfNeeded()
   if playerSpec==nil then updatePlayerSpec() end
   if playerClassAndSpec==nil then updatePlayerClassAndSpec() end
end

local function isPlayerDPSPhysical()
   updatePlayerClassAndSpecIfNeeded()
   if playerClassAndSpec==nil then send("playerClassAndSpec came nil inside function to check if player is dps physical, report this.");return false; end

   local isPhysical = doesElementContainsAnyValueFromTable(dpsPhysicalClasses, playerClassAndSpec)
   --if wrDebug then send("player class is dps physical? " .. tostring(isPhysical)) end
   return isPhysical
end

local function isPlayerDPSSpell()
   updatePlayerClassAndSpecIfNeeded()
   if playerClassAndSpec==nil then send("playerClassAndSpec came nil inside function to check if player is dps spell, report this.");return false; end

   local isSpell = doesElementContainsAnyValueFromTable(dpsSpellClasses, playerClassAndSpec)
   --if wrDebug then send("player class is dps spell? " .. tostring(isSpell)) end
   return isSpell
end

local function isPlayerHealer()
   updatePlayerClassAndSpecIfNeeded()
   if playerClassAndSpec==nil then send("playerClassAndSpec came nil inside function to check if player is healer, report this.");return false; end

   local isHealer = doesElementContainsAnyValueFromTable(healerClasses, playerClassAndSpec)
   --if wrDebug then send("player class is healer? " .. tostring(isHealer)) end
   return isHealer
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

local function cancelAllBuffsFromPlayerInTable(buffTable)
   if buffTable ==nil then send("buffTable came nil inside function to remove all buffs inside table from player, report this.");return false; end

   for _, value in pairs(buffTable) do
      CancelUnitBuff("player", value)
   end
end

-- Logic functions are under here
local function removeWeapons(isTesting)
   if(isTesting==nil) then isTesting = false end
   updatePlayerClassAndSpecIfNeeded()

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
      if not isTesting then
         weaponsRemovedCount = weaponsRemovedCount + 1
         AWR.db.weaponsremovedcount = weaponsRemovedCount
      end
   elseif wrDebug then send("class is not selected for weapon removal.") end
end

local function onDominateMindCast(isTesting)
   if(isTesting==nil) then isTesting = false end
   updatePlayerClassAndSpecIfNeeded()

   if sendMessageOnChatWhenControlled and (GetTime() > (sentChatMessageTime + 5)) and (not wrDebug or not isTesting) then -- GetTime comparison here is preventing sending same message two times in a row, a "just in case" check
      say(messageToBeSentWhenControlled)
      sentChatMessageTime = GetTime()
   end
   if not isTesting then
      playerControlledCount = playerControlledCount + 1
      AWR.db.playercontrolledcount = playerControlledCount
   end
   removeWeapons(isTesting)

   if not isTesting or wrDebug then
      -- Canceling player buffs
      -- Generic buffs
      if not isPlayerDPSPhysical() then
         CancelUnitBuff("player", HEROISM)
      end
      if isPlayerDPSSpell() then
         CancelUnitBuff("player", DEMONIC_PACT)
      end
      -- Trinket buffs
      cancelAllBuffsFromPlayerInTable(trinket_before)
      -- Weapon enchant buffs
      cancelAllBuffsFromPlayerInTable(weapon_enchant_before)
      -- Item buffs
      cancelAllBuffsFromPlayerInTable(item_before)
      -- Class buffs
      if playerClass=="HUNTER" then
         cancelAllBuffsFromPlayerInTable(hunter_before)
      elseif playerClass=="DEATHKNIGHT" then
         cancelAllBuffsFromPlayerInTable(dk_before)
      elseif playerClass=="PALADIN" then
         cancelAllBuffsFromPlayerInTable(paladin_before)
      elseif playerClass=="WARRIOR" then
         cancelAllBuffsFromPlayerInTable(warrior_before)
      elseif playerClass=="DRUID" then
         cancelAllBuffsFromPlayerInTable(druid_before)
      elseif playerClass=="SHAMAN" then
         cancelAllBuffsFromPlayerInTable(shaman_before)
      elseif playerClass=="PRIEST" then
         cancelAllBuffsFromPlayerInTable(priest_before)
      elseif playerClass=="MAGE" then
         cancelAllBuffsFromPlayerInTable(mage_before)
      elseif playerClass=="WARLOCK" then
         cancelAllBuffsFromPlayerInTable(warlock_before)
      end
   end
end

local function onDominateMindFade()
   updatePlayerClassAndSpecIfNeeded()

   if playerClass=="PALADIN" then
      if getPlayerSpec()~="Protection" and removePaladinRFAfterControlsEnd then CancelUnitBuff("player", paladin_after["RIGHTEOUS_FURY"]) end
      if getPlayerSpec()=="Holy" and removeDivinePleaAfterControlsEndIfHoly then CancelUnitBuff("player", paladin_after["DIVINE_PLEA"]) end
      CancelUnitBuff("player", paladin_after["DIVINE_SACRIFICE"])
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

local function regForAllEvents()
   if(AWR==nil) then send("frame is nil inside function that register for all events function, report this"); return; end
   if wrDebug then send("addon is now listening to all combatlog events.") end

   AWR:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   AWR:RegisterEvent("PLAYER_REGEN_ENABLED")
   AWR:RegisterEvent("PLAYER_REGEN_DISABLED")
   AWR:RegisterEvent("PLAYER_TALENT_UPDATE")
   AWR:RegisterEvent("PLAYER_DIFFICULTY_CHANGED")
end

local function unregFromAllEvents()
   if(AWR==nil) then send("frame is nil inside function that unregister all events function, report this"); return; end
   if wrDebug then send("addon is no longer listening to combatlog events.") end

   AWR:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   AWR:UnregisterEvent("PLAYER_REGEN_ENABLED")
   AWR:UnregisterEvent("PLAYER_REGEN_DISABLED")
   AWR:UnregisterEvent("PLAYER_TALENT_UPDATE")
   if instanceName~="Icecrown Citadel" then AWR:UnregisterEvent("PLAYER_DIFFICULTY_CHANGED") end -- Even if the addon unregister from all events, if player is inside ICC 10-man normal its difficulty may still change to heroic
end

-- Checks if addon should be enabled, and enable it if isn't enabled, and disable if it should not be enabled
local function checkIfAddonShouldBeEnabled()
   if(AWR==nil) then send("frame came nil inside function that check if this addon should be enabled, report this"); return; end

   updatePlayerLocalIfNeeded()
   -- Check if user disabled the addon, if the player is inside ICC, if the ICC is either 25n, 10hc or 25hc and if it's 10 man mode then if it's heroic or not
   -- The addon will remain active inside ICC because I cannot get the number of bossesKilled within the instance
   if AWR.db.enabled and ((instanceName == "Icecrown Citadel" and (instanceDifficultyIndex > 1 or instanceIsHeroic)) or wrDebug) then
      regForAllEvents()
      return true
   else
      unregFromAllEvents()
      return false
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

-- Called when player enters combat
-- Used here to double check if we have what spec player is, and if not then we call getPlayerSpec to get what spec player is beforehand, yet another "just in case" code that if lady casts dominate mind addon maybe won't have time to query what class player is before the control affects the player
function AWR:PLAYER_REGEN_DISABLED()
   updatePlayerClassAndSpec()
end

function AWR:PLAYER_DIFFICULTY_CHANGED()
   checkIfAddonShouldBeEnabled()
end

function AWR:PLAYER_TALENT_UPDATE()
   updatePlayerClassAndSpec()
   if wrDebug then send("updated talents, now you are using " .. playerSpec or "Unknown") end
end

function AWR:PLAYER_ENTERING_WORLD()
   -- instanceName is index 1, difficultyIndex is index 3 (return 1 means 10 normal, 2 means 25 normal, 3 means 10 heroic and 4 means 25 heroic), isHeroic is index 6
   -- /run print(GetInstanceInfo())
   -- while in Dalaran it returned Northrend none 1  0 0 false
   -- while inside ICC it returned Icecrown Citadel raid 2 25 Player 25 0 true
   updatePlayerLocal()
   updatePlayerClassAndSpecIfNeeded()
   checkIfAddonShouldBeEnabled()
end

-- Slash commands functions
-- toggle, on, off
local function slashCommandToggleAddon(state)
   if state == "on" or (not AWR.db.enabled and state==nil) then
      AWR.db.enabled = true
      checkIfAddonShouldBeEnabled()
      send("|cff00ff00on|r")
   elseif state == "off" or (AWR.db.enabled and state==nil) then
      AWR.db.enabled = false
      checkIfAddonShouldBeEnabled()
      send("|cffff0000off|r")
   end
end

-- status, state
local function slashCommandStatus()
   if not AWR.db.enabled then send(AWR_REASON_ADDONISOFF)
   else
      updatePlayerLocalIfNeeded()
      if instanceName~="Icecrown Citadel" then send(AWR_REASON_NOTINICC)
      elseif (difficultyIndex==1 and isHeroic==0) then send(AWR_REASON_RAIDDIFFICULTY)
      else send(AWR_REASON_INSIDEICC) end
   end
end

-- version, ver
local function slashCommandVersion()
   if(addonVersion==nil) then send(AWR_ADDON_STILL_LOADING); return; end
   send("version " .. addonVersion)
end

-- spec
local function slashCommandSpec()
   if(playerClass==nil) then send(AWR_ADDON_STILL_LOADING); return; end
   updatePlayerClassAndSpec()
   local spec = getPlayerSpec()
   local class = playerClass

   if class=="DEATHKNIGHT" then class = "Death Knight"
   else class = upperFirstOnly(playerClass) end
   if spec==nil then spec = "Unknown"
   else spec = upperFirstOnly(spec) end

   send("Your class is " .. class .. " and your build is " .. spec .. ".")
end

-- debug
local function slashCommandDebug()
   if not wrDebug then
      wrDebug = true
      AWR.db.debug = true
      send("debug mode turned |cff00ff00on|r")
   else
      wrDebug = false
      AWR.db.debug = false
      send("debug mode turned |cffff0000off|r")
   end
end

-- count, report
local function slashCommandCount()
   send(format(AWR_REPORT_COUNT,playerControlledCount,weaponsRemovedCount))
end

-- message
local function slashCommandMessage(message)
   if message==nil or message=="" then
      send(format(AWR_CURRENT_MESSAGE,messageToBeSentWhenControlled))
      return
   end

   messageToBeSentWhenControlled = message
   AWR.db.messagetobesentwhencontrolled = messageToBeSentWhenControlled
   send(format(AWR_CHANGED_SAY_MESSAGE,messageToBeSentWhenControlled))
end

-- channel
local function slashCommandChannel(channel)
   if channel==nil or channel=="" then
      send(format(AWR_SELECTED_CHANNEL,channelToSendMessage))
      return
   end

   channel = channel:upper()
   if tableHasThisEntry(validChannels, channel) then
      send(format(AWR_CHANGED_CURRENTLY_CHANNEL,channel))
      channelToSendMessage = channel
      AWR.db.channeltosendmessage = channelToSendMessage
   else
      local str = ""
      local validChannelsLength = getTableLength(validChannels)
      for index, value in ipairs(validChannels) do
         str = str .. "\"" .. value .. "\"" .. (index~=validChannelsLength and ", " or ".")
      end
      send(format(AWR_ERROR_INVALID_CHANNEL,str))
   end

end

local function slashCommand(typed)
   local cmd = string.match(typed, "^(%w+)") -- Gets the first word the user has typed
   if cmd~=nil then cmd = cmd:lower() end            -- And makes it lower case
   local extra = removeWords(typed,1)

   if(cmd=="help" or cmd=="?" or cmd=="" or cmd==nil) then
      sendNoPrefix(AWR_HELP1)
      sendNoPrefix(AWR_HELP2)
      sendNoPrefix(AWR_HELP3)
      sendNoPrefix(AWR_HELP4)
      sendNoPrefix(AWR_HELP5)
      sendNoPrefix(AWR_HELP6)
      sendNoPrefix(AWR_HELP7)
      sendNoPrefix(AWR_HELP8)
      sendNoPrefix(AWR_HELP9)
   elseif(cmd=="toggle") then slashCommandToggleAddon()
   elseif(cmd=="on") then slashCommandToggleAddon("on")
   elseif(cmd=="off") then slashCommandToggleAddon("off")
   elseif(cmd=="status" or cmd=="state") then slashCommandStatus()
   elseif(cmd=="version" or cmd=="ver") then slashCommandVersion()
   elseif(cmd=="spec") then slashCommandSpec()
   elseif(cmd=="removeweapon" or cmd=="removeweapons" or cmd=="rw") then onDominateMindCast(true)
   elseif(cmd=="debug") then slashCommandDebug()
   elseif(cmd=="count" or cmd=="report") then slashCommandCount()
   elseif(cmd=="message" or cmd=="m") then slashCommandMessage(extra)
   elseif(cmd=="channel" or cmd=="c") then slashCommandChannel(extra)
   end
end
-- End of slash commands function

function AWR:ADDON_LOADED(addon)
   if addon ~= "AutomaticWeaponRemoval" then return end

   playerClass = select(2,UnitClass("player"))  -- Get player class
   if not turnAddonOnEvenIfClassIsNotSelected and not isAddonEnabledForPlayerClass() then
      if wrDebug then send("addon is not enabled for " .. playerClass .. ", disabling the addon.") end
      self:UnregisterEvent("ADDON_LOADED")
      return
   elseif wrDebug then send("addon is enabled for " .. playerClass .. ", nice!")
   end

   addonVersion = GetAddOnMetadata("AutomaticWeaponRemoval", "Version")
   groupTalentsLib = LibStub("LibGroupTalents-1.0")   -- Importing LibGroupTalents so I can use it later by using groupTalentsLib variable
   AWRDB = AWRDB or { enabled = true }
   self.db = AWRDB
   -- Loading variables
   wrDebug = self.db.debug or wrDebug
   playerControlledCount = self.db.playercontrolledcount or playerControlledCount
   weaponsRemovedCount = self.db.weaponsremovedcount or weaponsRemovedCount
   messageToBeSentWhenControlled = self.db.messagetobesentwhencontrolled or messageToBeSentWhenControlled
   channelToSendMessage = self.db.channeltosendmessage or channelToSendMessage
   SLASH_AUTOMATICWEAPONREMOVAL1 = "/awr"
   SLASH_AUTOMATICWEAPONREMOVAL2 = "/automaticweaponremoval"
   SlashCmdList.AUTOMATICWEAPONREMOVAL = function(cmd) slashCommand(cmd) end
   if wrDebug then send("remember that debug mode is " .. "|cff00ff00ON|r.") end

   self:RegisterEvent("PLAYER_ENTERING_WORLD")
   self:UnregisterEvent("ADDON_LOADED")
end

AWR:RegisterEvent("ADDON_LOADED")