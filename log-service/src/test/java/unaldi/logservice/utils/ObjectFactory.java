package unaldi.logservice.utils;

import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import unaldi.logservice.model.Log;
import unaldi.logservice.model.enums.LogType;
import unaldi.logservice.model.enums.OperationType;
import unaldi.logservice.model.request.LogSaveRequest;
import unaldi.logservice.model.request.LogUpdateRequest;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Copyright (c) 2024
 * All rights reserved.
 *
 * @author Emre Ünaldı
 */
@NoArgsConstructor(access = AccessLevel.PRIVATE)
public class ObjectFactory {
    private static ObjectFactory instance;
    private Log log;
    private List<Log> logList;
    private LogSaveRequest logSaveRequest;
    private LogUpdateRequest logUpdateRequest;

    public static synchronized ObjectFactory getInstance() {
        if (instance == null) {
            instance = new ObjectFactory();
        }

        return instance;
    }

    public Log getLog() {
        if (log == null) {
            log = new Log(
                    "log-001",
                    "user-service",
                    OperationType.POST,
                    LogType.INFO,
                    "User created successfully",
                    LocalDateTime.of(2024, 1, 1, 10, 0),
                    null
            );
        }

        return log;
    }

    public List<Log> getLogList() {
        if (logList == null) {
            logList = List.of(
                    getLog(),
                    new Log(
                            "log-002",
                            "bank-service",
                            OperationType.DELETE,
                            LogType.WARN,
                            "Bank account deleted",
                            LocalDateTime.of(2024, 1, 2, 11, 0),
                            null
                    )
            );
        }

        return logList;
    }

    public LogSaveRequest getLogSaveRequest() {
        if (logSaveRequest == null) {
            logSaveRequest = new LogSaveRequest(
                    "user-service",
                    OperationType.POST,
                    LogType.INFO,
                    "User created successfully",
                    LocalDateTime.of(2024, 1, 1, 10, 0),
                    null
            );
        }

        return logSaveRequest;
    }

    public LogUpdateRequest getLogUpdateRequest() {
        if (logUpdateRequest == null) {
            logUpdateRequest = new LogUpdateRequest(
                    "log-001",
                    "user-service",
                    OperationType.PUT,
                    LogType.INFO,
                    "User updated successfully",
                    LocalDateTime.of(2024, 1, 1, 12, 0),
                    null
            );
        }

        return logUpdateRequest;
    }
}
