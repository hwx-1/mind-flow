import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { rcp } from '@kit.RemoteCommunicationKit';
import { Const } from '../constants/Const';
import { UploadData } from '../model/Models';
import { Auth } from '../store/Auth';

type UploadKind = 'image' | 'video';

interface UploadResp {
  code: number;
  msg: string;
  data?: UploadData;
}

interface PreparedFile {
  path: string;
  fileName: string;
  contentType: string;
  size: number;
}

interface ErrorLike {
  code?: number;
  message?: string;
}

export class UploadUtil {
  private static readonly TAG: string = 'UploadUtil';
  private static readonly BUFFER_SIZE: number = 1024 * 256;
  private static readonly IMAGE_EXTS: string[] = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'avif'];
  private static readonly VIDEO_EXTS: string[] = ['mp4', 'mov', 'm4v', 'webm', 'avi'];

  /** 选择若干张图片，返回系统 PhotoViewPicker 授权的媒体 uri。 */
  static async pickImages(maxCount: number = 9): Promise<string[]> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = maxCount;

    const picker = new photoAccessHelper.PhotoViewPicker();
    const result = await picker.select(options);
    return result.photoUris;
  }

  static async pickVideo(): Promise<string | null> {
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
    options.maxSelectNumber = 1;

    const picker = new photoAccessHelper.PhotoViewPicker();
    const result = await picker.select(options);
    return result.photoUris.length > 0 ? result.photoUris[0] : null;
  }

  /** 上传文件并返回后端返回的资源 URL。 */
  static async upload(ctx: common.UIAbilityContext, uri: string, kind: UploadKind): Promise<string> {
    const prepared = await UploadUtil.prepareFile(ctx, uri, kind);
    console.info(`[${UploadUtil.TAG}] prepared ${kind} name=${prepared.fileName} size=${prepared.size}`);

    try {
      return await UploadUtil.uploadByRcpMultipart(prepared, kind);
    } finally {
      UploadUtil.removeQuietly(prepared.path);
    }
  }

  private static async prepareFile(ctx: common.UIAbilityContext, sourceUri: string, kind: UploadKind): Promise<PreparedFile> {
    const ext = UploadUtil.inferExt(sourceUri, kind);
    const fileName = UploadUtil.normalizeFileName(`picker.${ext}`, kind, ext);
    const path = `${ctx.cacheDir}/${UploadUtil.uniqueName(fileName, ext)}`;

    UploadUtil.copyUriToPath(sourceUri, path);

    const stat = fileIo.statSync(path);
    if (stat.size <= 0) {
      throw new Error('选择的文件为空，请重新选择');
    }

    return {
      path,
      fileName: path.substring(path.lastIndexOf('/') + 1),
      contentType: UploadUtil.contentTypeOf(ext, kind),
      size: stat.size
    };
  }

  private static copyUriToPath(uri: string, path: string): void {
    let source: fileIo.File | null = null;
    let target: fileIo.File | null = null;

    try {
      source = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      target = fileIo.openSync(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
      const buffer = new ArrayBuffer(UploadUtil.BUFFER_SIZE);
      let readLength = fileIo.readSync(source.fd, buffer);
      while (readLength > 0) {
        fileIo.writeSync(target.fd, buffer, { length: readLength });
        readLength = fileIo.readSync(source.fd, buffer);
      }
    } catch (e) {
      UploadUtil.removeQuietly(path);
      throw new Error(`读取相册文件失败：${UploadUtil.describeError(e)}`);
    } finally {
      if (source !== null) {
        fileIo.closeSync(source);
      }
      if (target !== null) {
        fileIo.closeSync(target);
      }
    }
  }

  /**
   * 使用 RCP（Remote Communication Kit，官方推荐）的 MultipartForm 上传。
   * RCP 无法直接读取相册 URI，需先拷贝到应用沙箱（prepareFile 已完成），再以沙箱路径上传。
   */
  private static async uploadByRcpMultipart(file: PreparedFile, kind: UploadKind): Promise<string> {
    const headers: rcp.RequestHeaders = {
      'Accept': 'application/json'
    };
    const token = Auth.getToken();
    if (token.length > 0) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const form = new rcp.MultipartForm({
      'file': {
        contentType: file.contentType,
        contentOrPath: file.path,
        // 关键：必须带上文件名，否则后端 getOriginalFilename() 取不到后缀，
        // 会判为「不支持的格式」导致上传失败（网页端浏览器会自动带 filename，所以能成功）。
        remoteFileName: file.fileName
      }
    });

    const session = rcp.createSession({
      requestConfiguration: {
        transfer: {
          timeout: {
            connectMs: 15000,
            transferMs: 120000
          }
        }
      }
    });

    try {
      const request = new rcp.Request(`${Const.BASE_URL}/upload/${kind}`, 'POST', headers, form);
      const response = await session.fetch(request);
      const text = response.toString() ?? '';
      console.info(`[${UploadUtil.TAG}] rcp response code=${response.statusCode} body=${text}`);
      return UploadUtil.parseUploadUrl(response.statusCode, text);
    } finally {
      session.close();
    }
  }

  private static parseUploadUrl(responseCode: number, text: string): string {
    if (responseCode < 200 || responseCode >= 300) {
      throw new Error(`上传接口 HTTP ${responseCode}: ${text}`);
    }
    if (text.trim().length === 0) {
      throw new Error('上传接口没有返回资源地址');
    }

    const json = JSON.parse(text) as UploadResp;
    if (json.code !== 0) {
      throw new Error(json.msg || '上传失败');
    }
    if (!json.data?.url) {
      throw new Error('上传接口返回缺少 url');
    }
    return json.data.url;
  }

  private static inferExt(fileNameOrUri: string, kind: UploadKind): string {
    const clean = fileNameOrUri.split('?')[0].split('#')[0].toLowerCase();
    const dot = clean.lastIndexOf('.');
    if (dot > -1 && dot < clean.length - 1) {
      const ext = clean.substring(dot + 1);
      const allowList = kind === 'image' ? UploadUtil.IMAGE_EXTS : UploadUtil.VIDEO_EXTS;
      if (allowList.includes(ext)) {
        return ext;
      }
    }
    return kind === 'image' ? 'jpg' : 'mp4';
  }

  private static normalizeFileName(fileName: string, kind: UploadKind, ext: string): string {
    const fallback = kind === 'image' ? `image.${ext}` : `video.${ext}`;
    const name = fileName.trim().length > 0 ? fileName.trim() : fallback;
    const safeName = name.replace(/[\\/:*?"<>|\s]+/g, '_');
    return safeName.toLowerCase().endsWith(`.${ext}`) ? safeName : `${safeName}.${ext}`;
  }

  private static uniqueName(fileName: string, ext: string): string {
    const baseName = fileName.substring(0, Math.max(fileName.length - ext.length - 1, 1));
    return `up_${Date.now()}_${Math.random().toString(36).substring(2, 8)}_${baseName}.${ext}`;
  }

  private static contentTypeOf(ext: string, kind: UploadKind): string {
    if (kind === 'video') {
      if (ext === 'mov') {
        return 'video/quicktime';
      }
      if (ext === 'webm') {
        return 'video/webm';
      }
      if (ext === 'avi') {
        return 'video/x-msvideo';
      }
      return 'video/mp4';
    }

    if (ext === 'png') {
      return 'image/png';
    }
    if (ext === 'gif') {
      return 'image/gif';
    }
    if (ext === 'webp') {
      return 'image/webp';
    }
    if (ext === 'bmp') {
      return 'image/bmp';
    }
    if (ext === 'heic') {
      return 'image/heic';
    }
    if (ext === 'heif') {
      return 'image/heif';
    }
    if (ext === 'avif') {
      return 'image/avif';
    }
    return 'image/jpeg';
  }

  private static removeQuietly(path: string): void {
    try {
      fileIo.unlinkSync(path);
    } catch (_) {
    }
  }

  private static describeError(error: Error): string {
    const maybeError = error as ErrorLike;
    if (typeof maybeError.code === 'number') {
      return `${maybeError.code} ${error.message || ''}`;
    }
    if (error.message) {
      return error.message;
    }
    return JSON.stringify(error);
  }
}