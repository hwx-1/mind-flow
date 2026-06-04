package com.mental.health.controller;

import com.mental.health.common.R;
import com.mental.health.service.UploadService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/upload")
@RequiredArgsConstructor
@Slf4j
public class UploadController {

    private final UploadService uploadService;

    @PostMapping("/image")
    public R<Map<String, String>> image(@RequestParam("file") MultipartFile file) {
        log.info("upload image originalName={}, contentType={}, size={}",
                file.getOriginalFilename(), file.getContentType(), file.getSize());
        return R.ok(Map.of("url", uploadService.image(file)));
    }

    @PostMapping("/video")
    public R<Map<String, String>> video(@RequestParam("file") MultipartFile file) {
        log.info("upload video originalName={}, contentType={}, size={}",
                file.getOriginalFilename(), file.getContentType(), file.getSize());
        return R.ok(Map.of("url", uploadService.video(file)));
    }
}
