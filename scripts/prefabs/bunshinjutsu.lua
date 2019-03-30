local assets =
{
    Asset("ANIM", "anim/bunshinjutsu.zip"),

    Asset("ATLAS", "images/inventoryimages/bunshinjutsu.xml"),
    Asset("IMAGE", "images/inventoryimages/bunshinjutsu.tex")
}

local prefabs =
{
    "bunshin"
}

local function doeffects(inst, pos)
    SpawnPrefab("maxwell_smoke").Transform:SetPosition(pos:Get()) -- or small_puff
end

local function canRead(inst)
    --return inst.components.sanity:GetMaxWithPenalty() >= TUNING.SHADOWWAXWELL_SANITY_PENALTY
    if JUTSUMOD then
        return inst.components.chakra:CheckEnough(CLONE_CHAKRA_COST)
    else
        return inst.components.narutochakra.currentchakra > CLONE_CHAKRA_COST -- > instead of >= so player doesn't die
    end
end

local function onread(inst, reader, ignorecosts)

    if not canRead(reader) then
        if reader.components.talker then
            reader.components.talker:Say("Can't... My chakra is too low...")
            return false
        end
    end

    -- if JUTSUMOD then
    --     c_runjutsu("shadowclone")
    --     -- for k,clone in pairs(reader.clones) do
    --     --     clone:AddTag("ninja")
    --     -- end
    --     return true
    -- end

    local theta = math.random() * 2 * PI
    local pt = inst:GetPosition()
    local radius = math.random(3, 6)
    local offset = FindWalkableOffset(pt, theta, radius, 12, true)
    if offset then
        if JUTSUMOD then
            reader.clones = (reader.clones or 0) + 1
        end

        local bunshin = SpawnPrefab('bunshin')
        local pos = pt + offset
        bunshin.Transform:SetPosition(pos:Get())
        doeffects(inst, pos)
        bunshin.ninjaid = reader.userid

        if reader.components.talker then
            reader.components.talker:Say('Kage Bunshin no Jutsu!')
        end
        
        if JUTSUMOD then
            reader.components.chakra:UseAmount(CLONE_CHAKRA_COST)
            reader.components.hunger:DoDelta(-CLONE_HUNGER_COST)
        else
            reader.components.narutochakra:DoDelta(-CLONE_CHAKRA_COST, 'Kage Bunshin no Jutsu', reader)
        end
        
        inst.SoundEmitter:PlaySound("dontstarve/maxwell/shadowmax_appear")
        return true
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bunshinjutsu")
    inst.AnimState:SetBuild("bunshinjutsu")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "bunshinjutsu"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/bunshinjutsu.xml"

    -----------------------------------
    inst:AddComponent("inspectable")
    inst:AddComponent("book")
    inst.components.book.onread = onread

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)

    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            inst.components.book.onread(inst, haunter, true)
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
            return true
        end
        return false
    end, true, false, true)

    if not inst.components.characterspecific then
        inst:AddComponent("characterspecific")
    end
 
    inst.components.characterspecific:SetOwner("naruto")
    inst.components.characterspecific:SetStorable(true)
    inst.components.characterspecific:SetComment("I don't know how to use it")

    return inst
end

return Prefab("common/bunshinjutsu", fn, assets, prefabs)  -- assets, prefabs