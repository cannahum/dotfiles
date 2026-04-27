### --- Homebrew env (no-op if missing) ---
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  export BREW_PREFIX="/home/linuxbrew/.linuxbrew"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export BREW_PREFIX="/opt/homebrew"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
  export BREW_PREFIX="/usr/local"
else
  unset BREW_PREFIX
fi

### --- History ---
HISTFILE=$HOME/.zhistory
SAVEHIST=10000
HISTSIZE=10000
setopt share_history hist_expire_dups_first hist_ignore_dups hist_verify

### --- Keybinds ---
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[p'  history-beginning-search-backward
bindkey '^[n'  history-beginning-search-forward

### --- Prompt setup (auto-detect Omarchy/desktop colors) ---
setopt prompt_subst
PROMPT_DIRTRIM=3

# Defaults if nothing is detected
OM_PATH=${OM_PATH:-yellow}
OM_GIT_CLEAN=${OM_GIT_CLEAN:-green}
OM_GIT_DIRTY=${OM_GIT_DIRTY:-red}

_om_load_colors() {
  local f v

  # 1) User override file (create if you want explicit control)
  for f in \
    "$HOME/.config/omarchy/prompt.env" \
    "$HOME/.config/omarchy/theme/prompt.env"
  do
    [[ -r "$f" ]] && source "$f"
  done

  # 2) Waybar CSS variables (very common on Omarchy)
  #    Looks for: --accent, --success, --error, --fg
  if [[ -r "$HOME/.config/waybar/colors.css" ]]; then
    # helper to pull a CSS variable like --accent: #ff00aa;
    _cssvar() { sed -nE "s/.*--$1:\s*([^;]+);.*/\1/p" "$HOME/.config/waybar/colors.css" | tail -1; }

    v=$(_cssvar accent);  [[ -n "$v" ]] && OM_PATH="$v"
    v=$(_cssvar success); [[ -n "$v" ]] && OM_GIT_CLEAN="$v"
    v=$(_cssvar good);    [[ -n "$v" && -z "$(_cssvar success)" ]] && OM_GIT_CLEAN="$v"
    v=$(_cssvar error);   [[ -n "$v" ]] && OM_GIT_DIRTY="$v"
    v=$(_cssvar danger);  [[ -n "$v" && -z "$(_cssvar error)"   ]] && OM_GIT_DIRTY="$v"
    unset -f _cssvar
  fi

  # 3) pywal (if you use it anywhere): ~/.cache/wal/colors.json
  if [[ -r "$HOME/.cache/wal/colors.json" ]]; then
    if command -v jq >/dev/null; then
      # Use accent-ish for path, greenish for clean, reddish for dirty
      OM_PATH=${OM_PATH:-"$(jq -r '.colors.color5 // empty' "$HOME/.cache/wal/colors.json")"}
      OM_GIT_CLEAN=${OM_GIT_CLEAN:-"$(jq -r '.colors.color2 // empty' "$HOME/.cache/wal/colors.json")"}
      OM_GIT_DIRTY=${OM_GIT_DIRTY:-"$(jq -r '.colors.color1 // empty' "$HOME/.cache/wal/colors.json")"}
    else
      # crude grep fallback
      _jsonval() { grep -E "\"$1\"" "$HOME/.cache/wal/colors.json" | head -1 | sed -E 's/.*:\s*"(#?[0-9a-fA-F]+)".*/\1/'; }
      [[ -z "$OM_PATH"      ]] && OM_PATH="$(_jsonval color5)"
      [[ -z "$OM_GIT_CLEAN" ]] && OM_GIT_CLEAN="$(_jsonval color2)"
      [[ -z "$OM_GIT_DIRTY" ]] && OM_GIT_DIRTY="$(_jsonval color1)"
      unset -f _jsonval
    fi
  fi

  # 4) Kitty theme (common on Omarchy): current-theme.conf
  if [[ -r "$HOME/.config/kitty/current-theme.conf" ]]; then
    # Use color5 as accent, color2 as clean, color1 as dirty if still unset
    _kitty() { awk -v k="$1" '$1==k{print $2}' "$HOME/.config/kitty/current-theme.conf" | tail -1; }
    [[ -z "$OM_PATH"      ]] && OM_PATH="$(_kitty color5)"
    [[ -z "$OM_GIT_CLEAN" ]] && OM_GIT_CLEAN="$(_kitty color2)"
    [[ -z "$OM_GIT_DIRTY" ]] && OM_GIT_DIRTY="$(_kitty color1)"
    unset -f _kitty
  fi
}
_om_load_colors

# Build Zsh color tokens (supports names or #RRGGBB)
CLR_PATH="%F{$OM_PATH}"
CLR_GIT_CLEAN="%F{$OM_GIT_CLEAN}"
CLR_GIT_DIRTY="%F{$OM_GIT_DIRTY}"
CLR_RESET="%f"

# --- Git prompt helper: [branch] green=clean, red=dirty ---
git_prompt() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
  local b
  b=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --always 2>/dev/null)
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo "${CLR_GIT_DIRTY}[$b*]${CLR_RESET}"
  else
    echo "${CLR_GIT_CLEAN}[$b]${CLR_RESET}"
  fi
}

