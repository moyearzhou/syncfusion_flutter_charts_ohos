<p align="center">
  <h1 align="center"> <code>syncfusion_flutter_pdfviewer</code> </h1>
</p>


本项目基于 [syncfusion_flutter_pdfviewer@29.1.38](https://pub.dev/packages/syncfusion_flutter_pdfviewer/versions/29.1.38) 开发。

## 1. 安装与使用

### 1.1 安装方式

进入到工程目录并在 pubspec.yaml 中添加以下依赖：

<!-- tabs:start -->

#### pubspec.yaml

```yaml
dependencies:
  syncfusion_flutter_pdfviewer:
    git:
      url: https://gitcode.com/CPF-Flutter/fluttertpc_syncfusion_flutter_charts.git
```

执行命令

```bash
flutter pub get
```

<!-- tabs:end -->

### 1.2 使用案例


使用案例详见 [example](example/lib/main.dart).

## 2. 约束与限制

### 2.1 兼容性

在以下版本中已测试通过

1. Flutter: 3.27.5-ohos-1.0.1; SDK: 5.0.0(12); IDE: DevEco Studio: 6.0.1.251; ROM: 6.0.0.115 SP16;
2. Flutter: 3.35.8-ohos-0.0.2; SDK: 6.0.2(22); IDE: DevEco Studio: 6.0.2.640; ROM: 6.0.0.328 SP52;

## 3. API

相关API官方文档 (https://help.syncfusion.com/document-processing/pdf/pdf-viewer/flutter/overview)

> [!TIP] "ohos Support"列为 yes 表示 ohos 平台支持该属性；no 则表示不支持；partially 表示部分支持。使用方法跨平台一致，效果对标 iOS 或 Android 的效果。

### syncfusion_flutter_pdfviewer

| Name      | Description | Type     |  Input   | Output      | ohos Support | 
| --------  | ----------- | -------- | -------- | ----------- | ------------ |
| `Future<int> initializePdfRenderer(Uint8List documentBytes)`       | 通过文档数据进行初始化pdf渲染器，并返回pdf总页数    | function | `Uint8List documentBytes： 解析后的文档数据，类型是Uint8List` | int | yes |
| `Future<List<dynamic>?> getPagesHeight()` | 获取页面的高度  | function | 无  | List<dynamic>?  | yes |
| `Future<List<dynamic>?> getPagesWidth()`  | 获取页面的宽度    | function | 无 | List<dynamic>?  | yes |
| `Future<void> closeDocument()`  | 关闭pdf文档  | function |  无  | void  | yes |
| `Future<Uint8List?> getPage(int pageNumber, int width, int height, String documentID)`  | 获取pdf 页面像素数据，返回Uint8List | function |  `int pageNumber：页码,int width：pdf 宽度,int height：pdf 高度,String documentID：pdf 唯一标识符`  | void  | yes |
| `Future<Uint8List?> getTileImage(int pageNumber, double currentScale, double x,double y, double width, double height, String documentID)`  | 获取缩放后的像素数据，返回Uint8List  | function |  `int pageNumber：页码,double currentScale,double x：PDF原始坐标系中的x轴坐标值,double y：PDF原始坐标系中的y轴坐标值,double width：pdf 宽度,double height：pdf 高度,String documentID：pdf 唯一标识符`  | void  | no |

## 4. 遗留问题

- Future<Uint8List?> getTileImage(int pageNumber, double currentScale, double x,double y, double width, double height, String documentID)：  获取缩放后的像素数据，返回Uint8List，此接口ohos pdf kit 暂不支持此功能

## 5. 其他

无

## 6. 开源协议

本项目基于 [unknown](https://gitcode.com/openharmony-sig/fluttertpc_syncfusion_flutter_charts/blob/master/packages/syncfusion_flutter_pdfviewer/LICENSE) ，请自由地享受和参与开源。