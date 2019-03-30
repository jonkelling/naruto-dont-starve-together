local assets =
{
	Asset("ANIM", "anim/naruto.zip" ),
    Asset("SOUND", "sound/maxwell.fsb"),
    Asset("ANIM", "anim/swap_pickaxe.zip"),
    Asset("ANIM", "anim/swap_axe.zip"),
}

if NINJATOOLSMOD then
    table.insert(assets, Asset("ANIM", "anim/basickunai.zip"))
    table.insert(assets, Asset("ANIM", "anim/swap_basickunai.zip"))
end

local brain = require "brains/bunshinbrain"

local items =
{
    AXE = "swap_axe",
    PICK = "swap_pickaxe",
    SWORD = "swap_basickunai"
}

if not NINJATOOLSMOD then
    items["SWORD"] = "swap_spear"
end

local function EquipItem(inst, item)
    if item then
        inst.AnimState:OverrideSymbol("swap_object", items["SWORD"], items["SWORD"])
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
        inst:DoTaskInTime(math.random(), die)
    end
end

local function getplayer(inst)
	--local x,y,z = inst.Transform:GetWorldPosition()
	--local players = TheSim:FindEntities(x, y, z, 50, {"player"}, {"clone"})
	for k,player in pairs(Ents) do
		if player.userid ~= nil and player.userid == inst.ninjaid then
			return player
		end
	end
	return -1
end

local function PeriodicChecks(inst)
	if inst.ninjaid ~= -1 then
        local clonemaker = getplayer(inst)
        
		if clonemaker ~= nil and clonemaker ~= -1 and not inst.components.health:IsDead() then
			-- inst.components.health:DoDelta(1)
			
			-- local osx, osy, osz = inst.Transform:GetScale()
			-- local nsx, nsy, nsz = clonemaker.Transform:GetScale()
			
			-- if osx ~= nsx or osy ~= nsy or osz ~= nsz then
			-- 	inst.Transform:SetScale(nsx, nsy, nsz)
			-- end
            
            if JUTSUMOD then
                if inst.components.chakra.max ~= (inst.basemaxchakra / clonemaker.clones) then
                    inst.components.chakra:SetMaxChakra(inst.basemaxchakra / clonemaker.clones)
                    inst.components.health.maxhealth = inst.basemaxhealth / clonemaker.clones
                end
                
                if inst.components.chakra.current > inst.components.chakra.max then
                    inst.components.chakra:SetCurrentChakra(inst.components.chakra.max)
                end
                
                if inst.components.health.currenthealth > inst.components.health.maxhealth then
                    inst.components.health.currenthealth = inst.components.health.maxhealth
                end
            end
			
			-- if clonemaker.components.beard ~= nil then
			-- 	local growthsizes = {16, 8, 4}
			-- 	local beardarg1 = "beard"
			-- 	local beardarg2 = "beard"
			-- 	local size = "0"
			-- 	if clonemaker.prefab == "webber" then
			-- 		growthsizes = {9, 6, 3}
			-- 		beardarg1 = "beard_silk"
			-- 		beardarg2 = "beardsilk"
			-- 	end
				
			-- 	if clonemaker.components.beard.daysgrowth >= growthsizes[1] then
			-- 		size = "_long"
			-- 	elseif clonemaker.components.beard.daysgrowth >= growthsizes[2] then
			-- 		size = "_medium"
			-- 	elseif clonemaker.components.beard.daysgrowth >= growthsizes[3] then
			-- 		size = "_short"
			-- 	end
				
			-- 	if size ~= "0" then
			-- 		inst.AnimState:OverrideSymbol("beard", beardarg1, beardarg2 .. size)
			-- 	end
			-- end
			
			local hand = clonemaker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			
			if hand and string.find(hand.prefab, "lantern") then
				hand = nil
			end
            
			if inst.hand ~= nil and hand ~= nil then
				if inst.hand.prefab == "grass" or (inst.hand.prefab ~= hand.prefab and not(inst.hand.prefab == "raijinkunai" and hand.prefab == "flyingraijinkunai") and not(inst.hand.prefab == "lucyclone" and hand.prefab == "lucy")) then
					--if inst.hand ~= nil then -- if hand is empty then there is nothing to remove
						inst.hand:Remove()--delete previous held item
					--end
					
					if hand.prefab == "flyingraijinkunai" then
						inst.components.inventory:Equip(SpawnPrefab("raijinkunai"))
					elseif hand.prefab == "lucy" then
						inst.components.inventory:Equip(SpawnPrefab("lucyclone"))
					else
						inst.components.inventory:Equip(SpawnPrefab(hand.prefab))
					end
					inst.hand = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
					
					if inst.hand.components.projectile ~= nil then
						inst.hand.components.projectile:SetOnHitFn(function(proj) proj:Remove() end)
					end
					
					inst.brain:Stop()
					inst.brain:Start()
				elseif inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == nil then
					if inst.hand ~= nil and not inst.hand:HasTag("catchable") then -- should be nil but just incase
						inst.hand:Remove()
					end
					inst.components.inventory:Equip(SpawnPrefab(hand.prefab))
					inst.hand = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
					
					if inst.hand.components.projectile ~= nil then
						inst.hand.components.projectile:SetOnHitFn(function(proj) proj:Remove() end)
					end
					
					--inst.brain:Stop()
					--inst.brain:Start()
				end
			end
			
			-- if clonemaker.components.chakra:GetPercentWithPenalty() < .2 or
			-- 	-- IsOverheating(inst) or
			-- 	-- IsFreezing(inst) or 
			-- 	clonemaker.components.health:GetPercent() < .15 or
			-- 	inst.components.chakra:GetPercent() < .1 or 
			-- 	-- newbuild == "werebeaver_build" or
			-- 	getplayer(inst) == -1 then
				
			-- 	inst.periodiccheck:Cancel()
			-- 	inst.components.health:Kill()
				
			-- end
		elseif clonemaker == nil or clonemaker == -1 then
			die(inst)
		end
	end
