#!/bin/bash

USER=`whoami`

read -s -p "Password: " PWD
echo ""
if echo "#require \"simple_pam\";; Simple_pam.authenticate \"login\" \"$USER\" \"$PWD\";;" | utop -stdin; then
  echo "PAM is available"
else
  echo "Error: you entered wrong password, or PAM is not available. Install pam-devel and reinstall simple_pam if the password is correct"
  exit 2
fi

