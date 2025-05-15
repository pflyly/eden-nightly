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

> [!IMPORTANT]
> This repository makes nightly release of eden for Linux, Linux-arm64, Android, MacOS and Windows.
>  
> For Linux, the AppImage is made with several flags of optimization especially targeted for **Steamdeck** & **ROG ALLY X** & **Modern CPUs**(Common Build) & **AArch64**.

* [**Latest Nightly Release Here**](https://github.com/pflyly/eden-nightly/releases/latest)

---------------------------------------------------------------
This repo is ported from my [citron-nightly repo](https://github.com/pflyly/Citron-Nightly), which is a fork based on the work of **@Samueru-sama**.

It is possible that this appimage may fail to work with appimagelauncher, I recommend these alternatives instead: 

* [AM](https://github.com/ivan-hc/AM) `am -i eden` or `appman -i eden`

* [dbin](https://github.com/xplshn/dbin) `dbin install eden.appimage`

* [soar](https://github.com/pkgforge/soar) `soar install eden`

This appimage works without fuse2 as it can use fuse3 instead, it can also work without fuse at all thanks to the [uruntime](https://github.com/VHSgunzo/uruntime)
