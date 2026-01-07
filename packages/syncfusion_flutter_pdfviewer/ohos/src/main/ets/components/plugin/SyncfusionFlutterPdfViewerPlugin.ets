/*
* Copyright (C) 2026 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { pdfService } from '@kit.PDFKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { HashMap } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { LogUtil } from './utils/LogUtil';

// 定义文档信息接口
interface DocumentInfo {
  filePath: string;
  pageCount: number;
  pdfDocument: pdfService.PdfDocument;
}

/** SyncfusionFlutterPdfViewerPlugin  **/
export default class SyncfusionFlutterPdfViewerPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private pathDir: string | null = '';
  // Width collections of rendered pages
  private pageWidth: number[] = [];
  // Height collections of rendered pages
  private pageHeight: number[] = [];
  // Document repository.
  private documentRepo: HashMap<String, DocumentInfo> = new HashMap<String, DocumentInfo>();

  getUniqueClassName(): string {
    return 'SyncfusionFlutterPdfViewerPlugin'
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'syncfusion_flutter_pdfviewer');
    this.pathDir = binding.getApplicationContext().filesDir;
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    switch (call.method) {
      case 'initializePdfRenderer':
        await this.initializePdfRenderer(call, result);
        break;
      case 'getPagesWidth':
        // 返回页面宽度数组
        this.getPagesWidth(call, result);
        break;
      case 'getPagesHeight':
        // 返回页面高度数组
        this.getPagesHeight(call, result);
        break;
      case 'getPage':
        await this.getPage(call, result);
        break;
      case 'getTileImage':
        // 实现瓦片图像渲染逻辑
        this.getTileImage(call, result);
        break;
      case 'closeDocument':
        this.closeDocument(call, result);
        break;
      case 'getPlatformVersion':
        result.success('OpenHarmony');
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private async initializePdfRenderer(call: MethodCall, result: MethodResult) {
    try {
      let buffer: Uint8Array = call.argument('documentBytes');
      let documentID: string = call.argument('documentID');

      // 验证参数
      if (!buffer || !documentID) {
        LogUtil.error('Syncfusion PDF Missing required parameters for initializePdfRenderer');
        result.error('initializePdfRenderer error',
          'Syncfusion PDF Missing required parameters for initializePdfRenderer', '');
        return;
      }

      // 将数据写入应用内的文件中
      let filePath = this.pathDir + '/temp_' + documentID + '.pdf';

      let file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let writeLen: number = await fs.write(file.fd, buffer.buffer)
      await fs.close(file);

      // 使用loadDocument接口加载pdf
      const pdfDocument: pdfService.PdfDocument = new pdfService.PdfDocument();
      let loadResult: pdfService.ParseResult = pdfDocument.loadDocument(filePath);

      if (pdfService.ParseResult.PARSE_SUCCESS === loadResult) {
        let pageCount: number = pdfDocument.getPageCount();
        // 存储文档信息
        this.documentRepo.set(documentID, { filePath: filePath, pageCount: pageCount, pdfDocument: pdfDocument });
        result.success(pageCount + '');
      }
      result.success(null);
    } catch (error) {
      LogUtil.error('Syncfusion PDF initializePdfRenderer failed with error : ' + error);
      result.error(error.code, error.message, error);
    }
  }

  private getPagesWidth(call: MethodCall, result: MethodResult) {
    try {
      let documentID: string = call.args;

      // 从文档仓库中获取文档信息
      if (this.documentRepo.hasKey(documentID)) {
        const docInfo = this.documentRepo.get(documentID);
        if (docInfo && docInfo.pageCount && docInfo.pdfDocument) {
          // 创建默认宽度数组
          for (let i = 0; i < docInfo.pageCount; i++) {
            let pdfPage: pdfService.PdfPage = docInfo.pdfDocument.getPage(i);
            this.pageWidth[i] = pdfPage.getWidth();
            pdfPage.release();
          }
          result.success(this.pageWidth);
          return;
        }
      }

      result.success(null);
    } catch (error) {
      LogUtil.error('Syncfusion PDF getPagesWidth failed with error : ' + error);
      result.error(error.code, error.message, error);
    }
  }

  private getPagesHeight(call: MethodCall, result: MethodResult) {
    try {
      let documentID: string = call.args;

      // 从文档仓库中获取文档信息
      if (this.documentRepo.hasKey(documentID)) {
        const docInfo = this.documentRepo.get(documentID);
        if (docInfo && docInfo.pageCount && docInfo.pdfDocument) {
          // 创建默认高度数组
          for (let i = 0; i < docInfo.pageCount; i++) {
            let pdfPage: pdfService.PdfPage = docInfo.pdfDocument.getPage(i);
            this.pageWidth[i] = pdfPage.getWidth();
            this.pageHeight[i] = pdfPage.getHeight();
            pdfPage.release();
          }
          result.success(this.pageHeight);
        }
      }

      result.success(null);
    } catch (error) {
      LogUtil.error('Syncfusion PDF getPagesHeight failed with error message: ' + error);
      result.error(error.code, error.message, error);
    }
  }

  private async getPage(call: MethodCall, result: MethodResult) {
    try {
      // 记录传入的参数
      const index: number = call.argument('index');
      const width: number = call.argument('width');
      const height: number = call.argument('height');
      const documentID: string = call.argument('documentID');

      // 验证参数
      if (index === undefined || width === undefined || height === undefined) {
        LogUtil.error('Syncfusion PDF getPage missing required parameters');
        result.success(null);
        return;
      }

      // 获取文档信息
      const docInfo = this.documentRepo.get(documentID);
      if (docInfo && docInfo.pageCount && docInfo.pdfDocument) {
        let pdfPage: pdfService.PdfPage = docInfo.pdfDocument.getPage(index - 1);

        let pdfMatrix: pdfService.PdfMatrix = new pdfService.PdfMatrix();
        pdfMatrix.x = 0;
        pdfMatrix.y = 0;
        pdfMatrix.width = width;
        pdfMatrix.height = height;
        pdfMatrix.rotate = 0;

        let img: image.PixelMap = pdfPage.getAreaPixelMap(pdfMatrix, width, height, false, true);
        let uint8Array: Uint8Array = await this.pixelMap2Buffer(img);
        LogUtil.info(`Syncfusion PDF getPage uint8Array length: ${uint8Array.length}, expected: ${width * height * 4}`);

        pdfPage.release();
        await img.release()
        result.success(uint8Array);
        return;
      }
      result.success(null);
    } catch (error) {
      LogUtil.error('Syncfusion PDF getPage failed with error : ' + error);
      result.error(error.code, error.message, error);
    }
  }

  private async getTileImage(call: MethodCall, result: MethodResult) {
    try {
      // 记录传入的参数
      const pageNumber: number = call.argument('pageNumber');
      const scale: number = call.argument('scale'); // zoomLevel * _dpr * ratio (缩放后的比例)
      const x: number = call.argument('x'); // exposed.left / zoomLevel (PDF原始坐标系中的x)
      const y: number = call.argument('y'); // exposed.top / zoomLevel (PDF原始坐标系中的y)
      const width: number = call.argument('width'); // tileImageSize.width (输出图像的像素宽度)
      const height: number = call.argument('height'); // tileImageSize.height (输出图像的像素高度)
      const documentID: string = call.argument('documentID');

      // 此规格暂不支持
      result.success(null);
    } catch (error) {
      LogUtil.error('Syncfusion PDF getTileImage failed with error : ' + error);
      result.error(error.code, error.message, error);
    }
  }

  // 将 pixelMap 转成图片格式  低版本
  private async pixelMap2Buffer(pixelMap: image.PixelMap): Promise<Uint8Array> {
    const byteCount = pixelMap.getPixelBytesNumber();
    const arrayBuffer = new ArrayBuffer(byteCount);
    await pixelMap.readPixelsToBuffer(arrayBuffer);
    return new Uint8Array(arrayBuffer);
  }

  private closeDocument(call: MethodCall, result: MethodResult) {
    try {
      let documentID: string = call.args;
      // 从文档仓库中获取文档信息
      if (this.documentRepo.hasKey(documentID)) {
        const docInfo = this.documentRepo.get(documentID);
        if (docInfo && docInfo.filePath) {
          // 删除临时文件
          fs.unlinkSync(docInfo.filePath);
          // 释放pdf 重置宽度高度集合
          docInfo.pdfDocument.releaseDocument();
          this.pageWidth = [];
          this.pageHeight = [];
          // 从仓库中移除文档信息
          this.documentRepo.remove(documentID);
        }
      }

      result.success(true);
    } catch (error) {
      LogUtil.error('Syncfusion PDF closeDocument failed with error : ' + error);
      result.error(error.code, error.message, error);
    }
  }
}