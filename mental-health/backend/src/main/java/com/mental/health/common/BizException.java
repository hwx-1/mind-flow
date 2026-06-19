package com.mental.health.common;

import lombok.Getter;

@Getter
public class BizException extends RuntimeException {
    private final int code;
    public BizException(String msg) { super(msg); this.code = 500; }
    public BizException(int code, String msg) { super(msg); this.code = code; }
}
