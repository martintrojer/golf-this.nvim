# golf-this.nvim

`golf-this.nvim` is a Neovim plugin prototype for vimgolf-style editing prompts.

## What it does

- `:GolfThis` opens an inline prompt input over your current buffer.
- Uses async model requests (no editor freeze on Neovim 0.10+).
- Sends your prompt with context:
  - current cursor line (always)
  - selected range text (when using range/Visual)
  - buffer excerpt
- Shows inline response with:
  - short explanation
  - step-by-step approach
  - optional executable key sequence
- `<Esc>` closes the popup.
- `<CR>` runs "Do It" (feeds the returned key sequence into Neovim) and closes.

## Libraries

- Inline UI: [MunifTanjim/nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- Model transport: async HTTP via `vim.system` (Neovim 0.10+) with optional fallback to [nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Model API shape:
  - Remote: OpenAI-compatible APIs (`openai`, `openrouter`) and native `anthropic`
  - Local: Ollama OpenAI-compatible endpoint

## Install

Repository: [https://github.com/martintrojer/golf-this.nvim](https://github.com/martintrojer/golf-this.nvim)

## API keys (recommended)

Use environment variables for API keys. Do not put raw API keys in your Neovim config.

```bash
export OPENAI_API_KEY="..."
export OPENROUTER_API_KEY="..."
export ANTHROPIC_API_KEY="..."
```

`api_key_env` must be the variable name (for example `"OPENROUTER_API_KEY"`), not the key value.

If omitted, `golf-this` infers defaults for common providers:
- `openai` or `api.openai.com` -> `OPENAI_API_KEY`
- `openrouter` or `openrouter.ai` -> `OPENROUTER_API_KEY`
- `anthropic` or `anthropic.com` -> `ANTHROPIC_API_KEY`

`golf-this` can also infer provider defaults (`kind`, `url`, and default model) from provider name/URL family for:
- OpenAI
- OpenRouter
- Anthropic
- Ollama

For these built-in providers, `kind`, `url`, `model`, and `api_key_env` are optional unless you want custom overrides.

### lazy.nvim

Minimal setup (provider internals inferred):

```lua
require("golf_this").setup({
  provider = "openrouter", -- openai | openrouter | anthropic | ollama
  include_in_prompt = "use lazyvim key bindings", -- optional
})
```

```lua
{
  "martintrojer/golf-this.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim", -- fallback HTTP path for older Neovim
  },
  config = function()
    require("golf_this").setup({
      provider = "openai", -- openai | openrouter | anthropic | ollama
      include_in_prompt = "use lazyvim key bindings", -- optional
      providers = {
        openai = {
          kind = "openai_compatible", -- optional
          url = "https://api.openai.com/v1/chat/completions", -- optional
          model = "gpt-4.1-mini", -- optional
          api_key_env = "OPENAI_API_KEY", -- optional
        },
        openrouter = {
          kind = "openai_compatible", -- optional
          url = "https://openrouter.ai/api/v1/chat/completions", -- optional
          model = "anthropic/claude-3.5-sonnet", -- optional
          api_key_env = "OPENROUTER_API_KEY", -- optional
          referer = "https://your-site.example", -- optional, recommended by OpenRouter
          title = "golf-this.nvim", -- optional
        },
        anthropic = {
          kind = "anthropic", -- optional
          url = "https://api.anthropic.com/v1/messages", -- optional
          model = "claude-3-5-sonnet-latest", -- optional
          api_key_env = "ANTHROPIC_API_KEY", -- optional
          anthropic_version = "2023-06-01", -- optional
          max_tokens = 600, -- optional
        },
        ollama = {
          kind = "openai_compatible", -- optional
          url = "http://localhost:11434/v1/chat/completions", -- optional
          model = "qwen2.5-coder:7b", -- optional
          api_key_env = nil, -- optional
        },
      },
    })
  end,
}
```

### vim-plug

```vim
Plug 'martintrojer/golf-this.nvim'
Plug 'MunifTanjim/nui.nvim'
Plug 'nvim-lua/plenary.nvim'
```

Then configure in Lua:

```lua
require("golf_this").setup({
  provider = "openai",
})
```

## Local development

Clone locally:

```bash
git clone https://github.com/martintrojer/golf-this.nvim ~/code/golf-this.nvim
```

Use local path with lazy.nvim:

```lua
{
  dir = "~/code/golf-this.nvim",
  name = "golf-this.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("golf_this").setup({
      provider = "openai",
      include_in_prompt = "use lazyvim key bindings", -- optional
    })
  end,
}
```

If you edit help docs, regenerate tags:

```vim
:helptags ~/code/golf-this.nvim/doc
```

## Usage

- Current line context (default): `:GolfThis`
- Visual/range context:
  1. Select lines in Visual mode.
  2. Run `:'<,'>GolfThis`
- Health check:
  - Run `:GolfThisHealth` to validate provider config, key resolution, and endpoint reachability.
  - Run `:checkhealth golf_this` for Neovim health-style diagnostics.
- Prompt customization:
  - `include_in_prompt` appends a static instruction to every request.
  - Example: `include_in_prompt = "use lazyvim key bindings"`.

In the response popup:
- Press `<Esc>` or `q` to close.
- Press `<CR>` to run returned keys.

## Vim docs

- Help file: `doc/golf-this.txt`
- After install, run `:helptags ALL` (or your plugin manager’s helptags hook), then use `:help golf-this`.

## Model Output Contract

The plugin asks the model to return JSON:

```json
{
  "explanation": "short explanation",
  "steps": ["step 1", "step 2"],
  "keys": "normal-mode-key-sequence"
}
```

If `keys` is empty or missing, "Do It" is unavailable.
