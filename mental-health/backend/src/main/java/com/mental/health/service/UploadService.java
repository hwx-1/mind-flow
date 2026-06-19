package com.mental.health.service;

import com.aliyun.oss.ClientException;
import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import com.aliyun.oss.OSSException;
import com.aliyun.oss.model.ObjectMetadata;
import com.mental.health.common.BizException;
import com.mental.health.config.UploadProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.FilenameUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class UploadService {

    private final UploadProperties properties;

    private static final Set<String> IMG = Set.of("jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "heif", "avif");
    private static final Set<String> VID = Set.of("mp4", "mov", "m4v", "webm", "avi");

    public String image(MultipartFile f) {
        validateImageContent(f);
        return save(f, "img", IMG, 50);
    }
    public String video(MultipartFile f) { return save(f, "video", VID, 200); }

    private String save(MultipartFile file, String sub, Set<String> allow, int maxMb) {
        if (file == null || file.isEmpty()) throw new BizException("文件为空");
        if (file.getSize() > maxMb * 1024L * 1024L) throw new BizException("文件超过 " + maxMb + "MB");
        String originalFilename = file.getOriginalFilename();
        String ext = FilenameUtils.getExtension(originalFilename == null ? "" : originalFilename).toLowerCase();
        if (!allow.contains(ext)) throw new BizException("不支持的格式: " + ext);

        String day = LocalDate.now().toString();
        String fn = UUID.randomUUID().toString().replace("-", "") + "." + ext;
        if (properties.ossEnabled()) {
            return saveToOss(file, sub, day, fn);
        }
        return saveToLocal(file, sub, day, fn);
    }

    private void validateImageContent(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return;
        }
        byte[] head = new byte[32];
        int len;
        try (InputStream input = file.getInputStream()) {
            len = input.read(head);
        } catch (IOException e) {
            throw new BizException("读取图片失败");
        }
        if (len < 2 || !isSupportedImage(head, len)) {
            throw new BizException("图片格式不支持或文件损坏");
        }
    }

    private boolean isSupportedImage(byte[] bytes, int len) {
        if (len >= 3 && (bytes[0] & 0xFF) == 0xFF && (bytes[1] & 0xFF) == 0xD8 && (bytes[2] & 0xFF) == 0xFF) {
            return true;
        }
        if (len >= 8 && (bytes[0] & 0xFF) == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47
                && bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A) {
            return true;
        }
        if (len >= 6 && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
            return true;
        }
        if (len >= 12 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46
                && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
            return true;
        }
        if (len >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
            return true;
        }
        if (len >= 12 && bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
            String brand = new String(bytes, 8, 4, java.nio.charset.StandardCharsets.US_ASCII);
            return Set.of("avif", "avis", "heic", "heix", "hevc", "hevx", "mif1", "msf1").contains(brand);
        }
        return false;
    }

    private String saveToOss(MultipartFile file, String sub, String day, String fn) {
        UploadProperties.Oss ossConfig = properties.getOss();
        validateOssConfig(ossConfig);

        String objectKey = normalizePrefix(ossConfig.getPrefix()) + sub + "/" + day + "/" + fn;
        OSS oss = new OSSClientBuilder()
                .build(ossConfig.getEndpoint(), ossConfig.getAccessKeyId(), ossConfig.getAccessKeySecret());
        try (InputStream input = file.getInputStream()) {
            ObjectMetadata metadata = new ObjectMetadata();
            metadata.setContentLength(file.getSize());
            if (file.getContentType() != null && !file.getContentType().isBlank()) {
                metadata.setContentType(file.getContentType());
            }
            oss.putObject(ossConfig.getBucket(), objectKey, input, metadata);
            String url = normalizeUrlPrefix(ossConfig.getPublicEndpoint()) + "/" + objectKey;
            log.info("upload oss saved originalName={}, contentType={}, size={}, bucket={}, objectKey={}",
                    file.getOriginalFilename(), file.getContentType(), file.getSize(), ossConfig.getBucket(), objectKey);
            return url;
        } catch (OSSException | ClientException e) {
            log.error("oss upload fail originalName={}, contentType={}, size={}, bucket={}, objectKey={}, ossCode={}, requestId={}",
                    file.getOriginalFilename(), file.getContentType(), file.getSize(),
                    ossConfig.getBucket(), objectKey, ossErrorCode(e), ossRequestId(e), e);
            throw new BizException("上传失败");
        } catch (IOException e) {
            log.error("read upload file fail originalName={}, contentType={}, size={}",
                    file.getOriginalFilename(), file.getContentType(), file.getSize(), e);
            throw new BizException("上传失败");
        } finally {
            oss.shutdown();
        }
    }

    private String saveToLocal(MultipartFile file, String sub, String day, String fn) {
        Path dir = Paths.get(properties.getPath(), sub, day);
        try {
            Files.createDirectories(dir);
            Path dest = dir.resolve(fn);
            file.transferTo(dest.toFile());
            log.info("upload saved originalName={}, contentType={}, size={}, dest={}",
                    file.getOriginalFilename(), file.getContentType(), file.getSize(), dest);
            return String.format("%s/%s/%s/%s", normalizeUrlPrefix(properties.getUrlPrefix()), sub, day, fn);
        } catch (IOException e) {
            log.error("upload fail originalName={}, contentType={}, size={}, dir={}",
                    file.getOriginalFilename(), file.getContentType(), file.getSize(), dir, e);
            throw new BizException("上传失败");
        }
    }

    private void validateOssConfig(UploadProperties.Oss oss) {
        if (isBlank(oss.getEndpoint()) || isBlank(oss.getPublicEndpoint()) || isBlank(oss.getBucket())
                || isBlank(oss.getAccessKeyId()) || isBlank(oss.getAccessKeySecret())) {
            throw new BizException("OSS配置未完成");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private String normalizePrefix(String prefix) {
        if (prefix == null || prefix.isBlank()) {
            return "";
        }
        String cleaned = prefix.startsWith("/") ? prefix.substring(1) : prefix;
        return cleaned.endsWith("/") ? cleaned : cleaned + "/";
    }

    private String normalizeUrlPrefix(String value) {
        if (value.endsWith("/")) {
            return value.substring(0, value.length() - 1);
        }
        return value;
    }

    private String ossErrorCode(Exception e) {
        return e instanceof OSSException ossException ? ossException.getErrorCode() : "";
    }

    private String ossRequestId(Exception e) {
        return e instanceof OSSException ossException ? ossException.getRequestId() : "";
    }
}
