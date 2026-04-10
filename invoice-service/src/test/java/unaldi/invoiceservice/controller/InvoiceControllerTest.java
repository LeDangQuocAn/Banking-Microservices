package unaldi.invoiceservice.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import unaldi.invoiceservice.entity.Invoice;
import unaldi.invoiceservice.entity.dto.InvoiceDTO;
import unaldi.invoiceservice.entity.request.InvoiceSaveRequest;
import unaldi.invoiceservice.entity.request.InvoiceUpdateRequest;
import unaldi.invoiceservice.service.abstracts.InvoiceService;
import unaldi.invoiceservice.utils.ObjectFactory;
import unaldi.invoiceservice.utils.rabbitMQ.producer.LogProducer;
import unaldi.invoiceservice.utils.client.dto.UserResponse;
import unaldi.invoiceservice.utils.result.DataResult;
import unaldi.invoiceservice.utils.result.Result;
import unaldi.invoiceservice.utils.result.SuccessDataResult;
import unaldi.invoiceservice.utils.result.SuccessResult;

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
@WebMvcTest(InvoiceController.class)
class InvoiceControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private InvoiceService invoiceService;

    @MockBean
    private LogProducer logProducer;

    private static Invoice invoice;
    private static InvoiceSaveRequest invoiceSaveRequest;
    private static InvoiceUpdateRequest invoiceUpdateRequest;
    private static UserResponse userResponse;

    @BeforeAll
    static void setUp() {
        invoice = ObjectFactory.getInstance().getInvoice();
        invoiceSaveRequest = ObjectFactory.getInstance().getInvoiceSaveRequest();
        invoiceUpdateRequest = ObjectFactory.getInstance().getInvoiceUpdateRequest();
        userResponse = ObjectFactory.getInstance().getUserResponse();
    }

    @Test
    void givenInvoiceSaveRequest_whenSave_thenReturn201() throws Exception {
        InvoiceDTO invoiceDTO = new InvoiceDTO(invoice.getId(), invoice.getInvoiceNumber(),
                invoice.getUserId(), invoice.getAmount(), invoice.getInvoiceDate(),
                invoice.getDueDate(), invoice.getPaymentStatus());
        DataResult<InvoiceDTO> result = new SuccessDataResult<>(invoiceDTO, "Invoice saved");

        when(invoiceService.save(any(InvoiceSaveRequest.class))).thenReturn(result);

        mockMvc.perform(post("/api/v1/invoices")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invoiceSaveRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenInvoiceUpdateRequest_whenUpdate_thenReturn200() throws Exception {
        InvoiceDTO invoiceDTO = new InvoiceDTO(invoice.getId(), invoice.getInvoiceNumber(),
                invoice.getUserId(), invoice.getAmount(), invoice.getInvoiceDate(),
                invoice.getDueDate(), invoice.getPaymentStatus());
        DataResult<InvoiceDTO> result = new SuccessDataResult<>(invoiceDTO, "Invoice updated");

        when(invoiceService.update(any(InvoiceUpdateRequest.class))).thenReturn(result);

        mockMvc.perform(put("/api/v1/invoices")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invoiceUpdateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenInvoiceId_whenDeleteById_thenReturn200() throws Exception {
        Result result = new SuccessResult("Invoice deleted");

        when(invoiceService.deleteById(invoice.getId())).thenReturn(result);

        mockMvc.perform(delete("/api/v1/invoices/{invoiceId}", invoice.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenInvoiceId_whenFindById_thenReturn200() throws Exception {
        InvoiceDTO invoiceDTO = new InvoiceDTO(invoice.getId(), invoice.getInvoiceNumber(),
                invoice.getUserId(), invoice.getAmount(), invoice.getInvoiceDate(),
                invoice.getDueDate(), invoice.getPaymentStatus());
        DataResult<InvoiceDTO> result = new SuccessDataResult<>(invoiceDTO, "Invoice found");

        when(invoiceService.findById(invoice.getId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/invoices/{invoiceId}", invoice.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void whenFindAll_thenReturn200() throws Exception {
        DataResult<List<InvoiceDTO>> result = new SuccessDataResult<>(List.of(), "Invoices listed");

        when(invoiceService.findAll()).thenReturn(result);

        mockMvc.perform(get("/api/v1/invoices"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void givenUserId_whenFindInvoiceUserByUserId_thenReturn200() throws Exception {
        DataResult<UserResponse> result = new SuccessDataResult<>(userResponse, "User found");

        when(invoiceService.findInvoiceUserByUserId(invoice.getUserId())).thenReturn(result);

        mockMvc.perform(get("/api/v1/invoices/users/{userId}", invoice.getUserId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
