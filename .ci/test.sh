#!/bin/bash
set -e
set -o pipefail

errors=()

while read -d $'\0' customizepkgfile
do
	package="$(basename "$customizepkgfile")"
	echo "** Testing package: $package" >&2

	srcdir=$(mktemp -p /var/tmp -d)

	git clone --depth=1 "https://aur.archlinux.org/$package.git" "$srcdir"
	export CUSTOMIZEPKG_CONFIG="$(pwd)"

	(
		cd "$srcdir"
		customizepkg
	) && \
	echo "** Test for package $package PASSED" >&2 || \
	echo "** Test for package $package FAILED, recording for later" >&2 && \
	errors+=("Package $package did not pass")
	rm -r "$srcdir"
	echo ""
done < <(find -maxdepth 1 -type f -print0)

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
