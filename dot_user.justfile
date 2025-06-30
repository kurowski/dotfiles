default:
	just --justfile ~/.user.justfile --list

clone-all-repos:
	mkdir -p ~/GitHub && pushd ~/GitHub
	gh repo list UCEAP --json name --template '{{'{{range .}}{{.name}}{{"\n"}}{{end}}'}}' | \
		while read name; do gh repo clone UCEAP/$name; done
	popd
