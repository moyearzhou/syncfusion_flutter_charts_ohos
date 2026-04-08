<p align="center">
  <h1 align="center"> <code>syncfusion_flutter_pdfviewer</code> </h1>
</p>


This project is based on [syncfusion_flutter_pdfviewer@29.1.38](https://pub.dev/packages/syncfusion_flutter_pdfviewer/versions/29.1.38).

## 1. Installation and Usage

### 1.1 Installation

Go to the project directory and add the following dependencies in pubspec.yaml

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  syncfusion_flutter_pdfviewer:
    git:
      url: https://gitcode.com/openharmony-sig/fluttertpc_syncfusion_flutter_charts.git
```

Execute Command

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 Usage

For use cases [example](example/lib/main.dart).

## 2. Constraints

### 2.1 Compatibility

This document is verified based on the following versions:

1. Flutter: 3.27.5-ohos-1.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.0.1.251; ROM: 6.0.0.115 SP16;
2. Flutter: 3.35.8-ohos-0.0.2; SDK: 6.0.2(22); IDE: DevEco Studio: 6.0.2.640; ROM: 6.0.0.328 SP52;

## 3. API

API documentation (https://help.syncfusion.com/document-processing/pdf/pdf-viewer/flutter/overview)

> [!TIP] If the value of **ohos Support** is **yes**, it means that the ohos platform supports this property; **no** means the opposite; **partially** means some capabilities of this property are supported. The usage method is the same on different platforms and the effect is the same as that of iOS or Android.

### syncfusion_flutter_pdfviewer

| Name      | Description | Type     |  Input   | Output      | ohos Support | 
| --------  | ----------- | -------- | -------- | ----------- | ------------ |
| `Future<int> initializePdfRenderer(Uint8List documentBytes)`       | Initialize the PDF renderer using the document data and return the total number of pages in the PDF    | function | `Uint8List documentBytes： 解析后的文档数据，类型是Uint8List` | int | yes |
| `Future<List<dynamic>?> getPagesHeight()` | Get the height of the page  | function | 无  | List<dynamic>?  | yes |
| `Future<List<dynamic>?> getPagesWidth()`  | Get the width of the page    | function | 无 | List<dynamic>?  | yes |
| `Future<void> closeDocument()`  | Close the PDF document  | function |  无  | void  | yes |
| `Future<Uint8List?> getPage(int pageNumber, int width, int height, String documentID)`  | Obtain pdf page pixel data and return a Uint8List | function |  `int pageNumber：页码,int width：pdf 宽度,int height：pdf 高度,String documentID：pdf 唯一标识符`  | void  | yes |
| `Future<Uint8List?> getTileImage(int pageNumber, double currentScale, double x,double y, double width, double height, String documentID)`  | Obtain scaled pixel data and return a Uint8List  | function |  `int pageNumber：页码,double currentScale,double x：PDF原始坐标系中的x轴坐标值,double y：PDF原始坐标系中的y轴坐标值,double width：pdf 宽度,double height：pdf 高度,String documentID：pdf 唯一标识符`  | void  | no |

## 4. Known Issues

- Future<Uint8List?> getTileImage(int pageNumber, double currentScale, double x,double y, double width, double height, String documentID)：  Obtain scaled pixel data and return a Uint8List. This feature is currently not supported by the OHOS PDF Kit interface

## 5. Others
None

## 6. License

This project is licensed under  [unknown](https://gitcode.com/openharmony-sig/fluttertpc_syncfusion_flutter_charts/blob/master/packages/syncfusion_flutter_pdfviewer/LICENSE) .