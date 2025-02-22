--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Automaton = require(Packages:FindFirstChild("Automaton"))

local colour = "red"
local automaton = Automaton.createAutomaton(colour, {
    {
        event = "panic",
        toState = "emergency",
        fromStates = {"green", "yellow", "red",},
        condition = function(_, code)
            return code == 123
        end,
    },
    {
        event = "go",
        toState = "green",
        fromStates = {"red",},
    },
    {
        event = "yield",
        toState = "yellow",
        fromStates = {"green",},
    },
    {
        event = "stop",
        toState = "red",
        fromStates = {"yellow",},
    },
})
print(`automaton is an Automaton: {Automaton.isAutomaton(automaton)}`)

automaton.stateChanging:connect(function(toState)
    colour = toState
    print(`colour changed to {colour}`)
end)

automaton:change("purple")

print(`initial: {automaton.state}`)
automaton:trigger("go")
print(`go: {automaton.state}`)
automaton:trigger("yield")
print(`yield: {automaton.state}`)
automaton:trigger("stop")
print(`stop: {automaton.state}`)

automaton:trigger("panic", 0)
print(`panic: {automaton.state}`)
automaton:trigger("panic", 123)
print(`panic: {automaton.state}`)
