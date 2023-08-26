import 'dart:async';
import 'dart:io';

import 'package:after_layout/after_layout.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_highlight/theme_map.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_highlight/themes/monokai.dart';
import 'package:toolbox/core/extension/navigator.dart';
import 'package:toolbox/core/utils/misc.dart';
import 'package:toolbox/core/utils/ui.dart';
import 'package:toolbox/data/res/highlight.dart';
import 'package:toolbox/data/store/setting.dart';
import 'package:toolbox/locator.dart';

import '../widget/custom_appbar.dart';
import '../widget/two_line_text.dart';

class EditorPage extends StatefulWidget {
  final String? path;
  const EditorPage({Key? key, this.path}) : super(key: key);

  @override
  _EditorPageState createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> with AfterLayoutMixin {
  late CodeController _controller;
  late final _focusNode = FocusNode();
  final _setting = locator<SettingStore>();
  Map<String, TextStyle>? _codeTheme;
  late S _s;
  late String? _langCode;
  late TextStyle _textStyle;

  @override
  void initState() {
    super.initState();
    _langCode = widget.path.highlightCode;
    _controller = CodeController(
      language: suffix2HighlightMap[_langCode],
    );
    _textStyle = TextStyle(fontSize: _setting.editorFontSize.fetch());

    WidgetsBinding.instance.addPostFrameCallback((Duration duration) async {
      if (isDarkMode(context)) {
        _codeTheme = themeMap[_setting.editorDarkTheme.fetch()] ?? monokaiTheme;
      } else {
        _codeTheme = themeMap[_setting.editorTheme.fetch()] ?? a11yLightTheme;
      }
      _focusNode.requestFocus();
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s = S.of(context)!;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _codeTheme?['root']?.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.done),
        onPressed: () async {
          // If path is not null, then it's a file editor
          // save the text and return true to pop the page
          if (widget.path != null) {
            showLoadingDialog(context);
            await File(widget.path!).writeAsString(_controller.text);
            context.pop();
            context.pop(true);
            return;
          }
          // else it's a text editor
          // return the text to the previous page
          context.pop(_controller.text);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: TwoLineText(up: getFileName(widget.path) ?? '', down: _s.editor),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          onSelected: (value) {
            _controller.language = suffix2HighlightMap[value];
            _langCode = value;
          },
          initialValue: _langCode,
          itemBuilder: (BuildContext context) {
            return suffix2HighlightMap.keys.map((e) {
              return PopupMenuItem(
                value: e,
                child: Text(e),
              );
            }).toList();
          },
        )
      ],
    );
  }

  Widget _buildBody() {
    return Visibility(
      visible: _codeTheme != null,
      replacement: const Center(
        child: CircularProgressIndicator(),
      ),
      child: SingleChildScrollView(
        child: CodeTheme(
          data: CodeThemeData(
              styles: _codeTheme ??
                  (isDarkMode(context) ? monokaiTheme : a11yLightTheme)),
          child: CodeField(
            focusNode: _focusNode,
            controller: _controller,
            textStyle: _textStyle,
            lineNumberStyle: const LineNumberStyle(
              width: 47,
              margin: 7,
            ),
          ),
        ),
      ),
    );
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    if (widget.path != null) {
      await Future.delayed(const Duration(milliseconds: 233));
      final code = await File(widget.path!).readAsString();
      _controller.text = code;
    }
  }
}
