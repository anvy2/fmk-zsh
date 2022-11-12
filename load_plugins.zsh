is_plugin() {
  local base_dir=$1
  local name=$2
  builtin test -f $base_dir/plugins/$name/$name.plugin.zsh \
    || builtin test -f $base_dir/plugins/$name/_$name
}

# Add all defined plugins to fpath. This must be done
# before running compinit.
for plugin ($plugins); do
  if is_plugin "$ZSH/omz" "$plugin"; then
    fpath=("$ZSH/omz/plugins/$plugin" $fpath)
  elif is_plugin "$ZSH" "$plugin"; then
    fpath=("$ZSH/plugins/$plugin" $fpath)
  else
    echo "plugin '$plugin' not found"
  fi
done
compinit

for plugin ($plugins); do
  if [[ -f "$ZSH/omz/plugins/$plugin/$plugin.plugin.zsh" ]]; then
    source "$ZSH/omz/plugins/$plugin/$plugin.plugin.zsh"
  elif [[ -f "$ZSH/plugins/$plugin/$plugin.plugin.zsh" ]]; then
    source "$ZSH/plugins/$plugin/$plugin.plugin.zsh"
  fi
done
unset plugin