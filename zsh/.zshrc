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

### --- Prompt (starship) ---
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

### --- Completion system (init early) ---
autoload -Uz compinit
# -u skips insecure-dir warnings; remove -u if you prefer strictness
compinit -u

### --- QoL plugins ---
# tree-sitter CLI (needed by nvim-treesitter main-branch parser builds)
# Stamp-guarded: only ever attempted once, so a slow/stuck install can't
# pile up blocking `brew install` calls across every newly opened pane.
_ts_cli_stamp="$HOME/.cache/dotfiles-tree-sitter-cli-attempted"
if [[ "$OSTYPE" == darwin* ]] && command -v brew >/dev/null && ! command -v tree-sitter >/dev/null && [[ ! -f "$_ts_cli_stamp" ]]; then
  mkdir -p "$HOME/.cache"
  touch "$_ts_cli_stamp"
  HOMEBREW_NO_AUTO_UPDATE=1 brew install tree-sitter-cli
fi
unset _ts_cli_stamp

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
  export BAT_THEME="Monokai Extended"
fi

# ls -> eza only if installed
if command -v eza >/dev/null; then
  alias ls="eza --icons=always --color=always --long --git --no-time --no-user"
fi

# zoxide
if command -v zoxide >/dev/null; then
  export _ZO_DOCTOR=0
  eval "$(zoxide init zsh)"

  # Mirrors Omarchy's own bash zd() (default/bash/aliases): real `cd` for no
  # args or a literal directory, zoxide's frecency jump only as a fallback --
  # safer than a blind `alias cd=z`, which hands every cd straight to zoxide.
  cd() {
    if (( $# == 0 )); then
      builtin cd ~ || return
    elif [[ -d $1 ]]; then
      builtin cd "$1" || return
    else
      if ! z "$@"; then
        echo "Error: Directory not found"
        return 1
      fi
    fi
  }
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

if command -v hyprlock >/dev/null; then
  alias suspend='hyprlock > /dev/null 2>&1 & systemctl suspend'
fi

### --- Local overrides (keep this last-ish, but before syntax-highlighting) ---
[ -f "$HOME/.zshrc_local" ] && source "$HOME/.zshrc_local"

### --- zsh-syntax-highlighting (must be last) ---
if [[ -n "$BREW_PREFIX" && -r "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -r "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
export PATH="$HOME/.local/bin:$PATH"
