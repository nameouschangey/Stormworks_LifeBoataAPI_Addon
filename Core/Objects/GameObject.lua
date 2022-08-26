-- Author: Nameous Changey
-- GitHub: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension
-- Workshop: https://steamcommunity.com/id/Bilkokuya/myworkshopfiles/?appid=573090
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

---@class EventTypes.LBOnCollisionStart_GameObject : LifeBoatAPI.Event
---@field register fun(self:LifeBoatAPI.Event, func:fun(l:LifeBoatAPI.IEventListener, context:any, object:LifeBoatAPI.GameObject, collision:LifeBoatAPI.Collision, zone:LifeBoatAPI.Zone), context:any, timesToExecute:number|nil) : LifeBoatAPI.IEventListener

---@class EventTypes.LBOnDespawn_GameObject : LifeBoatAPI.Event
---@field register fun(self:LifeBoatAPI.Event, func:fun(l:LifeBoatAPI.IEventListener, context:any, object:LifeBoatAPI.GameObject), context:any, timesToExecute:number|nil) : LifeBoatAPI.IEventListener


---@class LifeBoatAPI.GameObjectSaveData : table
---@field id number
---@field type string
---@field transform LifeBoatAPI.Matrix
---@field collisionLayer string|nil nil means "not collidable"
---@field parentID number
---@field parentType string
---@field onInitScript string name of the script to execute on initialization

---@class LifeBoatAPI.GameObject : LifeBoatAPI.IDisposable
---@field savedata LifeBoatAPI.GameObjectSaveData
---@field id number id for this object, to use with game functions
---@field transform LifeBoatAPI.Matrix
---@field lastTransform LifeBoatAPI.Matrix
---@field collisionPairs table<any, LifeBoatAPI.CollisionPair>
---@field getTransform (fun(self:LifeBoatAPI.ITransform):LifeBoatAPI.Matrix)|nil if nil, it's static and the transform can be taken directly from the transform field
---@field nextUpdateTick number last tick the transform was updated, internal
---@field onDespawn EventTypes.LBOnDespawn_GameObject
---@field onCollision EventTypes.LBOnCollisionStart_GameObject
LifeBoatAPI.GameObject = {
    despawn = LifeBoatAPI.lb_dispose;
}