Go to Tools->Screenshot to open the window. Settings are saved in the operating system's registry, on a per-project basis.

Preferences:
--------------------
Go to Edit->Preferences->Screenshot tab. This can also be accessed through the window's context menu, which has an "Open Settings" item.

Here you can configure the filename- and date format for screenshots.

The "Print-screen button" option only takes effect if the window is open

Cinemachine:
---------------------
If your main camera has a CinemachineBrain component attached to it, the camera cannot be temporarly moved for a scene-view screenshot.

Open the ScreenshotUtility.cs file and uncomment the first line (#define CINEMACHINE). 
This will temporarily disable the CinemachineBrain component when capturing.