end

local function OnSummoned(inst)
	--print("Clonemaker ID: " .. inst.ninjaid)
	if inst.ninjaid ~= -1 then
	    local clonemaker = getplayer(inst)
		if clonemaker ~= nil and clonemaker ~= -1 then
		
			inst.components.follower:SetLeader(clonemaker)
			inst.components.follower:KeepLeaderOnAttacked()

			-- inst.components.follower:StartLeashing()
			-- if clonemaker.prefab == "webber" then
			-- 	inst:AddTag("spiderwhisperer")
			-- end
			-- SpawnPrefab("smoke").Transform:SetPosition(inst.Transform:GetWorldPosition())
			
			-- local bank, build = GetBBA(clonemaker)
			-- inst.AnimState:SetBank(bank)--("wilson")
			-- inst.AnimState:SetBuild(build)--(clonemaker.prefab)
			-- inst.AnimState:PlayAnimation("idle", true)
			
			-- local allclothing = clonemaker.components.skinner:GetClothing()
			-- for k,v in pairs(allclothing) do
			-- 	inst.components.skinner:SetClothing(v)
			-- end

			-- inst.components.named:SetName(clonemaker.name)
            
            if JUTSUMOD then
                inst.basemaxhealth = clonemaker.components.health.maxhealth * .75
                inst.basemaxchakra = clonemaker.components.chakra.max / 2 --normally 50
                local maxhealth = 0
                local maxchakra = 0
                if clonemaker.clones ~= nil and clonemaker.clones > 0 then
                    maxhealth = inst.basemaxhealth / clonemaker.clones
                    maxchakra = inst.basemaxchakra / clonemaker.clones
                else
                    maxchakra = inst.basemaxchakra
                    maxhealth = inst.basemaxhealth
                end
                inst.components.health.maxhealth = maxhealth
                --inst.components.chakra.max = inst.maxchakra
                inst.components.chakra:SetMaxChakra(maxchakra)
                inst.components.chakra:SetCurrentChakra(maxchakra)
            end
			
			local head = clonemaker.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
			local body = clonemaker.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
			local hand = clonemaker.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

			if hand and string.find(hand.prefab, "lantern") then
				hand = nil
			end
			
			if head then
				inst.components.inventory:Equip(SpawnPrefab(head.prefab))
				inst.head = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
			end
			if body then
				inst.components.inventory:Equip(SpawnPrefab(body.prefab))
				inst.body = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
			end
			if hand then
				if hand.prefab == "flyingraijinkunai" then
					inst.components.inventory:Equip(SpawnPrefab("raijinkunai"))
				elseif hand.prefab == "lucy" then
					inst.components.inventory:Equip(SpawnPrefab("lucyclone"))
				else
					inst.components.inventory:Equip(SpawnPrefab(hand.prefab))
				end
				inst.hand = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
				if inst.hand.components.projectile ~= nil then
					inst.hand.components.projectile:SetOnHitFn(function() inst.hand:Remove() end)
				end
				--inst.hand:ListenForEvent("ondropped", function() inst.hand:DoTaskInTime(2, function() inst.hand:Remove() end) end)
			else
				local handitem = SpawnPrefab("cutgrass")
				inst.components.inventory:GiveItem(handitem)
				inst.hand = handitem
			end
			
			PeriodicChecks(inst)
		end	
	else
		die(inst)
	end
