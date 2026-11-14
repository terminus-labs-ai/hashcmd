# hashcmd

Type what you want as a comment at the zsh prompt, press Enter, and an LLM replaces the line with the command. Nothing runs until you press Enter a second time.

```
$ #find python files changed in the last 2 days     ← you type this, press Enter
$ find . -name "*.py" -mtime -2                      ← the line becomes this; Enter runs it
```

Lines that don't start with `#` run as usual. The widget is one zsh file. It needs `curl` and `jq`, and it works with any endpoint that speaks the OpenAI chat completions API: Ollama, llama.cpp `llama-server`, vLLM, LM Studio, OpenAI or OpenRouter.

## Install

To have a coding agent install and configure it, point the agent at [INSTALL.md](INSTALL.md).

To install by hand:

1. Install `curl` and `jq` (`brew install jq` on macOS, `sudo apt install jq curl` on Debian/Ubuntu).
2. Clone the repo:

   ```zsh
   git clone https://github.com/terminus-labs-ai/hashcmd.git ~/.hashcmd
   ```

3. Add your settings and the `source` line to the end of `~/.zshrc`. For a local Ollama:

   ```zsh
   export HASHCMD_URL=http://localhost:11434/v1/chat/completions
   export HASHCMD_MODEL=qwen3:8b
   source ~/.hashcmd/hashcmd.zsh
   ```

4. Open a new terminal and type `#print the kernel version`.

## Settings

| Variable | Default | Meaning |
|---|---|---|
| `HASHCMD_URL` | `http://localhost:11434/v1/chat/completions` | Chat completions URL of the endpoint. |
| `HASHCMD_MODEL` | none (required) | Model id exactly as the endpoint lists it at `/v1/models`. |
| `HASHCMD_API_KEY` | none | Bearer token. Set it only for hosted APIs. |
| `HASHCMD_NO_THINK` | unset | `1` sends `chat_template_kwargs.enable_thinking=false`, which makes Qwen3-style local models answer without a reasoning pass. Leave it unset for hosted APIs, which can reject unknown request fields. |
| `HASHCMD_TIMEOUT` | `30` | Seconds to wait for an answer. |

The model sees your request, your OS name (`uname -s`) and the current directory path. It does not see file contents, history or environment variables.

## Choosing a model

A small fast model is the right fit: the job is one line of shell. In testing against a llama.cpp server running a small Qwen model with `HASHCMD_NO_THINK=1`, answers took about 1 second once the model was loaded. The first request after a model loads can take much longer while it starts.

## Safety

The command is generated, not checked. Read it before the second Enter, because a model can return a command that is wrong or destructive. The widget never executes anything itself; it only edits the line.

## Troubleshooting

- `hashcmd: set HASHCMD_MODEL first`: the variable is empty in this shell. Set it in `~/.zshrc` before the `source` line and open a new terminal.
- `hashcmd: no answer from ...`: test the endpoint directly. In zsh, `hashcmd_ask 'list files'` prints the model's answer or nothing. If it prints nothing, check `curl $HASHCMD_URL` reachability, the model id and the API key.
- Enter behaves strangely with other plugins: hashcmd replaces zsh's `accept-line` widget. Source it after plugins that also wrap `accept-line` (zsh-autosuggestions, zsh-syntax-highlighting) are loaded.

## Uninstall

Remove the `HASHCMD_*` lines and the `source` line from `~/.zshrc`, then `rm -rf ~/.hashcmd`.
