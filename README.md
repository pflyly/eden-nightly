<h1 align="left">
  <br>
  <a href="https://git.eden-emu.dev/eden-emu/eden"><img src="https://git.eden-emu.dev/eden-emu/eden/raw/branch/master/dist/eden.ico" width="200"></a>
  <br>
  <b>Eden Nightly Release</b>
  <br>
</h1>

[![GitHub Release](https://img.shields.io/github/v/release/pflyly/eden-nightly?label=Current%20Release)](https://github.com/pflyly/eden-nightly/releases/latest)
[![GitHub Downloads](https://img.shields.io/github/downloads/pflyly/eden-nightly/total?logo=github&label=GitHub%20Downloads)](https://github.com/pflyly/eden-nightly/releases/latest)
[![CI Build Status](https://github.com//pflyly/eden-nightly/actions/workflows/build-nightly.yml/badge.svg)](https://github.com/pflyly/eden-nightly/releases/latest)

## Release Overview

This repository provides **nightly releases** of **Eden** for the following platforms:

- **Linux** (`x86_64`, `aarch64`)
- **Android**
- **Windows** (`x86_64`, `arm64`) — **ARM64 is canceled for now**
- **MacOS** (`x86_64`, `arm64`)

> [!IMPORTANT]
> This repository is intended to provide an easy way to try out the latest features from recent commits — that's what **Nightly** builds are for!
> 
> These builds are **experimental and may be unstable**, so use them at your own discretion.

---------------------------------------------------------------

### 🐧 Linux Builds

The builds for Linux are built with several CPU-specific compliler optimization flags targeting:

- **Steam Deck** — optimized for `znver2` (Zen 2)
- **AArch64 devices** — compatible with `aarch64` architecture
- **Modern x86_64 CPUs** — optimized for `x86-64-v3` (via the Common Build)

AppImages built using [**Sharun**](https://github.com/VHSgunzo/sharun) are bundled with **Mesa drivers** to ensure maximum compatibility — similar to Eden’s official releases and may include the latest fixes for certain games (though untested).

A newly added **AppBundle** version, built with [**pelf**](https://github.com/xplshn/pelf), serves as an alternative to AppImage. It's a lightweight format written in Go and intended for broader Linux compatibility.

A **Light version** Appimage is also available, built with **linuxdeploy**. It does **not** include Mesa drivers, resulting in a more lightweight build that relies on the system’s native graphics drivers — similar to many other emulators.

> ⚠️ The `aarch64` build is based on a workaround change and is intended for testing purposes only.
>
> If you encounter any problems, you're welcome to open an issue.

These builds should work on any linux distro.

---------------------------------------------------------------

### 🤖 Android Builds

Eden nightly for Android is available in two versions:

- **Replace** Build
  
Shares the same application ID as the official Eden release. Installing this version will replace the official app on your device. It appears as "**eden**" on the home screen.

- **Coexist** Build
  
Uses a nightly application ID, allowing it to coexist with the official Eden release. It appears as "**eden nightly**" on the home screen, and "**Eden Nightly**" on the main screen of eden.

---------------------------------------------------------------

### 🪟 Windows Builds

> ⚠️ The Windows **ARM64** build is based on **work-in-progress (WIP)** changes and is intended for testing purposes only.
>
> If you encounter any problems, you're welcome to open an issue.

---------------------------------------------------------------

### 🍎 MacOS Builds

> ⚠️ MacOS builds are **not officially supported** at the moment and are provided for **testing purposes only**.
>   
> Functionality may be limited and issues are expected. If you encounter any problems, you're welcome to open an issue.


---------------------------------------------------------------


* [**Latest Nightly Release Here**](https://github.com/pflyly/eden-nightly/releases/latest)


---------------------------------------------------------------
This repo is ported from my [citron-nightly repo](https://github.com/pflyly/Citron-Nightly), which is a fork based on the work of **@Samueru-sama**.

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i eden-nightly` or `appman -i eden-nightly`

* [dbin](https://github.com/xplshn/dbin) `dbin install eden-nightly.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install eden-nightly`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)
