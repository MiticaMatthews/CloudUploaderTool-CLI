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

# Function to print out recommended regions for UK, Europe and the US
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

# Calling the select region function
select_region

# Function to create a resource group
create_resource_group() {
	echo "Creating resource group: $resource_group in $selected_region."
	az group create -g $resource_group -l $selected_region --query "properties.provisioningState" -o tsv
}

# Calling the create a resource group function
create_resource_group

# Function to check for resource group
check_resource_group() {
	while true; do
		read -p "Enter a name for your resource group: " resource_group
		if [ "$(az group exists --name "$resource_group")" = "true" ]; then
			echo "A resource group with the name "$resource_group" already exists in $selected_region."
			read -p "Would you like to use a pre-made resource group? (yes or no): " choice

			case $choice in
				Y|y|YES|yes) 
					read -p "Enter the name of your pre-made resource group: " pre_resource_group
					if [ "$(az group show --name "pre_resource_group" --query "name" -o tsv)" = "$pre_resource_group" ]; then 
						resource_group=$pre_resource_group
						echo "Match detected. Using your pre-made resource group: $pre_resource_group"
						break 
					else 
						echo "No match found. Please provide another name."
					fi 
					;;
					
				N|n|NO|no)
					echo "Please provide another name for your resource group..."
					;; 
				*) 
					echo "Invalid option. Please enter yes or no."
					;;
			esac
		else 
			echo "The resource group name: $resource_group is available." 
			break 
		fi 
	done 
}

# Calling the check resource group function
check_resource_group

# Function to list all resource groups
list_resource_groups() {
	az group list -o table
}

# Calling the list resource groups function
list_resource_groups

# Function to create a storage
create_storage_account() {
	echo "Creating storage account: $storage_account in resource group: $resource_group in $selected_region."
	az storage account create -n $storage_account -g $resource_group -l $selected_region --sku Standard_LRS
}

# Calling the create a storage account function
create_storage_account

# Function to check for storage account
check_storage_account() {
	while true; do
		read -p "Enter a name for your storage account: " storage_account
		name_check=$(az storage account check-name --name "$storage_account" --query "nameAvailable" -o tsv)
		if [ "$name_check" = "true" ]; then
			read -p "Would you like to use a pre-made storage account? (yes or no): " choice

			case $choice in
				Y|y|YES|yes) 
					read -p "Enter the name of your pre-made storage account: " pre_storage_account
					# Checking whether the provided pre-made storage account exists
					account_check=$(az storage account show --name "$pre_storage_account" --query "name" -o tsv)
					if [ "$account_check" = "$pre_storage_account" ]; then 
						storage_account=$pre_storage_account
						echo "Match detected. Using your pre-made storage account: $pre_storage_account"
						break 
					else 
						echo "No match found. Please provide another name."
					fi 
					;;
					
				N|n|NO|no)
					echo "Please provide another name for your storage account..."
					;; 
				*) 
					echo "Invalid option. Please enter yes or no."
					;;
			esac
		else 
			echo "The storage account name: $storage_account is not available. Please provide another name." 
			break 
		fi 
	done 
}

# Calling the check storage account function
check_storage_account

# Function to list all storage accounts
list_storage_accounts() {
	az storage account list -o table
}

# Calling the list resource groups function
list_storage_accounts

# Function to create a container
create_container() {
	echo "Creating a container: $storage_container in storage account: $storage_account in resource group: $resource_group."
	az storage container create --name "$storage_container" --account-name "$storage_account" --auth-mode login
}

# Calling the create a container function
create_container

# Function to check for container
check_container() {
	while true; do
		read -p "Enter a name for your container: " storage_container
		name_check=$(az storage container exists --name "$storage_container" --account-name $storage_account --query "exists" -o tsv)
		if [ "$name_check" = "true" ]; then
            echo "A container with the name: $storage_container already exists in the storage account: $storage_account."
			read -p "Would you like to use a pre-made storage container? (yes or no): " choice

			case $choice in
				Y|y|YES|yes) 
					read -p "Enter the name of your pre-made storage container: " pre_storage_container
					# Checking whether the provided pre-made storage container exists
					container_check=$(az storage container show --name "$pre_storage_container" --query "name" -o tsv)
					if [ "$container_check" = "$pre_storage_container" ]; then 
						storage_container=$pre_storage_container
						echo "Match detected. Using your pre-made storage container: $pre_storage_container"
						break 
					else 
						echo "No match found. Please provide another name."
					fi 
					;;
					
				N|n|NO|no)
					echo "Please provide another name for your storage container..."
					;; 
				*) 
					echo "Invalid option. Please enter yes or no."
					;;
			esac
		else 
			echo "The storage container name: $storage_container is available." 
			break 
		fi 
	done 
}

# Calling the check container function
check_container

# Function to list all storage containers
list_storage_containers() {
	az storage container list --account-name "$storage_account" -o table
}

# Calling the list resource groups function
list_storage_containers

