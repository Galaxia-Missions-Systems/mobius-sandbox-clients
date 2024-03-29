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

DETECT_WSL()
{
if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]
then
	return 1
else
	return 0
fi
}

ASK_KEY()
{
read -p "Have your credentials been added as a deploy key at GALAXIA? (y/N): " yn 
case $yn in 
        [Nn]* | "" ) 
                GH_USERNAME_NOTICE
                exit
                ;;
        [Yy]* ) 
                AUTH=yes
                echo "AUTH=$AUTH" >> .env
                ;;
esac
echo ""
}

ASK_GEN_KEY() 
{
read -p "Would you like to generate them now? (Y/n):" yn;
echo ""
case $yn in 
	[Yy]* | "") GENERATE_KEYS;;
	[Nn]* ) echo "You will need to be authorized to continue. Contact your POC at GALAXIA."; exit;;
esac
}

GENERATE_KEYS()
{
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

                PUBLIC_KEY_NOTICE

                # Save key name to the .env file 
                echo "key_name=$key_name" >> .env

                exit
                ;;
        * ) echo "Errors detected in keygen."; exit;;
esac

echo ""
}

PUBLIC_KEY_NOTICE() 
{

echo "#!/bin/bash
./bootstrap.sh" > continue.sh 
chmod +x continue.sh

echo ""
echo "Your auth keypair has already been generated (~/.ssh/$key_name and ~/.ssh/$key_name.pub)."
echo ""
echo "Please send the value of the public key below to a GALAXIA point of contact for authorization."
echo ""
echo "        $(cat ~/.ssh/$key_name.pub)"
echo ""
echo "When complete, run the ./continue.sh script to proceed with the on-boarding process."
echo ""
}

GH_USERNAME_NOTICE() 
{
echo "#!/bin/bash
./bootstrap.sh" > continue.sh 
chmod +x continue.sh

echo ""
echo "To continue, you will need to send your Github username to a GALAXIA point of contact for authorization."
echo ""
echo "Make sure you have setup this machine's SSH key to work with your Github account."
echo "See this page for more information: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent"
echo ""
echo "When complete, run the ./continue.sh script to proceed with the on-boarding process."
echo ""
}

# Preface
echo "Mobius Sandbox Client"
echo "v0.1-Alpha"
echo ""

# Check if running in WSL
DETECT_WSL
if [[ $? -eq 1 ]]
then
        echo "WARNING: WSL DETECTED"
        echo ""
        echo "Please ensure that you are not using WSL in a Windows NTFS directory (such as anywhere on the C:/ drive.)"
        echo "This can result in undefined behaviour and CR LF conversion issues when fetching git respositories."
        echo ""
        read -p "Continue? (Y/n): " yn

        case $yn in
                [Yy]* | * ) echo "Proceeding...";;
                [Nn]* ) echo "Aborting."; exit;;
        esac
fi

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
	echo "If you were not given a *Client ID*, please invent one suitable for your company. Make sure it is unique and used consistently during development."
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

# Set key name to client ID 
key_name=$CLIENT_ID

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
	echo ""
        echo "CLIENT_ID=$CLIENT_ID"
        echo "BUILD_REPO_AND_TAG=$BUILD_REPO_AND_TAG"
	echo "key_name=$key_name"
        if [[ -n $custom_key ]]
        then
                echo "custom_key=$custom_key"
        fi
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
                [Nn]* ) GH_USERNAME_NOTICE; exit;;
        esac
fi

# Clone the mobius-sandbox repo (read-only)
if ! [[ -d "mobius-sandbox" ]]
then
        if [[ -n $custom_key ]]
        then
                echo "Using custom_key=$custom_key..."
                git clone -c core.sshCommand="/usr/bin/ssh -i $custom_key" --branch "0.1-dev" --recurse-submodules git@github.com:Galaxia-Missions-Systems/mobius-sandbox.git
        else
                git clone --branch "0.1-dev" --recurse-submodules git@github.com:Galaxia-Missions-Systems/mobius-sandbox.git
        fi
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

case $? in 
        0 ) echo ""; echo "Template container build and push successful.";;
        * ) 
                echo ""
                echo "Failed to build and push template container."
                echo ""
                echo "Docker troubleshooting tips:"
                echo "----------------------------"
                echo "1. Ensure that docker was installed according to the instructions found in https://docs.docker.com/engine/install"
                echo "          Older versions may not have shipped with buildx."
		echo "2. Perhaps docker has not been authenticated on the Github Container Repository (GHCR) yet. See to doing this in https://docs.docker.com/reference/cli/docker/login/ using a Classic Personal Authentication Token (PAT) from your Github account."
                echo "3. Lastly - it is also possible that the current user (`whoami`) is not a member of the 'docker' user group."
                echo ""
                exit
                ;;
esac
