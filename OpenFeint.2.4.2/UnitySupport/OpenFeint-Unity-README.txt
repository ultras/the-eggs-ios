********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************

                          OpenFeint Unity Support 2.0

                          release date 1.15.2010

                              Release Notes

        Copyright (c) 2009-2010 Aurora Feint Inc. All Rights Reserved.

********************************************************************************

********************************************************************************
********************************************************************************
********************************************************************************

This document explains how to integrate the OpenFeint-UnityiPhone package.

Below is a step by step explanation for the integration process.

1. If this is a new Unity project, make sure to set up your Player settings first (Edit->Project Settings->Player). This is required for the automation process to work properly.
2. In Unity, go to "Assets->Import Package..." and import the attached Unity package.
3. Note the new "OpenFeint" menu item in the menu bar. Click on this and go to "Set Application Initialization Settings...". In this dialog, set up all of the OpenFeint initialization settings and click Apply. This step only needs to be done once for each application. It is recommended that you turn "Allow Notifications" on.
4. If desired, copy your "openfeint_offline_config.xml" into the "Editor/OpenFeint/Offline Config File Goes Here" folder. You will need to do this every time you make a change to achievements or leaderboards through the developer dashboard.
6. For your first build with OF support (and anytime you need to do anything other than an "Append" build in Unity), make sure that the Xcode project isn't open as it causes problems. We're looking for a solution for this.
7. Go to Unity "Build Settings" (File->Build Settings...) and "Build" the project (not "Build & Run" for the first build; subsequent builds of the project can use Build & Run though).
8. Follow the instructions in the OpenFeint readme.txt file. These are steps for adding OpenFeint to your xcode project. You only need to do this once.
9. Hit "Build & Run". Your application will launch on your iPhone and the OpenFeint welcome screen will appear on your first run.
10. Use the handy methods, events, and properties located in "Plugins/OpenFeint.cs" to hook up achievements, leaderboards etc.

NOTE: If you want to build for an iPhone OS prior to 3.0 it is important that you follow the instructions in the OpenFeint readme.txt file for weak linking your libraries. 
