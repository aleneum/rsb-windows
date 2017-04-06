Setup and build.bat to build a working dynamically linked [RSB](http://docs.cor-lab.org/rsb-manual/0.15/html/) environment for Windows.

Fixed library versions contain:

* boost -- boost-1.62.0
* protobu -- v2.6.1
* rsx -- 0.15

All values can easily be adapted in the header of `build.bat`

### Usage

```
$ git clone https://github.com/aleneum/rsb-windows.git
cd rsb-windows
build.bat [arch] [mscver] [target] [rstUrl]
```

* `arch` -- Target architecture of the system. May be `x86` or `x64`.
* `mscver` -- Microsoft Studio Version. Tested with `14`.
* `target` -- Build target of the environment. Values may be `Release` oder `Debug`.
* `rstUrl` -- Optional URL to RST-Git. If omitted, RST will not be built.

After a successful built, the finished built will be available under `build\arch\mscver\target`.
It consists of several folders where `bin` contains all DLLs and executables and `lib` will contain used libraries.
