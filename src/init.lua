--!strict
--Services
--Packages
local Package = script
local Packages = Package.Parent
assert(Packages)
--Modules
--Types
--Constants
--Class
-- Packages
local ColdFusion = require(Packages:WaitForChild("ColdFusion"))
local Maid = require(Packages:WaitForChild("Maid"))

type StateSignal = RBXScriptSignal

local FSM = {}
FSM.__index = FSM

type ValueState<T> = ColdFusion.ValueState<T>
type State<T> = ColdFusion.State<T>
type StateEnumItem = EnumItem | string

type FiniteState = { [StateSignal]: StateEnumItem | () -> StateEnumItem }
type FiniteStateStates = {
	[StateEnumItem]: FiniteState,
}

export type FiniteStateMachineParameters = {
	States: FiniteStateStates,
	Start: StateEnumItem,
	Parent: (Instance | State<Instance>)?,
}

export type FiniteStateMachine = {
	Start: State<StateEnumItem>,
	Parent: State<Instance>,
	Current: State<StateEnumItem>,
	Requested: State<StateEnumItem>,
	CurrentName: State<string>,
	CurrentState: State<StateEnumItem>,
	Instance: Configuration,
}

function FSM.new(config: FiniteStateMachineParameters): FiniteStateMachine
	local _maid = Maid.new()
	local _fuse = ColdFusion.fuse(_maid)
	local _new = _fuse.new
	local _import = _fuse.import

	local _Value = _fuse.Value
	local _Computed = _fuse.Computed

	local States: State<FiniteStateStates> = _import(config.States, {}) :: any
	local Start: State<StateEnumItem> = _import(config.Start, nil) :: any
	local Requested = _Value(nil :: StateEnumItem?)
	local Current = _Computed(function(start: StateEnumItem, req: StateEnumItem?): StateEnumItem?
		if req then
			return req
		elseif start then
			return start
		end
		return nil
	end, Start, Requested)
	local CurrentName = _Computed(function(cur: StateEnumItem?): string
		if cur then
			if type(cur) == "string" then
				return cur
			else
				return cur.Name
			end
		end
		return ""
	end, Current)
	local CurrentState = _Computed(function(key: StateEnumItem?, states: FiniteStateStates): FiniteState
		assert(key ~= nil and states ~= nil)
		return states[key]
	end, Current, States)

	_Computed(function(eventRegistry: FiniteState)
		assert(eventRegistry, "Bad registry")
		local _stateMaid: Maid.Maid = Maid.new()
		_maid._stateMaid = _stateMaid

		for event: StateSignal, key: StateEnumItem | () -> StateEnumItem in pairs(eventRegistry) do
			_stateMaid:GiveTask(event:Connect(function()
				if typeof(key) == "function" then
					Requested:Set(key())
				else
					Requested:Set(key)
				end
			end))
		end
		return nil
	end, CurrentState)

	local constructor = _new("Configuration")

	local self = {
		Start = Start,
		Current = Current,
		Requested = Requested,
		CurrentName = CurrentName,
		CurrentState = CurrentState,
		["Instance"] = constructor({
			Parent = _import(config.Parent, nil),
			Name = "FSM",
		}),
	}

	setmetatable(self, FSM)

	local result: any = self
	return result
end

return FSM

