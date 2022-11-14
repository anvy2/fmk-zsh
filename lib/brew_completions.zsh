function source_completions {
    local _completion_dir="/opt/homebrew/share/zsh/site-functions"
    for _f in $_completion_dir/*; do
        local match=`echo $_f | sed -nr "s/(.*)\.sh/\1/p"`
        [[ ! $match ]] && zsh-defer source $f
    done
}

if [[ $ENABLE_HOMEBREW_COMPLETIONS ]]; then
    source_completions
fi