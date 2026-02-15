# promptly.nvim

`promptly.nvim` is a Neovim plugin for prompt-driven editing suggestions.

## What it does

- `:Promptly` opens an inline prompt input over your current buffer.
- Sends prompt + editor context (current line, optional selection, buffer excerpt).
- Shows explanation, steps, and one or more suggestions.
- Applies suggestions directly to the current buffer.

Supported suggestion kinds:
- `keys`
- `replace_selection`
- `replace_buffer`
- `ex_command`

## Install

Repository: [https://github.com/martintrojer/promptly.nvim](https://github.com/martintrojer/promptly.nvim)

## API keys

Use environment variables for API keys.

```bash
export OPENAI_API_KEY="..."
export OPENROUTER_API_KEY="..."
export ANTHROPIC_API_KEY="..."
```

## Configuration

```lua
require("promptly").setup({
  profile = "promptly",

  providers = {
    openrouter = {
      kind = "openai_compatible",
      url = "https://openrouter.ai/api/v1/chat/completions",
      model = "anthropic/claude-3.5-sonnet",
      api_key_env = "OPENROUTER_API_KEY",
    },
  },

  profiles = {
    promptly = {
      provider = "openrouter",
      include_in_prompt = "use lazyvim key bindings",
      context = {
        max_context_lines = 400,
        include_current_line = true,
        include_selection = true,
      },
      apply = {
        default = "first_suggestion",
        handlers = {
          keys = "feedkeys",
          replace_selection = "replace_selection",
          replace_buffer = "replace_buffer",
          ex_command = "nvim_cmd",
        },
      },
      ui = {
        prompt_title = " Promptly Prompt ",
        result_title = " Promptly Suggestions ",
      },
    },
  },
})
```

## Commands

- `:Promptly`
- `:PromptlyHealth`

## Usage

- `:Promptly` for current-line context.
- `:'<,'>Promptly` for range/Visual context.

In result popup:
- `<Esc>` or `q`: close
- `<CR>`: apply suggestion #1
- `1-9`: apply suggestion
