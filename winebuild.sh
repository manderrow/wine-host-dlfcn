#!/bin/sh -e

# echo winebuild "$@" >&2
# echo "$@" > winebuild-args-$(date --rfc-3339=ns "$@" | sed 's/ /T/' | sed 's/:/-/g' | head -c -7).txt
winebuild "$@"
