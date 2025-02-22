--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Signal = require(Packages:FindFirstChild("Signal"))

type Signal = Signal.Signal

type condition = (fromState: string, ...any) -> boolean
type transition = {
    event: string,
    toState: string,
    fromStates: {string},
    condition: condition?,
}

local Automaton = {}
Automaton.__index = Automaton

export type Automaton = typeof(setmetatable({} :: {
    state: string,
    _states: {string},
    _listenersMap: {[string]: {transition}},

    stateChanging: Signal,
    stateChanged: Signal,
}, Automaton))

local function isAutomaton(value: any): boolean
    return type(value) == "table" and getmetatable(value) == Automaton
end

local function createAutomaton(initial: string, transitions: {transition}): Automaton
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

        stateChanging = Signal.createSignal(),
        stateChanged = Signal.createSignal(),
    }, Automaton)
end

function Automaton.change(self: Automaton, toState: string): ()
    if not isAutomaton(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
    elseif type(toState) ~= "string" then
        error(`expected string for toState, got '{typeof(toState)}'`, 2)
    end

    if table.find(self._states, toState) then
        local fromState = self.state
        self.stateChanging:trigger(toState, fromState)
        self.state = toState
        self.stateChanged:trigger(toState, fromState)
    else
        -- this should maybe be an error instead,
        -- but further consideration must be made.
        warn(`attempted to change to an invalid state '{toState}'`)
    end
end

function Automaton.trigger(self: Automaton, event: string, ...: any): ()
    if not isAutomaton(self) then
        error(`expected Automaton for self, got '{typeof(self)}'`, 2)
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
    isAutomaton = isAutomaton,
    createAutomaton = createAutomaton,
})
