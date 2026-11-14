# hashcmd: type "#<what you want>" at the zsh prompt and press Enter.
# An LLM replaces the line with one shell command. Nothing runs until you
# press Enter again. Lines that don't start with "#" run normally.
#
# Settings (set them before this file is sourced, e.g. in ~/.zshrc):
#   HASHCMD_URL     OpenAI-compatible chat completions URL
#                   (default: http://localhost:11434/v1/chat/completions, Ollama)
#   HASHCMD_MODEL   model id the endpoint serves (required)
#   HASHCMD_API_KEY bearer token, only for hosted APIs (optional)
#   HASHCMD_NO_THINK=1  ask Qwen-style local models to skip thinking (faster);
#                   leave unset for hosted APIs, which reject the extra field
#   HASHCMD_TIMEOUT seconds to wait for an answer (default: 30)

: ${HASHCMD_URL:=http://localhost:11434/v1/chat/completions}
: ${HASHCMD_TIMEOUT:=30}

hashcmd_ask() {
  local -a auth
  [[ -n $HASHCMD_API_KEY ]] && auth=(-H "Authorization: Bearer $HASHCMD_API_KEY")
  jq -n --arg m "$HASHCMD_MODEL" --arg q "$1" --arg os "$(uname -s)" --arg pwd "$PWD" \
        --arg nothink "${HASHCMD_NO_THINK:-}" '{
    model: $m, temperature: 0.1, max_tokens: 300,
    messages: [
      {role: "system", content: ("You translate a request into exactly one zsh command for " + $os + ". The current directory is " + $pwd + ". Output only the command on one line. No explanation, no markdown, no code fences, no backticks.")},
      {role: "user", content: $q}
    ]} + (if $nothink == "1" then {chat_template_kwargs: {enable_thinking: false}} else {} end)' |
  curl -s -m "$HASHCMD_TIMEOUT" "$HASHCMD_URL" -H 'Content-Type: application/json' "${auth[@]}" -d @- |
  jq -r '.choices[0].message.content // empty | gsub("<think>[\\s\\S]*?</think>"; "")' |
  sed -e '/^```/d' -e 's/^`//' -e 's/`$//' -e '/^[[:space:]]*$/d' | head -n 1
}

_hashcmd_accept_line() {
  if [[ $BUFFER == '#'* ]]; then
    if [[ -z $HASHCMD_MODEL ]]; then
      zle -M "hashcmd: set HASHCMD_MODEL first"
      return
    fi
    zle -M "hashcmd: asking $HASHCMD_MODEL..."
    zle -R
    local cmd=$(hashcmd_ask "${BUFFER#\#}")
    if [[ -n $cmd ]]; then
      BUFFER=$cmd
      CURSOR=${#BUFFER}
      zle -M ""
    else
      zle -M "hashcmd: no answer from $HASHCMD_MODEL at $HASHCMD_URL"
    fi
  else
    zle .accept-line
  fi
}
zle -N accept-line _hashcmd_accept_line
