package unaldi.logservice.consumer;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import unaldi.logservice.model.Log;
import unaldi.logservice.model.enums.LogType;
import unaldi.logservice.model.enums.OperationType;
import unaldi.logservice.repository.LogRepository;
import unaldi.logservice.utils.RabbitMQ.consumer.LogConsumer;
import unaldi.logservice.utils.RabbitMQ.response.LogResponse;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

/**
 * Copyright (c) 2024
 * All rights reserved.
 *
 * @author Emre Ünaldı
 */
@ExtendWith(MockitoExtension.class)
class LogConsumerTest {
    @Mock
    private LogRepository logRepository;

    @InjectMocks
    private LogConsumer logConsumer;

    @Test
    void givenLogResponse_whenFetchLogAndSaveToMongoDB_thenLogShouldBeSaved() {
        LogResponse logResponse = new LogResponse(
                "user-service",
                OperationType.POST,
                LogType.INFO,
                "User created successfully",
                LocalDateTime.of(2024, 1, 1, 10, 0),
                null
        );

        logConsumer.fetchLogAndSaveToMongoDB(logResponse);

        verify(logRepository, times(1)).save(any(Log.class));
    }
}
