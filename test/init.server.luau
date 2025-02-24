--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:FindFirstChild("Packages")

local Automaton = require(Packages:FindFirstChild("Automaton"))

local Machine = Automaton.Machine

local colour = "red"
local machine = Machine.new(colour, {
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
print(`machine is a Machine: {Machine.is(machine)}`)

machine.stateChanging:connect(function(toState)
    colour = toState
    print(`colour changed to {colour}`)
end)

machine:change("purple")

print(`initial: {machine.state}`)
machine:fire("go")
print(`go: {machine.state}`)
machine:fire("yield")
print(`yield: {machine.state}`)
machine:fire("stop")
print(`stop: {machine.state}`)

machine:fire("panic", 0)
print(`panic: {machine.state}`)
machine:fire("panic", 123)
print(`panic: {machine.state}`)
