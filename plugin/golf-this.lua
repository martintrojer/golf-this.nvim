vim.api.nvim_create_user_command("GolfThis", function(opts)
	require("golf_this").run(opts)
end, {
	desc = "Ask an LLM for a vimgolf-style edit solution",
	range = true,
})

vim.api.nvim_create_user_command("GolfThisHealth", function()
	require("golf_this.health").check()
end, {
	desc = "Check golf-this provider configuration and endpoint reachability",
})
