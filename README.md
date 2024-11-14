# Installation guide

Updated as of 18/09/2024.

Source: https://docs.flutter.dev/get-started/install/windows/mobile


## For development
  It is recommended to use Visual Studio Code with the "Flutter" extension

  - System requirements:
      Flutter supports 64-bit versions of Windows 10 or higher.
      These versions of Windows must include Windows PowerShell version 5 or higher.
    
  - Development tools:
    Download and install the Windows version of the following packages:

     1. Git for Windows 2.27 or later to manage source code.

     2. Android Studio 2023.3.1 (Jellyfish) or later to debug and compile Java or Kotlin code for Android.
     
    Flutter requires the full version of Android Studio.

    The developers of the preceding software provide support for those products. 
    To troubleshoot installation issues, consult that product's documentation.

  - Configure a text editor or IDE:
      You can build apps with Flutter using any text editor or integrated development environment (IDE) combined with Flutter's command-line tools.

      Using an IDE with a Flutter extension or plugin provides code completion, syntax highlighting, widget editing assists, debugging, and other features.

  - Recommended:
      The Flutter team recommends installing Visual Studio Code 1.77 or later and the Flutter extension for VS Code.
      This combination simplifies installing the Flutter SDK.

## Install the Flutter SDK

  To install the Flutter SDK, you can use the VS Code Flutter extension or download and install the Flutter bundle yourself.

  Use VS Code to install:
  
    To install Flutter using these instructions, verify that you have installed 
    Visual Studio Code 1.77 or later and the Flutter extension for VS Code.

  Prompt VS Code to install Flutter:
  
    1. Launch VS Code.
    
    2.  To open the Command Palette, press Control + Shift + P.
    
    3.  In the Command Palette, type flutter.
    
    4.  Select Flutter -> New Project.
    
    5.  VS Code prompts you to locate the Flutter SDK on your computer.
    
      a.  If you have the Flutter SDK installed, click Locate SDK.
      
      b.  If you do not have the Flutter SDK installed, click Download SDK.
          This option sends you the Flutter install page if you have not installed Git for Windows 
          as directed in the development tools prerequisites.
          
    6. When prompted Which Flutter template?, ignore it. Press Esc. You can create a test project after checking your development setup.

  Download the Flutter SDK:

    1. When the Select Folder for Flutter SDK dialog displays, choose where you want to install Flutter.
       VS Code places you in your user profile to start. Choose a different location.
       
       Consider %USERPROFILE% or C:\dev.
       
       Click Clone Flutter.
       
    2. While downloading Flutter, VS Code displays this pop-up notification
    
       "Downloading the Flutter SDK. This may take a few minutes."
      
       This download takes a few minutes. If you suspect that the download has hung, click Cancel then start the installation again.
       
    3. Once it finishes downloading Flutter, the Output panel displays.
    
            "Checking Dart SDK version...
            
            Downloading Dart SDK from the Flutter engine ...
            
            Expanding downloaded archive..."
            
        When successful, VS Code displays this pop-up notification
        
            "Initializing the Flutter SDK. This may take a few minutes."
            
        While initializing, the Output panel displays the following
        
            "Building flutter tool...
            
            Running pub upgrade...
            
            Resolving dependencies...
            
            Got dependencies.
            
            Downloading Material fonts...
            
            Downloading Gradle Wrapper...
            
            Downloading package sky_engine...
            
            Downloading flutter_patched_sdk tools...
            
            Downloading flutter_patched_sdk_product tools...
            
            Downloading windows-x64 tools...
            
            Downloading windows-x64/font-subset tools..."
            
        This process also runs flutter doctor -v. At this point in the procedure, ignore this output. 
        Flutter Doctor might show errors that don't apply to this quick start. 
        When the Flutter install succeeds, VS Code displays this pop-up notification
        
            "Do you want to add the Flutter SDK to PATH so it's accessible
            in external terminals?"
            
    4. Click Add SDK to PATH.
    
        When successful, a notification displays
        
        "The Flutter SDK was added to your PATH"
        
    5. To enable flutter in all PowerShell windows
    
        Close, then reopen all PowerShell windows.
        Restart VS Code.




