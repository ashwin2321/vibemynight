package com.vibemynight.backend.service.impl;

import com.vibemynight.backend.dto.LoginRequest;
import com.vibemynight.backend.dto.LoginResponse;
import com.vibemynight.backend.entity.ActiveStatus;
import com.vibemynight.backend.entity.User;
import com.vibemynight.backend.exception.BadRequestException;
import com.vibemynight.backend.repository.UserRepository;
import com.vibemynight.backend.security.JwtService;
import com.vibemynight.backend.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Override
    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                // Same error for "no such email" and "wrong password" - don't leak which one.
                .orElseThrow(() -> new BadRequestException("Invalid email or password"));

        if (user.getStatus() != ActiveStatus.ACTIVE) {
            throw new BadRequestException("This account is deactivated");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadRequestException("Invalid email or password");
        }

        String token = jwtService.generateToken(user.getEmail(), user.getId(), user.getRole().name());

        return LoginResponse.builder()
                .accessToken(token)
                .tokenType("Bearer")
                .userId(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .role(user.getRole().name())
                .build();
    }
}
