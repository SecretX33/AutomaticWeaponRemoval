local validChannels  = AWR_VALID_CHANNELS
local validLanguages = AWR_SUPPORTED_LANGUAGES

local specs = AWR_SPECS

function AWR:LOAD_INTERFACE()
   -- Before mind control
   local classOptionsListBefore = {
      ["removeOnlyBowIfHunter"] = AWR_REMOVE_ONLY_BOW_DESC,
   }
   -- After mind control
   local classOptionsListAfter = {
      ["removePaladinRFAfterControlsEnd"] = AWR_CANCEL_RF_FROM_PALA_IF_NOT_TANK,
      ["removeDivinePleaAfterControlsEndIfHoly"] = AWR_CANCEL_DIVINE_PLEA_IF_HOLY_PALA,
   }

   --[[ Option table ]]--
   local optionsFrameModel = {
      name = "AutomaticWeaponRemoval",
      handler = AWR,
      type = "group",
      args = {
         enable = {
            type = "toggle",
            name = AWR_ENABLE_ADDON,
            desc = AWR_ENABLE_ADDON_DESC,
            get = "IsAWREnabled",
            set = "ToggleEnable",
            width = "double",
            order = 0,
         },
         language = {
            type = "select",
            name = AWR_LANGUAGE,
            values = validLanguages,
            get = "GetLanguage",
            set = "SetLanguage",
            style = "dropdown",
            order = 1,
         },
         enablemessage = {
            type = "toggle",
            name = AWR_SEND_MESSAGE_WHEN_CONTROLLED,
            desc = AWR_SEND_MESSAGE_WHEN_CONTROLLED_DESC,
            get = "IsMessageEnabled",
            set = "ToggleEnableMessage",
            width = "double",
            order = 2,
         },
         channel = {
            type = "select",
            name = AWR_CHANNEL,
            desc = AWR_CHANNEL_DESC,
            values = validChannels,
            get = "GetChannel",
            set = "SetChannel",
            style = "dropdown",
            order = 3,
         },
         message = {
            type = "input",
            name = AWR_MESSAGE,
            desc = AWR_MESSAGE_DESC,
            set = "SetMessage",
            get = "GetMessage",
            width = "full",
            order = 4,
         },
         desc1 = {
            type = "header",
            name = AWR_CLASS_OPTIONS,
            order = 5,
         },
         classoptionsbefore = {
            type = "multiselect",
            name = AWR_BEFORE_MIND_CONTROL,
            values = classOptionsListBefore,
            tristate = false,
            get = "GetClassOption",
            set = "SetClassOption",
            width = "full",
            order = 6,
         },
         classoptionsafter = {
            type = "multiselect",
            name = AWR_AFTER_MIND_CONTROL,
            values = classOptionsListAfter,
            tristate = false,
            get = "GetClassOption",
            set = "SetClassOption",
            width = "full",
            order = 7,
         },
         desc2 = {
            type = "header",
            name = AWR_REMOVE_WEAPONS_FOR,
            order = 8,
         },
         hunter = {
            type = "multiselect",
            name = "Hunter",
            values = specs.hunter,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 9,
         },
         deathknight = {
            type = "multiselect",
            name = "Death Knight",
            values = specs.deathknight,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 10,
         },
         paladin = {
            type = "multiselect",
            name = "Paladin",
            values = specs.paladin,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 11,
         },
         warrior = {
            type = "multiselect",
            name = "Warrior",
            values = specs.warrior,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 12,
         },
         druid = {
            type = "multiselect",
            name = "Druid",
            values = specs.druid,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 13,
         },
         rogue = {
            type = "multiselect",
            name = "Rogue",
            values = specs.rogue,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 14,
         },
         shaman = {
            type = "multiselect",
            name = "Shaman",
            values = specs.shaman,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 15,
         },
         priest = {
            type = "multiselect",
            name = "Priest",
            values = specs.priest,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 16,
         },
         mage = {
            type = "multiselect",
            name = "Mage",
            values = specs.mage,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 17,
         },
         warlock = {
            type = "multiselect",
            name = "Warlock",
            values = specs.warlock,
            tristate = false,
            set = "SetSpecState",
            get = "GetSpecState",
            order = 18,
         },
      },
   }
   -- Loading Config Frame
   LibStub("AceConfig-3.0"):RegisterOptionsTable("AutomaticWeaponRemoval", optionsFrameModel)
   AWR.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutomaticWeaponRemoval")
   CH.UnregisterCallback(self, "LOAD_INTERFACE")
end

CH.RegisterCallback(AWR,"LOAD_INTERFACE")