# Left prompt: <short-pwd> <git-segment> <#>
PROMPT="${CLR_PATH}%~${CLR_RESET} \$(git_prompt) %# "

### --- Completion system (init early) ---
autoload -Uz compinit
# -u skips insecure-dir warnings; remove -u if you prefer strictness
compinit -u

### --- QoL plugins ---
# zsh-autosuggestions
if [[ -n "$BREW_PREFIX" && -r "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -r "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

### --- fzf (with guarded previews) ---
if command -v fzf >/dev/null; then
  eval "$(fzf --zsh)"

  # base FD commands
  if command -v fd >/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
    _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
    _fzf_compgen_dir()  { fd --type=d --hidden --exclude .git . "$1"; }
  fi

  # previews only if tools exist
  if command -v eza >/dev/null && command -v bat >/dev/null; then
    show_file_or_dir_preview='if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'
    export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
  elif command -v eza >/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'eza --tree --color=always {} | head -200'"
  elif command -v bat >/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
  fi
fi

### --- bat / eza / zoxide (guarded) ---
# bat
if command -v bat >/dev/null; then
  export BAT_THEME=tokyonight_night
fi

# ls -> eza only if installed
if command -v eza >/dev/null; then
  alias ls="eza --icons=always --color=always --long --git --no-time --no-user"
fi

# zoxide
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
  # only alias cd if `z` exists to avoid breaking builtin cd
  if command -v z >/dev/null; then
    alias cd='z'
  fi
fi

### --- pnpm path ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in *":$PNPM_HOME:"*) ;; *) export PATH="$PNPM_HOME:$PATH" ;; esac

### --- mise (runtime manager) ---
if command -v mise >/dev/null; then
  eval "$(mise activate zsh)"
fi

### --- direnv ---
if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
fi

### --- Extra CLI completions (example: Temporal) ---
if command -v temporal &>/dev/null; then
  # You can also `source <(temporal completion zsh)`; eval avoids subshell
  eval "$(temporal completion zsh)"
fi

### --- Editor & handy aliases ---
export EDITOR="nvim"
alias reload-zsh="source ~/.zshrc"
alias edit-zsh="nvim ~/.zshrc"

### --- Local overrides (keep this last-ish, but before syntax-highlighting) ---
[ -f "$HOME/.zshrc_local" ] && source "$HOME/.zshrc_local"

### --- zsh-syntax-highlighting (must be last) ---
if [[ -n "$BREW_PREFIX" && -r "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -r "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
export PATH="$HOME/.local/bin:$PATH"
