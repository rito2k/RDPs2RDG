# RDPs2RDG
This script loops through all valid RDP Files in a provided folder path, extracts machine and logon name for each of them and generates a Remote Desktop Connection Manager group file for your convenience.

## Table of Contents

- [RDPs2RDG](#RDPs2RDG)
  - [Table of Contents](#table-of-contents)
  - [About The Project](#about-the-project)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)    
  - [Usage](#usage)
  - [Contributing](#contributing)
  - [License](#license)
  - [Contact](#contact)


## About The Project

Using single and separated Remote Desktop Connection RDP files can be difficult when dealing with a large number of servers to connect to. Being a heavy user of the Remote Desktop Connection Manager, I decided to quickly develop a script to create the different connection nodes from the different RDP files stored in a single location, and enjoy connecting to them from a centralized workspace.

## Getting started

This script loops through all valid RDP Files in a provided folder path, extracts machine and logon name for each of them and generates a Remote Desktop Connection Manager group file for your convenience.

### Prerequisites

- PowerShell Version 5.1+
     
## Usage

- Provide the default logon user name to connect to the remote machines with. If not provided, "Administrator" will be used.
- Provide the path to the existing RDP files to generate the RDCMan file from. If not provided, the path where the script is located will be used.
- Provide the name for the group node containing the remote servers to connect to. If not provided, "MyWorkspace" will be used.

**EXAMPLE:**
_RDPs2RDG.ps1 -DefaultLogonName WsAdm -RdpFilesPath C:\RDPs -WorkspaceName MyWorkspace_

## License

Distributed under the MIT License. See `LICENSE` for more information.
