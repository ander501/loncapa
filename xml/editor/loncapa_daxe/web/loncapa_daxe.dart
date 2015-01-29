/*
  This file is part of LON-CAPA.

  LON-CAPA is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  LON-CAPA is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with LON-CAPA.  If not, see <http://www.gnu.org/licenses/>.
*/

library loncapa_daxe;

import 'dart:async';
import 'dart:collection';
import 'dart:html' as h;
import 'package:daxe/daxe.dart';
import 'package:daxe/src/xmldom/xmldom.dart' as x;
import 'package:daxe/src/strings.dart';
import 'package:daxe/src/nodes/nodes.dart' show DNCData, DNText, SimpleTypeControl;
import 'dart:js' as js;

import 'lcd_strings.dart';
part 'nodes/lcd_block.dart';
part 'nodes/tex_mathjax.dart';
part 'lcd_button.dart';


void main() {
  NodeFactory.addCoreDisplayTypes();
  
  addDisplayType('lcdblock',
        (x.Element ref) => new LCDBlock.fromRef(ref),
        (x.Node node, DaxeNode parent) => new LCDBlock.fromNode(node, parent)
    );
  
  addDisplayType('texmathjax',
        (x.Element ref) => new TeXMathJax.fromRef(ref),
        (x.Node node, DaxeNode parent) => new TeXMathJax.fromNode(node, parent)
    );
  
  Future.wait([Strings.load(), LCDStrings.load()]).then((List responses) {
    _init_daxe().then((v) {
      ToolbarMenu sectionMenu = _makeSectionMenu();
      if (sectionMenu != null)
        page.toolbar.add(sectionMenu);
      x.Element texRef = doc.cfg.elementReference('m');
      if (texRef != null) {
        ToolbarBox insertBox = new ToolbarBox();
        ToolbarButton texButton = new ToolbarButton(
            LCDStrings.get('tex_equation'), 'images/tex.png',
            () => doc.insertNewNode(texRef, 'element'), Toolbar.insertButtonUpdate, 
            data:new ToolbarStyleInfo([texRef], null, null));
        insertBox.add(texButton);
        page.toolbar.add(insertBox);
      }
      h.Element tbh = h.querySelector('.toolbar');
      tbh.replaceWith(page.toolbar.html());
      page.adjustPositionsUnderToolbar();
      page.updateAfterPathChange();
    });
  });
}

Future _init_daxe() {
  Completer completer = new Completer();
  doc = new DaxeDocument();
  page = new WebPage();
  
  // check parameters for a config and file to open
  String file = null;
  String config = null;
  String saveURL = null;
  h.Location location = h.window.location;
  String search = location.search;
  if (search.startsWith('?'))
    search = search.substring(1);
  List<String> parameters = search.split('&');
  for (String param in parameters) {
    List<String> lparam = param.split('=');
    if (lparam.length != 2)
      continue;
    if (lparam[0] == 'config')
      config = lparam[1];
    else if (lparam[0] == 'file')
      file = Uri.decodeComponent(lparam[1]);
    else if (lparam[0] == 'save')
      saveURL = lparam[1];
  }
  if (saveURL != null)
    doc.saveURL = saveURL;
  if (config != null && file != null)
    page.openDocument(file, config).then((v) => completer.complete());
  else if (config != null)
    page.newDocument(config).then((v) => completer.complete());
  else {
    h.window.alert(Strings.get('daxe.missing_config'));
    completer.completeError(Strings.get('daxe.missing_config'));
  }
  return(completer.future);
}

ToolbarMenu _makeSectionMenu() {
  Menu menu = new Menu(LCDStrings.get('Section'));
  List<x.Element> sectionRefs = doc.cfg.elementReferences('section');
  if (sectionRefs == null || sectionRefs.length == 0)
    return(null);
  x.Element h1Ref = doc.cfg.elementReference('h1');
  for (String role in ['introduction', 'conclusion', 'prerequisites', 'objectives',
                       'reminder', 'definition', 'demonstration', 'example', 'advise',
                       'remark', 'warning', 'more_information', 'method',
                       'activity', 'bibliography', 'citation']) {
    MenuItem menuItem = new MenuItem(LCDStrings.get(role), null,
        data:new ToolbarStyleInfo(sectionRefs, null, null));
    menuItem.action = () {
      ToolbarStyleInfo info = menuItem.data;
      x.Element sectionRef = info.validRef;
      DaxeNode section = NodeFactory.create(sectionRef);
      section.setAttribute('class', 'role-' + role);
      DaxeNode h1 = NodeFactory.create(h1Ref);
      if (doc.insert2(section, page.getSelectionStart())) {
        doc.insertNode(h1, new Position(section, 0));
        page.cursor.moveTo(new Position(h1, 0));
        page.updateAfterPathChange();
      }
    };
    menu.add(menuItem);
  }
  ToolbarMenu tbmenu = new ToolbarMenu(menu, Toolbar.insertMenuUpdate, page.toolbar);
  return(tbmenu);
}

