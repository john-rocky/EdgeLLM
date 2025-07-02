# Xcode View Debugger Issue Fix

## Error
```
dyld[8414]: Symbol not found: _OBJC_CLASS_$_AVPlayerView
Referenced from: libViewDebuggerSupport.dylib
Expected in: AVKit.framework
```

## Solutions

### Option 1: Disable View Debugger (Recommended for Testing)
1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** on the left
3. Go to the **Diagnostics** tab
4. Uncheck **"View Debugging"** under Runtime API Checking
5. Click **Close**
6. Run the app again

### Option 2: Run on Real iOS Device
- Connect an iPhone or iPad
- Select it as the target device
- This issue only occurs on simulators/Mac Catalyst

### Option 3: Clean Build
1. **Product** → **Clean Build Folder** (Shift+Cmd+K)
2. Delete derived data:
   - **Xcode** → **Settings** → **Locations**
   - Click arrow next to **Derived Data**
   - Delete the folder for SimpleChat
3. Restart Xcode
4. Build and run again

### Option 4: Use Different Simulator
- Try iOS 17.x simulator instead of iOS 18.x
- Or use iPhone 14/15 simulator

This is a known Xcode issue and doesn't affect the actual app functionality.