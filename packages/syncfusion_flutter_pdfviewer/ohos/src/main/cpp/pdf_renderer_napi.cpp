#include <napi/native_api.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "fpdf_edit.h"
#include "fpdfview.h"

namespace {

constexpr int64_t kMaxTilePixels = 16 * 1024 * 1024;

std::mutex gPdfiumMutex;
std::unordered_map<int32_t, FPDF_DOCUMENT> gDocuments;
std::unordered_map<uint64_t, int32_t> gLatestTileRequests;
int32_t gNextDocumentId = 1;
bool gPdfiumInitialized = false;

struct RenderTileWork {
  napi_env env = nullptr;
  napi_async_work work = nullptr;
  napi_deferred deferred = nullptr;
  int32_t documentId = 0;
  int32_t pageIndex = 0;
  double x = 0;
  double y = 0;
  int32_t width = 0;
  int32_t height = 0;
  double scale = 0;
  int32_t requestGeneration = 0;
  std::vector<uint8_t> pixels;
  std::string error;
  bool superseded = false;
};

uint64_t TileRequestKey(int32_t documentId, int32_t pageIndex) {
  return (static_cast<uint64_t>(static_cast<uint32_t>(documentId)) << 32) |
         static_cast<uint32_t>(pageIndex);
}

void ThrowError(napi_env env, const std::string& message) {
  napi_throw_error(env, nullptr, message.c_str());
}

bool GetInt32(napi_env env, napi_value value, int32_t* output) {
  return napi_get_value_int32(env, value, output) == napi_ok;
}

bool GetDouble(napi_env env, napi_value value, double* output) {
  return napi_get_value_double(env, value, output) == napi_ok;
}

bool GetString(napi_env env, napi_value value, std::string* output) {
  size_t length = 0;
  if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok) {
    return false;
  }
  std::vector<char> buffer(length + 1);
  if (napi_get_value_string_utf8(env, value, buffer.data(), buffer.size(), &length) != napi_ok) {
    return false;
  }
  output->assign(buffer.data(), length);
  return true;
}

napi_value OpenDocument(napi_env env, napi_callback_info info) {
  size_t argc = 1;
  napi_value argv[1];
  if (napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr) != napi_ok || argc != 1) {
    ThrowError(env, "openDocument requires a PDF file path");
    return nullptr;
  }

  std::string path;
  if (!GetString(env, argv[0], &path) || path.empty()) {
    ThrowError(env, "openDocument received an invalid PDF file path");
    return nullptr;
  }

  std::lock_guard<std::mutex> lock(gPdfiumMutex);
  FPDF_DOCUMENT document = FPDF_LoadDocument(path.c_str(), nullptr);
  if (document == nullptr) {
    ThrowError(env, "PDFium failed to open document, error=" + std::to_string(FPDF_GetLastError()));
    return nullptr;
  }

  const int32_t documentId = gNextDocumentId++;
  gDocuments.emplace(documentId, document);
  napi_value result;
  napi_create_int32(env, documentId, &result);
  return result;
}

napi_value CloseDocument(napi_env env, napi_callback_info info) {
  size_t argc = 1;
  napi_value argv[1];
  int32_t documentId = 0;
  if (napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr) != napi_ok || argc != 1 ||
      !GetInt32(env, argv[0], &documentId)) {
    ThrowError(env, "closeDocument requires a document id");
    return nullptr;
  }

  bool closed = false;
  {
    std::lock_guard<std::mutex> lock(gPdfiumMutex);
    auto document = gDocuments.find(documentId);
    if (document != gDocuments.end()) {
      FPDF_CloseDocument(document->second);
      gDocuments.erase(document);
      for (auto request = gLatestTileRequests.begin(); request != gLatestTileRequests.end();) {
        if (static_cast<int32_t>(request->first >> 32) == documentId) {
          request = gLatestTileRequests.erase(request);
        } else {
          ++request;
        }
      }
      closed = true;
    }
  }

  napi_value result;
  napi_get_boolean(env, closed, &result);
  return result;
}

