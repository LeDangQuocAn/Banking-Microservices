package unaldi.creditcardservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import unaldi.creditcardservice.entity.CreditCard;
import unaldi.creditcardservice.entity.dto.CreditCardDTO;
import unaldi.creditcardservice.entity.request.CreditCardSaveRequest;
import unaldi.creditcardservice.entity.request.CreditCardUpdateRequest;
import unaldi.creditcardservice.service.abstracts.CreditCardService;
import unaldi.creditcardservice.utils.ObjectFactory;
import unaldi.creditcardservice.utils.rabbitMQ.producer.LogProducer;
import unaldi.creditcardservice.utils.client.dto.BankResponse;
import unaldi.creditcardservice.utils.client.dto.UserResponse;
import unaldi.creditcardservice.utils.result.DataResult;
import unaldi.creditcardservice.utils.result.Result;
import unaldi.creditcardservice.utils.result.SuccessDataResult;
import unaldi.creditcardservice.utils.result.SuccessResult;

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
@WebMvcTest(CreditCardController.class)
class CreditCardControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private CreditCardService creditCardService;

    @MockBean
    private LogProducer logProducer;

    private static CreditCard creditCard;
    private static CreditCardSaveRequest creditCardSaveRequest;
    private static CreditCardUpdateRequest creditCardUpdateRequest;
    private static UserResponse userResponse;
    private static BankResponse bankResponse;

    @BeforeAll
    static void setUp() {
        creditCard = ObjectFactory.getInstance().getCreditCard();
        creditCardSaveRequest = ObjectFactory.getInstance().getCreditCardSaveRequest();
        creditCardUpdateRequest = ObjectFactory.getInstance().getCreditCardUpdateRequest();
        userResponse = ObjectFactory.getInstance().getUserResponse();
        bankResponse = ObjectFactory.getInstance().getBankResponse();
    }

    @Test
    void givenCreditCardSaveRequest_whenSave_thenReturn201() throws Exception {
        CreditCardDTO creditCardDTO = new CreditCardDTO(creditCard.getId(), creditCard.getCardNumber(),
                creditCard.getUserId(), creditCard.getExpirationDate(), creditCard.getCvv(),
                creditCard.getCreditLimit(), creditCard.getDebtAmount(), creditCard.getBankId());
        DataResult<CreditCardDTO> result = new SuccessDataResult<>(creditCardDTO, "Credit card saved");

        when(creditCardService.save(any(CreditCardSaveRequest.class))).thenReturn(result);

        mockMvc.perform(post("/api/v1/creditCards")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(creditCardSaveRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenCreditCardUpdateRequest_whenUpdate_thenReturn200() throws Exception {
        CreditCardDTO creditCardDTO = new CreditCardDTO(creditCard.getId(), creditCard.getCardNumber(),
                creditCard.getUserId(), creditCard.getExpirationDate(), creditCard.getCvv(),
                creditCard.getCreditLimit(), creditCard.getDebtAmount(), creditCard.getBankId());
        DataResult<CreditCardDTO> result = new SuccessDataResult<>(creditCardDTO, "Credit card updated");

        when(creditCardService.update(any(CreditCardUpdateRequest.class))).thenReturn(result);

        mockMvc.perform(put("/api/v1/creditCards")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(creditCardUpdateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenCreditCardId_whenDeleteById_thenReturn200() throws Exception {
        Result result = new SuccessResult("Credit card deleted");

        when(creditCardService.deleteById(creditCard.getId())).thenReturn(result);

        mockMvc.perform(delete("/api/v1/creditCards/{creditCardId}", creditCard.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenCreditCardId_whenFindById_thenReturn200() throws Exception {
        CreditCardDTO creditCardDTO = new CreditCardDTO(creditCard.getId(), creditCard.getCardNumber(),
                creditCard.getUserId(), creditCard.getExpirationDate(), creditCard.getCvv(),
                creditCard.getCreditLimit(), creditCard.getDebtAmount(), creditCard.getBankId());
        DataResult<CreditCardDTO> result = new SuccessDataResult<>(creditCardDTO, "Credit card found");

        when(creditCardService.findById(creditCard.getId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/creditCards/{creditCardId}", creditCard.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void whenFindAll_thenReturn200() throws Exception {
        DataResult<List<CreditCardDTO>> result = new SuccessDataResult<>(List.of(), "Credit cards listed");

        when(creditCardService.findAll()).thenReturn(result);

        mockMvc.perform(get("/api/v1/creditCards"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenUserId_whenFindCreditCardUserByUserId_thenReturn200() throws Exception {
        DataResult<UserResponse> result = new SuccessDataResult<>(userResponse, "User found");

        when(creditCardService.findCreditCardUserByUserId(creditCard.getUserId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/creditCards/users/{userId}", creditCard.getUserId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenBankId_whenFindCreditCardBankByBankId_thenReturn200() throws Exception {
        DataResult<BankResponse> result = new SuccessDataResult<>(bankResponse, "Bank found");

        when(creditCardService.findCreditCardBankByBankId(creditCard.getBankId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/creditCards/banks/{bankId}", creditCard.getBankId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
