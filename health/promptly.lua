local adapters = require("promptly.adapters")
local config = require("promptly.config")
local shared = require("promptly.adapters.shared")

local M = {}

local function has_value(v)
	return type(v) == "string" and v ~= ""
end

local function health_api()
	local h = vim.health or {}
	return {
		start = h.start or function(msg)
			vim.fn["health#report_start"](msg)
		end,
		ok = h.ok or function(msg)
			vim.fn["health#report_ok"](msg)
		end,
		warn = h.warn or function(msg)
			vim.fn["health#report_warn"](msg)
		end,
		error = h.error or function(msg)
			vim.fn["health#report_error"](msg)
		end,
		info = h.info or function(msg)
			vim.fn["health#report_info"](msg)
		end,
	}
end

function M.check()
	local health = health_api()
	health.start("promptly.nvim")

	if vim.fn.executable("curl") == 1 then
		health.ok("curl executable found")
	else
		health.error("curl executable not found; model requests will fail")
	end

	local profile_name = config.current_profile_name()
	local profile = config.current_profile()
	local profile_err = config.current_profile_error()
	if profile_err then
		health.error(profile_err)
		return
	end
	local provider_name = profile and profile.provider or nil
	local provider = config.current_provider()
	if not provider then
		health.error("configured provider '" .. tostring(provider_name) .. "' not found in setup().providers")
		return
	end

	health.info("active profile: " .. tostring(profile_name))
	health.info("active provider: " .. tostring(provider_name))

	local kind = provider.kind or "openai_compatible"
	if kind == "openai_compatible" or kind == "anthropic" then
		health.ok("provider kind: " .. kind)
	else
		health.error("unsupported provider kind: " .. tostring(kind))
	end

	if has_value(provider.url) then
		health.ok("provider url set")
		health.info("url: " .. provider.url)
	else
		health.error("provider.url is missing")
	end

	if has_value(provider.model) then
		health.ok("provider model set: " .. provider.model)
	else
		health.error("provider.model is missing")
	end

	local api_key, api_key_env = shared.get_api_key(provider)
	if api_key_env then
		if has_value(api_key) then
			health.ok("api key resolved from $" .. api_key_env)
		else
			health.error("api key env var is configured but empty: $" .. api_key_env)
		end
	elseif has_value(provider.api_key) then
		health.ok("api key configured directly")
	else
		health.warn("no api key configured (fine for local providers like ollama)")
	end

	local adapter, adapter_err = adapters.resolve(provider)
	if adapter_err then
		health.error("adapter resolve failed: " .. adapter_err)
		return
	end
	health.ok("adapter resolved")

	local validation_err = adapter.validate and adapter.validate() or nil
	if validation_err then
		health.error("adapter validation failed: " .. validation_err)
	else
		health.ok("adapter validation passed")
	end
end

return M
