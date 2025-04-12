#! /bin/bash

on_add() {
	back=$(pwd)
	cd $REPO
	git add .
	git commit -m "add '$(basename $1)'"
	git push --set-upstream origin master
	cd "$back"
}

on_edit() {
	back=$(pwd)
	cd $REPO
	git add .
	git commit -m "remove '$(basename $1)' / add $(basename $2)"
	git push --set-upstream origin master
	cd "$back"
}

new() {
    TMP_FILENAME=$(uuidgen -r)
	TMP_FILE=/tmp/"$TMP_FILENAME"

	if [ -n "$1" ]; then
		touch "$TMP_FILE"
		cat "$1" > "$TMP_FILE"
	fi

	eval "$EDITOR $TMP_FILE"

	TITLE=""
	KEYWORDS=""
	while IFS= read -r LINE; do
		if [ -n "$LINE" ] \
           && [ -n "$TITLE" ] && [ -z "$KEYWORDS" ]; then
				KEYWORDS=$(echo "$LINE" | sed 's/^ *//g' \
										| sed 's/ *$//g' \
										| sed 's/, */,/g' \
										| sed 's/ *,/,/g')
		fi

		if [ -n "$LINE" ] && [ -z "$TITLE" ]; then
			TITLE=$(echo "$LINE" | sed 's/^ *//g' \
								 | sed 's/ *$//g')	
		fi
	done < "$TMP_FILE"

	TITLE_DASH=$(echo "$TITLE" | sed 's/ /-/g')

	ALL_KEYWORDS=""
	IFS=- read -ra parts <<< "$TITLE_DASH"
	for part in "${parts[@]}"; do
		  ALL_KEYWORDS="$ALL_KEYWORDS","$part"
	done

	ALL_KEYWORDS="${ALL_KEYWORDS:1}"

	if [ -n "$KEYWORDS" ]; then
		ALL_KEYWORDS="$ALL_KEYWORDS","$KEYWORDS"
	fi

	if [ ! -a "$REPO/.index" ]; then
		touch "$REPO/.index"
	fi

	#last_id=0
	x=0
	i=0
	while IFS= read -r LINE; do
		if [ -n "$LINE" ]; then
			i=$(( i + 1 ))

			if (( i == 3 )); then
				x="$(echo $LINE | cut -d: -f1)"
				break
			fi
		fi
	done < <(tac "$REPO/.index")
	
	x=$(( $x + 1 ))

	FILENAME="${x}_${TITLE_DASH}".kn

	echo "${x}:f:$FILENAME" >> "$REPO/.index"
	echo "${x}:t:$TITLE" >> "$REPO/.index"
	echo "${x}:k:$ALL_KEYWORDS" >> "$REPO/.index"

	mv "$TMP_FILE" "$REPO/$FILENAME"

	added="$REPO/$FILENAME"
}

find() {
	titles=$(cat "$REPO/.index" \
		| grep -E "^[0-9]*:k:.*$" \
		| grep "$1" \
		| cut -d: -f1 \
		| xargs -I {} grep -E '^{}:t:.*$' "$REPO/.index" \
		| cut -d: -f3 | tr '\n' ';')

	IFS=';' read -a options <<< "$titles"

	select name in "${options[@]}"
    do
		file=$(grep -E "^[0-9]*:t:$name$" "$REPO/.index" \
				| cut -d: -f1 \
				| xargs -I {} grep -E "^{}:f:.*$" "$REPO/.index" \
				| cut -d: -f3)
		break
	done

	found="$file"
}

delete_by_file() {
	id=$(basename "$1" | cut -d\_ -f1)
	index_file="$REPO/.index"

	cat "$index_file" \
		| grep -E -v "^${id}:.*$" > "$REPO/.index.new"
	mv "${index_file}" "$REPO/.index.old"
	mv "$REPO/.index.new" "$REPO/.index"
	rm "$1"
}

COMMAND=$1
ARG_1=$2
REPO=$(dirname $(realpath $0))

if [ "$COMMAND" = "new" ]
  then
    new
	on_add "$added"
elif [ "$COMMAND" = 'find' ]
  then
	find "$ARG_1"
	less "$REPO/$found"
elif [ "$COMMAND" = 'edit' ]
  then
	find "$ARG_1"

	if [ -n "$REPO/$found" ]; then
		new "$REPO/$found"
		delete_by_file "$REPO/$found"
		on_edit "$REPO/$found" "$added"
	else
		echo "Nothing found for $ARG_1"
	fi
else
	echo "Unknown command $COMMAND"
fi

