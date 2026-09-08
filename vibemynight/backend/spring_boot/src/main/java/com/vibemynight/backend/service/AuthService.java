package com.vibemynight.backend.service;

import com.vibemynight.backend.dto.LoginRequest;
import com.vibemynight.backend.dto.LoginResponse;

public interface AuthService {
    LoginResponse login(LoginRequest request);
}
