default:
	just --justfile ~/.user.justfile --list

clone-all-repos:
	mkdir -p ~/GitHub
	cd ~/GitHub && \
		gh repo list UCEAP --no-archived --json name --template '{{'{{range .}}{{.name}}{{"\n"}}{{end}}'}}' | \
		while read name; do gh repo clone UCEAP/$name; done
