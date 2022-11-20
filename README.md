# Focus

Focus on a single app -- blur out the rest. 

<p align="center">
  <img src="https://raw.githubusercontent.com/takeiteasy/Focus/master/screenshot.png">
</p>

## Usage

Pass the name of an app, e.g. ```focus -a Xcode``` to focus on Xcode. Once Xcode loses focus, focus (this app) ends.

```
usage: focus -a [app] [options]

    -a/--app      App name to focus    [default: Currently running app]
    -o/--opacity  Background opacity   [value: 0-1, default: .5]
    -c/--color    Background color     [value: #hex, default: #333333]
    -b/--blur     Blur radius          [value: 1-100, default: 20]
    -h/--help     Show this message
```

To build the CLI program, run ```make```. To build the app, run ```make app```. Or build the Xcode project with [xcodegen](https://github.com/yonaskolb/XcodeGen) to build the .app version. The app version brings up a dialog to select an app to focus.

## License
```
The MIT License (MIT)

Copyright (c) 2022 George Watson

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
