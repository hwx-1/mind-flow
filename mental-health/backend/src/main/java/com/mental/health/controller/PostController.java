package com.mental.health.controller;

import com.mental.health.common.R;
import com.mental.health.dto.PostDto;
import com.mental.health.security.UserContext;
import com.mental.health.service.PostService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/post")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;

    @GetMapping("/list")
    public R<?> list(@RequestParam(defaultValue = "recommend") String type,
                     @RequestParam(defaultValue = "1") int page,
                     @RequestParam(defaultValue = "10") int size) {
        var p = postService.list(UserContext.get(), type, page, size);
        return R.ok(Map.of("total", p.getTotal(), "list", p.getRecords()));
    }

    @GetMapping("/search")
    public R<?> search(@RequestParam String keyword,
                       @RequestParam(defaultValue = "1") int page,
                       @RequestParam(defaultValue = "10") int size) {
        var p = postService.search(UserContext.get(), keyword, page, size);
        return R.ok(Map.of("total", p.getTotal(), "list", p.getRecords()));
    }

    @GetMapping("/{id}")
    public R<PostDto.Vo> detail(@PathVariable Long id) {
        return R.ok(postService.detail(id, UserContext.get()));
    }

    @PostMapping("/publish")
    public R<Map<String, Long>> publish(@Valid @RequestBody PostDto.Publish req) {
        Long id = postService.publish(UserContext.require(), req);
        return R.ok(Map.of("id", id));
    }

    @DeleteMapping("/{id}/delete")
    public R<?> delete(@PathVariable Long id) {
        postService.delete(UserContext.require(), id);
        return R.ok();
    }

    @PostMapping("/{id}/like")
    public R<Map<String, Boolean>> like(@PathVariable Long id) {
        boolean liked = postService.toggleLike(UserContext.require(), id);
        return R.ok(Map.of("liked", liked));
    }

    @PostMapping("/{id}/collect")
    public R<Map<String, Boolean>> collect(@PathVariable Long id) {
        boolean c = postService.toggleCollect(UserContext.require(), id);
        return R.ok(Map.of("collected", c));
    }

    @GetMapping("/{id}/comments")
    public R<?> comments(@PathVariable Long id,
                         @RequestParam(defaultValue = "1") int page,
                         @RequestParam(defaultValue = "20") int size) {
        return R.ok(postService.comments(id, page, size));
    }

    @PostMapping("/{id}/comment")
    public R<Map<String, Long>> comment(@PathVariable Long id, @Valid @RequestBody PostDto.CommentReq req) {
        Long cid = postService.comment(UserContext.require(), id, req);
        return R.ok(Map.of("id", cid));
    }

    @GetMapping("/my")
    public R<?> my(@RequestParam(defaultValue = "1") int page,
                   @RequestParam(defaultValue = "10") int size) {
        var p = postService.myPosts(UserContext.require(), page, size);
        return R.ok(Map.of("total", p.getTotal(), "list", p.getRecords()));
    }

    @GetMapping("/user/{userId}")
    public R<?> userPosts(@PathVariable Long userId,
                          @RequestParam(defaultValue = "1") int page,
                          @RequestParam(defaultValue = "10") int size) {
        var p = postService.userPosts(userId, UserContext.get(), page, size);
        return R.ok(Map.of("total", p.getTotal(), "list", p.getRecords()));
    }

    @GetMapping("/my-comments")
    public R<?> myComments() {
        return R.ok(postService.myComments(UserContext.require()));
    }

    @GetMapping("/my-likes")
    public R<?> myLikes(@RequestParam(defaultValue = "1") int page,
                        @RequestParam(defaultValue = "10") int size) {
        var p = postService.myLikes(UserContext.require(), page, size);
        return R.ok(Map.of("total", p.getTotal(), "list", p.getRecords()));
    }
}
