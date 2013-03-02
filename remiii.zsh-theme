# vim:ft=zsh ts=2 sw=2 sts=2
#
# remiii's Theme - https://gist.github.com/4140040
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
SEGMENT_SEPARATOR='⮀'

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Simple segment
prompt_simple_segment() {
  [[ -n $1 ]] && echo -n $1
  echo -n "\n"
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`
  prompt_segment default default "[%(!.%{%F{yellow}%}.)%{%F{red}%}$user%{%f%}@%{%F{green}%}%m%{%f%}]"
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ZSH_THEME_GIT_PROMPT_DIRTY='±'
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
    fi
    echo -n "${ref/refs\/heads\//⭠ }$dirty"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue black '%~'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local alerts
  local alertRoot
  alerts=()
  alertRoot=()
  [[ $RETVAL -ne 0 ]] && alerts+=" %{%F{red}%}✘"
  [[ $UID -eq 0 ]] && alertRoot+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && alerts+=" %{%F{cyan}%}⚙"

  [[ -n "$alerts" ]] && prompt_simple_segment "$alerts"
  [[ -n "$alertRoot" ]] && prompt_segment black default "$alertRoot"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_dir
  prompt_git
  prompt_end
}

## Right prompt
build_right_prompt() {
  prompt_context
}

RPROMPT='$(build_right_prompt)%{%f%b%k%}'
PROMPT='%{%f%b%k%}$(build_prompt) '
