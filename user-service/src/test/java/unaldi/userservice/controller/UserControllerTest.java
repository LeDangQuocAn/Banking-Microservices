package unaldi.userservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import unaldi.userservice.entity.User;
import unaldi.userservice.entity.dto.UserDTO;
import unaldi.userservice.entity.enums.Gender;
import unaldi.userservice.entity.request.UserSaveRequest;
import unaldi.userservice.entity.request.UserUpdateRequest;
import unaldi.userservice.service.abstracts.UserService;
import unaldi.userservice.utils.ObjectFactory;
import unaldi.userservice.utils.result.DataResult;
import unaldi.userservice.utils.result.Result;
import unaldi.userservice.utils.result.SuccessDataResult;
import unaldi.userservice.utils.result.SuccessResult;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Copyright (c) 2024
 * All rights reserved.
 *
 * @author Emre Ünaldı
 */
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private UserService userService;

    private static User user;
    private static UserSaveRequest userSaveRequest;
    private static UserUpdateRequest userUpdateRequest;

    @BeforeAll
    static void setUp() {
        user = ObjectFactory.getInstance().getUser();
        userSaveRequest = ObjectFactory.getInstance().getUserSaveRequest();
        userUpdateRequest = ObjectFactory.getInstance().getUserUpdateRequest();
    }

    @Test
    void givenUserSaveRequest_whenSave_thenReturn201() throws Exception {
        UserDTO userDTO = new UserDTO(user.getId(), user.getUsername(), user.getPassword(),
                user.getEmail(), user.getFirstName(), user.getLastName(),
                user.getPhoneNumber(), user.getBirthDate(), user.getGender());
        DataResult<UserDTO> result = new SuccessDataResult<>(userDTO, "User saved");

        when(userService.save(any(UserSaveRequest.class))).thenReturn(result);

        mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(userSaveRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenUserUpdateRequest_whenUpdate_thenReturn200() throws Exception {
        UserDTO userDTO = new UserDTO(user.getId(), user.getUsername(), user.getPassword(),
                user.getEmail(), user.getFirstName(), user.getLastName(),
                user.getPhoneNumber(), user.getBirthDate(), user.getGender());
        DataResult<UserDTO> result = new SuccessDataResult<>(userDTO, "User updated");

        when(userService.update(any(UserUpdateRequest.class))).thenReturn(result);

        mockMvc.perform(put("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(userUpdateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenUserId_whenDelete_thenReturn200() throws Exception {
        Result result = new SuccessResult("User deleted");

        when(userService.deleteById(user.getId())).thenReturn(result);

        mockMvc.perform(delete("/api/v1/users/{userId}", user.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenUserId_whenFindById_thenReturn200() throws Exception {
        UserDTO userDTO = new UserDTO(user.getId(), user.getUsername(), user.getPassword(),
                user.getEmail(), user.getFirstName(), user.getLastName(),
                user.getPhoneNumber(), user.getBirthDate(), user.getGender());
        DataResult<UserDTO> result = new SuccessDataResult<>(userDTO, "User found");

        when(userService.findById(user.getId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/users/{userId}", user.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void whenFindAll_thenReturn200() throws Exception {
        DataResult<List<UserDTO>> result = new SuccessDataResult<>(List.of(), "Users listed");

        when(userService.findAll()).thenReturn(result);

        mockMvc.perform(get("/api/v1/users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
