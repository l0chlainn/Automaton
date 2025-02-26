--!strict

local Signal = require(script.Parent.Parent:FindFirstChild("Signal"))

local Event = Signal.Event

type Event = Signal.Event

type condition = (fromState: string, ...any) -> boolean
type transition = {
    event: string,
    toState: string,
    fromStates: {string},
    condition: condition?,
}

local Machine = {}
Machine.__index = Machine

export type Machine = typeof(setmetatable({} :: {
    state: string,
    _states: {string},
    _listenersMap: {[string]: {transition}},

    stateChanging: Event,
    stateChanged: Event,
}, Machine))

local function isMachine(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Machine
end

local function createMachine(initial: string, transitions: {transition}): Machine
    local states = {initial}
    local listenersMap = {}
    for index, transition in transitions do
        local toState = transition.toState
        if not table.find(states, toState) then
            table.insert(states, toState)
        end

        local event = transition.event
        local listeners = listenersMap[event]
        if listeners then
            table.insert(listeners, transition)
        else
            listenersMap[event] = {transition}
        end
    end

    return setmetatable({
        state = initial,
        _states = states,
        _listenersMap = listenersMap,

        stateChanging = Event.new(),
        stateChanged = Event.new(),
    }, Machine)
end

function Machine.change(self: Machine, toState: string): ()
    if table.find(self._states, toState) then
        local fromState = self.state
        self.stateChanging:fire(toState, fromState)
        self.state = toState
        self.stateChanged:fire(toState, fromState)
    end
end

function Machine.fire(self: Machine, event: string, ...: any): ()
    local listeners = self._listenersMap[event]
    if listeners then
        local fromState = self.state
        for _, transition in listeners do
            local condition = transition.condition
            if
                table.find(transition.fromStates, fromState)
                and (not condition or condition(fromState, ...))
            then
                self:change(transition.toState)
                break
            end
        end
    end
end

return table.freeze({
    is = isMachine,
    new = createMachine,
})