void ExecuteRenderTile(napi_env, void* data) {
  auto* request = static_cast<RenderTileWork*>(data);
  std::lock_guard<std::mutex> lock(gPdfiumMutex);

  // Dart cancellation cannot stop queued NAPI work, so only the newest tile per page is rendered.
  const auto latestRequest = gLatestTileRequests.find(
      TileRequestKey(request->documentId, request->pageIndex));
  if (latestRequest == gLatestTileRequests.end() ||
      latestRequest->second != request->requestGeneration) {
    request->superseded = true;
    return;
  }

  const auto documentEntry = gDocuments.find(request->documentId);
  if (documentEntry == gDocuments.end()) {
    request->error = "PDFium document is not open";
    return;
  }

  FPDF_PAGE page = FPDF_LoadPage(documentEntry->second, request->pageIndex);
  if (page == nullptr) {
    request->error = "PDFium failed to load page";
    return;
  }

  FPDF_BITMAP bitmap = FPDFBitmap_Create(request->width, request->height, 1);
  if (bitmap == nullptr) {
    FPDF_ClosePage(page);
    request->error = "PDFium failed to allocate tile bitmap";
    return;
  }

  FPDFBitmap_FillRect(bitmap, 0, 0, request->width, request->height, 0xFFFFFFFF);

  const int rotation = FPDFPage_GetRotation(page);
  double pageWidth = FPDF_GetPageWidthF(page);
  double pageHeight = FPDF_GetPageHeightF(page);
  if (rotation == 1 || rotation == 3) {
    std::swap(pageWidth, pageHeight);
  }

  const int renderWidth = std::max(1, static_cast<int>(std::lround(pageWidth * request->scale)));
  const int renderHeight = std::max(1, static_cast<int>(std::lround(pageHeight * request->scale)));
  const int renderX = -static_cast<int>(std::lround(request->x * request->scale));
  const int renderY = -static_cast<int>(std::lround(request->y * request->scale));

  FPDF_RenderPageBitmap(bitmap, page, renderX, renderY, renderWidth, renderHeight, rotation,
                        FPDF_ANNOT | FPDF_LCD_TEXT);

  const auto* source = static_cast<const uint8_t*>(FPDFBitmap_GetBuffer(bitmap));
  if (source == nullptr) {
    FPDFBitmap_Destroy(bitmap);
    FPDF_ClosePage(page);
    request->error = "PDFium tile bitmap buffer is unavailable";
    return;
  }
  const int stride = FPDFBitmap_GetStride(bitmap);
  const size_t rowBytes = static_cast<size_t>(request->width) * 4;
  request->pixels.resize(rowBytes * static_cast<size_t>(request->height));
  for (int row = 0; row < request->height; ++row) {
    std::memcpy(request->pixels.data() + static_cast<size_t>(row) * rowBytes,
                source + static_cast<size_t>(row) * stride, rowBytes);
  }

  FPDFBitmap_Destroy(bitmap);
  FPDF_ClosePage(page);
}

void CompleteRenderTile(napi_env env, napi_status status, void* data) {
  auto* request = static_cast<RenderTileWork*>(data);
  if (status != napi_ok && request->error.empty()) {
    request->error = "PDFium tile work was cancelled";
  }

  if (request->superseded) {
    napi_value nullValue;
    napi_get_null(env, &nullValue);
    napi_resolve_deferred(env, request->deferred, nullValue);
  } else if (!request->error.empty()) {
    napi_value error;
    napi_create_string_utf8(env, request->error.c_str(), NAPI_AUTO_LENGTH, &error);
    napi_reject_deferred(env, request->deferred, error);
  } else {
    void* destination = nullptr;
    napi_value arrayBuffer;
    napi_create_arraybuffer(env, request->pixels.size(), &destination, &arrayBuffer);
    std::memcpy(destination, request->pixels.data(), request->pixels.size());

    napi_value bytes;
    napi_create_typedarray(env, napi_uint8_array, request->pixels.size(), arrayBuffer, 0, &bytes);
    napi_resolve_deferred(env, request->deferred, bytes);
  }

  napi_delete_async_work(env, request->work);
  delete request;
}

