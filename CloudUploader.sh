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

# Function to login and authenticate Azure CLI
azure_login() {
	echo "Logging into Azure..."
	az login --use-device-code
}

# Calling the login function
azure_login

# Function to print out recommended regions for UK, Europe & the US
print_regions() {
    regions_array=($(az account list-locations --query "[?contains(name, 'uk') || contains(name, 'europe') || contains(name, 'us')].name" -o tsv | \
    grep -E '\b(uksouth|ukwest|northeurope|westeurope|eastus|westus|centralus)\b'))

    for i in "${regions_array[@]}"
    do
        echo "$i"
    done
}

# Function to select a region
select_region() {
	local region_exists=false
	while [[ "$region_exists" == false ]]; do 
		print_regions
		read -p "Enter your region: " selected_region
		for i in ${regions_array[@]}
		do 
			if [[ "$selected_region" == "$i" ]];then 
				region_exists=true
				echo "Region exists!"
				break 
			else 
				continue
			fi 
		done 
	done 
}

# Function to print resource group naming convention instructions
rg_naming_instructions() {
echo "Please follow these instructions to name your resource group."
sleep 3
echo "Use the following naming convention format:"
echo "Format: <resourcetype>-<apporservicename>-<###>"
sleep 5
echo "See examples below:"
sleep 2
echo "Resource group: rg-xxwebapp-001"
echo "Storage account: st-xxwebapp-001"
echo "Storage container: sc-xxwebapp-001"
}

# Function to get user input to name resource group
name_resource_group() {
    read -p "Enter the relevant abbreviation for your resource type (e.g. rg, st, sc): " resource_type
    read -p "Enter the name of your tool, application or service: " app_name
    read -p "Enter a unique identifier (e.g. 001): " unique_id
}

# Function to generate resource group name
generate_rg_name() {
resource_name="${resource_type}-${app_name}-${unique_id}"
echo "$resource_name"
}

# Function to validate resource group name
validate_rg_name() {
if [[ $resource_name =~ ^[a-z]{2}-[a-z]+-[0-9]{3}$ ]]; then
    echo "Valid resource name: $resource_name."
else 
    echo "Invalid resource name: $resource_name."
    exit 1
fi 
}

# Function to create resource group
create_resource_group () {
    az group create --location "$selected_region" --name "$resource_name"
    if [ $? -eq 0 ]; then
        echo "Resourse group: $resource_name successfully created!"
    else 
        echo "Error: Failed to create resource group: $resource_name"
        exit 1
    fi 
}

# Function to list resource groups
list_resource_groups() {
az group list -o table
}

select_region
rg_naming_instructions
name_resource_group
generate_rg_name
validate_rg_name
create_resource_group
list_resource_groups

