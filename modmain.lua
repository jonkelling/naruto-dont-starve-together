PrefabFiles = {
	"naruto",
	"bunshinjutsu",
	"bunshin"
}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/naruto.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/naruto.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/naruto.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/naruto.xml" ),
	
    Asset( "IMAGE", "images/selectscreen_portraits/naruto_silho.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/naruto_silho.xml" ),

    Asset( "IMAGE", "bigportraits/naruto.tex" ),
    Asset( "ATLAS", "bigportraits/naruto.xml" ),
	
	Asset( "IMAGE", "images/map_icons/naruto.tex" ),
	Asset( "ATLAS", "images/map_icons/naruto.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_naruto.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_naruto.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_ghost_naruto.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_naruto.xml" ),

	Asset("ANIM", "anim/narutochakra.zip"),

    Asset( "IMAGE", "images/recipe_tab/tab_ninja_gear.tex" ),
	Asset( "ATLAS", "images/recipe_tab/tab_ninja_gear.xml" )
}

local require 		= GLOBAL.require
local STRINGS 		= GLOBAL.STRINGS
local Ingredient 	= GLOBAL.Ingredient
local RECIPETABS 	= GLOBAL.RECIPETABS
local TECH 			= GLOBAL.TECH

-- The character select screen lines
STRINGS.CHARACTER_TITLES.naruto = "Naruto"
STRINGS.CHARACTER_NAMES.naruto = "Naruto"
STRINGS.CHARACTER_DESCRIPTIONS.naruto = "*Kage Bunshin no Jutsu\n*Uses Kunai"
STRINGS.CHARACTER_QUOTES.naruto = "\"One day I'll become Hokage!\""

-- Custom speech strings
STRINGS.CHARACTERS.NARUTO = require "speech_naruto"

-- The character's name as appears in-game 
STRINGS.NAMES.NARUTO = "Naruto"

-- The default responses of examining the character
STRINGS.CHARACTERS.GENERIC.DESCRIBE.NARUTO = 
{
	GENERIC = "It's Naruto!",
	ATTACKER = "Naruto looks shifty...",
	MURDERER = "Murderer!",
	REVIVER = "Naruto, friend of ghosts.",
	GHOST = "Naruto could use a heart."
}

if not RECIPETABS['NINJA_GEAR'] then
	RECIPETABS['NINJA_GEAR'] = { str = "NINJA_GEAR", sort = 1000, icon = "tab_ninja_gear.tex", icon_atlas = "images/recipe_tab/tab_ninja_gear.xml" }
	STRINGS.TABS.NINJA_GEAR = "Ninja gear"
end

STRINGS.NAMES.BUNSHINJUTSU = "Scroll of the Forbidden Seal"
STRINGS.CHARACTERS.NARUTO.DESCRIBE.BUNSHINJUTSU = "Powerful Ninjutsu. Creates a clone, takes hunger for each copy."
STRINGS.CHARACTERS.GENERIC.DESCRIBE.BUNSHINJUTSU = "Weird scroll."

AddRecipe("bunshinjutsu",
	{
		Ingredient("papyrus", 2),
		Ingredient('nightmarefuel', 1)
	},
	RECIPETABS.NINJA_GEAR, TECH.NONE, nil, nil, nil, nil, 'ninja', "images/inventoryimages/bunshinjutsu.xml")

GLOBAL.CLONE_CHAKRA_COST 	= GetModConfigData("clone_chakra_cost")
GLOBAL.CLONE_HUNGER_COST 	= GetModConfigData("clone_hunger_cost")
GLOBAL.CLONE_HEALTH 		= GetModConfigData("clone_health")
GLOBAL.CLONE_DAMAGE 		= GetModConfigData("clone_damage")
GLOBAL.CLONE_LIFETIME 		= GetModConfigData("clone_lifetime")

GLOBAL.NINJATOOLSMOD        = GLOBAL.KnownModIndex:IsModEnabled("workshop-1679106997")
GLOBAL.JUTSUMOD             = GLOBAL.KnownModIndex:IsModEnabled("workshop-644104565")

AddMinimapAtlas("images/map_icons/naruto.xml")

-- Add mod character to mod character list. Also specify a gender. Possible genders are MALE, FEMALE, ROBOT, NEUTRAL, and PLURAL.
AddModCharacter("naruto", "MALE")

GLOBAL.CONTROLS = nil

if not GLOBAL.JUTSUMOD then
	local ChakraBadge = GLOBAL.require("widgets/narutochakrabadge")

	local function AddChakraIndicator(self)
		controls = self -- this just makes controls available in the rest of the modmain's functions

		controls.chakraindicator = controls.sidepanel:AddChild(ChakraBadge())
		controls.chakraindicator:SetPosition(0, -151, 0)

		controls.chakraindicator:MoveToBack()

		controls.chakraindicator:SetClickable(false)

		GLOBAL.CONTROLS = controls
	end

	AddClassPostConstruct("widgets/controls", AddChakraIndicator)
end
