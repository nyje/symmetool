# Symmetool Mirror
***(c)2019 Nigel Garnett***

A building tool for MineTest which places multiple blocks based on the current mode of its marker's symmetry settings.

### Description & caveats ###
It is designed to speed up building structures which have mirror symmetry in one, two or all three dimensions. It does this by mirroring nodes placed or dug with the tool in the X, Y & Z directions across a 'virtual mirror' which is marked by the tool placed 'in world'.

It can be used in creative mode, or in survival. For survival mode it soft depends on default for its crafting recipe:

    "default:glass"        "default:steel_ingot"      "default:glass"
    "default:steel_ingot"  "default:meselamp"         "default:steel_ingot"
    "default:glass"        "default:steel_ingot"      "default:glass"

In survival mode, the materials the tool tries to use for building must be available in your main inventory somewhere.

It has only been tested on desktop but only uses the left/right mouse buttons, so should work fine on phones/tablets. In this case I believe "***double tap***"="***right click***" _(how you place stuff)_ and "***long tap***"="***left click***" _(how you dig stuff)_, although this is entirely untested ;-)

Testing has shown that protection mods are respected, the mod ***should*** be safe to use on multiplayer servers.

### Basics ###
Place the symmetry tool as you would any normal block. This creates the marker which will act as the mirror across which nodes will be mirrored.

At this stage (or any time the tool is not 'loaded' _(see below)_) the controls do the following:
- ***Left clicking the node*** will remove it _(or it can be dug as normal whilst holding almost any other node)_.
- ***Right clicking on the node*** will cycle through the symmetry modes, which are shown visually, and in the in game chat. After ten seconds, the visual markers will disappear, but the node's infotext will indicate the mirroring mode.
- ***Left clicking another node*** will load that node into the tool, and from now on right clicking will build with that node.
- ***Right clicking another node*** will move the mirror node to the clicked position (you can only have one mirror node in world at any time).


From now on, until the tool is unloaded:
- ***Right Click*** will place the loaded node in the world, and will also place a node on the opposite side of the mirror node, the same distance as you are from the mirror for every axis you have chosen.
- ***Left Click*** will dig the node you are pointing at, and also dig the node in the mirrored positions for each axis.
- ***Left clicking the sky (or nothing)*** will unload the tool so you can choose another node to build with.


Protection is respected for each individual node placement or removal, so the tool should be safe for multiplayer use.


Happy building ;-)
