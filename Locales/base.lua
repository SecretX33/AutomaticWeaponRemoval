-- AutomaticWeaponRemoval Localization File
-- No translation needed

AWR = CreateFrame("frame")

-- Necessary code to handle language change
CH = LibStub("AceAddon-3.0"):NewAddon("CH", "AceEvent-3.0")
CH.callbacks = LibStub("CallbackHandler-1.0"):New(CH)
AWR_LANGUAGE_SET = false
AWR_LANGUAGE_LOADED = false

AWR_SUPPORTED_LANGUAGES = {
   ["enUS"] = "English",
   ["ptBR"] = "Português",
}

AWR_ADDON_PREFIX = "|cff2f6af5AWR:|r "

AWR_VALID_CHANNELS       = {"SAY", "YELL", "RAID", "PARTY"}
AWR_VALID_INSTANCES      = {"Icecrown Citadel", "Ulduar", "Naxxramas"}
AWR_DPS_PHYSICAL_CLASSES = {"HUNTER", "DEATHKNIGHT", "PALADIN_Protection", "PALADIN_Retribution", "WARRIOR", "DRUID_Feral", "ROGUE", "SHAMAN_Enhancement"}
AWR_DPS_SPELL_CLASSES    = {"DRUID_Balance","SHAMAN_Elemental","PRIEST_Shadow","MAGE","WARLOCK"}
AWR_HEALER_CLASSES       = {"PALADIN_Holy","DRUID_Restoration","SHAMAN_Restoration","PRIEST_Discipline","PRIEST_Holy"}

AWR_SPECS = {
   hunter = {
      ["BeastMastery"] = "Beast Mastery",
      ["Marksmanship"] = "Marksmanship",
      ["Survival"] = "Survival",
   },
   deathknight = {
      ["Blood"] = "Blood",
      ["Frost"] = "Frost",
      ["Unholy"] = "Unholy",
   },
   paladin = {
      ["Holy"] = "Holy",
      ["Protection"] = "Protection",
      ["Retribution"] = "Retribution",
   },
   warrior = {
      ["Arms"] = "Arms",
      ["Fury"] = "Fury",
      ["Protection"] = "Protection",
   },
   druid = {
      ["Balance"] = "Balance",
      ["Feral"] = "Feral Combat",
      ["Restoration"] = "Restoration",
   },
   rogue = {
      ["Assassination"] = "Assassination",
      ["Combat"] = "Combat",
      ["Subtlety"] = "Subtlety",
   },
   shaman = {
      ["Elemental"] = "Elemental",
      ["Enhancement"] = "Enhancement",
      ["Restoration"] = "Restoration",
   },
   priest = {
      ["Discipline"] = "Discipline",
      ["Holy"] = "Holy",
      ["Shadow"] = "Shadow",
   },
   mage = {
      ["Arcane"] = "Arcane",
      ["Fire"] = "Fire",
      ["Frost"] = "Frost",
   },
   warlock = {
      ["Affliction"] = "Affliction",
      ["Demonology"] = "Demonology",
      ["Destruction"] = "Destruction",
   },
}

function AWR:LOAD_LANGUAGE(_,language)
   if language == "ptBR" then
      CH.callbacks:Fire("LOAD_LANGUAGE_PTBR")
   else
      CH.callbacks:Fire("LOAD_LANGUAGE_ENUS")
   end
   CH.UnregisterCallback(self, "LOAD_LANGUAGE")
end

CH.RegisterCallback(AWR,"LOAD_LANGUAGE")