end

local function onattacked(inst, data)
	local clonemaker = getplayer(inst)
	
	if data.attacker == clonemaker then
		inst.components.health:Kill()
	else
		inst.components.combat:SetTarget(data.attacker)
		inst.components.combat:ShareTarget(data.attacker, 30, function(friend)
			return not friend.components.health:IsDead()
				and friend.components.follower ~= nil
				and friend.components.follower.leader == inst.components.follower.leader
		end, 10)
	end
		
end

local function doattack(inst, data)
	--inst.sg:GoToState("attack", data.target)
	
	if inst.components.health and not inst.components.health:IsDead() and (not inst.sg:HasStateTag("busy") or inst.sg:HasStateTag("hit")) then
		local buffered_attack = BufferedAction(inst, data.target, ACTIONS.ATTACK)
		inst:PushBufferedAction(buffered_attack)
	end
    
	if inst.components.chakra.current <= 0 then
		inst.components.health:Kill()
	end
end

local function OnCloneDeath(inst)
	-- inst:RemoveEventCallback("death", inst.ondeathfunc)
	if inst.brain ~= nil then
		inst.brain:Stop()
	end
	if inst.death ~= nil then
		inst.death:Cancel()
		inst.death = nil
	end
	if inst.periodiccheck ~= nil then
		inst.periodiccheck:Cancel()
	end
	-- if inst.head then inst.head:Remove() end
	-- if inst.body then inst.body:Remove() end
	-- if inst.hand then inst.hand:Remove() end
	local clonemaker = getplayer(inst)
	if clonemaker ~= -1 and clonemaker.clones ~= nil then
		-- clonemaker.components.chakra:PenaltyDelta(-clonemaker.components.chakra.max * (20/100))-- 20 will be configurable
		clonemaker.clones = clonemaker.clones - 1
		if clonemaker.clones == 0 then
			clonemaker.clones = nil
		end
	end
	inst:DoTaskInTime(0.5, function() SpawnPrefab("smoke").Transform:SetPosition(inst.Transform:GetWorldPosition()) end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddLightWatcher()
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

    inst:AddTag("_named")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:RemoveTag("_named")

    inst:AddTag("scarytoprey")
    inst:AddTag("kage_bunshin")
    inst:AddTag("ninja")
    inst:AddTag("clone")

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
    
	inst:AddComponent("rider") -- required for stategraph
	inst:AddComponent("skinner")
	inst:AddComponent("catcher") -- catch le boomerganerinos

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(CLONE_HEALTH)
    inst.components.health.nofadeout = true
	
	inst:AddComponent("sanity")
	inst.components.sanity:SetMax(9999)
	
	inst:AddComponent("hunger")
	inst.components.hunger:SetMax(9999)

    inst:AddComponent("inventory")
    inst.components.inventory:DisableDropOnDeath()

    MakeHauntablePanic(inst)

    inst.items = items
    inst.equipfn = EquipItem

    inst.lifetime = CLONE_LIFETIME * 60
    inst.death = inst:DoTaskInTime(inst.lifetime, die)-- kill clone after 5 mins

    inst.OnSave = onsave
    inst.OnLoad = onload

    EquipItem(inst)

    -- inst:ListenForEvent("entity_death", function(world, data) entitydeathfn(inst, data) end, TheWorld)

    inst:AddComponent("follower")

	inst:AddComponent("temperature")
    inst.components.temperature.usespawnlight = true
	
	inst:AddComponent("moisture")
	
	inst:AddComponent("grogginess")
    inst.components.grogginess:SetResistance(3)
    inst.components.grogginess:SetKnockOutTest(function()
        return DefaultKnockoutTest(inst) and not inst.sg:HasStateTag("yawn")
    end)

    inst:SetStateGraph("SGbunshin")

	-----       
    
    if JUTSUMOD then
        inst.ondeathfunc = inst:ListenForEvent("death", OnCloneDeath)
    end

    -----

    inst.ninjaid = inst.ninjaid or -1


    inst:SetBrain(brain)
    
	
	inst:AddComponent("named")
    inst.components.named:SetName("Shadow Clone")
    

    inst:DoTaskInTime(0.1, OnSummoned)

    inst.periodiccheck = inst:DoPeriodicTask(1, PeriodicChecks)

    -- inst.DoTaskInTime(0.1, function() inst.components.health:Kill())

    return inst
end

return Prefab("common/bunshin", fn, assets)