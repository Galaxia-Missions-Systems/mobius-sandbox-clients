# Mobius Sandbox Clients
Target: `v0.1 Alpha`

## Purpose
This repo serves as an entry point for Mobius Sandbox clients and further as a collection point for client-derived Mobius Sandbox containers.

## Point of Contact
Getting in touch with a GALAXIA Point-of-Contact (POC) is required at certain steps, particularly when dealing with authentication.

As of March 7th, 2024, the listed GALAXIA POC is Alex A. Amellal (aaa@galaxiams.com).

# Getting Started
## Dependencies
For the boostrap script to work, a few dependencies are required - namely:

- Git
- SSH
- WSL/2 or a UNIX-like System.
- Docker (https://docs.docker.com/engine/install).

## Bootstrap Script
_NOTE_: This script is meant to run in a UNIX-like environment. It has been tested on the following systems:

- Windows WSL2 (Ubuntu),
- Ubuntu 22.04,
- Arch Linux 6.6

**To get started, clone this repo and run the bootstrap script:**

``` 
git clone https://github.com/Galaxia-Missions-Systems/mobius-sandbox-clients.git

./bootstrap.sh
```

The script will take you through the following steps.

### Running on Windows
To run this script on Windows, **please use WSL/WSL2 inside of a Linux directory** (working within a Windows NTFS directory aka C:\ drive WILL cause issues).

The rest of the instructions may be followed as normal once in the WSL/WSL2 environment.

## Running the `bootstrap.sh` script
### 1. Setting your Client ID
Your *Client ID* is a unique self-assigned identifier for yourself and/or your company.

If you were not given a *Client ID*, please invent one suitable for your company. Make sure it is unique and used consistently during development.

![Step 1 in bootstrap.sh](/img/1.jpg)

Be mindful of the *Client ID* you choose because it will be used to name authentication key files and store/retrieve your docker containers, for example.

![Step 1.1 in bootstrap.sh](/img/1.1.jpg)

### 2. Validating authentication at GALAXIA
Next you will be asked whether your credentials have been added at GALAXIA.

Please send your Github username to a point-of-contact at GALAXIA to proceed. Make sure your system is authenticated with an SSH key on your Github account as well (as instructed in https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).

_NOTE_: Any further attempt to proceed without authentication will lead to issues proceeding with the script.

### 3. Running the `./continue.sh` script
After SSH key generation is complete, a `continue.sh` script will appear in the working directory. This is intended to be run _only_ after authentication at GALAXIA has been complete by the POC.

This script will automatically clone the private `mobius-sandbox` repo -- this is why proper authentication is important. 

![Step 3 of bootstrap.sh](/img/3.jpg)

This repo contains the Dockerfiles and scripts required to develop within the Mobius Sandbox.

From there, the `continue.sh` script will also handle the following steps.

### 4. Building the Docker container template
Assuming the `mobius-sandbox` repo cloned without issue, a template Docker container (your Mobius Sandbox) will begin building.

![Step 4 of bootstrap.sh](/img/4.jpg)

This requires both Docker to be installed and user permissions (namely the active user being a part of the `docker` group) to work.

Completion of this steps involves the building of a bare template Sandbox container. It serves as the building block for the development of your Mobius App.

### 5. Pushing the container to GALAXIA's Github Container Repo (GHCR)
The final step involves pushing the built template container to your unique client container tag in GALAXIA's Github Container Repo (GHCR).

![Step 5 of bootstrap.sh](/img/5.jpg)

When pushed successfully, all necessary prerequisites are considered in-place for development. The successful push also safeguards your container's Client ID tag in GALAXIA's Github Container Repo.

## Troubleshooting
Issues may occur, particularly when building and pushing the template Docker container to GALAXIA's GHCR.

![Troubleshooting Error](/img/T.jpg)

In these cases, it is always best to try one or more of the 3 troubleshooting tips for Docker:
> 1. Ensure that docker was installed according to the instructions found in https://docs.docker.com/engine/install

This is because some Docker distributions do not ship with `buildx`, a necessary component of the emulation layer.

> 2. Perhaps docker has not been authenticated on the Github Container Repository (GHCR) yet. See to doing this in https://docs.docker.com/reference/cli/docker/login/ using a Classic Personal Authentication Token (PAT) from your Github account.

This part requires a Classic Personal Authentication Token (Classic PAT) to be generated from your Github user settings. You will also need to have been added a collaborator to the repo, as pre your GALAXIA point-of-contact would have permitted.

> 3. Lastly - it is also possible that the current user (alex) is not a member of the 'docker' user group.

This is a common error for `docker permission denied` issues, largely having to do with needing to run `sudo docker` for docker commands to work.

This can easily be remedied by adding the current user to the `docker` group using the command `sudo usermod -a -G docker $(whoami)`. 

You can also replace `$(whoami)` with the name of your user (e.g.: in my case this would mean `sudo usermod -a -G docker alex`).

