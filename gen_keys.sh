#!/bin/bash

echo "This step will generate the SSH ed25519 keys needed to authorize you as a deploy key on the MOBIUS GitHub."
echo "The steps are identical to those on this page: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent"
echo ""
echo "Note for Mac users: you need to add MAC=yes in your .env file for this to work"
echo ""
read -p "Enter your GitHub email: " gh_email
echo ""
echo "The new key will be stored in ~/.ssh/$key_name."
echo ""
echo "When asked for a passphrase, this is **NOT** your Github password -- this is a passphrase which locally encrypts the SSH key. The choice to do this is at your own discretion."
echo ""

ssh-keygen -t ed25519 -C "$gh_email" -f $HOME/.ssh/$key_name
eval "$(ssh-agent -s)"
if [[ -z $MAC && "$MAC" == "yes" ]]
then
        ssh-add --apple-use-keychain ~/.ssh/$key_name
else
        ssh-add ~/.ssh/$key_name
fi

echo ""

case $? in 
        0 ) 
                echo "Key generation successful"; 
                echo ""; 

                exit
                ;;
        * ) echo "Errors detected in keygen."; exit;;
esac

echo ""
