#!/usr/bin/env bash
# Prevents `/usr/bin/cat $HOME/.dir_colors: Is a directory`
mv $HOME/.dir_colors/* . && rm -rf $HOME/.dir_colors
