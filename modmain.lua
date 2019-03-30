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

local function OnChakraDirty(inst)
	if inst ~= nil then
		local current = inst.currentchakra:value()
		local max = inst.maxchakra:value()
		local penalty = inst.penaltychakra:value()
		if max < 100 and not inst:HasTag("clone") then
			max = 100
		end
		
		if inst.components.chakra.max ~= max then
			inst.components.chakra:SetMaxChakra(max)
		end
		
		if inst.components.chakra.penalty ~= penalty then
			inst.components.chakra:SetPenalty(penalty)
		end
		
		inst.components.chakra:SetCurrentChakra(current)
		
		inst:PushEvent("chakradirty", {newpercent = current / max, current = current, max = max, penalty = penalty})
	end
end

local function CloneChakra(inst)
	if inst.components.chakra == nil then
		inst:AddComponent("chakra")
		inst.components.chakra:StartCharge(1, 3/2)
		inst.maxchakra = GLOBAL.net_ushortint( inst.GUID, "chakramax", "currentdirty")
		inst.currentchakra = GLOBAL.net_ushortint( inst.GUID, "chakracurrent", "currentdirty")
		inst.penaltychakra = GLOBAL.net_float( inst.GUID, "chakrapenalty", "currentdirty")

		-- inst.components.chakra:SetInfinite(true, false)
	
		inst:ListenForEvent("currentdirty", function(inst) OnChakraDirty(inst) end)
	end	
end

local function BetterFlyingRaijinJutsuOnUse(jutsu, ninja)
	local jv = jutsu.vars
	ninja = jutsu.components.inventoryitem.owner or ninja
	local HasInfiniteChakra = ninja.components.chakra:IsInfinite()
	local canuse = ninja.components.chakra
	local consumejutsu = true
	local totalkunais = 0
	local lowestkunai = 0
	local highestkunai = 0
	local foundvalid = false
	local Ents = GLOBAL.Ents
	local sortedKunai = {}
	local SpawnPrefab = GLOBAL.SpawnPrefab
	local foundLastKunai = false

	ninja.lastkunai = ninja.lastkunai or -1
	
	for k,kunai in pairs(Ents) do
		if kunai.prefab == "flyingraijinkunai" then
			if kunai:HasTag(ninja.userid) then
				if kunai.GUID == ninja.lastkunai then
					foundLastKunai = true
				end
				if lowestkunai == 0 or kunai.GUID < lowestkunai then
					lowestkunai = kunai.GUID
				end
				if kunai.GUID > highestkunai then
					highestkunai = kunai.GUID
				end
				totalkunais = totalkunais + 1
				sortedKunai[#sortedKunai+1] = kunai
			end
		end
	end

	if not foundLastKunai then
		ninja.lastkunai = -1
	end

	table.sort(sortedKunai, function(a,b) return a.GUID < b.GUID end )

	if canuse and totalkunais ~= 0 then
		for k,kunai in ipairs(sortedKunai) do
			if kunai.prefab == "flyingraijinkunai" and kunai:HasTag(ninja.userid) then
				if not foundvalid and ninja.Transform:GetWorldPosition() ~= kunai.Transform:GetWorldPosition() and (kunai.GUID > ninja.lastkunai or totalkunais == 1 or (ninja.lastkunai == highestkunai and kunai.GUID == lowestkunai)) then
					ninja.components.talker:Say("(Better) " .. jv.strings.use)
					local xn, yn, zn = ninja.Transform:GetWorldPosition()
					local x, y, z = kunai.Transform:GetWorldPosition()

					SpawnPrefab("smoke").Transform:SetPosition(xn, yn, zn) -- smoke fx before cast
					kunai:DoTaskInTime(.1, function() SpawnPrefab("smoke").Transform:SetPosition(x, y, z) end) -- smoke fx after cast
					if kunai.GUID == highestkunai and totalkunais ~= 1 then
						ninja.Physics:Teleport(x-0.1, y, z)
					else
						ninja.Physics:Teleport(x, y, z)
					end
					
					ninja.lastkunai = kunai.GUID
					
					if not HasInfiniteChakra then
						ninja.components.chakra:UseAmount(jv.chakra)
					end
					
					foundvalid = true
				end			
			end
		end
	else
		if totalkunais == 0 then
			ninja.components.talker:Say("(Better) " .. jv.strings.none)
		elseif not canuse then
			ninja.components.talker:Say(jutsu.nochakra)
		end
	end
	
	jutsu.components.useableitem:StopUsingItem()
end

GLOBAL.CONTROLS = nil

if GLOBAL.JUTSUMOD then
	AddPrefabPostInit("bunshin", CloneChakra)

	AddPrefabPostInit("flyingraijin", function(inst)
		inst:DoTaskInTime(1, function()
			if inst.components.useableitem ~= nil then
				inst.components.useableitem:SetOnUseFn(BetterFlyingRaijinJutsuOnUse)
			end
		end)
	end)
else
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
