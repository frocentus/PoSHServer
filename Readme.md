# PowerShell Web Server

Secure, flexible and lightweight web server to meet your requirements.

- Website: http://www.poshserver.net
- Documentation: http://www.yusufozturk.info/wp-download.php?file=PoSHServer.Documentation.pdf

Contact:
ysfozy@gmail.com

## Introduction

PoSHServer is a secure, flexible and lightweight web server to meet your requirements. It’s free and open source. You can add or remove features via PowerShell ISE. You just need to know PowerShell scripting language to work on it. PoSHServer supports many features:

- Authentication
  - Basic Authentication
  - Windows Authentication
- PHP
  - PHP 5.3.X
  - PHP 5.4.X
- Security
  - IP Restriction
  - Content Filtering
  - Directory Browsing
  - 404 Custom Error Page
- Logging
  - Advanced Logging
  - Log Parser
- Installation
  - Running as PowerShell Process
  - Running as Background Job
- SSL
  - Self-Signed SSL Certificate
  - Commercial SSL Certificate
- Others
  - Custom Mime Types
  - Background Jobs
  - Get/Post Support
  - Windows Server Core Support

## Installation

Before beginning PoSHServer installation, please make sure you have Administrative privileges on server. Because PoSHServer setup requires to add PowerShell module files into `C:\Program Files\PoSHServer` directory. If you don’t have Administrative privileges, then PoSHServer setup can’t access to Program Files directory.

TODO: pictures of Installation - Process

After installation, you can go to `C:\Program Files` directory to check if installation is successful. All source codes are under PoSHServer directory. You can use PowerShell ISE to modify source codes for your requirements. PoSHServer doesn’t do any registry changes so you are always free to change or remove files. If something is broken, you just need to paste the original files.

## How to start PoSHServer?

You have two options to start PoSHServer:

1. Run as PowerShell Process
2. Run as Background Job

Running as PowerShell Process is a good way for testing purposes. But if you want your server permanent, then you should run it as background job. So when you restart server, PoSHServer continues to run.

If you want to start PoSHServer as a PowerShell process, just open a PowerShell console and type:

- `Start-PoSHServer`

That makes PoSHServer to run on that PowerShell session. If you close that PowerShell window, that will stop PoSHServer. You can get examples by typing:

- `Get-Help Start-PoSHServer –full`

By default, PoSHServer listens port 8080. But you can change it by specifying new port. For example, if you want to publish a website called poshserver.net from port 80:

- `Start-PoSHServer -Hostname "poshserver.net,www.poshserver.net" -Port 80`

When you try to start PoSHServer, you may see “Please execute PoSH Server with administrative privileges. Aborting” message. You can fix this issue by clicking “Run as Administrator” on your PowerShell shortcut.

If you see the welcome message in your shell window, you can go to your browser to browse your website.

TODO: Write rest of documentation