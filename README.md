# dotfiles

## Installation

Clone the repository (including submodules):

```shell
git clone https://github.com/Tseing/dotfiles.git ~/dotfiles
```

Run the installation script:

```shell
bash ~/dotfiles/install.sh
```

This will create necessary symlinks to `$HOME` directory.

## Emacs (.emacs.d)


This configuration uses [lsp-bridge](https://github.com/manateelazycat/lsp-bridge) for fast LSP support.

Requirements:
- [uv](https://docs.astral.sh/uv/#installation)

```shell
mkdir -p ~/.local/bin
ln -sf ~/.emacs.d/straight/repos/lsp-bridge/python-lsp-bridge ~/.local/bin/python-lsp-bridge
chmod +x ~/.emacs.d/straight/repos/lsp-bridge/python-lsp-bridge
```

### Python LSP

Requirements:
- [pipx](https://pipx.pypa.io/stable/how-to/install-pipx/)

```shell
pipx install basedpyright
```

Then clone grammar repo and compile parser:

```elisp
M-x treesit-install-language-grammar
python
```

### Rust LSP

```shell
rustup component add rust-analyzer
rustup component add rust-src
```

```elisp
M-x treesit-install-language-grammar
rust
```

### Package Dependencies

```shell
# enchant
sudo dnf install enchant2-devel pkgconf-pkg-config hunspell hunspell-en-US

# ripgrep
sudo dnf install ripgrep
```

## Update

```shell
cd ~/dotfiles
git pull
```
