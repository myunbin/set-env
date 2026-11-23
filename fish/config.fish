if status is-interactive
    # Commands to run in interactive sessions can go here
end
set -gx TERM xterm-256color
set -gx COLORTERM truecolor
fish_add_path --path "$HOME/.local/bin"
