# Company Portal Dependencies

This folder contains the full set of offline Company Portal dependencies across all architectures. These are the source files downloaded from Microsoft.

## Contents

| File | Architectures |
|---|---|
| `*.appxbundle` | Company Portal offline bundle |
| `*_License1.xml` | Offline license file |
| `Microsoft.VCLibs.140.00` | arm, arm64, x64, x86 |
| `Microsoft.NET.Native.Framework.2.2` | arm, arm64, x64, x86 |
| `Microsoft.NET.Native.Runtime.2.2` | arm, arm64, x64, x86 |
| `Microsoft.UI.Xaml.2.7` | arm, arm64, x64, x86 |
| `Microsoft.Services.Store.Engagement` | arm, arm64, x64, x86 |

## Source

Download the offline Company Portal package from the Microsoft Download Center:

https://www.microsoft.com/en-us/download/details.aspx?id=108156

## Step-by-Step: Download and Extract Dependencies

1. Go to the [Microsoft Download Center](https://www.microsoft.com/en-us/download/details.aspx?id=108156)
2. Download the offline Company Portal package
3. Extract the contents — you will get the `.appxbundle`, license XML, and all framework dependency `.appx` files across all architectures
4. Place all extracted files in this folder for reference
5. Copy only the **x64** `.appx` dependencies, the `.appxbundle`, and the `*_License1.xml` into the `Win32/` folder for packaging

## Usage

The `Win32/` folder only includes the x64 dependencies needed for deployment. This folder retains the full set of dependencies across all architectures for reference or if x86/arm/arm64 support is needed in the future.
