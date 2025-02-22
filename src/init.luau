--!strict

local Machine = require(script:FindFirstChild("Machine"))

export type Machine = Machine.Machine

return table.freeze({
    Machine = Machine,
})
