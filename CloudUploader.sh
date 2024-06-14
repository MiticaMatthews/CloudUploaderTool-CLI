#!/bin/bash

# A bash-based CLI tool that allows users to quickly upload files to Azure blob storage, providing a simple and seamless upload experience similar to popular storage services. 


# Functions for  installing Azure CLI on different environments
install_azure_cli_debian(){
echo "Detected Debian-based system. Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
}

install_azure_cli_macos(){
echo "Detected MacOS. Installing Azure CLI..."
# Checking for Homebrew package manager 
if ! command -v brew &> /dev/null;then
	echo "Homebrew package manager not found. Installing Homebrew first..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi 
brew update && brew install azure-cli

}

install_azure_cli_windows(){
echo "Detected Windows. Please follow these instructions to install Azure CLI:"
echo "1. Download the MSI installer from https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli#install-or-update"
echo "2. Run the installer and follow the prompts."
echo "Alternatively, use Windows Package manager to install Azure CLI."
echo "winget install -e --id Microsoft.AzureCLI"

}

# Function to prompt user to install Azure CLI
prompt_install_azure_cli() {
	.
	read -p "Azure CLI has not been detected. This tool requires Azure CLI. Would you like to install it now? (yes or no): " option

	case $option in
		Y|y|YES|yes) echo "Installing Azure CLI now..."
			# Calling the appropriate installation function based on the OS

			# Check for Debian-based system
			if [ -f /etc/debian_version ];then
				install_azure_cli_debian

			# Check for Linux systems 
			elif [ "$(uname -s)" == "Linux" ];then
				install_azure_cli_debian

			# Check for MacOS 
			elif [ "$(uname -s)" == "Darwin" ];then
				install_azure_cli_macos

			# Check for Windows environments
			elif [[ "$(uname -s)" == CYGWIN* ]] || [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]];then
				install_azure_cli_windows

			# Handle Unsupported or unknown operating systems
			else
				echo "Unsupported or unknown (OS) Operating System. Please refer to official documentation: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"

			fi
			;;
		N|n|NO|no) echo "Azure CLI installation skipped. Please install manually before using this tool."
			;;
		*) 
			echo "Invalid option. Please enter yes or no."
			;;
	esac 

}

#Check whether Azure CLI is installed
if command -v az >/dev/null 2>&1;then 
	echo "Azure CLI is already installed."
else
	prompt_install_azure_cli

fi


