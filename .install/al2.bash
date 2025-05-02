#!/usr/bin/env bash
# Prevents `/usr/bin/cat $HOME/.dir_colors: Is a directory`
mv $HOME/.dir_colors/* $HOME && rm -rf $HOME/.dir_colors
