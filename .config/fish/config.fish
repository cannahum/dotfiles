if status is-interactive
    pyenv init - | source
    # Commands to run in interactive sessions can go here
end

set -gx GOPATH $HOME/go; set -gx GOROOT $HOME/.go; set -gx PATH $GOPATH/bin $PATH; # g-install: do NOT edit, see https://github.com/stefanmaric/g

# pnpm
set -gx PNPM_HOME "/Users/cannahum/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end


alias vim='nvim'
alias vi='nvim'

