-- AutomaticWeaponRemoval Localization File
-- English (enUS)

function AWR:LOAD_LANGUAGE_ENUS()
   AWR_YES = "Yes"
   AWR_NO = "No"

   -- Interface text
   AWR_CREDITS = "Created by Freezingice of SlowFall (WoW-Brasil)"
   AWR_ENABLE_ADDON = "Enable addon"
   AWR_ENABLE_ADDON_DESC = "If unchecked, AWR will disable itself."
   AWR_LANGUAGE = "Language"
   AWR_RELOAD_UI_POPUP_TITLE = "Your interface needs to be reloaded apply the new language. Reload now?"
   AWR_SEND_MESSAGE_WHEN_CONTROLLED = "Send message when controlled"
   AWR_SEND_MESSAGE_WHEN_CONTROLLED_DESC = "If unchecked, you won't say anything when you get mind controlled."
   AWR_CHANNEL = "Channel"
   AWR_CHANNEL_DESC = "Channel where the message will be sent."
   AWR_MESSAGE = "Message"
   AWR_MESSAGE_DESC = "Message that will be send when you get mind controlled."
   AWR_CLASS_OPTIONS = "Class Options"
   AWR_BEFORE_MIND_CONTROL = "Before mind control"
   AWR_AFTER_MIND_CONTROL = "After mind control"
   AWR_REMOVE_ONLY_BOW_DESC = "Unequip ONLY bow from Hunter"
   AWR_CANCEL_RF_FROM_PALA_IF_NOT_TANK = "Cancel Righteous Fury from Paladin if NOT a tank"
   AWR_CANCEL_DIVINE_PLEA_IF_HOLY_PALA = "Cancel Divine Plea from Holy Paladin"
   AWR_REMOVE_WEAPONS_FOR = "Remove weapons for"

   -- Chat messages
   AWR_ADDON_LOADED = "loaded v%s."
   AWR_ADDON_STILL_LOADING = "Try again later, addon still loading..."

   AWR_HELP1 = "|cff2f6af5The options available in the 'AutomaticWeaponRemoval' addon are as follows:|r"
   AWR_HELP2 = "|cff2f6af5/awr toggle:|r Toggle the addon on/off."
   AWR_HELP3 = "|cff2f6af5/awr message \"your_message\":|r Change the message that you will say when you get controlled by any skill."
   AWR_HELP4 = "|cff2f6af5/awr channel \"the_channel\":|r Change the channel where you will send the message."
   AWR_HELP5 = "|cff2f6af5/awr removeweapon:|r Simulate a Dominate Mind cast on you."
   AWR_HELP6 = "|cff2f6af5/awr count:|r Show how many you have been controlled."
   AWR_HELP7 = "|cff2f6af5/awr spec:|r Show what class and spec."
   AWR_HELP8 = "|cff2f6af5/awr status:|r Show if addon is on/off and why, useful to double check current addon state."
   AWR_HELP9 = "|cff2f6af5/awr version:|r Show addon version."

   AWR_TEST_BOSS = "Test Boss"
   AWR_LADY_NAME = "Lady Deathwhisper"
   AWR_ADDON_MESSAGE_FOR_CONTROL = "%s casted control on you."
   AWR_ADDON_MESSAGE_FOR_CONTROL_AND_WEAPON_REMOVAL = "%s casted control on you, removing weapons."
   AWR_ADDON_MESSAGE_FOR_CONTROL_AND_WEAPON_REMOVAL_BUT_BAG_WAS_PARTIALLY_FULL = "%s casted control on you, but AWR could not remove all your weapons because |cfff00a0aYOUR BAG WAS PARTIALLY FULL!!!|r."
   AWR_ADDON_MESSAGE_FOR_CONTROL_AND_WEAPON_REMOVAL_BUT_BAG_IS_FULL = "%s casted control on you, but AWR could not remove your weapons at all because |cfff00a0aYOUR BAG IS FULL!!!|r."

   AWR_SPEC_MESSAGE = "Your class is %s and your build is %s."

   AWR_REASON_ADDON_IS_OFF = "|cffffe83bstatus:|r addon is |cffff0000off|r because it was set as OFF by the command \'/awr toggle\'."
   AWR_REASON_DEBUG_MODE_IS_ON = "|cffffe83bstatus:|r addon is |cff00ff00on|r because debug mode is turned on."
   AWR_REASON_INSIDE_VALID_INSTANCE = "|cffffe83bstatus:|r addon is |cff00ff00on|r because you are inside a valid instance (%s)."
   AWR_REASON_NOT_INSIDE_VALID_INSTANCE = "|cffffe83bstatus:|r addon is |cffff0000off|r because you not inside a valid instance."

   AWR_REPORT_COUNT = "you have been controlled by bosses |cffffaf24%d|r time(s) and your weapons have been removed by this addon |cffffaf24%d|r time(s)."

   AWR_CURRENT_MESSAGE = "current message is: |cffbffd31%s|r"
   AWR_CHANGED_SAY_MESSAGE = "you will now say |cff48df28%s|r when you get controlled."
   AWR_MESSAGE_ON = "turned messages |cff00ff00on|r."
   AWR_MESSAGE_OFF = "turned messages |cffff0000off|r."
   AWR_ERROR_MESSAGE_CANNOT_BE_EMPTY = "the message cannot be empty."

   AWR_SPEC_TOGGLED_ON_MESSAGE = "Turned |cff00ff00on|r Remove Weapons for %s %s."   -- spec, class
   AWR_SPEC_TOGGLED_OFF_MESSAGE = "Turned |cffff0000off|r Remove Weapons for %s %s." -- spec, class

   AWR_SELECTED_CHANNEL = "select channel is: |cfff84d13%s|r"
   AWR_CHANGED_CURRENTLY_CHANNEL = "you will now send messages on |cffff7631%s|r."
   AWR_ERROR_INVALID_CHANNEL = "this channel doesn't exist, please choose one of the following: %s"

   AWR_SELECTED_LANGUAGE = "select language is: |cfff84d13%s|r"
   AWR_CHANGED_CURRENTLY_LANGUAGE = "your language will be set to |cffff7631%s%s|r and loaded after you reload your UI."
   AWR_ERROR_INVALID_LANGUAGE = "this language doesn't exist, please choose one of the following: %s"

   -- Dealing with language load
   CH.callbacks:Fire("LOAD_INTERFACE")
   CH.callbacks:Fire("UNREGISTER_LANGUAGE_CALLBACK")
end

CH.RegisterCallback(AWR,"LOAD_LANGUAGE_ENUS")