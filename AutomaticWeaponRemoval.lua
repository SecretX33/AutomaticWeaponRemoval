--[[------------------------------------------------------------+
|   AutomaticWeaponRemoval                                      |
|   --> Automatic weapon removal when mind controlled           |
|   Author: SecretX (Freezingice @ WoW Brasil)                  |
|   Contact: notyetmidnight@gmail.com                           |
+--------------------------------------------------------------]]

local sendMessageOnChatWhenControlled       = true     -- default is true
local channelToSendMessage                  = "YELL"   -- valid options are SAY, YELL, RAID, PARTY
local messageToBeSentWhenControlled         = "I got controlled, CC me NOW!!!"
local showAddonMessageForWeaponRemoval      = true     -- default is true

-- Class Options
local classOptions = {
   ["removeOnlyBowIfHunter"] = false,                  -- default is false
   ["removePaladinRFAfterControlsEnd"] = true,         -- default is true, the addon won't remove RF if player is protection paladin even if this is set "true"
   ["removeDivinePleaAfterControlsEndIfHoly"] = true,  -- default is true, the idea is to be able to fully heal someone (or yourself) after dominate mind fades because usually you are low on HP then that happens, so be able to heal 100% is better than 50%
}

-- Global Weapon Removal Options
local removeFor = {
   -- Hunter
   ["HUNTER_BeastMastery"] = true,
   ["HUNTER_Marksmanship"] = true,
   ["HUNTER_Survival"]     = true,
   -- Death Knight
   ["DEATHKNIGHT_Blood"]   = true,
   ["DEATHKNIGHT_Frost"]   = true,
   ["DEATHKNIGHT_Unholy"]  = true,
   -- Paladin
   ["PALADIN_Holy"]        = false,
   ["PALADIN_Protection"]  = true,
   ["PALADIN_Retribution"] = true,
   -- Warrior
   ["WARRIOR_Arms"]        = true,
   ["WARRIOR_Fury"]        = true,
   ["WARRIOR_Protection"]  = true,
   -- Druid
   ["DRUID_Balance"]       = false,
   ["DRUID_Feral"]         = true,
   ["DRUID_Restoration"]   = false,
   -- Rogue
   ["ROGUE_Assassination"] = true,
   ["ROGUE_Combat"]        = true,
   ["ROGUE_Subtlety"]      = true,
   -- Shaman
   ["SHAMAN_Elemental"]    = false,
   ["SHAMAN_Enhancement"]  = true,
   ["SHAMAN_Restoration"]  = false,
   -- Priest
   ["PRIEST_Discipline"]   = false,
   ["PRIEST_Holy"]         = false,
   ["PRIEST_Shadow"]       = false,
   -- Mage
   ["MAGE_Arcane"]         = false,
   ["MAGE_Fire"]           = false,
   ["MAGE_Frost"]          = false,
   -- Warlock
   ["WARLOCK_Affliction"]  = false,
   ["WARLOCK_Demonology"]  = false,
   ["WARLOCK_Destruction"] = false,
}

local validChannels      = AWR_VALID_CHANNELS
local validInstances     = AWR_VALID_INSTANCES
local validLanguages     = AWR_SUPPORTED_LANGUAGES
local dpsPhysicalClasses = AWR_DPS_PHYSICAL_CLASSES
local dpsSpellClasses    = AWR_DPS_SPELL_CLASSES
local healerClasses      = AWR_HEALER_CLASSES
local specs              = AWR_SPECS

