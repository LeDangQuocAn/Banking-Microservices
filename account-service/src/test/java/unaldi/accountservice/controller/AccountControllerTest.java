package unaldi.accountservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import unaldi.accountservice.entity.Account;
import unaldi.accountservice.entity.dto.AccountDTO;
import unaldi.accountservice.entity.request.AccountSaveRequest;
import unaldi.accountservice.entity.request.AccountUpdateRequest;
import unaldi.accountservice.service.abstracts.AccountService;
import unaldi.accountservice.utils.ObjectFactory;
import unaldi.accountservice.utils.client.dto.BankResponse;
import unaldi.accountservice.utils.client.dto.UserResponse;
import unaldi.accountservice.utils.result.DataResult;
import unaldi.accountservice.utils.result.Result;
import unaldi.accountservice.utils.result.SuccessDataResult;
import unaldi.accountservice.utils.result.SuccessResult;

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
@WebMvcTest(AccountController.class)
class AccountControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private AccountService accountService;

    private static Account account;
    private static AccountSaveRequest accountSaveRequest;
    private static AccountUpdateRequest accountUpdateRequest;
    private static UserResponse userResponse;
    private static BankResponse bankResponse;

    @BeforeAll
    static void setUp() {
        account = ObjectFactory.getInstance().getAccount();
        accountSaveRequest = ObjectFactory.getInstance().getAccountSaveRequest();
        accountUpdateRequest = ObjectFactory.getInstance().getAccountUpdateRequest();
        userResponse = ObjectFactory.getInstance().getUserResponse();
        bankResponse = ObjectFactory.getInstance().getBankResponse();
    }

    @Test
    void givenAccountSaveRequest_whenSave_thenReturn201() throws Exception {
        AccountDTO accountDTO = new AccountDTO(account.getId(), account.getAccountNumber(),
                account.getUserId(), account.getBalance(), account.getAccountType(),
                account.getAccountStatus(), account.getBankId());
        DataResult<AccountDTO> result = new SuccessDataResult<>(accountDTO, "Account saved");

        when(accountService.save(any(AccountSaveRequest.class))).thenReturn(result);

        mockMvc.perform(post("/api/v1/accounts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(accountSaveRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenAccountUpdateRequest_whenUpdate_thenReturn200() throws Exception {
        AccountDTO accountDTO = new AccountDTO(account.getId(), account.getAccountNumber(),
                account.getUserId(), account.getBalance(), account.getAccountType(),
                account.getAccountStatus(), account.getBankId());
        DataResult<AccountDTO> result = new SuccessDataResult<>(accountDTO, "Account updated");

        when(accountService.update(any(AccountUpdateRequest.class))).thenReturn(result);

        mockMvc.perform(put("/api/v1/accounts")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(accountUpdateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenAccountId_whenDeleteById_thenReturn200() throws Exception {
        Result result = new SuccessResult("Account deleted");

        when(accountService.deleteById(account.getId())).thenReturn(result);

        mockMvc.perform(delete("/api/v1/accounts/{accountId}", account.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenAccountId_whenFindById_thenReturn200() throws Exception {
        AccountDTO accountDTO = new AccountDTO(account.getId(), account.getAccountNumber(),
                account.getUserId(), account.getBalance(), account.getAccountType(),
                account.getAccountStatus(), account.getBankId());
        DataResult<AccountDTO> result = new SuccessDataResult<>(accountDTO, "Account found");

        when(accountService.findById(account.getId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/accounts/{accountId}", account.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void whenFindAll_thenReturn200() throws Exception {
        DataResult<List<AccountDTO>> result = new SuccessDataResult<>(List.of(), "Accounts listed");

        when(accountService.findAll()).thenReturn(result);

        mockMvc.perform(get("/api/v1/accounts"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenUserId_whenFindAccountUserByUserId_thenReturn200() throws Exception {
        DataResult<UserResponse> result = new SuccessDataResult<>(userResponse, "User found");

        when(accountService.findAccountUserByUserId(account.getUserId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/accounts/users/{userId}", account.getUserId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenBankId_whenFindAccountBankByBankId_thenReturn200() throws Exception {
        DataResult<BankResponse> result = new SuccessDataResult<>(bankResponse, "Bank found");

        when(accountService.findAccountBankByBankId(account.getBankId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/accounts/banks/{bankId}", account.getBankId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
