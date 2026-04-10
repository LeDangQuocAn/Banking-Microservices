package unaldi.bankservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import unaldi.bankservice.entity.Bank;
import unaldi.bankservice.entity.dto.BankDTO;
import unaldi.bankservice.entity.request.BankSaveRequest;
import unaldi.bankservice.entity.request.BankUpdateRequest;
import unaldi.bankservice.service.abstracts.BankService;
import unaldi.bankservice.utils.ObjectFactory;
import unaldi.bankservice.utils.result.DataResult;
import unaldi.bankservice.utils.result.Result;
import unaldi.bankservice.utils.result.SuccessDataResult;
import unaldi.bankservice.utils.result.SuccessResult;

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
@WebMvcTest(BankController.class)
class BankControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private BankService bankService;

    private static Bank bank;
    private static BankSaveRequest bankSaveRequest;
    private static BankUpdateRequest bankUpdateRequest;

    @BeforeAll
    static void setUp() {
        bank = ObjectFactory.getInstance().getBank();
        bankSaveRequest = ObjectFactory.getInstance().getBankSaveRequest();
        bankUpdateRequest = ObjectFactory.getInstance().getBankUpdateRequest();
    }

    @Test
    void givenBankSaveRequest_whenSave_thenReturn201() throws Exception {
        BankDTO bankDTO = new BankDTO(bank.getId(), bank.getBankName(), bank.getBankCode(),
                bank.getBranchName(), bank.getBranchCode(), bank.getAccountNumber(),
                bank.getAddress(), bank.getEmail(), bank.getPhoneNumber());
        DataResult<BankDTO> result = new SuccessDataResult<>(bankDTO, "Bank saved");

        when(bankService.save(any(BankSaveRequest.class))).thenReturn(result);

        mockMvc.perform(post("/api/v1/banks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(bankSaveRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenBankUpdateRequest_whenUpdate_thenReturn200() throws Exception {
        BankDTO bankDTO = new BankDTO(bank.getId(), bank.getBankName(), bank.getBankCode(),
                bank.getBranchName(), bank.getBranchCode(), bank.getAccountNumber(),
                bank.getAddress(), bank.getEmail(), bank.getPhoneNumber());
        DataResult<BankDTO> result = new SuccessDataResult<>(bankDTO, "Bank updated");

        when(bankService.update(any(BankUpdateRequest.class))).thenReturn(result);

        mockMvc.perform(put("/api/v1/banks")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(bankUpdateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenBankId_whenDelete_thenReturn200() throws Exception {
        Result result = new SuccessResult("Bank deleted");

        when(bankService.deleteById(bank.getId())).thenReturn(result);

        mockMvc.perform(delete("/api/v1/banks/{bankId}", bank.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenBankId_whenFindById_thenReturn200() throws Exception {
        BankDTO bankDTO = new BankDTO(bank.getId(), bank.getBankName(), bank.getBankCode(),
                bank.getBranchName(), bank.getBranchCode(), bank.getAccountNumber(),
                bank.getAddress(), bank.getEmail(), bank.getPhoneNumber());
        DataResult<BankDTO> result = new SuccessDataResult<>(bankDTO, "Bank found");

        when(bankService.findById(bank.getId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/banks/{bankId}", bank.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void whenFindAll_thenReturn200() throws Exception {
        DataResult<List<BankDTO>> result = new SuccessDataResult<>(List.of(), "Banks listed");

        when(bankService.findAll()).thenReturn(result);

        mockMvc.perform(get("/api/v1/banks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
