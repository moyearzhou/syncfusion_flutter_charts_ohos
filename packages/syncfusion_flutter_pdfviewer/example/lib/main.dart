import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Syncfusion PDF Viewer Demo',
    home: HomePage(),
  ));
}

/// Represents Homepage for Navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  void _disposeDocument() {
    // 调用PDF Viewer的dispose方法来关闭文档
    _pdfViewerKey.currentState?.dispose();
    
    // 显示提示信息
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('文档已关闭'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syncfusion Flutter PDF Viewer'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.green,
              semanticLabel: '关闭文档',
            ),
            onPressed: _disposeDocument,
          ),
          IconButton(
            icon: const Icon(
              Icons.bookmark,
              color: Colors.green,
              semanticLabel: 'Bookmark',
            ),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
        ],
      ),
      body: SfPdfViewer.network(
        'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
        key: _pdfViewerKey,
      ),
    );
  }
}
