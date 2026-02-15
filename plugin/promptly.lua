vim.api.nvim_create_user_command("Promptly", function(opts)
	require("promptly").run(opts)
end, {
	desc = "Ask an LLM for editing suggestions",
	range = true,
})

vim.api.nvim_create_user_command("PromptlyHealth", function()
	require("promptly.health").check()
end, {
	desc = "Check promptly provider/profile configuration and endpoint reachability",
})
