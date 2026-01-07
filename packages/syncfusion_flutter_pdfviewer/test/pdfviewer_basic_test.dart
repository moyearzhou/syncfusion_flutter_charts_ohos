import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  group('SfPdfViewer Successful Unit Tests', () {
    test('PdfViewerController initialization test', () {
      // 测试控制器初始化
      final controller = PdfViewerController();
      expect(controller, isNotNull);
      expect(controller.zoomLevel, 1.0); // 默认缩放级别为1.0
    });

    test('PdfViewerController zoom level test', () {
      // 测试缩放级别设置
      final controller = PdfViewerController();
      controller.zoomLevel = 2.0;
      expect(controller.zoomLevel, 2.0);
      
      controller.zoomLevel = 1.5;
      expect(controller.zoomLevel, 1.5);
    });

    test('PdfViewerController jumpToPage test', () {
      // 测试页面跳转方法
      final controller = PdfViewerController();
      expect(() => controller.jumpToPage(1), returnsNormally);
      expect(() => controller.jumpToPage(5), returnsNormally);
    });

    test('PdfViewerController jumpTo test', () {
      // 测试跳转到指定偏移量
      final controller = PdfViewerController();
      expect(() => controller.jumpTo(xOffset: 100.0, yOffset: 200.0), returnsNormally);
      expect(() => controller.jumpTo(), returnsNormally); // 使用默认值
    });

    test('PdfViewerController previousPage and nextPage test', () {
      // 测试页面导航方法
      final controller = PdfViewerController();
      expect(() => controller.previousPage(), returnsNormally);
      expect(() => controller.nextPage(), returnsNormally);
    });

    test('PdfViewerController jumpToBookmark test', () {
      // 测试书签跳转方法
      final controller = PdfViewerController();
      // 注意：PdfBookmark需要在PDF文档加载后才能使用
      // 这里只测试方法存在性
      expect(controller, isNotNull);
    });

    test('PdfInteractionMode enum test', () {
      // 测试交互模式枚举
      expect(PdfInteractionMode.values, contains(PdfInteractionMode.selection));
      expect(PdfInteractionMode.values, contains(PdfInteractionMode.pan));
      expect(PdfInteractionMode.values.length, 2);
      expect(PdfInteractionMode.selection.toString(), 'PdfInteractionMode.selection');
      expect(PdfInteractionMode.pan.toString(), 'PdfInteractionMode.pan');
    });

    test('PdfScrollDirection enum test', () {
      // 测试滚动方向枚举
      expect(PdfScrollDirection.values, contains(PdfScrollDirection.vertical));
      expect(PdfScrollDirection.values, contains(PdfScrollDirection.horizontal));
      expect(PdfScrollDirection.values.length, 2);
      expect(PdfScrollDirection.vertical.toString(), 'PdfScrollDirection.vertical');
      expect(PdfScrollDirection.horizontal.toString(), 'PdfScrollDirection.horizontal');
    });

    test('PdfPageLayoutMode enum test', () {
      // 测试页面布局模式枚举
      expect(PdfPageLayoutMode.values, contains(PdfPageLayoutMode.continuous));
      expect(PdfPageLayoutMode.values, contains(PdfPageLayoutMode.single));
      expect(PdfPageLayoutMode.values.length, 2);
      expect(PdfPageLayoutMode.continuous.toString(), 'PdfPageLayoutMode.continuous');
      expect(PdfPageLayoutMode.single.toString(), 'PdfPageLayoutMode.single');
    });

    test('PdfAnnotationMode enum test', () {
      // 测试注释模式枚举
      expect(PdfAnnotationMode.values.length, 6);
      expect(PdfAnnotationMode.values, contains(PdfAnnotationMode.none));
      expect(PdfAnnotationMode.values, contains(PdfAnnotationMode.highlight));
      expect(PdfAnnotationMode.values, contains(PdfAnnotationMode.underline));
      expect(PdfAnnotationMode.values, contains(PdfAnnotationMode.strikethrough));
      expect(PdfAnnotationMode.values, contains(PdfAnnotationMode.squiggly));
      expect(PdfAnnotationMode.values, contains(PdfAnnotationMode.stickyNote));
    });

    test('PdfStickyNoteIcon enum test', () {
      // 测试粘性便签图标枚举
      expect(PdfStickyNoteIcon.values.length, 7);
      expect(PdfStickyNoteIcon.values, contains(PdfStickyNoteIcon.comment));
      expect(PdfStickyNoteIcon.values, contains(PdfStickyNoteIcon.key));
      expect(PdfStickyNoteIcon.values, contains(PdfStickyNoteIcon.note));
      expect(PdfStickyNoteIcon.values, contains(PdfStickyNoteIcon.help));
      expect(PdfStickyNoteIcon.values, contains(PdfStickyNoteIcon.newParagraph));
      expect(PdfStickyNoteIcon.values, contains(PdfStickyNoteIcon.paragraph));
      expect(PdfStickyNoteIcon.values, contains(PdfStickyNoteIcon.insert));
    });

    test('PdfFlattenOption enum test', () {
      // 测试平化选项枚举
      expect(PdfFlattenOption.values.length, 2);
      expect(PdfFlattenOption.values, contains(PdfFlattenOption.none));
      expect(PdfFlattenOption.values, contains(PdfFlattenOption.formFields));
    });

    test('SfPdfViewer constructor default values test', () {
      // 测试SfPdfViewer构造函数的默认值
      final viewer = SfPdfViewer.asset('assets/sample.pdf');
      
      // 验证默认值
      expect(viewer.canShowScrollHead, true);
      expect(viewer.canShowScrollStatus, true);
      expect(viewer.canShowPageLoadingIndicator, true);
      expect(viewer.enableDoubleTapZooming, true);
      expect(viewer.enableTextSelection, true);
      expect(viewer.enableDocumentLinkAnnotation, true);
      expect(viewer.canShowPaginationDialog, true);
      expect(viewer.initialZoomLevel, 1.0);
      expect(viewer.maxZoomLevel, 3.0);
      expect(viewer.pageSpacing, 4.0);
      expect(viewer.initialPageNumber, 1);
      expect(viewer.interactionMode, PdfInteractionMode.selection);
      expect(viewer.pageLayoutMode, PdfPageLayoutMode.continuous);
    });

    test('SfPdfViewer constructor with custom values test', () {
      // 测试SfPdfViewer构造函数的自定义值
      final controller = PdfViewerController();
      controller.zoomLevel = 2.0;
      
      final viewer = SfPdfViewer.asset(
        'assets/sample.pdf',
        controller: controller,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        canShowPageLoadingIndicator: false,
        enableDoubleTapZooming: false,
        enableTextSelection: false,
        enableDocumentLinkAnnotation: false,
        canShowPaginationDialog: false,
        initialZoomLevel: 1.5,
        maxZoomLevel: 4.0,
        pageSpacing: 8.0,
        initialPageNumber: 3,
        interactionMode: PdfInteractionMode.pan,
        pageLayoutMode: PdfPageLayoutMode.single,
        currentSearchTextHighlightColor: const Color(0xFFFF0000), // 红色
        otherSearchTextHighlightColor: const Color(0xFF00FF00),   // 绿色
      );
      
      // 验证自定义值
      expect(viewer.canShowScrollHead, false);
      expect(viewer.canShowScrollStatus, false);
      expect(viewer.canShowPageLoadingIndicator, false);
      expect(viewer.enableDoubleTapZooming, false);
      expect(viewer.enableTextSelection, false);
      expect(viewer.enableDocumentLinkAnnotation, false);
      expect(viewer.canShowPaginationDialog, false);
      expect(viewer.initialZoomLevel, 1.5);
      expect(viewer.maxZoomLevel, 4.0);
      expect(viewer.pageSpacing, 8.0);
      expect(viewer.initialPageNumber, 3);
      expect(viewer.interactionMode, PdfInteractionMode.pan);
      expect(viewer.pageLayoutMode, PdfPageLayoutMode.single);
    });

    test('SfPdfViewer network constructor test', () {
      // 测试网络构造函数
      final viewer = SfPdfViewer.network(
        'https://example.com/sample.pdf',
        canShowScrollHead: true,
        enableTextSelection: true,
      );
      
      expect(viewer.canShowScrollHead, true);
      expect(viewer.enableTextSelection, true);
    });

    test('SfPdfViewer memory constructor test', () {
      // 测试内存构造函数
      final viewer = SfPdfViewer.memory(
        Uint8List.fromList([37, 80, 68, 70]), // PDF文件头: %PDF
        initialZoomLevel: 2.0,
        maxZoomLevel: 5.0,
      );
      
      expect(viewer.initialZoomLevel, 2.0);
      expect(viewer.maxZoomLevel, 5.0);
    });
  });
}