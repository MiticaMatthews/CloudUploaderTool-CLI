Microsoft Azure File Uploader Script

This Bash script is designed to automate the process of uploading files to Azure Blob Storage via Command-Line Interface (CLI). It simplifies the setup of Azure resources, automates the assignment of role-based permissions, supports both single file and batch file uploads and generates shareable links using SAS tokens for added security.

## Requirements

1. **Azure Account:** Ensure that you have an active Azure account before using this script. Create a free account using the following link: (https://azure.microsoft.com/en-gb/free/).

2. **Azure CLI:** Ensure that Azure CLI is installed on your machine for the script work as intended. The script will automate and guide users through the installation process for different environments if Azure CLI is not detected, including: Debian, Linux, MacOS and Windows.

## Installation

1. Clone the repository:

```bash
git clone https://github.com/MiticaMatthews/CloudUploaderTool-CLI.git
```

2. Navigate to the script directory:

```bash
cd CloudUploaderTool-CLI
```

3. Run the following command to make the script executable:

```bash
chmod +x CloudUploader.sh
```

## Usage

1. Run the script:

```bash
./CloudUploader.sh
```
2. Follow the prompts to:

* Install Azure CLI on your system (if not already installed).

* Login and authenticate your active Azure account.

* Select your subscription number.

* Select an Azure region.

* Provide names for resource types (resource groups, storage accounts and storage containers) following the guidance to ensure a valid and globally unique name. Here, you can choose whether to create a new resource type or use a pre-existing one.

* Provide an accurate path to the file or directory you want to upload to Azure storage.

* Choose whether to overwrite, skip upload or rename existing files in your storage container.

## Features

- **Azure CLI Installation:** Checks if Azure CLI is installed, and offers to install it for the user if it is not detected on their system. 

- **Azure CLI Login & Authentication:** Prompts users to login to Azure CLI using device code authentication.

- **Select Region:** Prompts the user to select a region from a list.

- **Guided User Interaction:** Provides instructions for naming resources to ensure compliance with Azure naming conventions.

- **Resource Group Management:** Checks if resource group exists and allows users to create a new resource group or use a pre-existing one. The script then lists resource groups.

- **Storage Account Management:** Checks if storage account exists and allows users to create a new storage account or use a pre-existing one. The script then lists storage accounts.

- **Assign Role 'RBAC':** Automates role assignment and confirms that the user's account has the required role-based permissions to create and manage resources.

- **Storage Container Management:** Checks if storage container exists and allows users to create a new container or use a pre-existing one. The script the lists containers.

- **Single File Upload:** Handles single file upload to selected container. Checks if file exists in container and prompts users to choose whether to overwrite, skip upload or rename an existing file.

- **Batch File Uploads:** Handles batch file uploads to selected container in a single session. Checks for the existence of each file and prompts the user to choose whether to overwrite, skip upload or rename existing files.

- **Shareable Link Generation:** Generates a shareable link with a SAS token for each file upload, which expires in 1 day.

## License

This script is licensed under the [MIT License](LICENSE).
