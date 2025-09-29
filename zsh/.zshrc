# --- Homebrew env (safe no-op if not installed) ---
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Detect platform (optional)
if [[ "$OSTYPE" == "darwin"* ]]; then
  export BREW_PREFIX="/opt/homebrew"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  export BREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

# --- Simple prompt (let Kitty/Omarchy handle fonts/colors) ---
PROMPT='%F{cyan}%n%f@%F{magenta}%m%f %F{yellow}%~%f %# '

# --- History ---
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history hist_expire_dups_first hist_ignore_dups hist_verify

# --- Keybinds ---
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[p' history-beginning-search-backward
bindkey '^[n' history-beginning-search-forward

# --- QoL plugins ---
# zsh-autosuggestions
if [[ -r "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -r "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
# zsh-syntax-highlighting (after autosuggestions)
if [[ -r "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -r "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# fzf (with previews if bat/eza exist)
if command -v fzf >/dev/null; then
  eval "$(fzf --zsh)"
  export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
  _fzf_compgen_path() { fd --hidden --exclude .git . "$1"; }
  _fzf_compgen_dir()  { fd --type=d --hidden --exclude .git . "$1"; }
  show_file_or_dir_preview='if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'
  export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
fi

# bat / eza / zoxide
export BAT_THEME=tokyonight_night
alias ls="eza --icons=always --color=always --long --git --no-time --no-user"
eval "$(zoxide init zsh)"
alias cd="z"

# pnpm path
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in *":$PNPM_HOME:"*) ;; *) export PATH="$PNPM_HOME:$PATH" ;; esac

# ----- mise: unified runtime manager (Node/Python/Ruby/Go/Java/…) -----
if command -v mise >/dev/null; then
  eval "$(mise activate zsh)"
fi

# direnv (optional, plays nicely with mise)
if command -v direnv >/dev/null; then
  eval "$(direnv hook zsh)"
fi

# completions (example)
if command -v temporal &> /dev/null; then
  eval "$(temporal completion zsh)"
fi

# Aliases & editor
alias reload-zsh="source ~/.zshrc"
alias edit-zsh="nvim ~/.zshrc"
export EDITOR=nvim

# Local overrides
[ -f ~/.zshrc_local ] && source ~/.zshrc_local
