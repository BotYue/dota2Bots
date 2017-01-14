_G.state = "laning"

local Constant = require(GetScriptDirectory().."/dev/constant_each_side")
local DotaBotUtility = require(GetScriptDirectory().."/utility")
local para = require(GetScriptDirectory().."/SFDQN")
local DQN = require(GetScriptDirectory().."/DQN")

DQN:LoadFromTable(para)
DQN:PrintValidationQ()

LastEnemyHP = 1000

EnemyTowerPosition = Vector(1024,320)
AllyTowerPosition = Vector(-1656,-1512)

LastEnemyTowerHP = 1300

LastDecesion = -1000

DeltaTime = 300 / 2

local function ClipTime(t)
    local ub = 3
    if t > ub then
        return ub
    else
        return t
    end
end

function OutputToConsole()
    local npcBot = GetBot()
    local EnemyBots = DotaBotUtility:GetEnemyBots();
    local enemyBot = GetTeamMember(TEAM_DIRE,1);

    if(enemyBot ~= nil) then 
        npcBot:SetTarget(enemyBot)
    end

    local enemyTower = GetTower(TEAM_DIRE,TOWER_MID_1);
    local AllyTower = GetTower(TEAM_RADIANT,TOWER_MID_1);

    if MyLastGold == nil then
        MyLastGold = npcBot:GetGold()
    end

    local GoldReward = 0

    if npcBot:GetGold() - MyLastGold > 5 then
        GoldReward = (npcBot:GetGold() - MyLastGold)
    end

    if MyLastHP == nil then
        MyLastHP = npcBot:GetHealth()
    end

    

    if LastEnemyHP == nil then
        LastEnemyHP = 600
    end

    if LastDistanceToEnemy == nil then
        LastDistanceToEnemy = 2000
    end

    if LastEnemyMaxHP == nil then
        LastEnemyMaxHP = 1000
    end
    
    if(enemyBot ~= nil) then 
        EnemyHP = enemyBot:GetHealth()
        EnemyMaxHP = enemyBot:GetMaxHealth()
    else
        
        EnemyHP = 600
        EnemyMaxHP = 1000
    end

    if(enemyBot ~= nil and enemyBot:CanBeSeen()) then
        DistanceToEnemy = GetUnitToUnitDistance(npcBot,enemyBot)
        if(DistanceToEnemy > 2000) then
            DistanceToEnemy = 2000
        end
    else
        DistanceToEnemy = LastDistanceToEnemy
    end

    if EnemyHP < 0 then
        EnemyHP = LastEnemyHP
        EnemyMaxHP = LastEnemyMaxHP
    end


    if AllyTowerLastHP == nil then
        AllyTowerLastHP = AllyTower:GetHealth()
    end

    if enemyTower:GetHealth() > 0 then
        EnemyTowerHP = enemyTower:GetHealth()
    else
        EnemyTowerHP = LastEnemyTowerHP
    end

    local AllyLaneFront = GetLaneFrontLocation(DotaBotUtility:GetEnemyTeam(),LANE_MID,0)
    local EnemyLaneFront = GetLaneFrontLocation(TEAM_RADIANT,LANE_MID,0)

    local DistanceToEnemyLane = GetUnitToLocationDistance(npcBot,EnemyLaneFront)
    local DistanceToAllyLane = GetUnitToLocationDistance(npcBot,AllyLaneFront)

    local DistanceToEnemyTower = GetUnitToLocationDistance(npcBot,EnemyTowerPosition)
    local DistanceToAllyTower = GetUnitToLocationDistance(npcBot,AllyTowerPosition)

    local DistanceToLane = (DistanceToEnemyLane + DistanceToAllyLane) / 2

    if LastDistanceToLane == nil then
        LastDistanceToLane = DistanceToLane
    end

    local EnemyLocation = enemyBot:GetLocation()
    local MyLocation = npcBot:GetLocation()

    local Reward = (npcBot:GetHealth() - MyLastHP)
    - (EnemyHP - LastEnemyHP)
    + (AllyTower:GetHealth() - AllyTowerLastHP)
    - (EnemyTowerHP - LastEnemyTowerHP)
    + GoldReward

    local input = {
        npcBot:GetHealth() / npcBot:GetMaxHealth(),
        npcBot:GetMana(),
        MyLocation[1],
        MyLocation[2],
        EnemyHP / EnemyMaxHP,
        EnemyLocation[1],
        EnemyLocation[2],
        EnemyLaneFront[1],
        EnemyLaneFront[2],
        AllyLaneFront[1],
        AllyLaneFront[2],
        EnemyTowerPosition[1],
        EnemyTowerPosition[2],
        AllyTowerPosition[1],
        AllyTowerPosition[2],
        ClipTime(npcBot:TimeSinceDamagedByAnyHero()),
        ClipTime(npcBot:TimeSinceDamagedByTower()),
        ClipTime(npcBot:TimeSinceDamagedByCreep()),
        AllyTower:GetHealth()/1300,
        EnemyTowerHP/1300,
        #npcBot:GetNearbyCreeps(800,false) / 10,
        #npcBot:GetNearbyCreeps(800,true) / 10
    }

    local Q_value = DQN:ForwardProp(input)

    print("LenLRX log: ",
        npcBot:GetHealth() / npcBot:GetMaxHealth(),
        npcBot:GetMana(),
        MyLocation[1],
        MyLocation[2],
        EnemyHP / EnemyMaxHP,
        EnemyLocation[1],
        EnemyLocation[2],
        EnemyLaneFront[1],
        EnemyLaneFront[2],
        AllyLaneFront[1],
        AllyLaneFront[2],
        EnemyTowerPosition[1],
        EnemyTowerPosition[2],
        AllyTowerPosition[1],
        AllyTowerPosition[2],
        ClipTime(npcBot:TimeSinceDamagedByAnyHero()),
        ClipTime(npcBot:TimeSinceDamagedByTower()),
        ClipTime(npcBot:TimeSinceDamagedByCreep()),
        AllyTower:GetHealth()/1300,
        EnemyTowerHP/1300,
        #npcBot:GetNearbyCreeps(800,false) / 10,
        #npcBot:GetNearbyCreeps(800,true) / 10,
        Reward,
        _G.state
    )

    

    
    local max_val = -100000
    local max_idx = -1

    for i = 0 , 2 , 1 do
        if Q_value[i] > max_val then
            max_val = Q_value[i]
            max_idx = i
        end
    end

    if true or DotaTime() - LastDecesion > DeltaTime then

        _G.LaningDesire = 0.0
        _G.AttackDesire = 0.0
        _G.RetreatDesire = 0.0

        local e = 0.0

        --  e-greedy policy
        if(math.random() < e) then
            _G.LaningDesire = math.random()
            _G.AttackDesire = math.random()
            _G.AttackDesire = math.random()
        else
            if max_idx == 0 then
                _G.LaningDesire = 1.0
            elseif max_idx == 1 then
                _G.AttackDesire = 1.0
            elseif max_idx == 2 then
                _G.RetreatDesire = 1.0
            end
        end

        LastDecesion = DotaTime()
    end

    if true then
    print("Q_Values",
    Q_value[0],
    Q_value[1],
    Q_value[2],
    "max_idx:",
    max_idx
    )
    end


    if enemyTower:GetHealth() > 0 then
        LastEnemyTowerHP = enemyTower:GetHealth()
    end

    MyLastHP = npcBot:GetHealth()
    AllyTowerLastHP = AllyTower:GetHealth()
    LastEnemyHP = EnemyHP
    LastEnemyMaxHP = EnemyMaxHP
    MyLastGold = npcBot:GetGold()
    LastDistanceToLane = DistanceToLane
    LastDistanceToEnemy = DistanceToEnemy
end

if ( GetTeam() == TEAM_RADIANT ) then
    LastTime = DotaTime()
end


function BuybackUsageThink()
    if ( GetTeam() == TEAM_RADIANT and 
    (GetGameState() == GAME_STATE_GAME_IN_PROGRESS or GetGameState() == GAME_STATE_PRE_GAME) ) then
        if true or DotaTime() - LastTime > 1 then
            OutputToConsole()
            LastTime = DotaTime()
        end
    end
end