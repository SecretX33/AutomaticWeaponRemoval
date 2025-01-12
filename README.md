# AutomaticWeaponRemoval

A World of Warcraft addon that automatically removes weapons when mind controlled by bosses (like Lady Deathwhisper in ICC).

* [Features](#features)
* [Download](#download)
* [How to Use](#how-to-use)
* [Commands](#commands)
* [FAQ](#faq)
* [Need Help?](#need-help)
* [Copyright](#copyright)

## Features

This addon is designed for World of Warcraft 3.3.5a (Wrath of the Lich King) and helps you in several ways:

1. **Automatic Weapon Removal**: When you get mind controlled by bosses (like Lady Deathwhisper), the addon automatically removes your weapons. This prevents you from hurting your friends while mind controlled!

2. **Smart Class Features**:
   - For Paladins: Automatically removes Righteous Fury if you're not a tank
   - For Holy Paladins: Can remove Divine Plea after mind control ends for better healing
   - For Hunters: Option to only remove bow/gun during mind control

3. **Raid Communication**: 
   - Automatically announces when you're mind controlled
   - Customizable messages and chat channels
   - Helps your raid react quickly to save you!

4. **User-Friendly Interface**:
   - Easy-to-use settings menu
   - Simple commands for quick adjustments
   - Status tracking to see how often you've been controlled

## Download

Get the latest version [here](https://github.com/SecretX33/AutomaticWeaponRemoval/releases/latest/download/AutomaticWeaponRemoval.zip).

Want an older version? Check all releases [here](https://github.com/SecretX33/AutomaticWeaponRemoval/releases).

## How to Use

1. Download and install the addon
2. The addon works automatically in relevant dungeons and raids
3. Open the settings menu through the game interface's Add-on menu (or type `/awr` if you prefer commands)
4. In the settings UI menu you can:
   - Turn the addon on/off
   - Customize your mind control warning message
   - Choose which chat channel to use for warnings
   - Configure class-specific settings

## Commands

All commands start with `/awr` or `/automaticweaponremoval`:

- `/awr` - Shows all available commands
- `/awr toggle` - Turns the addon on/off
- `/awr message "your message"` - Sets what you'll say when mind controlled
- `/awr channel "your channel"` - Changes which chat channel your message appears in (SAY, YELL, RAID, or PARTY)
- `/awr removeweapon` - Tests what happens when you get controlled
- `/awr count` - Shows how many times you've been controlled
- `/awr spec` - Shows your class and specialization
- `/awr status` - Shows if the addon is working and why
- `/awr version` - Shows which version you're running

## FAQ

**Q:** Will this really unequip my weapons when Lady Deathwhisper mind controls me?

**A:** Yes! The addon automatically detects mind control effects and removes your weapons to keep your friends safe.

**Q:** Is this allowed by the game?

**A:** Yes! The addon only uses features that Blizzard allows. You can read more about addon safety [here](https://eu.forums.blizzard.com/en/wow/t/can-i-get-banned-for-this/78719/8).

**Q:** Does the addon have a settings menu?

**A:** Yes! As of version 1.1, there's a full user interface to customize all settings.

## Need Help?

Have ideas or found a problem? We're here to help!

- For suggestions: Create a new issue with the tag "suggestion" or "idea"
- For problems: Report them through our [issue tracker](https://github.com/SecretX33/AutomaticWeaponRemoval/issues)

When reporting issues, please check if someone else has already reported the same problem to avoid duplicates.

## Copyright

License: AGPL 3.0

Read file [LICENSE](LICENSE).
