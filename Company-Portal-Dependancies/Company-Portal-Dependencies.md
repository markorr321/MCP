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

## Usage

The `Win32/` folder only includes the x64 dependencies needed for deployment. This folder retains the full set of dependencies across all architectures for reference or if x86/arm/arm64 support is needed in the future.
