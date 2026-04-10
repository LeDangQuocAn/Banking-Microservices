package unaldi.logservice.utils;

import lombok.AccessLevel;
import lombok.NoArgsConstructor;

/**
 * Copyright (c) 2024
 * All rights reserved.
 *
 * @author Emre Ünaldı
 */
@NoArgsConstructor(access = AccessLevel.PRIVATE)
public class FailTestMessages {
    public static final String LOG_SAVE = "Log save operation test failed !";
    public static final String LOG_UPDATE = "Log update operation test failed !";
    public static final String LOG_DELETE = "Log delete operation test failed !";
    public static final String LOG_FIND = "Log find operation test failed !";
    public static final String LOGS_FIND = "Log list fetch operation test failed !";

    public static final String LOG_UPDATE_EXCEPTION = "LogNotFoundException was expected but not thrown during update operation";
    public static final String LOG_DELETE_EXCEPTION = "LogNotFoundException was expected but not thrown during delete operation";
    public static final String LOG_FIND_EXCEPTION = "LogNotFoundException was expected but not thrown during find operation";
}
