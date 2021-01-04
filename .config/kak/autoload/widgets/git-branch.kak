##
## git-branch.kak by lenormf
## Store the current git branch that contains the buffer
## https://github.com/mawww/kakoune/wiki/Status-line#git-branch-integration
##

declare-option -docstring "name of the git branch holding the current buffer" \
    str modeline_git_branch

hook global WinCreate .* %{
    hook window NormalIdle .* %{ evaluate-commands %sh{
        branch=$(cd "$(dirname "${kak_buffile}")" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [ -n "${branch}" ]; then
            printf 'set window modeline_git_branch %%{%s}' "${branch}"
        fi
    } }
}

