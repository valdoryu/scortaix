#!/usr/bin/env bash
# install.sh — installs scortaix, the shell wrapper, and tab completions

set -euo pipefail

SCORTAIX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
BINARY="$BIN_DIR/scortaix"

BOLD='\033[1m'
PRIMARY='\033[0;34m'
NC='\033[0m'

echo "Installing scortaix..."
echo ""

# ── Projects directory ─────────────────────────────────────────────────────────
read -r -p "$(echo -e "${BOLD}Where are your Scortex projects?${NC} [$HOME/Projects] ")" projects_dir
projects_dir="${projects_dir:-$HOME/Projects}"
projects_dir="${projects_dir%/}"  # strip trailing slash

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/scortaix"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/config" << EOF
SCORTAIX_PROJECTS_DIR="$projects_dir"
SCORTAIX_SOURCE_DIR="$SCORTAIX_DIR"
EOF
echo "✓ Config written to $CONFIG_DIR/config"

# ── Install binary ─────────────────────────────────────────────────────────────
mkdir -p "$BIN_DIR"
cp "$SCORTAIX_DIR/scortaix" "$BINARY"
chmod +x "$BINARY"
echo "✓ Installed $BINARY"

# Warn if ~/.local/bin is not in PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    echo "  ! $BIN_DIR is not in your PATH."
    echo "    Add it to your shell config, e.g.:"
    echo -e "      fish: ${PRIMARY}fish_add_path $BIN_DIR${NC}"
    echo -e "      zsh:  ${PRIMARY}echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc${NC}"
    echo -e "      bash: ${PRIMARY}echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc${NC}"
fi

# ── Shell wrapper + completions ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Which shell do you use?${NC}"
echo "  1) fish"
echo "  2) zsh"
echo "  3) bash"
read -r -p "$(echo -e "${BOLD}Choice${NC} [1/2/3]: ")" choice
echo ""

case "$choice" in
    (1|fish)
        FISH_FUNC_DIR="$HOME/.config/fish/functions"
        FISH_COMP_DIR="$HOME/.config/fish/completions"
        mkdir -p "$FISH_FUNC_DIR" "$FISH_COMP_DIR"

        cat > "$FISH_FUNC_DIR/scortaix.fish" << 'EOF'
# scortaix shell wrapper — handles `cd` after `scortaix tree` and `scortaix clean`
function scortaix
    set -x SCORTAIX_CALL_ID (random)
    command scortaix $argv
    set -l exit_code $status
    set -l last_dir_file /tmp/scortaix-last-dir-$SCORTAIX_CALL_ID
    if contains -- $argv[1] tree clean; and test -f $last_dir_file
        cd (cat $last_dir_file)
        rm -f $last_dir_file
    end
    set -e SCORTAIX_CALL_ID
    return $exit_code
end
EOF
        cp "$SCORTAIX_DIR/completions/scortaix.fish" "$FISH_COMP_DIR/scortaix.fish"

        echo "✓ Fish wrapper installed at $FISH_FUNC_DIR/scortaix.fish"
        echo "✓ Fish completions installed at $FISH_COMP_DIR/scortaix.fish"
        echo ""
        echo -e "Reload your shell or run:  ${PRIMARY}source $FISH_FUNC_DIR/scortaix.fish${NC}"
        ;;

    (2|zsh)
        ZSHRC="$HOME/.zshrc"
        ZSH_COMP_DIR="$HOME/.local/share/zsh/site-functions"
        mkdir -p "$ZSH_COMP_DIR"
        cp "$SCORTAIX_DIR/completions/_scortaix" "$ZSH_COMP_DIR/_scortaix"

        # Avoid duplicates — check both old and new markers
        if grep -qE "# scortaix shell wrapper|# >>> scortaix >>>" "$ZSHRC" 2>/dev/null; then
            echo "! Zsh wrapper already present in $ZSHRC — skipping."
        else
            cat >> "$ZSHRC" << EOF

# >>> scortaix >>>
# scortaix shell wrapper — handles \`cd\` after \`scortaix tree\` and \`scortaix clean\`
scortaix() {
    export SCORTAIX_CALL_ID=\$RANDOM
    command scortaix "\$@"
    local exit_code=\$?
    local last_dir_file="/tmp/scortaix-last-dir-\$SCORTAIX_CALL_ID"
    if [[ "\$1" == "tree" || "\$1" == "clean" ]] && [[ -f "\$last_dir_file" ]]; then
        cd "\$(cat "\$last_dir_file")"
        rm -f "\$last_dir_file"
    fi
    unset SCORTAIX_CALL_ID
    return \$exit_code
}
fpath=("$ZSH_COMP_DIR" \$fpath)
autoload -Uz _scortaix
(( \${+functions[compdef]} )) && compdef _scortaix scortaix
# <<< scortaix <<<
EOF
            echo "✓ Zsh wrapper appended to $ZSHRC"
            echo "✓ Zsh completions installed at $ZSH_COMP_DIR/_scortaix"
            echo ""
            echo -e "Reload your shell or run:  ${PRIMARY}source $ZSHRC${NC}"
            echo "  (run 'compinit' or restart your shell to activate completions)"
        fi
        ;;

    (3|bash)
        BASHRC="$HOME/.bashrc"
        BASH_COMP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
        mkdir -p "$BASH_COMP_DIR"
        cp "$SCORTAIX_DIR/completions/scortaix.bash" "$BASH_COMP_DIR/scortaix"

        # Avoid duplicates
        if grep -q "# >>> scortaix >>>" "$BASHRC" 2>/dev/null; then
            echo "! Bash wrapper already present in $BASHRC — skipping."
        else
            cat >> "$BASHRC" << EOF

# >>> scortaix >>>
# scortaix shell wrapper — handles \`cd\` after \`scortaix tree\` and \`scortaix clean\`
scortaix() {
    export SCORTAIX_CALL_ID=\$RANDOM
    command scortaix "\$@"
    local exit_code=\$?
    local last_dir_file="/tmp/scortaix-last-dir-\$SCORTAIX_CALL_ID"
    if [[ "\$1" == "tree" || "\$1" == "clean" ]] && [[ -f "\$last_dir_file" ]]; then
        cd "\$(cat "\$last_dir_file")"
        rm -f "\$last_dir_file"
    fi
    unset SCORTAIX_CALL_ID
    return \$exit_code
}
source "$BASH_COMP_DIR/scortaix"
# <<< scortaix <<<
EOF
            echo "✓ Bash wrapper + completions appended to $BASHRC"
            echo "✓ Bash completion script installed at $BASH_COMP_DIR/scortaix"
            echo ""
            echo -e "Reload your shell or run:  ${PRIMARY}source $BASHRC${NC}"
        fi
        ;;

    (*)
        echo "! Unknown choice — binary installed but no shell wrapper set up."
        echo "  'scortaix tree' will run but won't cd automatically."
        ;;
esac

echo ""
echo -e "Done! Try: ${PRIMARY}scortaix help${NC}"
