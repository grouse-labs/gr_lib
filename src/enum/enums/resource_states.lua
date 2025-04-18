---@enum resource_states
return {
	invalid = {
		[1] = "missing",
		[2] = "unknown",
		[3] = "stopped",
		[4] = "stopping"
	},
	valid = {
		[1] = "started",
		[2] = "starting"
	}
}