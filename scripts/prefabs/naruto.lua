
local MakePlayerCharacter = require "prefabs/player_common"


local assets = {

        Asset( "ANIM", "anim/player_basic.zip" ),
        Asset( "ANIM", "anim/player_idles_shiver.zip" ),
        Asset( "ANIM", "anim/player_actions.zip" ),
        Asset( "ANIM", "anim/player_actions_axe.zip" ),
        Asset( "ANIM", "anim/player_actions_pickaxe.zip" ),
        Asset( "ANIM", "anim/player_actions_shovel.zip" ),
        Asset( "ANIM", "anim/player_actions_blowdart.zip" ),
        Asset( "ANIM", "anim/player_actions_eat.zip" ),
        Asset( "ANIM", "anim/player_actions_item.zip" ),
        Asset( "ANIM", "anim/player_actions_uniqueitem.zip" ),
        Asset( "ANIM", "anim/player_actions_bugnet.zip" ),
        Asset( "ANIM", "anim/player_actions_fishing.zip" ),
        Asset( "ANIM", "anim/player_actions_boomerang.zip" ),
        Asset( "ANIM", "anim/player_bush_hat.zip" ),
        Asset( "ANIM", "anim/player_attacks.zip" ),
        Asset( "ANIM", "anim/player_idles.zip" ),
        Asset( "ANIM", "anim/player_rebirth.zip" ),
        Asset( "ANIM", "anim/player_jump.zip" ),
        Asset( "ANIM", "anim/player_amulet_resurrect.zip" ),
        Asset( "ANIM", "anim/player_teleport.zip" ),
        Asset( "ANIM", "anim/wilson_fx.zip" ),
        Asset( "ANIM", "anim/player_one_man_band.zip" ),
        Asset( "ANIM", "anim/shadow_hands.zip" ),
        Asset( "SOUND", "sound/sfx.fsb" ),
        Asset( "SOUND", "sound/wilson.fsb" ),
        Asset( "ANIM", "anim/beard.zip" ),

        Asset( "ANIM", "anim/naruto.zip" ),
        Asset( "ANIM", "anim/ghost_naruto_build.zip" )
}
local prefabs = {}

-- Custom starting items
local start_inv = {
    "bunshinjutsu",
    "kunai"
}

-- When the character is revived from human
local function onbecamehuman(inst)
	-- Set speed when loading or reviving from ghost (optional)
	inst.components.locomotor.walkspeed = 5
	inst.components.locomotor.runspeed = 7

    if not KnownModIndex:IsModEnabled("workshop-644104565") then
        if CONTROLS then
            CONTROLS.chakraindicator:Show()
        end
    end
end


local function OnBecameGhost(inst)
    if not KnownModIndex:IsModEnabled("workshop-644104565") then
        if CONTROLS then
            CONTROLS.chakraindicator:Hide()
        end
    end
end

-- When loading the character
local function OnLoad(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", OnBecameGhost)

    if inst:HasTag("playerghost") then
        OnBecameGhost(inst)
    else
        onbecamehuman(inst)
    end
end

local function OnNewSpawn(inst)
    OnLoad(inst)

    if inst.components.inventory ~= nil then
        inst.components.inventory.ignoresound = true
        
        inst.components.inventory:Equip(SpawnPrefab('headband_blue'))

        inst.components.inventory.ignoresound = false
    end
end

local function OnPlayerLeft(inst, player)
    --player.components.talker:Say('OnPlayerLeft ms_playerleft')
    if not player or not player.components or not player.components.leader then
        return
    end
    
    for k, v in pairs(player.components.leader.followers) do
        if k:HasTag('kage_bunshin') then
            player.components.talker:Say('Kage Bunshin should dispose now!')
            k.components.health:Kill()
            --self:RemoveFollower(k)
        end
    end
end

-- This initializes for both the server and client. Tags can be added here.
local function common_postinit(inst) 
	-- Minimap icon
	inst.MiniMapEntity:SetIcon("naruto.tex")

    inst:AddTag('ninja')

    inst:ListenForEvent("ms_playerleft", function(src, player) OnPlayerLeft(inst, player) end, TheWorld) -- http://forums.kleientertainment.com/topic/56400-player-logout-eventhook-name/#entry656494
end

local function TakeHungerForChakra(inst, data)
    if data == nil then return end

    if data.amount == nil or data.amount >= 0 then return end

    inst.components.hunger:DoDelta(-CLONE_HUNGER_COST)
end

local function OnChakraDelta(inst, data)
    TakeHungerForChakra(inst, data)

    local chakra = nil
    if not KnownModIndex:IsModEnabled("workshop-644104565") then
        chakra = inst.components.narutochakra.currentchakra
    else 
        chakra = inst.components.chakra:GetCurrent()
    end

    if chakra == nil then return end

    local hasTag        = inst:HasTag('double_sanity_loss')
    local rateModifier  = inst.components.sanity.rate_modifier

    if chakra < 20 and not hasTag then
        inst.components.sanity.rate_modifier = rateModifier * 2
        inst:AddTag('double_sanity_loss')
    elseif chakra >= 20 and hasTag then
        inst.components.sanity.rate_modifier = rateModifier / 2
        inst:RemoveTag('double_sanity_loss')
    end
end

-- This initializes for the server only. Components are added here.
local function master_postinit(inst)
    inst:AddComponent("reader")
    
	-- choose which sounds this character will play
	inst.soundsname = "willow"
	
	-- Uncomment if "wathgrithr"(Wigfrid) or "webber" voice is used
    --inst.talker_path_override = "dontstarve_DLC001/characters/"
	
	-- Stats	
	inst.components.health:SetMaxHealth(180)
	inst.components.hunger:SetMax(150)
	inst.components.sanity:SetMax(220)
	
	-- Damage multiplier (optional)
    inst.components.combat.damagemultiplier = 1
	
	-- Hunger rate (optional)
	inst.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE
	
	inst.OnLoad = OnLoad
    inst.OnNewSpawn = OnNewSpawn

    if not KnownModIndex:IsModEnabled("workshop-644104565") then
        inst:AddComponent('narutochakra')
        inst.components.narutochakra:SetMaxChakra(100)
        inst.components.narutochakra:StartRegen(1, 10)
    end
    
    -- This event is pushed by the Jutsu mod as well
    inst:ListenForEvent('chakradelta', OnChakraDelta)
end

return MakePlayerCharacter("naruto", prefabs, assets, common_postinit, master_postinit, start_inv)
