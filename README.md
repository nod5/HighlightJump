# HighlightJump

AutoHotkey app to add, remove and jump to color highlights in SumatraPDF  

Version 2020-02-09  -  Free software GPLv3  -  by Nod5  
  
[![HighlightJump Feature Overview](https://github.com/nod5/HighlightJump/blob/master/images/HighlightJump_youtube_screenshot.png?raw=true)](https://www.youtube.com/watch?v=AcVI616W5D8 "HighlightJump Feature Overview")

# Setup  
1. Get [SumatraPDF Prerelease](https://www.sumatrapdfreader.org/prerelease.html) version  

2. In SumatraPDF > Settings > Advanced Options:  
   `SaveIntoDocument = false`  
    `FullPathInTitle = true`  

3. Install [AutoHotkey](https://www.autohotkey.com/) unicode

# Use
[Download repo](https://github.com/nod5/HighlightJump/archive/master.zip), unzip and run `HighlightJump.ahk`  
There is no UI. Use keyboard and mouse shortcuts.  
Use tray icon to close or show help.  
Tip: Copy a `HighlightJump.ahk` shortcut to Startup folder in Windows.  

# Keyboard shortcuts
<kbd>A</kbd> or <kbd>Y</kbd> : Highlight selection yellow  
<kbd>A (hold)</kbd> : cycle highlight color: yellow > red > green > cancel  

<kbd>R</kbd> : Highlight selection red  
<kbd>G</kbd> : Highlight selection green  
<kbd>D</kbd> : Make a blue square dot at the mouse pointer ("D for dot")  

<kbd>E (hold)</kbd> : Remove all highlighting mouse moves over ("E for erase")  
<kbd>Ctrl + Delete</kbd> : Remove all highlighting on active page  

<kbd>Win + A</kbd> : Hide/Show all highlighting  

<kbd>Ctrl + PgUp/PgDn</kbd> : Jump to next/previous page with highlight  
<kbd>Ctrl + Home/End</kbd> : Jump to first/last page with highlight  

<kbd>Ctrl + Shift + Y/R/G/D</kbd> : select jump filter color  
<kbd>Ctrl + Shift + A</kbd> : cycle jump filter colors  
<kbd>Ctrl + Shift + PgUp/PgDn</kbd> : Jump to next/previous filter color page  
<kbd>Ctrl + Shift + Home/End</kbd> : Jump to first/Last filter color page  

# Quick jump shortcuts
<kbd>1/2/3/4 (hold)</kbd> : temporarily store current page number  
<kbd>1/2/3/4 (tap)</kbd> : jump to stored page (tap again to undo jump)  
<kbd>5</kbd> : show list of stored pages  

# Mouse shortcuts
<kbd>Lbutton + Rbutton</kbd> : Highlight selected text yellow  
<kbd>Lbutton + Rbutton (hold)</kbd> : Cycle highlight color: yellow > red > green > cancel  

<kbd>Rbutton + Mbutton</kbd> : Make a blue square dot at the mouse pointer  

<kbd>Rbutton + Lbutton (hold)</kbd> : Remove all highlighting mouse moves over  

<kbd>Rbutton (hold) + Scroll Up/Down</kbd> : Jump to next/previous page with highlight  

<kbd>Ctrl + Lbutton (click drag)</kbd> : Draw rectangle, then <kbd>A/Y/R/G</kbd> to make highlight

# License  
Free Software GPLv3 by github.com/nod5  
Icon CC-BY-3.0 by p.yusukekamiyamane.com  

# FAQ

**Q** Why does HighlightJump exist?  
**A** HighlightJump is "feature request ware". I hope someone builds this into SumatraPDF.  

**Q** Why does HighlightJump only work in SumatraPDF Prerelease?  
**A** Regular SumatraPDF does not (yet) have the feature to make highlights ("A" shortcut).  

**Q** Why are edits to SumatraPDF advanced settings required?  
**A** Saving annotations (highlighting) to an external plaintext file `filename.pdf.smx` is necessary for HighlightJump to read/edit them. Showing full file path in window title is currently necessary for HighlightJump to know the file path. There is an experimental workaround, see further down.  

**Q** I do not like that `R` and `G` override [SumatraPDF shortcuts](https://www.sumatrapdfreader.org/manual.html).  
**A** Easy recall ("R for red") can be worth a small shortcut conflict. HighlightJump creates `Ctrl+R` as replacement `reload` shortcut and SumatraPDF already has `Ctrl+G` for `go to`. If you disagree then in `HighlightJump.ahk.ini` set `RedGreenRG=0`. That makes `Y` red and `U` green.  

**Q** How do the quick jump keys work?  
**A** Hold down one of `1 / 2 / 3 / 4` to store the current pagenumber. Later tap (short press) that key again to jump to the stored page. While on that page tap again to undo the jump. Press `5` to show a list of stored pages. Use it for temporary jumps. Clears when HighlightJump is closed. Independent from highlights. Similar to [MuPDF Viewer](https://mupdf.com/docs/manual-mupdf-gl.html) numbered bookmarks.  

**Q** What file encoding should be used?  
**A** The correct encoding for `HighlightJump.ahk` is `UTF-8 BOM`. See AutoHotkey [FAQ](https://www.autohotkey.com/docs/FAQ.htm#nonascii). The download from GitHub has that encoding.  

# Experimental: improved methods
HighlightJump has experimental methods to get the active document file path and canvas position via SendMessage. Improvements compared to default methods: faster, more reliable, silent, and no `FullPathInTitle` setting required.  

To try the experimental features:  
- Edit [SumatraPDF](https://github.com/sumatrapdfreader/sumatrapdf) C++ source via instructions in folder `SumatraPDF_modifications` and compile as `32-bit Debug` version.  
- In `HighlightJump.ahk.ini` set `Experimental=1`.  

See also SumatraPDF repo issues [1411](https://github.com/sumatrapdfreader/sumatrapdf/issues/1411) and  [1412](https://github.com/sumatrapdfreader/sumatrapdf/issues/1412)  
