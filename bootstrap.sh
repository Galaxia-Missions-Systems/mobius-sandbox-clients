#!/bin/bash

# The steps go:
# 0. Clone mobius-sandbox-clients repo.
# 1. Get client ID + derive other vars.
# 2. Generate build script (generates template container).
# 3. Generate the client's SSH deploy key (or let them use their own).
#       a. Ask them to send it to us to give them write permissions to mobius-sandbox-clients.
#       b. We also need to give them read permissions for mobius-sandbox
#       c. They need to give us their GitHub usernames to be added as collabs.
# ######## FOLLOWING STEPS REQUIRE AUTH ############################
# 4. Fetch the mobius-sandbox repo (obtains the build environment).
#       a. Run the necessary setup scripts in there.
# 5. Build the template container and push to their 'parking spot'
# 6. Let the client take over from there.

# Keys:
# 1. mobius-sandbox-clients 
#       a. Deploy keys (read/write)
# 2. mobius-sandbox 
#       a. Deploy keys (read only)

ASK_KEY() {
read -p "Have your credentials been added as a deploy key at GALAXIA? (y/N): " yn 
case $yn in 
        [Nn]* | "" ) 
                read -p "Would you like to generate them now? (Y/n):" yn;
                echo ""
                case $yn in 
                        [Yy]* | "") GENERATE_KEYS;;
                        [Nn]* ) echo "You will need to be authorized to continue. Contact your POC at GALAXIA."
                esac
                ;;
        [Yy]* ) 
                AUTH=yes
                echo "AUTH=$AUTH" >> .env
                ;;
esac
echo ""
}

GENERATE_KEYS() {
echo "This step will generate the SSH ed25519 keys needed to login to GitHub."
echo "The steps are identical to those on this page: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent"
echo ""
echo "Note for Mac users: you need to add MAC=yes in your .env file for this to work"
echo ""
read -p "Enter your GitHub email: " gh_email
read -p "Enter the name of the key (will be going to ~/.ssh/<key_name>): " key_name 
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
                echo "Your public key is stored in `echo $HOME/.ssh/$key_name.pub`";
                echo ""
                echo "\t`cat $HOME/.ssh/$key_name.pub`"
                echo ""
                echo "Please send this public key to your POC at GALAXIA."
                echo "They will also need the GitHub usernames of all those who will be pushing/pulling containers."
                echo ""

                # Save key name to the .env file 
                echo "key_name=$key_name" >> .env
                ;;
        * ) echo "Errors detected in keygen."; exit;;
esac

echo ""
}

# Preface
echo "Mobius Sandbox Client"
echo "v0.1-Alpha"
echo ""

# Source .env 
if [[ -f .env ]]
then
        source .env 
        ENV_EXISTS=1
fi

# Check if client-id set 
if [[ -z $CLIENT_ID ]]
then
        echo "You will be prompted to enter your client ID."
        echo "Note this can be anything you want so long as it is descriptive of your company/project."
        echo ""
        echo "Whatever you set now will persist so choose wisely."
        echo ""
        # Ask for client name 
        read -p "Enter your client ID: " CLIENT_ID
        echo ""
        echo "You set ($CLIENT_ID) as you client ID."
        read -p "Continue? (Y/n): " yn
else
        echo "You are ($CLIENT_ID)."
        echo ""
        echo "If this is incorrect, delete the .env file in this directory and re-run this script."
        echo "Otherwise, you may edit the value in the .env file directly if you know what they mean."
        echo ""
        read -p "Continue? (Y/n): " yn
fi

case $yn in
        [Yy]* | "" ) echo "Proceeding...";;
        [Nn]* ) echo "Client ID rejected. Quitting."; exit;;
esac

if [[ -z $ENV_EXISTS ]]
then
        # Set missing values 
        BUILD_REPO_AND_TAG="ghcr.io/galaxia-missions-systems/mobius-sandbox-clients:0.1-dev-$CLIENT_ID"

        # Write client ID to the .env file 
        echo "CLIENT_ID=$CLIENT_ID" > .env

        # Write docker image build and tag entry 
        echo "BUILD_REPO_AND_TAG=$BUILD_REPO_AND_TAG" >> .env

else
        # Print .env file values 
        echo "CLIENT_ID=$CLIENT_ID"
        echo "BUILD_REPO_AND_TAG=$BUILD_REPO_AND_TAG"
        echo ""
fi

# Ask about deploy key 
if [[ -z $AUTH ]]
then
        ASK_KEY
elif [[ "$AUTH" == "no" ]]
then
        echo "Your .env file indicates that you are not authorized on the GALAXIA repo."
        read -p "Has this changed? (Y/n): " yn 
        case $yn in 
                [Yy]* | "") ASK_KEY;;
                [Nn]* ) echo "You will need to be authorized to continue."; exit;;
        esac
fi

# Clone the mobius-sandbox repo (read-only)
if ! [[ -d "mobius-sandbox" ]]
then
        if [[ -z $key_name ]]
        then
                read -p "Please enter the name of your auth key (~/.ssh/<key_name>): " key_name
                echo ""
                echo "key_name=$key_name" >> .env
        fi

        git clone -c core.sshCommand="/usr/bin/ssh -i $HOME/.ssh/$key_name" --branch "0.1-dev" git@github.com:Galaxia-Missions-Systems/mobius-sandbox.git
        echo ""

        case $? in
                0 ) echo "Git clone success";;
                * ) echo "Failed to clone Galaxia-Missions-Systems/mobius-sandbox. Perhaps you are not yet authenticated?"; exit;;
        esac
        echo ""
fi

# DEBUG 
echo "BUILD_REPO_AND_TAG BEFORE = $BUILD_REPO_AND_TAG"

# Build the template docker image using the repo script 
cd mobius-sandbox
./Scripts/init-buildx-qemu.sh
NOPUSH=1 FORCE_REPO_AND_TAG=$BUILD_REPO_AND_TAG ./Scripts/build-docker-image.sh

# DEBUG 
echo "BUILD_REPO_AND_TAG AFTER = $BUILD_REPO_AND_TAG"

# Push template image to the GHCR (creates parking space)
docker push $BUILD_REPO_AND_TAG
