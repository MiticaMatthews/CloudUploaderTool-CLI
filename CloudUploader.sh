#!/bin/bash

# A bash script that allows users to quickly upload files to Azure blob storage via CLI. 


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

# Function to retrieve the subscription ID using Azure CLI to avoid errors when working with Azure resources
get_subscription_id() {
    subscription_id=$(az account show --query "id" --output tsv)
    if [ -z "$subscription_id" ]; then
        echo "Error: Failed to retrieve subscription ID."
        exit 1
    fi 
    echo "Successfully retrieved subscription ID: $subscription_id."
}

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
            read -p "Enter the name of your pre-made storage account: " storage_name
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

# Function to assign role to user to ensure proper access management 
assign_role() {
    role="Storage Blob Data Contributor"
    scope="/subscriptions/$subscription_id/resourceGroups/$resource_name/providers/Microsoft.Storage/storageAccounts/$storage_name"

    # Retrieve signed in user's Object ID
    user_object_id=$(az ad signed-in-user show --query id -o tsv)
    if [ -z "$user_object_id" ]; then
        echo "Error: Failed to retrieve signed-in user's Object ID. Object ID cannot be empty."
    fi 
    echo "Retrieved signed-in user's Object ID: $user_object_id"

    # Assign role to Object (principal) ID
    echo "Assigning role $role to principal ID $user_object_id for scope $scope..."
        az role assignment create --assignee "$user_object_id" --role "$role" --scope "$scope"
        if [ $? -eq 0 ]; then
            echo "Role assignment successful."
        else 
            echo "Error: Failed to assign role."
        fi 
}

# Function to check if storage container exists
storage_container_exists() {
    local storage_container_name=$1
    az storage container show --name "$storage_container_name" --account-name "$storage_name" --auth-mode login &> /dev/null
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
    az storage container create --name "$storage_container_name" --account-name "$storage_name" --auth-mode login
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
            read -p "Enter the name of your pre-made storage container: " storage_container_name
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
    az storage container list --account-name "$storage_name" --auth-mode login -o table
}

# Function to upload a single file and print shareable link
file_upload() {
    az storage blob upload --account-name "$storage_name" --auth-mode login --container-name "$storage_container_name" --name "$file_name" --file "$file_path"
    if [ $? -eq 0 ]; then
        echo "Successfully uploaded file: $file_name."
        generate_shareable_link
    else 
        echo "Error: Failed to upload file: $file_name."
        exit 1
    fi
}

# Function to overwrite file and print shareable link
file_overwrite() {
    az storage blob upload --account-name "$storage_name" --auth-mode login --container-name "$storage_container_name" --name "$file_name" --file "$file_path" --overwrite true
    if [ $? -eq 0 ]; then
        echo "File successfully overwritten."
        generate_shareable_link
    else 
        echo "Error: Failed to overwrite file."
        exit 1
    fi 
}

# Function to generate and print a shareable link for blobs with SAS token
generate_shareable_link() {
    # Get expiry date (compatible with MacOS and GNU date)
    if [[ "$OSTYPE" == "darwin"* ]]; then 
        # macOS date command
        expiry_date=$(date -u -v +1d +%Y-%m-%dT%H:%MZ)
    else 
        # Linux/GNU date command
        expiry_date=$(date -u -d '1 day' +%Y-%m-%dT%H:%MZ)
    fi

    # Generate SAS token and URL
    sas_token=$(az storage blob generate-sas --account-name "$storage_name" --container-name "$storage_container_name" --name "$file_name" --permissions acdrw --expiry "$expiry_date" --auth-mode login --as-user --output tsv)
    if [ $? -eq 0 ]; then
        blob_url=$(az storage blob url --account-name "$storage_name" --container-name "$storage_container_name" --name "$file_name" --output tsv)
        echo "Shareable link for $file_name: ${blob_url}?${sas_token}"
    else 
        echo "Error: failed to generate shareable link for: $file_name."
    fi 
}

# Function to handle a single file upload 
handle_single_file_upload() {
    read -p "Enter the full path of the file you want to upload: " file_path
    file_name=$(basename "$file_path")

    # Check if file name already exists in container
    az storage blob show --account-name "$storage_name" --auth-mode login --container-name "$storage_container_name" --name "$file_name" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        read -p "File name already exists. Would you like to (o)verwrite, (s)kip or (r)ename the file? (O/S/R): " option
        case $option in
            O|o) echo "Overwriting the existing file..."
                file_overwrite
                ;;
            S|s) echo "Skipping file upload. Exiting now..."
                exit 1
                ;;
            R|r) read -p "Enter a new name for the file: " new_file_name
                # Renaming file
                mv "$file_path" "$(dirname "$file_path")/$new_file_name"
                file_name="$new_file_name"
                file_path="$(dirname "$file_path")/$new_file_name"
                echo "File successfully renamed to: $file_name"
                file_upload
                ;;
             *) echo "Invalid input. Please enter 'O', 'S', or 'R'."
                handle_single_file_upload
                ;;
        esac
    else 
        echo "File name does not exist. Uploading file..."
        file_upload
    fi
}

# Function to handle a batch file upload
handle_batch_file_upload() {
    read -p "Enter the full local directory path of the files you would like to batch upload: " local_directory_path

    # Validate local directory path
    if [ ! -d "$local_directory_path" ]; then
        echo "Error: Local directory: '$local_directory_path' does not exist."
        exit 1
    fi 

    # Loop through all files in the selected local directory
    for file_path in "$local_directory_path"/*;
    do
        if [ -f "$file_path" ]; then
            file_name=$(basename "$file_path")

            # Check if blob name exists in container
            blob_exists=$(az storage blob exists --account-name "$storage_name" --auth-mode login --container-name "$storage_container_name" --name "$file_name" --query "exists" --output tsv)
            if [ "$blob_exists" = true ]; then
                echo "File name: $file_name already exists in the container: $storage_container_name."
                read -p "Would you like to (o)verwrite, (s)kip or (r)ename the file? (O/S/R): " option
                case $option in
                    O|o) echo "Overwriting existing file..."
                        file_overwrite
                        ;;
                    S|s) echo "Skipping file upload for $file_name. Exiting now..."
                         continue
                        ;;
                    R|r) read -p "Enter a new name for the file: " new_file_name
                         # Renaming file
                         mv "$file_path" "$(dirname "$file_path")/$new_file_name"
                         file_name="$new_file_name"
                         file_path="$(dirname "$file_path")/$new_file_name"
                         echo "File successfully renamed to: $file_name."
                         file_upload
                         ;;
                       *) echo "Invalid input. Please enter 'O', 'S' or 'R'."
                           ;;
                   esac 
               else 
                   echo "File name: $file_name does not exist in the container: $storage_container_name. Uploading file now..."
                   file_upload
            fi
        fi 
    done 
}

# Prompt for user to choose single or batch file upload
choose_upload_type() {
    read -p "Would you like to upload a (s)ingle file or a (b)atch of all files from a local directory? (S/B): " choice

    case $choice in
        S|s)
            handle_single_file_upload
            ;;
        B|b)
            handle_batch_file_upload
            ;;
           *)
               echo "Invalid input. Please enter 'S' or 'B'."
               ;;
       esac
}

# Calling functions 
azure_login
get_subscription_id
select_region
prompt_premade_rg
list_resource_groups
prompt_premade_st
list_storage_accounts
assign_role
prompt_premade_sc
list_storage_containers
choose_upload_type
