--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Signal = require(Packages:FindFirstChild("Signal"))

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
    if type(initial) ~= "string" then
        error(`expected string for initial, got '{typeof(initial)}'`, 2)
    elseif type(transitions) ~= "table" then
        error(`expected table for transitions, got '{typeof(transitions)}'`, 2)
    end

    local states = {initial}
    local listenersMap = {}
    for index, transition in transitions do
        if type(transition) ~= "table" then
            error(`expected table for transitions[{index}], got '{typeof(transition)}'`, 2)
        end

        local event = transition.event
        local toState = transition.toState
        local fromStates = transition.fromStates
        local condition = transition.condition
        if type(event) ~= "string" then
            error(`expected string for transitions[{index}].event, got '{typeof(event)}'`, 2)
        elseif type(toState) ~= "string" then
            error(`expected string for transitions[{index}].toState, got '{typeof(toState)}'`, 2)
        elseif type(fromStates) ~= "table" then
            error(`expected table for transitions[{index}].fromStates, got '{typeof(fromStates)}'`, 2)
        elseif condition ~= nil and type(condition) ~= "function" then
            error(`expected function for transitions[{index}].condition, got '{typeof(condition)}'`, 2)
        end

        local listeners = listenersMap[event]
        if listeners then
            table.insert(listeners, transition)
        else
            listenersMap[event] = {transition}
        end
        if not table.find(states, toState) then
            table.insert(states, toState)
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
    if not isMachine(self) then
        error(`expected Machine for self, got '{typeof(self)}'`, 2)
    elseif type(toState) ~= "string" then
        error(`expected string for toState, got '{typeof(toState)}'`, 2)
    end

    if table.find(self._states, toState) then
        local fromState = self.state
        self.stateChanging:fire(toState, fromState)
        self.state = toState
        self.stateChanged:fire(toState, fromState)
    else
        -- this should maybe be an error instead,
        -- but further consideration must be made.
        warn(`attempted to change to an invalid state '{toState}'`)
    end
end

function Machine.fire(self: Machine, event: string, ...: any): ()
    if not isMachine(self) then
        error(`expected Machine for self, got '{typeof(self)}'`, 2)
    elseif type(event) ~= "string" then
        error(`expected string for event, got '{typeof(event)}'`, 2)
    end

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
