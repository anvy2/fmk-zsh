for config_file ("$ZSH"/lib/*.zsh); do
  custom_config_file="$ZSH_CUSTOM/lib/${config_file:t}"
  [[ -f "$custom_config_file" ]] && config_file="$custom_config_file"
  zsh-defer source "$config_file"
done
unset config_file
unset custom_config_file