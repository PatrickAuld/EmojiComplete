## Emojicomplete

Get Emojis when you need them


### Installation

Emojicomplete is an extension for [Hammerspoon](http://hammerspoon.org/). Once Hammerspoon is installed (see [install Hammerspoon](#install-hammerspoon) below) you can run the following script to install Emojicomplete.

    $ curl -sSL https://raw.githubusercontent.com/PatrickAuld/EmojiComplete/master/install.sh | bash

[install.sh](https://github.com/PatrickAuld/Emojicomplete/blob/master/install.sh) just clones this repository into `~/.hammerspoon`, loads it into Hammerspoon and sets `⌃⌥⌘G` as the default keybinding.

#### Manual installation

    $ git clone https://github.com/PatrickAuld/EmojiComplete.git ~/.hammerspoon/emojicomplete

To initialize, add to `~/.hammerspoon/init.lua` (creating it if it does not exist):

    local emojicomplete = require "emojicomplete/emojicomplete"
    emojicomplete.registerDefaultBindings()

Alternatively, copy `emojicomplete.lua` from this repository to wherever
you keep other Hammerspoon modules and load it appropriately.

Reload the Hammerspoon config.

#### Install Hammerspoon

Hammerspoon can be installed using [homebrew/caskroom](https://caskroom.github.io/).

    $ brew cask install hammerspoon
    $ open -a /Applications/Hammerspoon.app

Accessibility must be enabled for Emojicomplete to work.

![](https://cloud.githubusercontent.com/assets/220827/20860328/a7dc4344-b975-11e6-893a-bb139ba8a102.png)

### Usage

Trigger with the hotkey `⌃⌥⌘E`. Once you start typing, suggestions will populate.
They can be choosen with `⌘1-9` or by pressing the arrow keys and Enter.
Pressing `⌘C` copies the selected item to the clipboard.

The hotkey can be changed by passing in arguments to
`registerDefaultBindings` call (in your `~/.hammerspoon/init.lua` file)
such as:

    emojicomplete.registerDefaultBindings({"cmd", "ctrl"}, 'L')

### Credits

This uses [Emoji Finder](https://emojifinder.com/) for searching.

The code was forked from [Anycomplete](https://github.com/nathancahill/Anycomplete) a great project that 
uses Google Autocomplete. 
