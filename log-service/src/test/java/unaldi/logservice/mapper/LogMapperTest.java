package unaldi.logservice.mapper;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import unaldi.logservice.model.Log;
import unaldi.logservice.model.dto.LogDTO;
import unaldi.logservice.model.request.LogSaveRequest;
import unaldi.logservice.model.request.LogUpdateRequest;
import unaldi.logservice.service.abstracts.mapper.LogMapper;
import unaldi.logservice.utils.ObjectFactory;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Copyright (c) 2024
 * All rights reserved.
 *
 * @author Emre Ünaldı
 */
class LogMapperTest {
    private static Log log;
    private static LogSaveRequest logSaveRequest;
    private static LogUpdateRequest logUpdateRequest;
    private static List<Log> logList;

    @BeforeAll
    static void setUp() {
        log = ObjectFactory.getInstance().getLog();
        logSaveRequest = ObjectFactory.getInstance().getLogSaveRequest();
        logUpdateRequest = ObjectFactory.getInstance().getLogUpdateRequest();
        logList = ObjectFactory.getInstance().getLogList();
    }

    @Test
    void givenLogSaveRequest_whenConvertToSaveLog_thenReturnLog() {
        Log result = LogMapper.INSTANCE.convertToSaveLog(logSaveRequest);

        assertNotNull(result, "Converted log should not be null");
        assertEquals(logSaveRequest.serviceName(), result.getServiceName(), "Service name does not match");
        assertEquals(logSaveRequest.operationType(), result.getOperationType(), "Operation type does not match");
        assertEquals(logSaveRequest.logType(), result.getLogType(), "Log type does not match");
    }

    @Test
    void givenLogUpdateRequest_whenConvertToUpdateLog_thenReturnLog() {
        Log result = LogMapper.INSTANCE.convertToUpdateLog(logUpdateRequest);

        assertNotNull(result, "Converted log should not be null");
        assertEquals(logUpdateRequest.id(), result.getId(), "Id does not match");
        assertEquals(logUpdateRequest.serviceName(), result.getServiceName(), "Service name does not match");
        assertEquals(logUpdateRequest.operationType(), result.getOperationType(), "Operation type does not match");
    }

    @Test
    void givenLog_whenConvertToLogDTO_thenReturnLogDTO() {
        LogDTO result = LogMapper.INSTANCE.convertToLogDTO(log);

        assertNotNull(result, "LogDTO should not be null");
        assertEquals(log.getId(), result.id(), "Id does not match");
        assertEquals(log.getServiceName(), result.serviceName(), "Service name does not match");
        assertEquals(log.getOperationType(), result.operationType(), "Operation type does not match");
        assertEquals(log.getLogType(), result.logType(), "Log type does not match");
        assertEquals(log.getMessage(), result.message(), "Message does not match");
        assertEquals(log.getTimestamp(), result.timestamp(), "Timestamp does not match");
    }

    @Test
    void givenLogList_whenConvertLogDTOs_thenReturnLogDTOList() {
        List<LogDTO> result = LogMapper.INSTANCE.convertLogDTOs(logList);

        assertNotNull(result, "LogDTO list should not be null");
        assertEquals(logList.size(), result.size(), "List size does not match");
        assertEquals(logList.get(0).getId(), result.get(0).id(), "First log id does not match");
    }
}
