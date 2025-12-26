local function Teleport(who, xf, zf)
    if who.Physics ~= nil then
        who.Physics:Teleport(xf-1, 0, zf)
    else
        who.Transform:SetPosition(xf-1, 0, zf)
    end

    -- follow
    if who.components.leader and who.components.leader.followers then
        for kf,vf in pairs(who.components.leader.followers) do
            if kf.Physics ~= nil then
                kf.Physics:Teleport(xf+1, 0, zf)
            else
                kf.Transform:SetPosition(xf+1, 0, zf)
            end
        end
    end

    local inventory  = who.components.inventory
    if inventory then
        for ki, vi in pairs(inventory.itemslots) do
            if vi.components.leader and vi.components.leader.followers then
                for kif,vif in pairs(vi.components.leader.followers) do
                    if kif.Physics ~= nil then
                        kif.Physics:Teleport(xf, 0, zf+1)
                    else
                        kif.Transform:SetPosition(xf, 0, zf+1)
                    end
                end
            end
        end
    end

    local container = inventory:GetOverflowContainer()
    if container then
        for kb, vb in pairs(container.slots) do
            if vb.components.leader and vb.components.leader.followers then
                for kbf,vbf in pairs(vb.components.leader.followers) do
                    if kbf.Physics ~= nil then
                        kbf.Physics:Teleport(xf, 0, zf-1)
                    else
                        kbf.Transform:SetPosition(xf, 0, zf-1)
                    end
                end
            end
        end
    end
end

local function BetterFlyingRaijinOnRead(inst, reader)
	local jv = inst.vars
	local ninja = reader
	local HasInfiniteChakra = ninja.components.chakra:IsInfinite()
	local canuse = ninja.components.chakra
	local totalkunais = 0
	local lowestkunai = 0
	local highestkunai = 0
	local foundvalid = false
	local sortedKunai = {}
	local foundLastKunai = false

	ninja.lastkunai = ninja.lastkunai or -1
	
	for k,kunai in pairs(Ents) do
		if kunai.prefab == "flyingraijinkunai" then
			if kunai:HasTag(ninja.userid) and not ninja.components.inventory:GetItemSlot(kunai) then
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
				local nx, ny, nz = ninja.Transform:GetWorldPosition()
				local kx, ky, kz = kunai.Transform:GetWorldPosition()
				local notSamePos = (nx ~= kx or nz ~= kz)
				
				if not foundvalid and not ninja.components.inventory:GetItemSlot(kunai) and notSamePos and (kunai.GUID > ninja.lastkunai or totalkunais == 1 or (ninja.lastkunai == highestkunai and kunai.GUID == lowestkunai)) then
					ninja.components.talker:Say("(Better) " .. jv.strings.use)
					local xn, yn, zn = ninja.Transform:GetWorldPosition()
					local x, y, z = kunai.Transform:GetWorldPosition()

					SpawnPrefab("smoke").Transform:SetPosition(xn, yn, zn)
					kunai:DoTaskInTime(.2, function() SpawnPrefab("smoke").Transform:SetPosition(x, y, z) end)
					kunai:DoTaskInTime(.1, function()
						Teleport(ninja, x, z)
						
						ninja.lastkunai = kunai.GUID
						
						if not HasInfiniteChakra then
							ninja.components.chakra:UseAmount(jv.chakra)
						end
					end)
					
					foundvalid = true
					return true
				end			
			end
		end
	else
		if totalkunais == 0 then
			ninja.components.talker:Say("(Better) " .. jv.strings.none)
		elseif not canuse then
			ninja.components.talker:Say(inst.nochakra)
		end
	end
	
	return false
end

return {
    BetterFlyingRaijinOnRead = BetterFlyingRaijinOnRead
}
	
	return false
end

return {
    BetterFlyingRaijinOnRead = BetterFlyingRaijinOnRead
}