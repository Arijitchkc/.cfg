# Dotfiles

Neovim, tmux, starship and shell aliases, kept as a bare git repo in `~/.cfg`.
Method: https://www.atlassian.com/git/tutorials/dotfiles

## Set up on a new cluster

```bash
# 1. get the files
git clone --bare https://github.com/Arijitchkc/.cfg.git $HOME/.cfg
alias config='git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no
config checkout
```

If `checkout` says a file "would be overwritten", move that file away
(e.g. `mv ~/.tmux.conf ~/.tmux.conf.old`) and run `config checkout` again.

```bash
# 2. load the aliases (including `config`) at every login
echo 'source ~/.all_alias' >> ~/.bashrc

# 3. tmux plugin manager, then inside tmux press  prefix + I
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

4. Neovim: needs a recent `nvim` (0.10+), plus `git`, `gcc`, `ripgrep`, `fd`, `node`
   (try `module avail`). First `nvim` start installs all plugins by itself.

## Daily use

```bash
config pull                 # get changes
config status               # see what changed
config add -u               # stage edits to tracked files
config commit -m "message"
config push
```

Add a new file with `config add <path>`. Never force-push: other machines
will lose their commits.
