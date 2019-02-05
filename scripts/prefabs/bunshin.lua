local assets =
{
	Asset("ANIM", "anim/naruto.zip" ),
    Asset("SOUND", "sound/maxwell.fsb"),
    Asset("ANIM", "anim/swap_pickaxe.zip"),
    Asset("ANIM", "anim/swap_axe.zip"),
    Asset("ANIM", "anim/basickunai.zip"),
    Asset("ANIM", "anim/swap_basickunai.zip")
}

local brain = require "brains/bunshinbrain"

local items =
{
    AXE = "swap_axe",
    PICK = "swap_pickaxe",
    SWORD = "swap_kunai"
}

local function EquipItem(inst, item)
    if item then
        inst.AnimState:OverrideSymbol("swap_object", 'swap_basickunai', 'kunai')
        inst.AnimState:Show("ARM_carry") 
        inst.AnimState:Hide("ARM_normal")
    end
end

local function die(inst)
    inst.components.health:Kill()
end

local function resume(inst, time)
    if inst.death then
        inst.death:Cancel()
        inst.death = nil
    end
    inst.death = inst:DoTaskInTime(time, die)
end

local function onsave(inst, data)
    data.timeleft = (inst.lifetime - inst:GetTimeAlive())
end

local function KeepTarget(isnt, target)
    return target and target:IsValid()
end

local function onload(inst, data)
    if data.timeleft then
        inst.lifetime = data.timeleft
        if inst.lifetime > 0 then
            resume(inst, inst.lifetime)
        else
            die(inst)
        end
    end
end

local function entitydeathfn(inst, data)
    if data.inst:HasTag("player") then
        inst:DoTaskInTime(math.random(), function() inst.components.health:Kill() end)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 50, .5)

    inst.Transform:SetFourFaced(inst)
    
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("naruto")
    inst.AnimState:PlayAnimation("idle")


    -- FROM PLAYER_COMMON
    inst.AnimState:Hide("HAT_HAIR")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")
    inst.AnimState:Hide("ARM_carry")

    --inst:Show()

    
    -- END FROM PLAYER_COMMON

    --inst.AnimState:Hide("ARM_carry")
    --inst.AnimState:Hide("hat")
    --inst.AnimState:Hide("hat_hair")

    inst:AddTag("scarytoprey")
    inst:AddTag("kage_bunshin")
    inst:AddTag("ninja")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --inst:AddComponent("colourtweener")
    --inst.components.colourtweener:StartTween({0,0,0,.5}, 0)

    inst:AddComponent("locomotor")
    inst.components.locomotor:SetSlowMultiplier( 0.6 )
    inst.components.locomotor.runspeed = TUNING.SHADOWWAXWELL_SPEED

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "torso"
    -- inst.components.combat:SetRetargetFunction(1, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetAttackPeriod(TUNING.SHADOWWAXWELL_ATTACK_PERIOD)
    inst.components.combat:SetRange(2, 3)
    inst.components.combat:SetDefaultDamage(CLONE_DAMAGE)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(CLONE_HEALTH)
    inst.components.health.nofadeout = true

    inst:AddComponent("inventory")
    inst.components.inventory:DisableDropOnDeath()

    MakeHauntablePanic(inst)

    inst.items = items
    inst.equipfn = EquipItem

    inst.lifetime = 5 * 60 --5 minutes; TUNING.SHADOWWAXWELL_LIFETIME
    inst.death = inst:DoTaskInTime(inst.lifetime, die)

    inst.OnSave = onsave
    inst.OnLoad = onload

    EquipItem(inst)

    inst:ListenForEvent("entity_death", function(world, data) entitydeathfn(inst, data) end, TheWorld)

    inst:AddComponent("follower")

    inst:SetBrain(brain)
    inst:SetStateGraph("SGbunshin")

    return inst
end

return Prefab("common/bunshin", fn, assets)