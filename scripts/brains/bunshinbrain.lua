require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/panic"
require "behaviours/follow"
require "behaviours/attackwall"
require "behaviours/leash"
require "behaviours/runaway"
require("debugprint")

local KageBunshinBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

--Images will help chop, mine and fight.

local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 4
local MAX_FOLLOW_DIST = 6

local START_FACE_DIST = 6
local KEEP_FACE_DIST = 8

local KEEP_WORKING_DIST = 14
local SEE_WORK_DIST = 15

local RUN_AWAY_DIST = 3
local STOP_RUN_AWAY_DIST = 5

local function HasStateTags(inst, tags)
    for i, v in ipairs(tags) do
        if inst.sg:HasStateTag(v) then
            return true
        end
    end
end

-- local function KeepWorkingAction(inst, actiontags)
--     return inst.components.follower.leader ~= nil
--         and inst.components.follower.leader:IsNear(inst, KEEP_WORKING_DIST)
--         and HasStateTags(inst.components.follower.leader, actiontags)
-- end

local function StartWorkingCondition(inst, actiontags)
    return inst.components.follower.leader ~= nil
        and HasStateTags(inst.components.follower.leader, actiontags)
        and not HasStateTags(inst, actiontags)
end

local function FindObjectToWorkAction(inst, action)
    if inst.sg:HasStateTag("working") then
        return
    end
    local target = FindEntity(inst.components.follower.leader, SEE_WORK_DIST, nil, { action.id.."_workable" }, { "INLIMBO" })
    return target ~= nil
        and BufferedAction(inst, target, action)
        or nil
end

local function GetLeader(inst)
    return inst.components.follower.leader
end

local function GetFaceTargetFn(inst)
    local target = FindClosestPlayerToInst(inst, START_FACE_DIST, true)
    return target ~= nil and not target:HasTag("notarget") and target or nil
end

local function KeepFaceTargetFn(inst, target)
    return not target:HasTag("notarget") and inst:IsNear(target, KEEP_FACE_DIST)
end

local function KeepWorkingAction(inst, dist)
    local leader = inst.components.follower.leader
    return leader ~= nil and inst:IsNear(leader, dist)
end

local function FindEntityToWorkAction(inst, action, addtltags)
    local leader = GetLeader(inst)
    if leader ~= nil then
        --Keep existing target?
        local target = inst.sg.statemem.target
        if target ~= nil and
            target:IsValid() and
            not target:IsInLimbo() and
            target.components.workable ~= nil and
            target.components.workable:CanBeWorked() and
            target.components.workable:GetWorkAction() == action and
            target.entity:IsVisible() and
            target:IsNear(leader, KEEP_WORKING_DIST) then
                
            if addtltags ~= nil then
                for i, v in ipairs(addtltags) do
                    if target:HasTag(v) then
                        return BufferedAction(inst, target, action)
                    end
                end
            else
                return BufferedAction(inst, target, action)
            end
        end

        --Find new target
        target = FindEntity(leader, SEE_WORK_DIST, nil, { action.id.."_workable" }, { "INLIMBO" }, addtltags)
        return target ~= nil and BufferedAction(inst, target, action) or nil
    end
end

function KageBunshinBrain:OnStart()
    local root = PriorityNode(
    {
        IfNode(
            function()
                return
                    self.inst.hand ~= nil and
                    (self.inst.hand.prefab == "grass" or self.inst.hand.components.weapon ~= nil) and
                    not (
                        self.inst.hand:HasTag("CHOP_tool") or
                        self.inst.hand:HasTag("MINE_tool") or
                        self.inst.hand:HasTag("DIG_tool")
                    )
            end,
            "Can Fight",
            PriorityNode({
                IfNode(
                    function()
                        return
                            self.inst.components.combat:HasTarget() and
                            self.inst.hand.components.weapon ~= nil and
                            self.inst.hand.components.weapon.projectile -- e.g. Rasengan!
                    end,
                    "Has target and is using projectile weapon",
                    ChaseAndAttack(self.inst, 5, nil, 1)
                ),
                WhileNode(
                    function()
                        return
                            self.inst.components.combat:HasTarget() and
                            self.inst.components.combat:GetCooldown() > .5 and
                            not (
                                self.inst.hand.components.weapon ~= nil and
                                self.inst.hand.components.weapon.projectile
                            )
                        end,
                    "Dodge",
                    RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)
                ),
                ChaseAndAttack(self.inst, 5)
        }, .25)),
		
        IfNode(function() return self.inst.hand ~= nil and self.inst.hand:HasTag("CHOP_tool") end, "Can Chop",
            WhileNode(function() return KeepWorkingAction(self.inst, KEEP_WORKING_DIST) end, "Keep Chopping",
                LoopNode{
                    DoAction(self.inst, function() return FindEntityToWorkAction(self.inst, ACTIONS.CHOP) end)
        })),

        IfNode(function() return self.inst.hand ~= nil and self.inst.hand:HasTag("MINE_tool") end, "Can Mine",
            WhileNode(function() return KeepWorkingAction(self.inst, KEEP_WORKING_DIST) end, "Keep Mining",
                LoopNode{
                    DoAction(self.inst, function() return FindEntityToWorkAction(self.inst, ACTIONS.MINE) end)
        })),

        -- IfNode(function() return self.inst.hand ~= nil and self.inst.hand:HasTag("DIG_tool") end, "Can Dig",
        --     WhileNode(function() return KeepWorkingAction(self.inst, KEEP_WORKING_DIST) end, "Keep Digging",
        --         DoAction(self.inst, function() return FindEntityToWorkAction(self.inst, ACTIONS.DIG, {"stump", "grave"}) end)
        -- )),

        -- WhileNode(function()
        --         return StartWorkingCondition(self.inst, { "chopping", "prechop" })
        --             and KeepWorkingAction(self.inst, { "chopping", "prechop" })
        --     end,
        --     "keep chopping",
        --     DoAction(self.inst, function() return FindObjectToWorkAction(self.inst, ACTIONS.CHOP) end)),

        -- WhileNode(function()
        --         return StartWorkingCondition(self.inst, { "mining", "premine" })
        --             and KeepWorkingAction(self.inst, { "mining", "premine" })
        --     end,
        --     "keep mining",
        --     DoAction(self.inst, function() return FindObjectToWorkAction(self.inst, ACTIONS.MINE) end)),

        
		
		IfNode(function() return not self.inst.components.combat:HasTarget() end, "Can Follow",
            Follow(self.inst, GetLeader, MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST)),

        IfNode(function() return GetLeader(self.inst) ~= nil end, "Has Leader",
            FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn)),
    }, .25)

    self.bt = BT(self.inst, root)
end

return KageBunshinBrain