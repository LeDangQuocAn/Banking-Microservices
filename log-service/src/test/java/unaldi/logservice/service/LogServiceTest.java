package unaldi.logservice.service;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import unaldi.logservice.model.Log;
import unaldi.logservice.model.dto.LogDTO;
import unaldi.logservice.model.request.LogSaveRequest;
import unaldi.logservice.model.request.LogUpdateRequest;
import unaldi.logservice.repository.LogRepository;
import unaldi.logservice.service.concretes.LogServiceImpl;
import unaldi.logservice.utils.FailTestMessages;
import unaldi.logservice.utils.ObjectFactory;
import unaldi.logservice.utils.exception.customExceptions.LogNotFoundException;
import unaldi.logservice.utils.result.DataResult;
import unaldi.logservice.utils.result.Result;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.*;

/**
 * Copyright (c) 2024
 * All rights reserved.
 *
 * @author Emre Ünaldı
 */
@ExtendWith(MockitoExtension.class)
class LogServiceTest {
    private static Log log;
    private static List<Log> logList;
    private static LogSaveRequest logSaveRequest;
    private static LogUpdateRequest logUpdateRequest;
    private final String nonExistentLogId = "non-existent-id";

    @Mock
    private LogRepository logRepository;

    @InjectMocks
    private LogServiceImpl logService;

    @BeforeAll
    static void setUp() {
        log = ObjectFactory.getInstance().getLog();
        logList = ObjectFactory.getInstance().getLogList();
        logSaveRequest = ObjectFactory.getInstance().getLogSaveRequest();
        logUpdateRequest = ObjectFactory.getInstance().getLogUpdateRequest();
    }

    @Test
    void givenLogSaveRequest_whenSave_thenLogShouldBeSaved() {
        when(logRepository.save(any(Log.class))).thenReturn(log);

        DataResult<LogDTO> result = logService.save(logSaveRequest);
        assertTrue(result.getSuccess(), FailTestMessages.LOG_SAVE);

        verify(logRepository, times(1)).save(any(Log.class));
    }

    @Test
    void givenLogUpdateRequest_whenUpdate_thenLogShouldBeUpdated() {
        when(logRepository.existsById(logUpdateRequest.id())).thenReturn(true);
        when(logRepository.save(any(Log.class))).thenReturn(log);

        DataResult<LogDTO> result = logService.update(logUpdateRequest);
        assertTrue(result.getSuccess(), FailTestMessages.LOG_UPDATE);

        verify(logRepository, times(1)).existsById(logUpdateRequest.id());
        verify(logRepository, times(1)).save(any(Log.class));
    }

    @Test
    void givenLogId_whenDeleteById_thenLogShouldBeDeleted() {
        when(logRepository.findById(log.getId())).thenReturn(Optional.of(log));

        Result result = logService.deleteById(log.getId());
        assertTrue(result.getSuccess(), FailTestMessages.LOG_DELETE);

        verify(logRepository, times(1)).deleteById(log.getId());
    }

    @Test
    void givenLogId_whenFindById_thenLogShouldBeFound() {
        when(logRepository.findById(log.getId())).thenReturn(Optional.of(log));

        DataResult<LogDTO> result = logService.findById(log.getId());
        assertTrue(result.getSuccess(), FailTestMessages.LOG_FIND);

        verify(logRepository, times(1)).findById(log.getId());
    }

    @Test
    void givenLogList_whenFindAll_thenAllLogsShouldBeReturned() {
        when(logRepository.findAll()).thenReturn(logList);

        DataResult<List<LogDTO>> result = logService.findAll();
        assertTrue(result.getSuccess(), FailTestMessages.LOGS_FIND);

        verify(logRepository, times(1)).findAll();
    }

    @Test
    void givenNonExistentLogUpdateRequest_whenUpdate_thenLogNotFoundExceptionShouldBeThrown() {
        when(logRepository.existsById(logUpdateRequest.id())).thenReturn(false);

        assertThrows(LogNotFoundException.class,
                () -> logService.update(logUpdateRequest),
                FailTestMessages.LOG_UPDATE_EXCEPTION);

        verify(logRepository, times(1)).existsById(logUpdateRequest.id());
        verify(logRepository, never()).save(any(Log.class));
    }

    @Test
    void givenNonExistentLogId_whenDeleteById_thenLogNotFoundExceptionShouldBeThrown() {
        when(logRepository.findById(nonExistentLogId)).thenReturn(Optional.empty());

        assertThrows(LogNotFoundException.class,
                () -> logService.deleteById(nonExistentLogId),
                FailTestMessages.LOG_DELETE_EXCEPTION);

        verify(logRepository, never()).deleteById(any());
    }

    @Test
    void givenNonExistentLogId_whenFindById_thenLogNotFoundExceptionShouldBeThrown() {
        when(logRepository.findById(nonExistentLogId)).thenReturn(Optional.empty());

        assertThrows(LogNotFoundException.class,
                () -> logService.findById(nonExistentLogId),
                FailTestMessages.LOG_FIND_EXCEPTION);

        verify(logRepository, times(1)).findById(nonExistentLogId);
    }
}
