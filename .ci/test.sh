#!/bin/bash
set -e
set -o pipefail

errors=()

while read -d $'\0' customizepkgfile
do
	# ignore certain standard files
	case "$customizepkgfile" in
	*.md)
		continue
		;;
	esac

	package="$(basename "$customizepkgfile")"
	echo "** Testing package: $package" >&2

	srcdir=$(mktemp -p /var/tmp -d)

	git_url=$(grep -Po "^$package\s+\K.+" .sources)
	git clone --depth=1 "$git_url" "$srcdir"
	export CUSTOMIZEPKG_CONFIG="$(pwd)"

	(
		cd "$srcdir"
		customizepkg
	) || \
	errors+=("Package $package did not pass")
	rm -r "$srcdir"
	echo ""
done < <(find -maxdepth 1 -type f -not -name '.*' -print0)

if [ "${#errors}" -gt 0 ]
then
	echo "Following ERRORs occurred:" >&2
	for error in "${errors[@]}"
	do
		echo "  - $error" >&2
	done
	exit 1
else
	echo "All tests passed, OK." >&2
fi
