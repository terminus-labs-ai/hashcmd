# hashcmd: install instructions for a coding agent

You are installing hashcmd for the user on this machine. Follow these steps in order. Ask the user only where a step says to ask. Do not change anything outside the files named here.

## 1. Check the shell and dependencies

- Run `echo $SHELL` and `zsh --version`. hashcmd works only in zsh. If the user's login shell is not zsh, stop and tell them.
- Check `command -v curl jq git`. If one is missing, install it with the system package manager (`brew install jq` on macOS; `sudo apt install -y jq curl git` on Debian/Ubuntu) after telling the user what you will install.

## 2. Get the code

```zsh
git clone https://github.com/terminus-labs-ai/hashcmd.git ~/.hashcmd
```

If `~/.hashcmd` already exists and is this repo, run `git -C ~/.hashcmd pull` instead.

## 3. Pick the endpoint and model

Ask the user which LLM endpoint to use. Offer these choices and use the matching settings:

| Choice | `HASHCMD_URL` | `HASHCMD_API_KEY` | `HASHCMD_NO_THINK` |
|---|---|---|---|
| Ollama on this machine | `http://localhost:11434/v1/chat/completions` | not set | `1` for Qwen3 models, otherwise not set |
| llama.cpp / vLLM / LM Studio server | `http://<host>:<port>/v1/chat/completions` | not set unless the server requires one | `1` for Qwen3 models, otherwise not set |
| OpenAI | `https://api.openai.com/v1/chat/completions` | the user's key | not set |
| OpenRouter | `https://openrouter.ai/api/v1/chat/completions` | the user's key | not set |

Then find the model id:

- Local servers: run `curl -s <base>/v1/models | jq -r '.data[].id'` (where `<base>` is the URL without `/chat/completions`) and let the user pick. Suggest the smallest instruction-tuned model listed. Use the id exactly as printed.
- Ollama with no models listed: suggest `ollama pull qwen3:8b` and ask before running it, since it downloads several GB.
- Hosted APIs: ask the user for the model id. A small cheap model is enough.

API key handling: never print the key, never commit it and never write it into the repo. Prefer a reference to an existing secret store or environment variable the user already has. If the user wants it in `~/.zshrc`, write it there and tell them it is stored in plain text.

## 4. Verify the endpoint before touching the shell config

Run this with the chosen values filled in and confirm it prints one shell command:

```zsh
zsh -fc 'export HASHCMD_URL=<url> HASHCMD_MODEL=<model> HASHCMD_NO_THINK=<1 or empty> HASHCMD_API_KEY=<key or empty>; source <(sed "/^zle -N/d" ~/.hashcmd/hashcmd.zsh); hashcmd_ask "print the kernel version"'
```

If it prints nothing, run the same request with `curl` directly to see the error body (wrong model id, bad key, unreachable host), fix the setting and repeat. Do not continue until this prints a command.

## 5. Add it to ~/.zshrc

Back up the file first: `cp ~/.zshrc ~/.zshrc.bak-hashcmd`. Then append this block at the end of `~/.zshrc`, after any plugin manager or oh-my-zsh setup, with only the settings that apply:

```zsh
# hashcmd: "#request" + Enter turns into a shell command
export HASHCMD_URL=<url>
export HASHCMD_MODEL=<model>
export HASHCMD_NO_THINK=1          # only for Qwen3-style local models
export HASHCMD_API_KEY=<key>       # only for hosted APIs
source ~/.hashcmd/hashcmd.zsh
```

If `~/.zshrc` is managed by a dotfiles tool (chezmoi, yadm, stow, a symlink into a repo), edit the managed source instead and apply it the way that tool expects. Tell the user which file you changed.

## 6. Confirm and hand over

- Run `zsh -ic 'whence -w _hashcmd_accept_line; zle -l | grep accept-line'` and confirm both mention hashcmd (the widget name shows as `accept-line (_hashcmd_accept_line)`).
- Tell the user to open a new terminal, type `#list the 5 largest files here`, press Enter, read the command that appears and press Enter again to run it.
- Tell them the uninstall: remove the hashcmd block from `~/.zshrc` and `rm -rf ~/.hashcmd`.
