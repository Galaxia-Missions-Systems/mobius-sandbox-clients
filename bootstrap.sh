#!/bin/bash

# The steps go:
# 0. Clone mobius-sandbox-clients repo.
# 1. Get client ID + derive other vars.
# 2. Generate build script (generates template container).
# 3. Generate the client's SSH deploy key (or let them use their own).
#       a. Ask them to send it to us to give them write permissions to mobius-sandbox-clients.
#       b. We also need to give them read permissions for mobius-sandbox
# ######## FOLLOWING STEPS REQUIRE AUTH ############################
# 4. Fetch the mobius-sandbox repo (obtains the build environment).
#       a. Run the necessary setup scripts in there.
# 5. Build the template container and push to their 'parking spot'
# 6. Let the client take over from there.

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

read -r -d '' BUILD_SCRIPT << EOM
#!/bin/bash

docker build 
