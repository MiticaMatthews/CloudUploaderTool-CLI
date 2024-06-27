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

# Function to check if resource group exists
resource_group_exists() {
    local resource_name=$1
    az group show --name "$resource_name" &> /dev/null
    return $?
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
        echo "Resource group: $resource_name successfully created!"
    else 
        echo "Error: Failed to create resource group: $resource_name."
        exit 1
    fi 
}

# Function to prompt user to choose pre-made resource group or create a new one
prompt_premade_rg() {
    read -p "Would you like to use a pre-made resource group? (yes or no): " use_premade
    case $use_premade in
        Y|y|YES|yes)
            read -p "Enter the name of your pre-made resource: " resource_name
            if resource_group_exists "$resource_name"; then
                echo "Using pre-made resource group: $resource_name."
            else 
                echo "Resource group: $resource_name does not exist." 
                exit 1
            fi 
            ;;
       N|n|NO|no)
           echo "Creating new resource group..."
           rg_naming_instructions
           name_resource_group
           generate_rg_name
           validate_rg_name
           create_resource_group
           ;;
      *)
          echo "Invalid input. Please enter 'yes' or 'no'."
          prompt_premade_rg
          ;;
  esac
}

# Function to list resource groups
list_resource_groups() {
    az group list -o table
}

# Function to check if storage account exists
storage_account_exists() {
    local storage_name=$1
    az storage account show --name "$storage_name" &> /dev/null
    return $?
}

# Function to print storage account naming convention instrucitons
st_naming_instructions() {
    echo "Please follow the instructions to name your storage account."
    sleep 3
    echo "Use the following naming format: "
    echo "Format: <resourcetype><apporservicename><###>"
    sleep 5
    echo "See example for storage account below: " 
    echo "stxxwebapp001" 
}

# Function to get user input to name storage account
name_storage_account() {
    read -p "Enter the abbreviation for your storage account resource (e.g. st): " resource_type
    read -p "Enter the name of your tool, application or service: " app_name
    read -p "Enter a unique identifier (e.g. 001): " unique_id
}

# Function to generate storage account name
generate_st_name() {
    storage_name="${resource_type}${app_name}${unique_id}"
    echo "$storage_name"
}

# Function to validate storage account name 
validate_st_name() {
    if [[ $storage_name =~ ^[a-z0-9]{3,24}$ ]]; then
        echo "Valid storage account name: $storage_name."
    else 
        echo "Invalid storage account name: $storage_name."
        exit 1
    fi 
}

# Function to create storage account
create_storage_account() {
    az storage account create --name "$storage_name" --resource-group "$resource_name" --location "$selected_region"
    if [ $? -eq 0 ]; then
        echo "Storage account: $storage_name successfully created in resource group: $resource_name!" 
    else 
        echo "Error: Failed to create storage account: $storage_name in resource group: $resource_name."
        exit 1
    fi 
}

# Function to prompt user to choose pre-made storage account or create a new one
prompt_premade_st() {
    read -p "Would you like to use a pre-made storage account? (yes or no): " use_premade
    case $use_premade in
        Y|y|YES|yes)
            if storage_account_exists "$storage_name"; then
                echo "Using pre-made storage account: $storage_name."
            else 
                echo "Storage account: $storage_name does not exist."
                exit 1
            fi 
            ;;
         N|n|NO|no)
             echo "Creating new storage account..."
             st_naming_instructions 
             name_storage_account
             generate_st_name
             validate_st_name
             create_storage_account
             ;;
         *)
             echo "Invalid input. Please enter 'yes' or 'no'."
             prompt_premade_st
             ;;
     esac
}

# Function to list storage accounts. Included additional formatting (spacing) between data/rows after header for improved readability
list_storage_accounts() {
    az storage account list -o tsv | awk 'NR==1; NR>1{print ""; print}'
}

# Function to check if storage container exists
storage_container_exists() {
    local storage_container_name=$1
    az storage container show --name "$storage_container_name" &> /dev/null
    return $?
} 

# Function to print storage container naming convention instructions
sc_naming_instructions() {
    echo "Please follow these instructions to name your storage container."
    sleep 3
    echo "Use the following naming format: "
    echo "Format: <resourcetype>-<apporservicename>-<###>"
    sleep 5
    echo "See example for storage container below: "
    echo "sc-xxwebapp-001"
}

# Function to get user input to name storage container
name_storage_container() {
    read -p "Enter the abbreviation for your storage container resource (e.g. sc): " resource_type
    read -p "Enter the name of your tool, application or service: " app_name
    read -p "Enter a unique identifier (e.g. 001): " unique_id
}

# Function to generate storage container name
generate_sc_name() {
    storage_container_name="${resource_type}-${app_name}-${unique_id}"
    echo "$storage_container_name"
}

# Function to validate storage container name
validate_sc_name() {
    if [[ $storage_container_name =~ ^[a-z]{2}-[a-z]+-[0-9]{3}$ ]]; then
        echo "Valid storage container name: $storage_container_name."
    else 
        echo "Invlid storage container name: $storage_container_name."
        exit 1 
    fi 
}

# Function to create storage container
create_storage_container() {
    az storage container create --name $storage_container_name --account-name $storage_name --auth-mode login
    if [ $? -eq 0 ]; then 
        echo "Storage container: $storage_container_name successfully created in storage account: $storage_name!"
    else 
        echo "Error: Failed to create storage container: $storage_container_name in storage account: $storage_name."
        exit 1 
    fi 
}

# Function to prompt user to choose pre-made storage container or create a new one
prompt_premade_sc() {
    read -p "Would you like to use a pre-made storage container? (yes or no): " use_premade
    case $use_premade in
        Y|y|YES|yes)
            read -p "Enter the name of your pre-made storage container: " storage_account_name
            if storage_container_exists "$storage_container_name"; then
                echo "Using pre-made storage container: $storage_container_name."
            else 
                echo "Storage container: $storage_container_name does not exist."
                exit 1
            fi 
            ;;
         N|n|NO|no)
             echo "Creating new storage container..."
             sc_naming_instructions
             name_storage_container
             generate_sc_name
             validate_sc_name
             create_storage_container
             ;;
         *) 
             echo "Invalid input. Please enter 'yes' or 'no'."
             prompt_premade_sc
             ;;
     esac
}

# Function to list storage containers
list_storage_containers() {
    az storage container list --account-name $storage_name --auth-mode login -o table
}

select_region
prompt_premade_rg
list_resource_groups
prompt_premade_st
list_storage_accounts
prompt_premade_sc
list_storage_containers
