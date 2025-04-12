#! /bin/bash

REPO=$(dirname $(realpath $0))

echo "Setting repo to '$REPO'"

cfg="$REPO/config"

if [ -a "$cfg" ]; then
	source "$cfg"

	if [ -n "${GIT_SSH_URL+x}" ]; then
		echo "GIT_SSH_URL='$GIT_SSH_URL'"
	else
		echo "'GIT_SSH_URL' not defined in '$cfg'"
		exit 1
	fi

	if [ -n "${EDITOR+x}" ]; then
		echo "EDITOR='$EDITOR'"
	else
		EDITOR='vim'
		echo "EDITOR='$EDITOR' (default)"
	fi

	if [ -n "${VIEWER+x}" ]; then
		echo "VIEWER='$VIEWER'"
	else
		VIEWER='less'
		echo "VIEWER='$VIEWER' (default)"
	fi

	if [ -d "$REPO/.git" ]; then
		echo "git already initialized"
	else
		git init && \
			git remote add origin $GIT_SSH_URL && \
			echo "Set origin '$GIT_SSH_URL'"
	fi

	functions_file="$REPO/functions.sh"

	echo "#! /bin/bash" > "${functions_file}"
	echo "REPO=$REPO" >> "${functions_file}"
	cat "$REPO/functions.template" >> "${functions_file}"

	echo "Done. Please add 'source ${functions_file}' to your .bashrc"
else
	echo "Cannot find '$cfg'"
fi



