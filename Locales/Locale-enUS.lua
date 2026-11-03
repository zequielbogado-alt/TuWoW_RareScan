--[[****************************************************************************
  * _NPCScan by Saiket                                                         *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


local _NPCScan = select( 2, ... );
_NPCScan.L = setmetatable( {
	NPCs = setmetatable( {}, {
		__index = function ( self, Name )
			return Name;
		end;
	} );
}, {
	__index = function ( self, Key )
		rawset( self, Key, Key );
		return Key;
	end;
} );

-- Default English localization
local L = _NPCScan.L;

L.BUTTON_FOUND = "NPC found!";
L.CACHED_FORMAT = "The following unit(s) are already cached: %s.";
L.CACHED_LONG_FORMAT = "The following unit(s) are already cached.  Consider removing them to re-alert: %s.";
L.CACHED_PET_RESTING_FORMAT = "The following tamable pet(s) were cached while resting: %s.";
L.CACHED_WORLD_FORMAT = "The following %2$s unit(s) are already cached: %1$s.";
L.CACHELIST_ENTRY_FORMAT = '|cff808080"%s"|r';
L.CACHELIST_SEPARATOR = ", ";
L.CMD_ADD = "ADD";
L.CMD_CACHE = "CACHE";
L.CMD_CACHE_EMPTY = "None of the mobs being searched for are cached.";
L.CMD_HELP = 'Commands are |cff808080"/npcscan add <NpcID> <Name>"|r, |cff808080"/npcscan remove <NpcID or Name>"|r, |cff808080"/npcscan cache"|r to list cached mobs, and simply |cff808080"/npcscan"|r for the options menu.';
L.CMD_REMOVE = "REMOVE";
L.CMD_REMOVENOTFOUND_FORMAT = 'NPC |cff808080"%s"|r not found.';
L.CONFIG_ALERT = "Alert Options";
L.CONFIG_ALERT_SOUND = "Alert sound file";
L.CONFIG_ALERT_SOUND_DEFAULT = "|cffffd200Default|r";
L.CONFIG_ALERT_SOUND_DESC = 'Choose the alert sound to play when an NPC is found.  Additional sounds can be added through |cff808080"SharedMedia"|r addons.';
L.CONFIG_ALERT_UNMUTE = "Unmute for alert sound";
L.CONFIG_ALERT_UNMUTE_DESC = "Briefly enables game sound when an NPC is found to play an alert tone if you have muted the game.";
L.CONFIG_CACHEWARNINGS = "Print cache reminders on login and world changes";
L.CONFIG_CACHEWARNINGS_DESC = "If an NPC is already cached when you log in or change worlds, this option prints a reminder of which chached mobs can't be searched for.";
L.CONFIG_MINIMAP = "Show minimap button";
L.CONFIG_MINIMAP_DESC = "Shows or hides the circular _NPCScan button on the minimap border.";
L.CONFIG_DESC = "These options let you configure the way _NPCScan alerts you when it finds rare NPCs.";
L.CONFIG_TEST = "Test Found Alert";
L.CONFIG_TEST_DESC = 'Simulates an |cff808080"NPC found"|r alert to let you know what to look out for.';
L.CONFIG_TEST_HELP_FORMAT = "Click the target button or use the provided keybinding to target the found mob.  Hold |cffffffff<%s>|r and drag to move the target button.  Note that if an NPC is found while you're in combat, the button will only appear after you exit combat.";
L.CONFIG_TEST_NAME = "You! (Test)";
L.CONFIG_TITLE = "_|cffCCCC88NPCScan|r";
L.FOUND_FORMAT = 'Found |cff808080"%s"|r!';
L.FOUND_TAMABLE_FORMAT = 'Found |cff808080"%s"|r!  |cffff2020(Note: Tamable mob, may only be a pet.)|r';
L.FOUND_TAMABLE_WRONGZONE_FORMAT = 'False alarm: Found tamable mob |cff808080"%s"|r in %s instead of %s (ID %d); Definitely a pet.';
L.PRINT_FORMAT = "_|cffCCCC88NPCScan|r: %s";
L.SEARCH_ACHIEVEMENTADDFOUND = "Search for completed Achievement NPCs";
L.SEARCH_ACHIEVEMENTADDFOUND_DESC = "Continues searching for all achievement NPCs, even if you no longer need them.";
L.SEARCH_ACHIEVEMENT_DISABLED = "Disabled";
L.SEARCH_ADD = "+";
L.SEARCH_ADD_DESC = "Add new NPC or save changes to existing one.";
L.SEARCH_ADD_TAMABLE_FORMAT = 'Note: |cff808080"%s"|r is tamable, so seeing it as a tamed hunter\'s pet will cause a false alarm.';
L.SEARCH_CACHED = "Cached";
L.SEARCH_COMPLETED = "Completed";
L.SEARCH_DESC = "These NPCs will be scanned for automatically.";
L.SEARCH_MAP = "World:";
L.SEARCH_MAP_DESC = "Which world to search for the NPC in.  Can be a continent or a dungeon zone name (case-sensitive).";
L.SEARCH_MAP_FORMAT = "(%s)";
L.SEARCH_MAP_FORMAT_BOTH = "%s (%s)";
L.SEARCH_NAME = "Name:";
L.SEARCH_NAME_DESC = "A label to identify the NPC by.  Doesn't have to match the mob's actual name.";
L.SEARCH_NPCS = "Custom NPCs";
L.SEARCH_NPCS_DESC = "Add any NPC to scan for, even if it has no associated achievement.";
L.SEARCH_REMOVE = "-";
L.SEARCH_REMOVE_DESC = "Remove selected NPC from search list.";
L.SEARCH_TITLE = "Search";
L.SEARCH_WORLD = "World:";
L.SEARCH_WORLD_DESC = "Which world to search for the NPC in.  Can be a continent or a dungeon zone name (case-sensitive).";
L.SEARCH_WORLD_FORMAT = "(%s)";
