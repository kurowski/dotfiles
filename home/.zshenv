# Read by every zsh, interactive or not — where .zshrc is interactive-only.
# Keep this file to what has to be true in both; everything else stays there.

# Agent harnesses (Claude Code and friends) never start an interactive shell.
# They source .zshrc once, serialize the resulting functions and aliases into a
# snapshot file, and replay that snapshot for each command they run. Arrays
# don't survive the round trip, so chpwd_functions comes back empty even though
# every zoxide function is restored intact.
#
# zoxide's health check tests that array and nothing else, and `zoxide init
# --cmd cd` makes cd itself the trigger, so every cd an agent ran printed a
# four-line warning claiming zoxide is initialized in the wrong place. It isn't
# — an interactive shell has __zoxide_hook in chpwd_functions, which is what the
# check is really asking about.
#
# Without a prompt loop there is no chpwd for the hook to run on, so the check
# has nothing to be right about here. Silence it where it cannot mean anything,
# and leave it armed where it can still catch a real ordering mistake. The
# unregistered hook costs nothing on its own: all it does is `zoxide add` the
# cwd, so agent navigation simply stays out of the frecency database.
[[ -o interactive ]] || export _ZO_DOCTOR=0
