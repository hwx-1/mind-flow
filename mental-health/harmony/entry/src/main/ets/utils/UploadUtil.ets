import { photoAccessHelper } from '@kit.MediaLibraryKit';
import request from '@ohos.request';
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { Const } from '../constants/Const';
import { Auth } from '../store/Auth';

interface UploadResp {
  code: number;
  msg: string;
  data: { url: string };
}

export class UploadUtil {

  /** 选择若干张图片，返回本地 uri 数组 */
  static async pickImages(maxCount: number = 9): Promise<string[]> {
    const opt = new photoAccessHelper.PhotoSelectOptions();
    opt.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    opt.maxSelectNumber = maxCount;
    const picker = new photoAccessHelper.PhotoViewPicker();
    const res = await picker.select(opt);
    return res.photoUris;
  }

  static async pickVideo(): Promise<string | null> {
    const opt = new photoAccessHelper.PhotoSelectOptions();
    opt.MIMEType = photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE;
    opt.maxSelectNumber = 1;
    const picker = new photoAccessHelper.PhotoViewPicker();
    const res = await picker.select(opt);
    return res.photoUris.length > 0 ? res.photoUris[0] : null;
  }

  /** 把媒体库 uri 复制到 cache 拿到真实路径 */
  private static copyToCache(ctx: common.UIAbilityContext, uri: string): string {
    const cacheDir = ctx.cacheDir;
    const name = `up_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    const dst = `${cacheDir}/${name}`;
    const src = fs.openSync(uri, fs.OpenMode.READ_ONLY);
    const out = fs.openSync(dst, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    const buf = new ArrayBuffer(4096);
    let read = fs.readSync(src.fd, buf);
    while (read > 0) {
      fs.writeSync(out.fd, buf, { length: read });
      read = fs.readSync(src.fd, buf);
    }
    fs.closeSync(src);
    fs.closeSync(out);
    return dst;
  }

  /** 上传单个文件，返回 CDN url */
  static upload(ctx: common.UIAbilityContext, uri: string, kind: 'image' | 'video'): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      const realPath = UploadUtil.copyToCache(ctx, uri);
      const fileName = realPath.substring(realPath.lastIndexOf('/') + 1);

      const files: Array<request.File> = [{
        filename: fileName,
        name: 'file',
        uri: `internal://cache/${fileName}`,
        type: kind === 'image' ? 'image/jpeg' : 'video/mp4'
      }];
      const cfg: request.UploadConfig = {
        url: `${Const.BASE_URL}/upload/${kind}`,
        header: { 'Authorization': `Bearer ${Auth.getToken()}` } as object,
        method: 'POST',
        files,
        data: []
      };
      request.uploadFile(ctx, cfg).then((task: request.UploadTask) => {
        task.on('headerReceive', (h: object) => {
          // 拿响应体走 complete 事件不行，鸿蒙的 upload 默认拿不到 body，需用 http 的 multipart 模式
        });
        task.on('complete', (res: Array<request.TaskState>) => {
          // 备用：失败时 fail 事件
        });
        task.on('fail', (states: Array<request.TaskState>) => {
          reject(new Error(`upload fail: ${JSON.stringify(states)}`));
        });
        // 用 progress 监听结束并轮询读取本地服务返回；改用纯 http multipart 更稳：
      }).catch(reject);

      // 兼容做法：直接用 http 走 multipart
      UploadUtil.multipartHttp(realPath, kind).then(resolve).catch(reject);
    });
  }

  /** 推荐做法：用 http 包做 multipart 上传 */
  private static async multipartHttp(path: string, kind: 'image' | 'video'): Promise<string> {
    const http = await import('@ohos.net.http');
    const boundary = '----HMUploadBoundary' + Date.now();
    const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
    const stat = fs.statSync(path);
    const buf = new ArrayBuffer(stat.size);
    fs.readSync(file.fd, buf);
    fs.closeSync(file);

    const fileName = path.substring(path.lastIndexOf('/') + 1);
    const head =
      `--${boundary}\r\n` +
      `Content-Disposition: form-data; name="file"; filename="${fileName}"\r\n` +
      `Content-Type: ${kind === 'image' ? 'image/jpeg' : 'video/mp4'}\r\n\r\n`;
    const tail = `\r\n--${boundary}--\r\n`;

    const headBytes = new TextEncoder().encode(head);
    const tailBytes = new TextEncoder().encode(tail);
    const fileBytes = new Uint8Array(buf);
    const total = new Uint8Array(headBytes.byteLength + fileBytes.byteLength + tailBytes.byteLength);
    total.set(headBytes, 0);
    total.set(fileBytes, headBytes.byteLength);
    total.set(tailBytes, headBytes.byteLength + fileBytes.byteLength);

    const req = http.default.createHttp();
    const res = await req.request(`${Const.BASE_URL}/upload/${kind}`, {
      method: http.default.RequestMethod.POST,
      header: {
        'Content-Type': `multipart/form-data; boundary=${boundary}`,
        'Authorization': `Bearer ${Auth.getToken()}`
      },
      extraData: total.buffer,
      readTimeout: 120000,
      connectTimeout: 15000
    });
    const json = JSON.parse(res.result as string) as UploadResp;
    if (json.code !== 0) throw new Error(json.msg);
    return json.data.url;
  }
}
