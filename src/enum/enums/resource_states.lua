---@enum resource_states
return {
	["invalid"] = {
		[1] = "missing",
		[2] = "unknown",
		[3] = "stopped",
		[4] = "stopping",
		["missing"] = 1,
		["unknown"] = 2,
		["stopped"] = 3,
		["stopping"] = 4
	},
	["valid"] = {
		[1] = "started",
		[2] = "starting",
		["started"] = 1,
		["starting"] = 2
	}
}