napi_value RenderTile(napi_env env, napi_callback_info info) {
  size_t argc = 8;
  napi_value argv[8];
  if (napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr) != napi_ok || argc != 8) {
    ThrowError(env, "renderTile requires document, page, x, y, width, height, scale and generation");
    return nullptr;
  }

  auto* request = new RenderTileWork();
  request->env = env;
  if (!GetInt32(env, argv[0], &request->documentId) ||
      !GetInt32(env, argv[1], &request->pageIndex) ||
      !GetDouble(env, argv[2], &request->x) ||
      !GetDouble(env, argv[3], &request->y) ||
      !GetInt32(env, argv[4], &request->width) ||
      !GetInt32(env, argv[5], &request->height) ||
      !GetDouble(env, argv[6], &request->scale) ||
      !GetInt32(env, argv[7], &request->requestGeneration)) {
    delete request;
    ThrowError(env, "renderTile received invalid argument types");
    return nullptr;
  }

  const int64_t pixelCount = static_cast<int64_t>(request->width) * request->height;
  if (request->documentId <= 0 || request->pageIndex < 0 || request->x < 0 || request->y < 0 ||
      request->width <= 0 || request->height <= 0 || request->scale <= 0 ||
      request->requestGeneration <= 0 ||
      !std::isfinite(request->x) || !std::isfinite(request->y) || !std::isfinite(request->scale) ||
      pixelCount > kMaxTilePixels) {
    delete request;
    ThrowError(env, "renderTile received out-of-range arguments");
    return nullptr;
  }

  {
    std::lock_guard<std::mutex> lock(gPdfiumMutex);
    gLatestTileRequests[TileRequestKey(request->documentId, request->pageIndex)] =
        request->requestGeneration;
  }

  napi_value promise;
  napi_create_promise(env, &request->deferred, &promise);
  napi_value resourceName;
  napi_create_string_utf8(env, "SyncfusionPdfiumRenderTile", NAPI_AUTO_LENGTH, &resourceName);
  if (napi_create_async_work(env, nullptr, resourceName, ExecuteRenderTile, CompleteRenderTile,
                             request, &request->work) != napi_ok ||
      napi_queue_async_work(env, request->work) != napi_ok) {
    if (request->work != nullptr) {
      napi_delete_async_work(env, request->work);
    }
    delete request;
    ThrowError(env, "renderTile failed to queue native work");
    return nullptr;
  }
  return promise;
}

napi_value Init(napi_env env, napi_value exports) {
  {
    std::lock_guard<std::mutex> lock(gPdfiumMutex);
    if (!gPdfiumInitialized) {
      FPDF_InitLibrary();
      gPdfiumInitialized = true;
    }
  }

  napi_property_descriptor descriptors[] = {
      {"openDocument", nullptr, OpenDocument, nullptr, nullptr, nullptr, napi_default, nullptr},
      {"closeDocument", nullptr, CloseDocument, nullptr, nullptr, nullptr, napi_default, nullptr},
      {"renderTile", nullptr, RenderTile, nullptr, nullptr, nullptr, napi_default, nullptr},
  };
  napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
  return exports;
}

void CleanupPdfium() {
  std::lock_guard<std::mutex> lock(gPdfiumMutex);
  for (const auto& document : gDocuments) {
    FPDF_CloseDocument(document.second);
  }
  gDocuments.clear();
  gLatestTileRequests.clear();
  if (gPdfiumInitialized) {
    FPDF_DestroyLibrary();
    gPdfiumInitialized = false;
  }
}

}  // namespace

static napi_module gPdfRendererModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "pdf_renderer",
    .nm_priv = nullptr,
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterPdfRendererModule() {
  napi_module_register(&gPdfRendererModule);
}

extern "C" __attribute__((destructor)) void UnregisterPdfRendererModule() {
  CleanupPdfium();
}
