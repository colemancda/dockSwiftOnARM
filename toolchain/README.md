<h2>macOS -> RasPi Cross Compilation Toolchain
  <img src="http://zeezide.com/img/rpi-swift.svg?2"
       align="right" width="180" height="180" />
</h2>

![Swift3](https://img.shields.io/badge/swift-3-blue.svg)
![tuxOS](https://img.shields.io/badge/os-Xenial-green.svg?style=flat)
![ARM](https://img.shields.io/badge/cpu-ARM-red.svg?style=flat)

End of April
[Johannes Weiß](https://github.com/weissi)
added
[custom toolchain support](https://github.com/apple/swift-package-manager/pull/1098)
to 
[Swift Package Manager](https://github.com/apple/swift-package-manager).
Johannes also provided 
[a script](https://github.com/apple/swift-package-manager/blob/master/Utilities/build_ubuntu_cross_compilation_toolchain)
which shows how to build an Ubuntu toolchain for x86-64.

So what we did is take that script and make it produce a Swift 3.1.1 cross 
compiler toolchain for the Raspberry Pi (armhf) Ubuntu Xenial port.

What this is good for?
You can build Raspberry Pi Swift binaries on a Mac. Like this:
```
mkdir helloworld && cd helloworld
swift package init --type=executable
swift build --destination /tmp/cross-toolchain/rpi-ubuntu-xenial-destination.json
file .build/debug/helloworld
.build/debug/helloworld: ELF 32-bit LSB executable, ARM, 
                         EABI5 version 1 (SYSV), dynamically linked, 
                         interpreter /lib/ld-linux-armhf.so.3, 
                         for GNU/Linux 3.2.0, not stripped
```

## Building the ARM toolchain

What we are going to do is build a Swift 3.1.1 cross compilation toolchain
for ARM Ubuntu Xenial.

### Step 1: Install recent Swift Snapshot

To do this, we need to install a recent version of Swift Package Manager.
And the easiest way to do this, is to install a recent 
[Swift snapshot](https://swift.org/download/#snapshots).
We tried `swift-DEVELOPMENT-SNAPSHOT-2017-05-09-a`:
[Download](https://swift.org/builds/development/xcode/swift-DEVELOPMENT-SNAPSHOT-2017-05-09-a/swift-DEVELOPMENT-SNAPSHOT-2017-05-09-a-osx.pkg).
Download the Xcode package and install it on your Mac.

*Note*: Snapshots require macOS 10.12, they do not run on macOS 10.11.

*Note*: We are indeed building a 3.1.1 toolchain! We are just using the
        Swift Package Manager from the snapshot.

The next step is to enable the swift tools from that snapshot. I use 
[swiftenv](https://swiftenv.fuller.li/en/latest/installation.html#via-homebrew)
for that, if you don't have it:

```
brew install kylef/formulae/swiftenv
echo 'if which swiftenv > /dev/null; then eval "$(swiftenv init -)"; fi' >> ~/.bash_profile
eval "$(swiftenv init -)"
```

And then enable the snapshot (use `swiftenv versions` to list the ones you
have available):

```
swiftenv global DEVELOPMENT-SNAPSHOT-2017-05-09-a
```

OK, good to go :-)

### Step 2: Build Toolchain using Script

First download our script and make it executable:
[build_rpi_ubuntu_cross_compilation_toolchain](https://raw.githubusercontent.com/helje5/dockSwiftOnARM/master/toolchain/build_rpi_ubuntu_cross_compilation_toolchain),
e.g. like:

```
pushd /tmp
curl https://raw.githubusercontent.com/helje5/dockSwiftOnARM/master/toolchain/build_rpi_ubuntu_cross_compilation_toolchain \
  | sed "s/$(printf '\r')\$//" \
  > build_rpi_ubuntu_cross_compilation_toolchain
chmod +x build_rpi_ubuntu_cross_compilation_toolchain
```

You can just call the script and it'll give you instructions, but let's just
go ahead.
Next step is to download Swift 3.1.1 tarballs. 
We need the macOS pkg for the host compiler and a Raspberry Pi tarball for the
Swift runtime. We use the one provided by Florian Friedrich for the latter:

```
pushd /tmp
curl -o /tmp/swift-3.1.1-armv7l-ubuntu16.04.tar.gz https://cloud.sersoft.de/nextcloud/index.php/s/0qty8wJxlgfVCcx/download
curl -o /tmp/swift-3.1.1-RELEASE-osx.pkg https://swift.org/builds/swift-3.1.1-release/xcode/swift-3.1.1-RELEASE/swift-3.1.1-RELEASE-osx.pkg
```
Those are a little heavy (~400 MB), so grab a 🍺 or 🍻.
Once they are available, build the actual toolchain using the script:

```
./build_rpi_ubuntu_cross_compilation_toolchain \
  /tmp/ \
  /tmp/swift-3.1.1-RELEASE-osx.pkg \
  /tmp/swift-3.1.1-armv7l-ubuntu16.04.tar.gz
```

If everything worked fine, it'll end like that:
```
OK, your cross compilation toolchain for Raspi Ubuntu Xenial is now ready to be used
 - SDK: /tmp/cross-toolchain/rpi-ubuntu-xenial.sdk
 - toolchain: /tmp/cross-toolchain/swift.xctoolchain
 - SwiftPM destination.json: /tmp/cross-toolchain/rpi-ubuntu-xenial-destination.json
```

### Step 3: Use the Toolchain

Let create a simple `helloworld` tool first:

```
mkdir helloworld && cd helloworld
swift package init --type=executable
swift build --destination /tmp/cross-toolchain/rpi-ubuntu-xenial-destination.json
```

## Testing builds using Docker on macOS

Docker for Mac comes with QEmu support enabled, meaning that you can run
simple ARM binaries without an actual Raspberry Pi.

```
docker run --rm --tty -i -v $PWD:/host helje5/rpi-swift:3.1.1 \
       /host/.build/debug/helloworld 
```

This works for simple builds, more complex stuff does not run in QEmu. Use
a proper Pi for that :-)


## Notes of interest

- SwiftPM reuses the name `.build` directory even if you call it w/ 
  different destinations. So make sure you clean before building for a
  different architecture.
- Ubuntu system headers and such for the toolchain are directly pulled
  from the Debian packages
- The cross compiler is just a regular clang/swiftc provided as part of
  a macOS toolchain. Yes, clang/swift are always setup as cross compilers
  and can produce binaries for all supported targets! (didn't know that)
- To trace filesystem calls on macOS you can use `fs_usage`, e.g.:
  `sudo fs_usage -w -f pathname swift` (only new `strace` ;-)

### Who

Brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We like feedback, GitHub stars, cool contract work,
presumably any form of praise you can think of.
We don't like people who are wrong.

There is the [swift-arm](https://slackpass.io/swift-arm) Slack channel
if you have questions about running Swift on ARM/Raspberry Pi.