local wrDebug                 = false      -- AWR debug messages
local mind_control_spells_ids = {
   ["LADY_DOMINATE_MIND"]            = 71289,     -- Lady's Mind Control ability (ICC)
   ["BQ_UNCONTROLLABLE_FRENZY"]      = 70923,     -- Blood Queen's Mind Control ability (ICC)
   ["FACELESS_HORROR_DOMINATE_MIND"] = 63713,     -- Ulduar trash mob
   ["YOGG_INSANE"]                   = 63120,     -- Yogg-Saron's Mind Control ability (Ulduar)
   ["CHAINS_OF_KELTHUZAD"]           = 28410,     -- Kel'Thuzad's Mind Control ability (Naxxramas)
}
-- Look for these spell casts
local mind_control_spells_cast = {
   ["LADY_DOMINATE_MIND"]            = mind_control_spells_ids["LADY_DOMINATE_MIND"],
   ["BQ_UNCONTROLLABLE_FRENZY"]      = mind_control_spells_ids["BQ_UNCONTROLLABLE_FRENZY"],
   ["FACELESS_HORROR_DOMINATE_MIND"] = mind_control_spells_ids["FACELESS_HORROR_DOMINATE_MIND"],
   ["YOGG_INSANE"]                   = mind_control_spells_ids["YOGG_INSANE"],
   ["CHAINS_OF_KELTHUZAD"]           = mind_control_spells_ids["CHAINS_OF_KELTHUZAD"],
   ["DEBUG"]                         = 0
}
local mind_control_spells_duration = {
   [mind_control_spells_ids["LADY_DOMINATE_MIND"]]            = 12,
   [mind_control_spells_ids["BQ_UNCONTROLLABLE_FRENZY"]]      = -1,    -- value '-1' here means infinite
   [mind_control_spells_ids["FACELESS_HORROR_DOMINATE_MIND"]] = 20,
   [mind_control_spells_ids["YOGG_INSANE"]]                   = -1,    -- Tecnically, it's not infinite, its duration is 1 minute but after debuff fades player will die
   [mind_control_spells_ids["CHAINS_OF_KELTHUZAD"]]           = 20,
}
-- And also for these spell fades
local mind_control_spells_fade = {
   ["LADY_DOMINATE_MIND"]            = mind_control_spells_ids["LADY_DOMINATE_MIND"],
}
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
local paladin_before = {
   ["ART_OF_WAR"]          = GetSpellInfo(paladin_ids["ART_OF_WAR"]),
   ["VENGEANCE"]           = GetSpellInfo(paladin_ids["VENGEANCE"]),
   ["VALIANCE_LIBRAM"]     = GetSpellInfo(paladin_ids["VALIANCE_LIBRAM"]),
   ["THREE_TRUTHS_LIBRAM"] = GetSpellInfo(paladin_ids["THREE_TRUTHS_LIBRAM"]),
}
-- do NOT loop here, the cancel for these spells are situational
local paladin_special = {
   ["AVENGING_WRATH"]   = GetSpellInfo(paladin_ids["AVENGING_WRATH"]),
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

local playerClass
local playerSpec
local playerClassAndSpec
local sentChatMessageTime   = 0       -- Last time the messageToBeSentWhenControlled were sent
local sentAddonMessageTime  = 0       -- Last time the addonMessageForWeaponRemoval were sent
local addedPlayerCountTime  = 0       -- Last time addon added +1 to the mind control count
local addedWeaponsCountTime = 0       -- Last time addon added +1 to the weapon removal count
local playerControlledCount = 0       -- How many times the player has been controlled by Lady
local weaponsRemovedCount   = 0       -- How many times weapons have been removed by this addon

-- Player current instance info
local instanceName
local instanceDifficultyIndex
local instanceIsHeroic

local libGroupTalents
local addonLanguage = "enUS"
local raid = {}

-- Upvalues
local UnitName, SendChatMessage, CancelUnitBuff, PickupInventoryItem, PutItemInBackpack, UnitBuff, format = UnitName, SendChatMessage, CancelUnitBuff, PickupInventoryItem, PutItemInBackpack, UnitBuff, string.format
local GetSpellLink, GetInstanceInfo, GetInventoryItemLink, GetTime, GetContainerNumFreeSlots = GetSpellLink, GetInstanceInfo, GetInventoryItemLink, GetTime, GetContainerNumFreeSlots

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
   if str==nil then return "" end
   assert(type(str) == "string", "bad argument #1: 'str' needs to be a string; instead what came was " .. tostring(type(str)))
   return (str:gsub("^%l", string.upper))
end

local function upperFirstOnly(str)
   if str==nil then return "" end
   assert(type(str) == "string", "bad argument #1: 'str' needs to be a string; instead what came was " .. tostring(type(str)))
   return upperFirst(str:lower())
end

-- Remove spaces on start and end of string
local function trim(s)
   if s==nil then return "" end
   assert(type(s) == "string", "bad argument #1: 's' needs to be a string; instead what came was " .. tostring(type(s)))
   return string.match(s,'^()%s*$') and '' or string.match(s,'^%s*(.*%S)')
end

local function removeWords(myString, howMany)
   if (myString~=nil and howMany~=nil) then
      assert(type(myString) == "string", "bad argument #1: 'myString' needs to be a string; instead what came was " .. tostring(type(myString)))
      assert(type(howMany) == "number", "bad argument #2: 'howMany' needs to be a number; instead what came was " .. tostring(type(howMany)))
      assert(math.floor(howMany) == howMany, "bad argument #2: 'howMany' needs to be an integer")

      for i=1, howMany do
         myString = string.gsub(myString,"^(%s*%a+)","",1)
      end
      return trim(myString)
   end
   return ""
end
-- end of [string utils]

local function doesElementContainsAnyValueFromTable(table, element)
   assert(table~=nil, "bad argument #1: 'table' cannot be nil")
   assert(type(table) == "table", "bad argument #1: 'table' needs to be a table; instead what came was " .. tostring(type(table)))
   assert(element~=nil, "bad argument #2: 'element' cannot be nil")

   -- If any value from the table is contained inside the element then return true, aka the table have a value that match fits inside the element
   for _, value in pairs(table) do
      if string.match(element, value) then
         return true
      end
   end
   return false
end

local function tableHasThisEntry(table, entry)
   assert(table~=nil, "bad argument #1: 'table' cannot be nil")
   assert(type(table) == "table", "bad argument #1: 'table' needs to be a table; instead what came was " .. tostring(type(table)))
   assert(entry~=nil, "bad argument #2: 'entry' cannot be nil")

   local func = (rawget(table, 1) ~= nil) and ipairs or pairs

   for _, value in func(table) do
      if value == entry then
         return true
      end
   end
   return false
end

local function tableHasThisEntryOnKeyOrValue(table, entry)
   assert(table~=nil, "bad argument #1: 'table' cannot be nil")
   assert(type(table) == "table", "bad argument #1: 'table' needs to be a table; instead what came was " .. tostring(type(table)))
   assert(entry~=nil, "bad argument #2: 'entry' cannot be nil")

   for key, value in pairs(table) do
      if key:lower() == entry:lower() or value:lower() == entry:lower() then
         return true
      end
   end
   return false
end

local function getTableLength(table)
   assert(table~=nil, "bad argument #1: 'table' cannot be nil")
   assert(type(table) == "table", "bad argument #1: 'table' needs to be a table; instead what came was " .. tostring(type(table)))

   local count = 0
   for _ in pairs(table) do count = count + 1 end
   return count
end

-- automatically sends an addon message to the appropriate channel (BATTLEGROUND, RAID or PARTY)
local function sendSync(prefix, msg)
   assert(prefix~=nil, "bad argument #1: 'prefix' cannot be nil")
   assert(type(prefix) == "string", "bad argument #1: 'prefix' needs to be a string; instead what came was " .. tostring(type(prefix)))
   local zoneType = select(2, IsInInstance())
   if zoneType == "pvp" or zoneType == "arena" then
      SendAddonMessage(prefix, msg, "BATTLEGROUND")
   elseif GetRealNumRaidMembers() > 0 then
      SendAddonMessage(prefix, msg, "RAID")
   elseif GetRealNumPartyMembers() > 0 then
      SendAddonMessage(prefix, msg, "PARTY")
   end
end

--local function isAddonEnabledForPlayerClass()
--   if(playerClass==nil) then send("playerClass came null inside function to check if addon should be enabled for class, report this"); return; end
--
--   -- If the key is for our class and if it's value is true then return true, else return false
--   for key, value in pairs(removeFor) do
--      if string.match(key, playerClass) and value then
--         return true
--      end
--   end
--   return false
--end

local function updatePlayerLocal()  -- Update variables with player current instance info
   instanceName,_,instanceDifficultyIndex,_,_,instanceIsHeroic = GetInstanceInfo()
end

local function updatePlayerLocalIfNeeded()
   if(instanceName==nil or instanceDifficultyIndex==nil or instanceIsHeroic==nil) then updatePlayerLocal() end
end

local function updatePlayerSpec()
   -- the function GetUnitTalentSpec from GroupTalentsLib can return a number if the player has not yet seen that class/build, so another "just in case" code, but I'm not sure what if this number means the talent tree number (like 1 for balance, 3 for restoration) or just the spec slot (player has just two slots), I guess I'll have to shoot in the dark here. ;)
   -- I just discovered that this function can also return nil if called when player is logging in (probably because the inspect function doesn't work while logging in)
   local spec = libGroupTalents:GetUnitTalentSpec(UnitName("player"))
   if spec=="Feral Combat" then spec = "Feral" end  -- We will treat 'Feral Combat' as 'Feral'

   if spec~=nil then
      playerSpec = spec
      AWR.dbc.spec = spec
   end
end

local function getPlayerSpec()
   if playerSpec==nil then
      updatePlayerSpec()
   end
   return playerSpec or AWR.dbc.spec
end

local function updatePlayerClassAndSpec()
   updatePlayerSpec()
   if playerSpec~=nil then
      playerClassAndSpec = playerClass .. "_" .. playerSpec  -- E.G. PALADIN_Retribution
   end
end

local function updatePlayerClassAndSpecIfNeeded()
   if playerSpec==nil or playerClassAndSpec==nil then updatePlayerClassAndSpec() end
end

do
   local nextQuery;

   local function onUpdate()
      if not nextQuery or GetTime() < nextQuery then
         return;
      end
      updatePlayerClassAndSpecIfNeeded()
      if playerSpec and playerClassAndSpec then
         if wrDebug then send("unregisted of function to query player class and spec") end
         nextQuery = nil
         this:SetScript("OnUpdate", nil)
         AWR:ResetRaid()
         AWR:RAID_ROSTER_UPDATE()
         AWR:PARTY_MEMBERS_CHANGED()
      else
         nextQuery = GetTime() + 1
      end
   end

   function AWR:QueueGetPlayerClassSpec()
      if not playerClassAndSpec and not nextQuery then
         nextQuery = GetTime() + 2
         this:SetScript("OnUpdate", onUpdate)
      end
   end
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

function AWR:GetFormattedClassSpec()
   updatePlayerClassAndSpec()
   local spec = getPlayerSpec()
   local class = playerClass

   if class=="DEATHKNIGHT" then class = "Death Knight"
   else class = upperFirstOnly(playerClass) end
   if spec==nil then spec = "Unknown"
   else spec = upperFirstOnly(spec) end

   return class, spec
end

local function getBuffExpirationTime(unit, buff)
   assert(unit~=nil, "bad argument #1: 'unit' cannot be nil")
   assert(type(unit) == "string", "bad argument #1: 'unit' needs to be a string; instead what came was " .. tostring(type(unit)))
   if(buff==nil) then return 0 end

   -- /run print(select(7,UnitBuff("player",GetSpellInfo(48518)))-GetTime())
   -- 11.402

   -- "API select" pull all the remaining returns from a given function or API starting from that index, the first valid number is 1
   -- [API_UnitBuff] index 7 is the absolute time (client time) when the buff will expire, in seconds

   local now = GetTime()
   local expirationAbsTime = select(7, UnitBuff(unit, buff))

   if expirationAbsTime~=nil then return math.max(0,(expirationAbsTime - now)) end
   return 0
end

local function getDebuffDurationTime(spellID)
   if spellID==nil then send("spellID came nil inside function to get debuff duration, report this"); return 0; end
   if type(spellID)~="number" or math.floor(spellID)~=spellID then send("spellID came, but it's not an integer inside function to get debuff duration, report this, its type is " .. tostring(type(spellID))); return 0; end

   for key, value in pairs(mind_control_spells_duration) do
      if key == spellID then
         if value == -1 then
            return 9999
         else
            return value
         end
      end
   end
   return 12  -- Default value for mind control duration, should cover most mind controls
end

local function cancelAllBuffsFromPlayerInTable(buffTable)
   assert(buffTable~=nil, "bad argument #1: 'buffTable' cannot be nil")
   assert(type(buffTable) == "table", "bad argument #1: 'buffTable' needs to be a table; instead what came was " .. tostring(type(buffTable)))

   for _, value in pairs(buffTable) do
      CancelUnitBuff("player", value)
   end
end

local function sendAddonMessageForControlled(message, removedWeapons, bossName, isTesting)
   if message==nil then return end
   assert(removedWeapons~=nil, "bad argument #2: 'removedWeapons' cannot be nil")
   assert(type(removedWeapons) == "boolean", "bad argument #2: 'buffTable' needs to be a boolean; instead what came was " .. tostring(type(removedWeapons)))
   if bossName==nil then bossName = AWR_LADY_NAME end
   if isTesting==nil then isTesting = false end

   if showAddonMessageForWeaponRemoval and (GetTime() > (sentAddonMessageTime + 5)) then -- GetTime comparison here is preventing sending same message two times in a row, a "just in case" check
      send(format(message,bossName))
      sentAddonMessageTime = GetTime()
   end
end

local function sayMessageOnChatForControlled(isTesting)
   if(isTesting==nil) then isTesting = false end

   if sendMessageOnChatWhenControlled and (GetTime() > (sentChatMessageTime + 5)) and (not wrDebug or not isTesting) then -- GetTime comparison here is preventing sending same message two times in a row, a "just in case" check
      say(messageToBeSentWhenControlled)
      sentChatMessageTime = GetTime()
   end
end

-- Logic functions are under here
local function removeWeapons(bossName, isTesting)
   if bossName==nil then bossName = AWR_LADY_NAME end
   if isTesting==nil then isTesting = false end
   updatePlayerClassAndSpecIfNeeded()

   local bagSpace, bagSpaceNeeded = 0, 0
   local removedWeapons = false

   if removeFor[playerClassAndSpec] then
      for i=0,(NUM_BAG_SLOTS-1) do bagSpace = bagSpace + GetContainerNumFreeSlots(i) end

      if (playerClass~="HUNTER" or not classOptions["removeOnlyBowIfHunter"]) then
         -- Player have something equipped in his Main Hand (slot 16)
         if GetInventoryItemLink("player", 16) then bagSpaceNeeded = bagSpaceNeeded + 1 end
         -- Player have something equipped in his Off Hand (slot 17)
         if GetInventoryItemLink("player", 17) then bagSpaceNeeded = bagSpaceNeeded + 1 end
      end
      -- Player is Hunter and have something equipped in his Ranged (slot 18)
      if playerClass=="HUNTER" and GetInventoryItemLink("player", 18) then bagSpaceNeeded = bagSpaceNeeded + 1 end
      if wrDebug then send("bagSpace is " .. bagSpace .. " and bagSpaceNeeded is " .. tostring(bagSpaceNeeded)) end

      removedWeapons = true
      if playerClass~="HUNTER" or not classOptions["removeOnlyBowIfHunter"] then
         PickupInventoryItem(16)
         PutItemInBackpack()
         PickupInventoryItem(17)
         PutItemInBackpack()
      end
      if playerClass=="HUNTER" then
         PickupInventoryItem(18)
         PutItemInBackpack()
      end
      if not isTesting and (GetTime() > (addedWeaponsCountTime + 5)) then
         weaponsRemovedCount = weaponsRemovedCount + 1
         AWR.dbc.weaponsRemovedCount = weaponsRemovedCount
         addedWeaponsCountTime = GetTime()
      end
   elseif wrDebug then send("class is not selected for weapon removal.") end

   local message = AWR_ADDON_MESSAGE_FOR_CONTROL
   if removedWeapons then
      if bagSpace == 0 then
         message = AWR_ADDON_MESSAGE_FOR_CONTROL_AND_WEAPON_REMOVAL_BUT_BAG_IS_FULL
      elseif bagSpaceNeeded > bagSpace then
         message = AWR_ADDON_MESSAGE_FOR_CONTROL_AND_WEAPON_REMOVAL_BUT_BAG_WAS_PARTIALLY_FULL
      else
         message = AWR_ADDON_MESSAGE_FOR_CONTROL_AND_WEAPON_REMOVAL
      end
   end
   sendAddonMessageForControlled(message, removedWeapons, bossName, isTesting)
end

local function onDominateMindCast(bossName, spellID, isTesting)
   if bossName==nil then bossName = AWR_LADY_NAME end
   if spellID==nil or type(spellID)~="number" then spellID = 0 end
   if isTesting==nil then isTesting = false end
   updatePlayerClassAndSpecIfNeeded()

   removeWeapons(bossName, isTesting)
   sayMessageOnChatForControlled(isTesting)
   if not isTesting and (GetTime() > (addedPlayerCountTime + 5)) then
      playerControlledCount = playerControlledCount + 1
      AWR.dbc.playerControlledCount = playerControlledCount
      addedPlayerCountTime = GetTime()
   end

   if not isTesting or wrDebug then
      -- Canceling player buffs
      -- Generic buffs
      if isPlayerHealer() then
         if(getBuffExpirationTime("player", HEROISM) < (getDebuffDurationTime(spellID) + 1)) then CancelUnitBuff("player", HEROISM) end
      elseif isPlayerDPSSpell() then
         CancelUnitBuff("player", HEROISM)
         CancelUnitBuff("player", DEMONIC_PACT)
      end
      -- Trinket buffs
      if not isPlayerHealer() then
         cancelAllBuffsFromPlayerInTable(trinket_before)
      end
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
         if getPlayerSpec()~="Holy" or (getBuffExpirationTime("player", paladin_special["AVENGING_WRATH"]) < (getDebuffDurationTime(spellID) + 1)) then
            CancelUnitBuff("player", paladin_special["AVENGING_WRATH"])
         end
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
      if getPlayerSpec()~="Protection" and classOptions["removePaladinRFAfterControlsEnd"] then CancelUnitBuff("player", paladin_special["RIGHTEOUS_FURY"]) end
      if getPlayerSpec()=="Holy" and classOptions["removeDivinePleaAfterControlsEndIfHoly"] then CancelUnitBuff("player", paladin_special["DIVINE_PLEA"]) end
      CancelUnitBuff("player", paladin_special["DIVINE_SACRIFICE"])
   end
end

function AWR:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, srcGUID, srcName, srcFlags, destGUID, destName, destFlags, spellID, spellName, ...)
   if spellID==nil then return end  -- If spell doesn't have an ID, it's not relevant since all mind control spells have one
   if srcName ~= UnitName("player") and destName ~= UnitName("player") then return end -- The event if NOT from the player, so that is not relevant

   -- If spell from this table gets cast on player
   if (tableHasThisEntry(mind_control_spells_cast, spellID) or spellName == "Dominate Mind") and (event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED") and destName == UnitName("player") then
      if wrDebug then send(srcName .. " just casted " .. (GetSpellLink(spellID) and GetSpellLink(spellID) or "") .. " on the player.") end
      onDominateMindCast(srcName, spellID)

   -- Else if spell from this table fades from player
   elseif (tableHasThisEntry(mind_control_spells_fade, spellID) or spellName == "Dominate Mind") and event == "SPELL_AURA_REMOVED" and destName == UnitName("player") then
      if wrDebug then send((GetSpellLink(spellID) and GetSpellLink(spellID) or "") .. " just faded from the player.") end
      onDominateMindFade()

   -- A test case with a Paladin casting 10 minute Kings on player to simulate a Mind Control
   --elseif wrDebug and spellID == 20217 and (event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED") and destName == UnitName("player") then
   --   send(srcName .. " just casted " .. (GetSpellLink(spellID) and GetSpellLink(spellID) or "") .. " on the player.")
   --   onDominateMindCast(srcName, spellID)
   end
end

local function splitVersion(version, delimiter)
   if delimiter == nil then
      delimiter = "%s"
   end
   local t={}
   for str in string.gmatch(version, "([^"..delimiter.."]+)") do
      table.insert(t, tonumber(str or 0))
   end
   return t
end

-----------------------------
--  Handle Incoming Syncs  --
-----------------------------
do
   local syncHandlers = {}

   syncHandlers["AWR-RW"] = function(msg, channel, sender)
      if msg == "Hi!" then
         if playerClassAndSpec then
            local state
            if not AWR.dbc.enabled then
               state = 0
            elseif not removeFor[playerClassAndSpec] then
               state = 1
            else
               state = 2
            end

            local spec_state = format("%s\t%s",getPlayerSpec(),tostring(state))
            sendSync("AWR-RW", spec_state)
         else
            AWR:QueueGetPlayerClassSpec()
         end
      else
         local spec, state = string.split("\t", msg)
         state = tonumber(state or 0)
         if sender and sender~="" then
            if wrDebug then send(format("%s sent you his spec (%s) and state (%s)",sender,(spec~=nil and spec or "Unknown"),tostring(state))) end
            raid[sender] = raid[sender] or {}
            raid[sender].spec = spec~=nil and spec or "Unknown"
            raid[sender].state = state
         end
      end
   end

   syncHandlers["AWR-Ver"] = function(msg, channel, sender)
      if msg == "Hi!" then
         sendSync("AWR-Ver", AWR.Version)
      else
         local version = msg
         if version and version~="" and sender and sender~="" and raid and raid[sender] then
            raid[sender].version = version
         end
      end
   end

   function AWR:CHAT_MSG_ADDON(prefix, msg, channel, sender)
      if msg and channel ~= "WHISPER" and channel ~= "GUILD" then
         local handler = syncHandlers[prefix]
         if handler then handler(msg, channel, sender) end
         --elseif msg and channel == "WHISPER" and self:GetRaidUnitId(sender) ~= "none" then
         --   local handler = whisperSyncHandlers[prefix]
         --   if handler then handler(msg, channel, sender) end
      end
   end
end

---------------------------
--  Raid/Party Handling  --
---------------------------
do
   local inRaid = false

   function AWR:RAID_ROSTER_UPDATE()
      if GetNumRaidMembers() >= 1 then
         if not inRaid then
            inRaid = true
            sendSync("AWR-Ver", "Hi!")
            sendSync("AWR-RW", "Hi!")
         end
         for i = 1, GetNumRaidMembers() do
            local name, rank, subgroup, _, _, fileName,_,online = GetRaidRosterInfo(i)
            if name and inRaid then
               raid[name] = raid[name] or {}
               raid[name].name = name
               raid[name].rank = rank
               raid[name].subgroup = subgroup
               raid[name].class = fileName
               raid[name].id = "raid"..i
               if raid[name].priority~=nil and not online then raid[name].priority=nil end
               raid[name].updated = true
            end
         end
         -- removing players that left pt
         for i, v in pairs(raid) do
            if not v.updated then
               raid[i] = nil
            else
               v.updated = nil
            end
         end
      else
         AWR:ResetRaid()
      end
   end

   function AWR:PARTY_MEMBERS_CHANGED()
      if GetNumRaidMembers() > 0 then return end
      if GetNumPartyMembers() >= 1 then
         if not inRaid then
            inRaid = true
            sendSync("AWR-Ver", "Hi!")
            sendSync("AWR-RW", "Hi!")
         end
         for i = 0, GetNumPartyMembers() do
            local id
            if (i == 0) then
               id = "player"
            else
               id = "party"..i
            end
            local name, server = UnitName(id)
            local rank, _, fileName = UnitIsPartyLeader(id), UnitClass(id)
            if server and server ~= ""  then
               name = name.."-"..server
            end
            local online = UnitIsConnected(name) and true or false
            raid[name] = raid[name] or {}
            raid[name].name = name
            if rank then
               raid[name].rank = 2
            else
               raid[name].rank = 0
            end
            raid[name].class = fileName
            raid[name].id = id
            if raid[name].priority~=nil and not online then raid[name].priority=nil end
            raid[name].updated = true
         end
         -- removing players that left pt
         for i, v in pairs(raid) do
            if not v.updated then
               raid[i] = nil
            else
               v.updated = nil
            end
         end
      else
         AWR:ResetRaid()
      end
   end

   function AWR:IsInRaid(name)
      return name==UnitName("player") and inRaid or (raid[name] and raid[name].id~=nil)
   end

   function AWR:GetRaidRank(name)
      name = name or UnitName("player")
      return (raid[name] and raid[name].rank) or 0
   end

   function AWR:GetRaidSubgroup(name)
      name = name or UnitName("player")
      return (raid[name] and raid[name].subgroup) or 0
   end

   function AWR:GetRaidClass(name)
      name = name or UnitName("player")
      return (raid[name] and raid[name].class) or "UNKNOWN"
   end

   function AWR:GetRaidUnitId(name)
      name = name or UnitName("player")
      return (raid[name] and raid[name].id) or "none"
   end

   function AWR:ResetRaid()
      for i, v in pairs(raid) do
         raid[i] = nil
      end
      raid = {}
      inRaid = false
   end
end

local function regForAllEvents()
   if(AWR==nil) then send("frame is nil inside function that register for all events function, report this"); return; end
   if wrDebug then send("addon is now listening to all combatlog events.") end

   AWR:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   AWR:RegisterEvent("PLAYER_REGEN_ENABLED")
   AWR:RegisterEvent("PLAYER_REGEN_DISABLED")
   AWR:RegisterEvent("PLAYER_TALENT_UPDATE")
   updatePlayerClassAndSpecIfNeeded()
end

local function unregFromAllEvents()
   if(AWR==nil) then send("frame is nil inside function that unregister all events function, report this"); return; end
   if wrDebug then send("addon is no longer listening to combatlog events.") end

   AWR:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   AWR:UnregisterEvent("PLAYER_REGEN_ENABLED")
   AWR:UnregisterEvent("PLAYER_REGEN_DISABLED")
   AWR:UnregisterEvent("PLAYER_TALENT_UPDATE")
end

-- Checks if addon should be enabled, and enable it if isn't enabled, and disable if it should not be enabled
local function checkIfAddonShouldBeEnabled()
   if(AWR==nil) then send("frame came nil inside function that check if this addon should be enabled, report this"); return; end
   updatePlayerLocalIfNeeded()

   local shouldIt = false
   local reason = AWR_REASON_ADDON_IS_OFF
   if AWR.dbc.enabled then
      if wrDebug then
         shouldIt = true
         reason = AWR_REASON_DEBUG_MODE_IS_ON
      elseif tableHasThisEntry(validInstances, instanceName) then
         shouldIt = true
         reason = format(AWR_REASON_INSIDE_VALID_INSTANCE,instanceName)
      else
         reason = AWR_REASON_NOT_INSIDE_VALID_INSTANCE
      end
   end

   if shouldIt then regForAllEvents()
   else unregFromAllEvents() end
   return shouldIt, reason
end

-- Called when player leaves combat
-- Used to zero all variables so the addon logic knows that, when player enters combat again, it's a new fight against a new enemy
function AWR:PLAYER_REGEN_ENABLED()
   if self.dbc.enabled then
      if wrDebug then send("Addon variables got zeroed because player leave combat.") end
      sentChatMessageTime  = 0
      sentAddonMessageTime = 0
   end
end

-- Called when player enters combat
-- Used here to double check if we have what spec player is, and if not then we call getPlayerSpec to get what spec player is beforehand, yet another "just in case" code that if lady casts dominate mind addon maybe won't have time to query what class player is before the control affects the player
function AWR:PLAYER_REGEN_DISABLED()
   updatePlayerClassAndSpecIfNeeded()
end

function AWR:PLAYER_TALENT_UPDATE()
   updatePlayerClassAndSpec()
   sendSync("AWR-RW", "Hi!")
   if wrDebug then send("updated talents, now you are using " .. (playerSpec or "Unknown")) end
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

do
   local function sort(v1, v2)
      if not v1 then return false end
      if not v2 then return true end
      if not v1.version then return false end
      if not v2.version then return true end
      if not UnitIsConnected(v1.name) then return false end
      if not UnitIsConnected(v2.name) then return true end
      if not v1.state then return false end
      if not v2.state then return true end

      local a = splitVersion(v1.version,".")
      local b = splitVersion(v2.version,".")

      local max = math.max(getTableLength(a), getTableLength(b), 1)
      for i=1, max do
         if not a[i] or not b[i] then return a[i]~=nil end
         if a[i]~=b[i] then return a[i] > b[i] end
      end
      return true
   end

   function AWR:ShowVersions()
      local sortedTable = {}
      for i, v in pairs(raid) do
         if v~=nil then table.insert(sortedTable, v) end
      end
      print("|cff2d61e3<|r|cff2f6af5AWR|r|cff2d61e3>|r |cff879ff5AWR - Versions|r")
      if getTableLength(sortedTable) > 1 then table.sort(sortedTable, sort) end
      if getTableLength(sortedTable) == 0 then
         if AWR.Version and AWR.dbc.enabled then
            print(format("|cff2d61e3<|r|cff2f6af5AWR|r|cff2d61e3>|r |cff879ff5%s|r: %s", UnitName("player"), AWR.Version))
         else
            print(format("|cff2d61e3<|r|cff2f6af5AWR|r|cff2d61e3>|r |cff879ff5%s|r: %s (addon is turned |cffff0000off|r)", UnitName("player"), AWR.Version))
         end
      else
         for i, v in ipairs(sortedTable) do
            local msg
            if v.version then
               msg = format("|cff2d61e3<|r|cff2f6af5AWR|r|cff2d61e3>|r |cff879ff5%s|r: %s", v.name, v.version)
               if not UnitIsConnected(v.name) then
                  msg = msg .. " (offline)"
               elseif v.state == 1 then
                  msg = msg .. " (weapon removal for spec turned |cffff0000off|r)"
               elseif v.state == 0 then
                  msg = msg .. " (addon is turned |cffff0000off|r)"
               end
            else
               msg = format("|cff2d61e3<|r|cff2f6af5AWR|r|cff2d61e3>|r |cff879ff5%s|r: AWR not installed", v.name)
            end
            print(msg)
         end
         for i = #sortedTable, 1, -1 do
            if not sortedTable[i].version then
               table.remove(sortedTable, i)
            end
         end
      end
      print(format("|cff2d61e3<|r|cff2f6af5AWR|r|cff2d61e3>|r |cff879ff5Found|r |cfff0a71f%s|r |cff879ff5player%s with AWR|r",(#sortedTable > 1 and #sortedTable or 1),(#sortedTable > 1 and "s" or "")))
      for i = #sortedTable, 1, -1 do
         sortedTable[i] = nil
      end
   end
end

-- Slash commands functions
-- toggle, on, off
local function slashToggleAddon(state)
   if state or (not AWR.dbc.enabled and state==nil)  then
      AWR.dbc.enabled = true
      AWR:ResetRaid()
      AWR:RAID_ROSTER_UPDATE()
      AWR:PARTY_MEMBERS_CHANGED()
   elseif not state or (AWR.dbc.enabled and state==nil) then
      AWR.dbc.enabled = false
      sendSync("AWR-RW", "Hi!")
   end
   checkIfAddonShouldBeEnabled()
   send(AWR.dbc.enabled and "|cff00ff00on|r" or "|cffff0000off|r")
end

-- status, state
local function slashStatus()
   if not AWR.dbc.enabled then
      send(AWR_REASON_ADDON_IS_OFF)
   else
      send(select(2,checkIfAddonShouldBeEnabled()))
   end
end

-- version, ver
local function slashVersion()
   if(AWR.Version==nil) then send(AWR_ADDON_STILL_LOADING); return; end
   send("version " .. AWR.Version)
end

-- spec
local function slashSpec()
   if(playerClass==nil) then send(AWR_ADDON_STILL_LOADING); return; end

   send(format(AWR_SPEC_MESSAGE,AWR:GetFormattedClassSpec()))
end

-- debug
local function slashDebug()
   if not wrDebug then
      wrDebug = true
      AWR.db.debug = true
      mind_control_spells_cast["DEBUG"] = 20217
   else
      wrDebug = false
      AWR.db.debug = false
      mind_control_spells_cast["DEBUG"] = 0
   end
   send("debug mode turned " .. (wrDebug and "|cff00ff00on|r" or "|cffff0000off|r"))
   checkIfAddonShouldBeEnabled()
end

local function slashReset()
   if not AWR.db.debug then return end

   playerControlledCount         = 0
   AWR.dbc.playerControlledCount = 0
   weaponsRemovedCount           = 0
   AWR.dbc.weaponsRemovedCount   = 0
   send("Count variables got zeroed.")
end

-- count, report
local function slashCount()
   send(format(AWR_REPORT_COUNT,playerControlledCount,weaponsRemovedCount))
end

-- message
local function slashMessage(message)
   if message==nil or message=="" then
      send(format(AWR_CURRENT_MESSAGE,messageToBeSentWhenControlled))
      return
   end
   assert(type(message) == "string", "bad argument #1: 'message' needs to be a string; instead what came was " .. tostring(type(message)))

   if message:lower()=="toggle" then
      if not sendMessageOnChatWhenControlled then message="on"
      else message="off" end
   end
   if message:lower()=="on" then
      send(AWR_MESSAGE_ON)
      sendMessageOnChatWhenControlled = true
      AWR.db.sendMessageOnChatWhenControlled = sendMessageOnChatWhenControlled
   elseif message:lower()=="off" then
      send(AWR_MESSAGE_OFF)
      sendMessageOnChatWhenControlled = false
      AWR.db.sendMessageOnChatWhenControlled = sendMessageOnChatWhenControlled
   else
      AWR:SetMessage(nil,message)
   end
end

-- channel
local function slashChannel(channel)
   if channel==nil or channel=="" then
      send(format(AWR_SELECTED_CHANNEL,channelToSendMessage))
      return
   end
   assert(type(channel) == "string", "bad argument #1: 'channel' needs to be a string; instead what came was " .. tostring(type(channel)))

   channel = channel:upper()
   -- Aliases
   if channel == "S" then channel = "SAY"
   elseif channel == "Y" then channel = "YELL"
   elseif channel == "R" then channel = "RAID"
   elseif channel == "P" then channel = "PARTY" end
   if tableHasThisEntry(validChannels, channel) then
      send(format(AWR_CHANGED_CURRENTLY_CHANNEL,channel))
      channelToSendMessage = channel
      AWR.db.channelToSendMessage = channelToSendMessage
   else
      local str = ""
      local validChannelsLength = getTableLength(validChannels)
      for index, value in ipairs(validChannels) do
         str = str .. "\"" .. value .. "\"" .. (index~=validChannelsLength and ", " or ".")
      end
      send(format(AWR_ERROR_INVALID_CHANNEL,str))
   end
end

-- setlanguage, sl
local function slashSetLanguage(language)
   if language == nil or language == "" then
      send(format(AWR_SELECTED_LANGUAGE,addonLanguage))
      return
   end
   assert(type(language) == "string", "bad argument #1: 'language' needs to be a string; instead what came was " .. tostring(type(language)))

   language = trim(language:lower())
   if tableHasThisEntryOnKeyOrValue(validLanguages, language) then
      for k,v in pairs(validLanguages) do
         if k:lower() == language or v:lower() == language then
            send(format(AWR_CHANGED_CURRENTLY_LANGUAGE,v,(format(" (%s)",k))))
            addonLanguage = k
            AWR.db.addonLanguage = k
            return
         end
      end
   else
      local str = ""
      local validLanguagesLength = getTableLength(validLanguages)
      for key, value in pairs(validLanguages) do
         str = str .. "\"" .. value .. " (" .. key .. ")" .. "\"" .. (index~= validLanguagesLength and ", " or ".")
      end
      send(format(AWR_ERROR_INVALID_LANGUAGE,str))
   end
end

local function slashCommand(typed)
   local cmd = string.match(typed,"^(%w+)") -- Gets the first word the user has typed
   if cmd~=nil then cmd = cmd:lower() end           -- And makes it lower case
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
   elseif(cmd=="toggle") then slashToggleAddon()
   elseif(cmd=="on" or cmd=="enable") then slashToggleAddon(true)
   elseif(cmd=="off" or cmd=="disable") then slashToggleAddon(false)
   elseif(cmd=="status" or cmd=="state" or cmd=="reason") then slashStatus()
   elseif(cmd=="version" or cmd=="ver") then AWR:ShowVersions()
   elseif(cmd=="spec") then slashSpec()
   elseif(cmd=="removeweapon" or cmd=="removeweapons" or cmd=="rw") then onDominateMindCast(AWR_TEST_BOSS,0,true)
   elseif(cmd=="debug") then slashDebug()
   elseif(cmd=="reset") then slashReset()
   elseif(cmd=="count" or cmd=="report") then slashCount()
   elseif(cmd=="message" or cmd=="m") then slashMessage(extra)
   elseif(cmd=="channel" or cmd=="c") then slashChannel(extra)
   elseif(cmd=="setlanguage" or cmd=="sl" or cmd=="languageset" or cmd=="ls") then slashSetLanguage(extra)
   end
end
-- End of slash commands function

-- Interface functions
function AWR:IsAWREnabled(info)
   return self.dbc.enabled
end

function AWR:ToggleEnable(info, newValue)
   assert(newValue~=nil, "bad argument #2: 'newValue' cannot be nil")
   assert(type(newValue) == "boolean", "bad argument #2: 'newValue' needs to be a string; instead what came was " .. tostring(type(newValue)))
   slashToggleAddon(newValue)
end

function AWR:IsMessageEnabled(info)
   return sendMessageOnChatWhenControlled
end

function AWR:ToggleEnableMessage(info, newValue)
   assert(newValue~=nil, "bad argument #2: 'newValue' cannot be nil")
   assert(type(newValue) == "boolean", "bad argument #2: 'newValue' needs to be a string; instead what came was " .. tostring(type(newValue)))
   send(newValue and AWR_MESSAGE_ON or AWR_MESSAGE_OFF)
   sendMessageOnChatWhenControlled = newValue
   self.db.sendMessageOnChatWhenControlled = newValue
end

function AWR:GetMessage(info)
   return messageToBeSentWhenControlled
end

function AWR:SetMessage(info, newMessage)
   if(newMessage==nil or newMessage == "") then
      send(AWR_ERROR_MESSAGE_CANNOT_BE_EMPTY)
      return
   end
   assert(type(newMessage) == "string", "bad argument #2: 'newMessage' needs to be a string; instead what came was " .. tostring(type(newMessage)))

   messageToBeSentWhenControlled = newMessage
   self.db.messageToBeSentWhenControlled = newMessage
   send(format(AWR_CHANGED_SAY_MESSAGE, newMessage))
end

function AWR:GetChannel(info)
   for index, channel in ipairs(validChannels) do
      if channel == channelToSendMessage then return index end
   end
end

function AWR:SetChannel(info, newChannel)
   assert(newChannel~=nil, "bad argument #2: 'newChannel' cannot be nil")
   assert(type(newChannel) == "number", "bad argument #2: 'newChannel' needs to be a number; instead what came was " .. tostring(type(newChannel)))

   newChannel = validChannels[newChannel]
   channelToSendMessage = newChannel
   self.db.channelToSendMessage = newChannel
   send(format(AWR_CHANGED_CURRENTLY_CHANNEL,newChannel))
end

function AWR:GetLanguage(info)
   for languageCode,_ in pairs(validLanguages) do
      if languageCode == addonLanguage then return languageCode end
   end
end

function AWR:SetLanguage(info, newLanguage)
   assert(newLanguage~=nil, "bad argument #2: 'newLanguage' cannot be nil")
   assert(type(newLanguage) == "string", "bad argument #2: 'newLanguage' needs to be a string; instead what came was " .. tostring(type(newLanguage)))

   addonLanguage = newLanguage
   self.db.addonLanguage = newLanguage
   send(format(AWR_CHANGED_CURRENTLY_LANGUAGE, validLanguages[newLanguage],""))

   StaticPopupDialogs["AWR_LANGUAGE_NEEDRELOAD"] = {
      text = AWR_RELOAD_UI_POPUP_TITLE,
      button1 = AWR_YES,
      button2 = AWR_NO,
      OnAccept = function (self) ReloadUI() end,
      OnHide = function (self) end,
      timeout = 0,
      whileDead = 1,
      exclusive = 1,
      showAlert = 1,
      hideOnEscape = 1
   };
   StaticPopup_Show("AWR_LANGUAGE_NEEDRELOAD")
end

function AWR:GetClassOption(info, option)
   assert(option~=nil, "bad argument #2: 'option' cannot be nil")
   assert(type(option) == "string", "bad argument #2: 'option' needs to be a string; instead what came was " .. tostring(type(option)))
   return classOptions[option]
end

function AWR:SetClassOption(info, option, newValue)
   assert(option~=nil, "bad argument #2: 'option' cannot be nil")
   assert(type(option) == "string", "bad argument #2: 'option' needs to be a string; instead what came was " .. tostring(type(option)))
   assert(newValue~=nil, "bad argument #3: 'newValue' cannot be nil")
   assert(type(newValue) == "boolean", "bad argument #3: 'newValue' needs to be a string; instead what came was " .. tostring(type(newValue)))

   if wrDebug then send("option is " .. option .. " and newvalue is " .. tostring(newValue)) end
   classOptions[option] = newValue
   self.db.classOptions = classOptions
end

function AWR:GetSpecState(info, spec)
   assert(spec~=nil, "bad argument #2: 'spec' cannot be nil")
   assert(type(spec) == "string", "bad argument #2: 'spec' needs to be a string; instead what came was " .. tostring(type(spec)))

   local class = info[#info]:upper()
   return removeFor[format("%s_%s",class,spec)]
end

function AWR:SetSpecState(info, spec, newValue)
   assert(spec~=nil, "bad argument #2: 'spec' cannot be nil")
   assert(type(spec) == "string", "bad argument #2: 'spec' needs to be a string; instead what came was " .. tostring(type(spec)))
   assert(newValue~=nil, "bad argument #3: 'newValue' cannot be nil")
   assert(type(newValue) == "boolean", "bad argument #3: 'newValue' needs to be a boolean; instead what came was " .. tostring(type(newValue)))

   local class = info[#info]:upper()
   removeFor[format("%s_%s",class,spec)] = newValue
   self.db.removeFor = removeFor
   if(class == playerClass and spec == getPlayerSpec() and playerClassAndSpec) then
      local spec_state = format("%s\t%s",getPlayerSpec(),tostring(removeFor[playerClassAndSpec]))
      sendSync("AWR-RW", spec_state)
   end

   for k,v in pairs(specs[class:lower()]) do
      if k == spec then
         spec = v
         break
      end
   end
   class = (class=="DEATHKNIGHT") and "Death Knight" or upperFirstOnly(class)
   local msg = newValue and AWR_SPEC_TOGGLED_ON_MESSAGE or AWR_SPEC_TOGGLED_OFF_MESSAGE
   send(format(msg,spec,class))
end
-- End of Interface functions

function AWR:LoadDefaultDBValues()
   -- Global Saved Vars
   if self.db.removeFor                       == nil then self.db.removeFor                       = removeFor end
   if self.db.sendMessageOnChatWhenControlled == nil then self.db.sendMessageOnChatWhenControlled = sendMessageOnChatWhenControlled end
   if self.db.messageToBeSentWhenControlled   == nil then self.db.messageToBeSentWhenControlled   = messageToBeSentWhenControlled end
   if self.db.channelToSendMessage            == nil then self.db.channelToSendMessage            = channelToSendMessage end
   if self.db.classOptions                    == nil then self.db.classOptions                    = classOptions
   else
      for k,v in pairs(classOptions) do
         if self.db.classOptions[k]==nil then self.db.classOptions[k] = v end
      end
   end
   -- Per Char Saved Vars
   if self.dbc.playerControlledCount          == nil then self.dbc.playerControlledCount          = playerControlledCount end
   if self.dbc.weaponsRemovedCount            == nil then self.dbc.weaponsRemovedCount            = weaponsRemovedCount end
end

--------------
--  OnLoad  --
--------------

function AWR:ADDON_LOADED(addon)
   if addon ~= "AutomaticWeaponRemoval" then return end

   AWRDB = AWRDB or { }
   AWRDBC = AWRDBC or { enabled = true }
   self.db = AWRDB
   self.dbc = AWRDBC

   playerClass = select(2,UnitClass("player"))  -- Get player class

   -- Loading variables
   self:LoadDefaultDBValues()
   wrDebug = self.db.debug or wrDebug
   removeFor = self.db.removeFor
   sendMessageOnChatWhenControlled = self.db.sendMessageOnChatWhenControlled
   messageToBeSentWhenControlled = self.db.messageToBeSentWhenControlled
   channelToSendMessage = self.db.channelToSendMessage
   classOptions = self.db.classOptions
   playerControlledCount = self.dbc.playerControlledCount
   weaponsRemovedCount = self.dbc.weaponsRemovedCount

   addonLanguage = self.db.addonLanguage or addonLanguage
   if self.db.addonLanguage==nil and GetRealmName():lower():find("brasil") then
      addonLanguage = "ptBR"
   end
   AWR.Version = GetAddOnMetadata("AutomaticWeaponRemoval", "Version")
   libGroupTalents = LibStub("LibGroupTalents-1.0")

   SLASH_AUTOMATICWEAPONREMOVAL1 = "/awr"
   SLASH_AUTOMATICWEAPONREMOVAL2 = "/automaticweaponremoval"
   SlashCmdList.AUTOMATICWEAPONREMOVAL = function(cmd) slashCommand(cmd) end
   if wrDebug then
      mind_control_spells_cast["DEBUG"] = 20217
      send("remember that debug mode is |cff00ff00ON|r.")
   end

   self:RegisterEvent("PLAYER_ENTERING_WORLD")
   self:RegisterEvent("RAID_ROSTER_UPDATE")
   self:RegisterEvent("PARTY_MEMBERS_CHANGED")
   self:RegisterEvent("CHAT_MSG_ADDON")
   self:QueueGetPlayerClassSpec()
   CH.callbacks:Fire("LOAD_LANGUAGE", addonLanguage)
   self:UnregisterEvent("ADDON_LOADED")
   send(format(AWR_ADDON_LOADED,AWR.Version))
end

AWR:RegisterEvent("ADDON_LOADED")