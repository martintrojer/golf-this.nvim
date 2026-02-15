local M = {}

local defaults = {
	provider = "openai",
	include_in_prompt = "",
	providers = {
		openai = {
			kind = "openai_compatible",
			url = "https://api.openai.com/v1/chat/completions",
			model = "gpt-4.1-mini",
			api_key_env = "OPENAI_API_KEY",
		},
		openrouter = {
			kind = "openai_compatible",
			url = "https://openrouter.ai/api/v1/chat/completions",
			model = "anthropic/claude-3.5-sonnet",
			api_key_env = "OPENROUTER_API_KEY",
			referer = nil,
			title = "golf-this.nvim",
		},
		anthropic = {
			kind = "anthropic",
			url = "https://api.anthropic.com/v1/messages",
			model = "claude-3-5-sonnet-latest",
			api_key_env = "ANTHROPIC_API_KEY",
			anthropic_version = "2023-06-01",
			max_tokens = 600,
		},
		ollama = {
			kind = "openai_compatible",
			url = "http://localhost:11434/v1/chat/completions",
			model = "qwen2.5-coder:7b",
			api_key_env = nil,
		},
	},
	max_context_lines = 400,
}

M.values = vim.deepcopy(defaults)

local function detect_family(provider_name, provider)
	local name = tostring(provider_name or ""):lower()
	local url = type(provider.url) == "string" and provider.url:lower() or ""
	local kind = type(provider.kind) == "string" and provider.kind:lower() or ""

	if name:find("openrouter", 1, true) or url:find("openrouter%.ai") then
		return "openrouter"
	end
	if name:find("anthropic", 1, true) or url:find("anthropic%.com") or kind == "anthropic" then
		return "anthropic"
	end
	if name:find("ollama", 1, true) or url:find("localhost:11434", 1, true) or url:find("127%.0%.0%.1:11434") then
		return "ollama"
	end
	if name:find("openai", 1, true) or url:find("api%.openai%.com") then
		return "openai"
	end

	return nil
end

local function apply_inferred_defaults(provider_name, provider)
	local family = detect_family(provider_name, provider)
	if not family then
		return
	end

	if family == "openrouter" then
		provider.kind = provider.kind or "openai_compatible"
		provider.url = provider.url or "https://openrouter.ai/api/v1/chat/completions"
		provider.model = provider.model or "anthropic/claude-3.5-sonnet"
		provider.title = provider.title or "golf-this.nvim"
		if not provider.api_key and not provider.api_key_env then
			provider.api_key_env = "OPENROUTER_API_KEY"
		end
		return
	end

	if family == "anthropic" then
		provider.kind = provider.kind or "anthropic"
		provider.url = provider.url or "https://api.anthropic.com/v1/messages"
		provider.model = provider.model or "claude-3-5-sonnet-latest"
		provider.anthropic_version = provider.anthropic_version or "2023-06-01"
		provider.max_tokens = provider.max_tokens or 600
		if not provider.api_key and not provider.api_key_env then
			provider.api_key_env = "ANTHROPIC_API_KEY"
		end
		return
	end

	if family == "ollama" then
		provider.kind = provider.kind or "openai_compatible"
		provider.url = provider.url or "http://localhost:11434/v1/chat/completions"
		provider.model = provider.model or "qwen2.5-coder:7b"
		return
	end

	if family == "openai" then
		provider.kind = provider.kind or "openai_compatible"
		provider.url = provider.url or "https://api.openai.com/v1/chat/completions"
		provider.model = provider.model or "gpt-4.1-mini"
		if not provider.api_key and not provider.api_key_env then
			provider.api_key_env = "OPENAI_API_KEY"
		end
	end
end

function M.setup(opts)
	M.values = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

function M.current_provider()
	local provider_name = M.values.provider
	local provider = M.values.providers[provider_name]
	if not provider then
		return nil
	end

	local resolved = vim.deepcopy(provider)
	apply_inferred_defaults(provider_name, resolved)
	return resolved
end

return M
