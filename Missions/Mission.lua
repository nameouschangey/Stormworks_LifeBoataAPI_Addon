-- Author: Nameous Changey
-- GitHub: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension
-- Workshop: https://steamcommunity.com/id/Bilkokuya/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

---@section Mission

---@class EventTypes.LBOnMissionComplete : LifeBoatAPI.Event
---@field register fun(self:LifeBoatAPI.Event, func:fun(l:LifeBoatAPI.IEventListener, context:any, mission:LifeBoatAPI.Mission), context:any, timesToExecute:number|nil) : LifeBoatAPI.IEventListener

---@alias LifeBoatAPI.MissionExecutionFunction fun(mission:LifeBoatAPI.MissionInstance, stage:LifeBoatAPI.MissionStageInstance, savedata:table, params:table)

---@class LifeBoatAPI.MissionManager
---@field missionTypes table<string, LifeBoatAPI.Mission>
---@field missionsByID table<number, LifeBoatAPI.MissionInstance>
---@field missionsByType table<string, LifeBoatAPI.MissionInstance[]>
---@field savedata table
LifeBoatAPI.MissionManager = {

    ---@param cls LifeBoatAPI.MissionManager
    ---@return LifeBoatAPI.MissionManager
    new = function(cls)
        local self = {
            savedata = {
                missionsByID = {}
            },
            missionsByType = {},
            missionsByID = {},
            missionTypes = {},

            --methods
            init = cls.init,
            registerMissionType = cls.registerMissionType,
            getMission = cls.getMission,
            trackInstance = cls.trackInstance,
            stopTracking = cls.stopTracking,
        }

        return self
    end;

    ---@param self LifeBoatAPI.MissionManager
    init = function(self)
        g_savedata.missionManager = g_savedata.missionManager or self.savedata
        self.savedata = g_savedata.missionManager

        for missionID, missionSave in pairs(self.savedata.missionsByID) do
            if self.missionTypes[missionSave.type] then
                local missionType = self.missionTypes[missionSave.type]
                local instance = LifeBoatAPI.MissionInstance:fromSavedata(missionType, missionSave)
                instance:runCurrent()
            else
                self.savedata.missionsByID[missionID] = nil -- remove no longer supported mission type
            end
        end
    end;

    ---@param self LifeBoatAPI.MissionManager
    ---@param id number
    getMission = function(self, id)
        return self.missionsByID[id]
    end;

    ---@param self LifeBoatAPI.MissionManager
    ---@param mission LifeBoatAPI.Mission
    registerMissionType = function(self, mission)
        self.missionTypes[mission.type] = mission
    end;

    ---@param self LifeBoatAPI.MissionManager
    ---@param missionInstance LifeBoatAPI.MissionInstance
    trackInstance = function(self, missionInstance, isTemporary)
        if missionInstance.isDisposed or self.missionsByID[missionInstance.id] then
            return
        end

        -- add to live lists
        self.missionsByID[missionInstance.id] = missionInstance
        local missionsByType = self.missionsByType[missionInstance.savedata.type]
        if not missionsByType then
            self.missionsByType[missionInstance.savedata.type] = {missionInstance}
        else
            missionsByType[#missionsByType+1] = missionInstance
        end

        -- persist if not temporary
        if not isTemporary then
            self.savedata.missionsByID[missionInstance.id] = missionInstance
        end
    end;

    ---@param self LifeBoatAPI.MissionManager
    ---@param missionInstance LifeBoatAPI.MissionInstance
    stopTracking = function(self, missionInstance)
        
        self.missionsByID[missionInstance.id] = nil
        self.savedata.missionsByID[missionInstance.id] = nil
        local missionsOfType = self.missionsByType[missionInstance.savedata.type]
        if missionsOfType then
            for i=1, #missionsOfType do
                local mission = missionsOfType[i]
                if mission.id == missionInstance.id then
                    table.remove(missionsOfType, i)
                    break
                end
            end
        end
    end;
}

---@class LifeBoatAPI.MissionStageInstance : LifeBoatAPI.IDisposable

-- like a Coroutine that's less, co-routiney?
---@class LifeBoatAPI.MissionStage
---@field onExecute LifeBoatAPI.MissionExecutionFunction
---@field id string|nil

---@class EventTypes.LBOnMissionComplete : LifeBoatAPI.Event
---@field register fun(self:LifeBoatAPI.ENVCallbackEvent, func:fun(l:LifeBoatAPI.IEventListener, context:any, mission:LifeBoatAPI.MissionInstance), context:any, timesToExecute:number|nil) : LifeBoatAPI.IEventListener


---on dispose, we kill it? right?
---@class LifeBoatAPI.MissionInstance : LifeBoatAPI.IDisposable
---@field savedata table
---@field mission LifeBoatAPI.Mission
---@field onComplete EventTypes.LBOnMissionComplete
---@field terminate fun(self:LifeBoatAPI.MissionInstance)
---@field currentStage LifeBoatAPI.MissionStageInstance
---@field id number
LifeBoatAPI.MissionInstance = {
    _generateID = function()
        g_savedata.lb_nextMissionID = g_savedata.lb_nextMissionID and (g_savedata.lb_nextMissionID + 1) or 0
        return g_savedata.lb_nextMissionID
    end;

    ---@param cls LifeBoatAPI.MissionInstance
    ---@param mission LifeBoatAPI.Mission
    ---@param savedata table
    fromSavedata = function(cls, mission, savedata)
        local self = {
            id = savedata.id,
            savedata = savedata,
            mission = mission;
            disposables = {};
            currentStage = nil;

            onComplete = LifeBoatAPI.Event:new();

            --methods 
            attach = LifeBoatAPI.lb_attachDisposable;
            onDispose = cls.onDispose;
            next = cls.next;
            terminate = LifeBoatAPI.lb_dispose;
            runCurrent = cls.runCurrent;
        }

        return self
    end;

    ---@param cls LifeBoatAPI.MissionInstance
    ---@param mission LifeBoatAPI.Mission
    ---@param isTemporary boolean|nil
    ---@param params table|nil
    new = function(cls, mission, params, isTemporary)
        local self = cls:fromSavedata(mission, {
            id = LifeBoatAPI.MissionInstance._generateID(),
            type = mission.type,
            current = 0, -- first thing we do with a new mission is call next()
        })
        
        LB.missions:trackInstance(self, isTemporary)

        self:next(nil, params)

        return self
    end;

    ---@param self LifeBoatAPI.MissionInstance
    ---@param name string|nil (optional) name to skip to, otherwise goes to the next stage numerically
    ---@param params table|nil (optional) params object to pass to the next stage, most useful for the initial spawn otherwise can pass just straight via savedata
    next = function(self, name, params)
        -- dispose of the current stage
        if self.currentStage then
            LifeBoatAPI.lb_dispose(self.currentStage)
            self.currentStage = nil
        end

        self.savedata.lastResult = params

        -- move to the next stage and run it
        self.savedata.current = (name and self.mission.stageIndexesByName[name]) or (self.savedata.current + 1)
        self:runCurrent()
    end;

    ---@param self LifeBoatAPI.MissionInstance
    runCurrent = function(self)
        local stageData = self.mission.stages[self.savedata.current]
        if not stageData then
            self:terminate()
        else
            self.currentStage = {
                stageData = stageData,
                disposables = {},
                attach = LifeBoatAPI.lb_attachDisposable
            }

            stageData.onExecute(self, self.currentStage, self.savedata, self.savedata.lastResult) -- run the next stage
        end
    end;

    ---@param self LifeBoatAPI.MissionInstance
    onDispose = function (self)
        if self.onComplete.hasListeners then
            self.onComplete:trigger(self)
        end

        if self.currentStage then
            LifeBoatAPI.lb_dispose(self.currentStage)
        end

        LB.missions:stopTracking(self)
    end;
}


-- could have the registration here too?
-- would mean that LB events onInit can be used from anywhere else - easier to connect things to
---@class LifeBoatAPI.Mission
---@field stages LifeBoatAPI.MissionStage[]
---@field stageIndexesByName table<string, number>
---@field type string
LifeBoatAPI.Mission = {

    ---@param cls LifeBoatAPI.Mission
    ---@param uniqueMissionTypeName string
    ---@return LifeBoatAPI.Mission
    new = function(cls, uniqueMissionTypeName)
        local self = {
            type = uniqueMissionTypeName,
            stages = {},
            stageIndexesByName = {},

            addStage = cls.addStage,
            addNamedStage = cls.addNamedStage,
            start = cls.start,
            startUnique = cls.startUnique,

        }

        LB.missions:registerMissionType(self)

        return self
    end;

    ---@param self LifeBoatAPI.Mission
    ---@param fun LifeBoatAPI.MissionExecutionFunction
    addStage = function(self, fun)
        self.stages[#self.stages+1] = {onExecute = fun}
    end;

    ---@param self LifeBoatAPI.Mission
    ---@param name string
    ---@param fun LifeBoatAPI.MissionExecutionFunction
    addNamedStage = function(self, name, fun)
        self.stages[#self.stages+1] = {id=name, onExecute = fun}
    end;

    ---Ensures this mission is unique, and gets the existing instance of it if one is there
    startUnique = function(self, params)
        -- find an existing version of this mission if it already exists
        local missionsOfType = LB.missions.missionsByType[self.type]
        if missionsOfType and #missionsOfType > 0 then
            return missionsOfType[1]
        else
            return self:start(params)
        end
    end;

    ---@param self LifeBoatAPI.Mission
    start = function(self, params, isTemporary)
        return LifeBoatAPI.MissionInstance:new(self, isTemporary)
    end;
}

---@endsection