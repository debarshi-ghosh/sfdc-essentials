@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class TriggerFactoryHandlerTest {

    /**
     * Concrete subclass to test the abstract TriggerFactoryHandler
     */
    private class ConcreteHandler extends TriggerFactoryHandler {
        public Boolean beforeInsertCalled = false;
        public Boolean beforeUpdateCalled = false;
        public Boolean beforeDeleteCalled = false;
        public Boolean afterInsertCalled = false;
        public Boolean afterUpdateCalled = false;
        public Boolean afterDeleteCalled = false;
        public Boolean afterUnDeleteCalled = false;
        public Boolean setupCallbackCalled = false;
        public Boolean logBeforeCalled = false;
        public Boolean logAfterCalled = false;

        protected override void onBeforeInsert(TriggerContext context) {
            beforeInsertCalled = true;
        }
        protected override void onBeforeUpdate(TriggerContext context) {
            beforeUpdateCalled = true;
        }
        protected override void onBeforeDelete(TriggerContext context) {
            beforeDeleteCalled = true;
        }
        protected override void onAfterInsert(TriggerContext context) {
            afterInsertCalled = true;
        }
        protected override void onAfterUpdate(TriggerContext context) {
            afterUpdateCalled = true;
        }
        protected override void onAfterDelete(TriggerContext context) {
            afterDeleteCalled = true;
        }
        protected override void onAfterUnDelete(TriggerContext context) {
            afterUnDeleteCalled = true;
        }
        protected override void sobjectTypeSetupCallback(Type typeName) {
            setupCallbackCalled = true;
        }
        protected override void logBeforeEventHandling(TriggerContext context) {
            logBeforeCalled = true;
        }
        protected override void logAfterEventHandling(TriggerContext context) {
            logAfterCalled = true;
        }
    }

    /**
     * Subclass that overrides nothing, so the default (empty) virtual implementations run.
     */
    private class BareHandler extends TriggerFactoryHandler {
    }

    @IsTest
    static void testDefaultVirtualImplementationsAreNoOps() {
        BareHandler handler = new BareHandler();
        TriggerFactoryHandler.TriggerContext ctx = new TriggerFactoryHandler.TriggerContext();

        handler.beforeInsert(ctx);
        handler.beforeUpdate(ctx);
        handler.beforeDelete(ctx);
        handler.afterInsert(ctx);
        handler.afterUpdate(ctx);
        handler.afterDelete(ctx);
        handler.afterUnDelete(ctx);
        handler.setSobjectType(Account.class);

        System.assertEquals(Account.class, handler.getTypeName(), 'The default implementations should not fail');
    }

    @IsTest
    static void testBeforeInsert() {
        ConcreteHandler handler = new ConcreteHandler();
        TriggerFactoryHandler.TriggerContext ctx = new TriggerFactoryHandler.TriggerContext();
        handler.beforeInsert(ctx);
        System.assert(handler.beforeInsertCalled, 'onBeforeInsert should be called');
        System.assert(handler.logBeforeCalled, 'logBefore should be called');
        System.assert(handler.logAfterCalled, 'logAfter should be called');
    }

    @IsTest
    static void testBeforeUpdate() {
        ConcreteHandler handler = new ConcreteHandler();
        TriggerFactoryHandler.TriggerContext ctx = new TriggerFactoryHandler.TriggerContext();
        handler.beforeUpdate(ctx);
        System.assert(handler.beforeUpdateCalled, 'onBeforeUpdate should be called');
    }

    @IsTest
    static void testBeforeDelete() {
        ConcreteHandler handler = new ConcreteHandler();
        TriggerFactoryHandler.TriggerContext ctx = new TriggerFactoryHandler.TriggerContext();
        handler.beforeDelete(ctx);
        System.assert(handler.beforeDeleteCalled, 'onBeforeDelete should be called');
    }

    @IsTest
    static void testAfterInsert() {
        ConcreteHandler handler = new ConcreteHandler();
        TriggerFactoryHandler.TriggerContext ctx = new TriggerFactoryHandler.TriggerContext();
        handler.afterInsert(ctx);
        System.assert(handler.afterInsertCalled, 'onAfterInsert should be called');
    }

    @IsTest
    static void testAfterUpdate() {
        ConcreteHandler handler = new ConcreteHandler();
        TriggerFactoryHandler.TriggerContext ctx = new TriggerFactoryHandler.TriggerContext();
        handler.afterUpdate(ctx);
        System.assert(handler.afterUpdateCalled, 'onAfterUpdate should be called');
    }

    @IsTest
    static void testAfterDelete() {
        ConcreteHandler handler = new ConcreteHandler();
        TriggerFactoryHandler.TriggerContext ctx = new TriggerFactoryHandler.TriggerContext();
        handler.afterDelete(ctx);
        System.assert(handler.afterDeleteCalled, 'onAfterDelete should be called');
    }

    @IsTest
    static void testAfterUnDelete() {
        ConcreteHandler handler = new ConcreteHandler();
        TriggerFactoryHandler.TriggerContext ctx = new TriggerFactoryHandler.TriggerContext();
        handler.afterUnDelete(ctx);
        System.assert(handler.afterUnDeleteCalled, 'onAfterUnDelete should be called');
    }

    @IsTest
    static void testSetGetSobjectType() {
        ConcreteHandler handler = new ConcreteHandler();
        handler.setSobjectType(Account.class);
        System.assertEquals(Account.class, handler.getTypeName(), 'Type should match');
        System.assert(handler.setupCallbackCalled, 'sobjectTypeSetupCallback should be called');
    }

    @IsTest
    static void testSetGetName() {
        ConcreteHandler handler = new ConcreteHandler();
        handler.setName('TestHandler');
        System.assertEquals('TestHandler', handler.getName(), 'Name should match');
    }

    @IsTest
    static void testTriggerContextConstructor() {
        TriggerFactoryHandler.TriggerContext ctx = new TriggerFactoryHandler.TriggerContext();
        // Outside trigger context, these should be null
        System.assertEquals(null, ctx.newList, 'newList should be null outside trigger');
        System.assertEquals(null, ctx.newMap, 'newMap should be null outside trigger');
        System.assertEquals(null, ctx.oldList, 'oldList should be null outside trigger');
        System.assertEquals(null, ctx.oldMap, 'oldMap should be null outside trigger');
    }

    @IsTest
    static void testDefaultConstructor() {
        ConcreteHandler handler = new ConcreteHandler();
        System.assertNotEquals(null, handler, 'Handler should be instantiated');
    }

    @IsTest
    static void testGetInstanceReturnsSingleton() {
        TriggerHandlerExecution first = TriggerHandlerExecution.getInstance();
        TriggerHandlerExecution second = TriggerHandlerExecution.getInstance();
        System.assertNotEquals(null, first, 'The singleton should be instantiated');
        System.assert(first === second, 'The same singleton instance should be returned');
    }

    @IsTest
    static void testGetHandlerIsPooledPerType() {
        TriggerHandlerExecution execution = TriggerHandlerExecution.getInstance();
        TriggerHandlerExecution.HandlerExecutor accountExecutor = execution.getHandler(Account.class);
        System.assert(
            accountExecutor === execution.getHandler(Account.class),
            'The executor should be reused for the same type'
        );
        System.assert(
            accountExecutor !== execution.getHandler(Contact.class),
            'A different type should get its own executor'
        );
    }

    @IsTest
    static void testExecuteSkipsHandlersWhenObjectIsBypassed() {
        AutomationBypass.clearCache();
        AutomationBypass.setBypass('Account', true);

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        TriggerHandlerExecution.getInstance().getHandler(Account.class).execute();
        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        System.assertEquals(queriesBefore, queriesAfter, 'A bypassed object should not read the configuration');
        System.assertEquals(true, AutomationBypass.isBypassed('Account'), 'The bypass decision should stay cached');
    }

    @IsTest
    static void testExecuteSkipsHandlersWhenGlobalBypassIsOn() {
        AutomationBypass.clearCache();
        TriggerHandlerExecution.BYPASS = true;
        try {
            Test.startTest();
            Integer queriesBefore = Limits.getQueries();
            TriggerHandlerExecution.getInstance().getHandler(Account.class).execute();
            Integer queriesAfter = Limits.getQueries();
            Test.stopTest();
            System.assertEquals(queriesBefore, queriesAfter, 'The global switch should short circuit the execution');
        } finally {
            TriggerHandlerExecution.BYPASS = false;
            AutomationBypass.clearCache();
        }
    }

    @IsTest
    static void testExecuteReadsConfigurationWhenNotBypassed() {
        AutomationBypass.clearCache();

        Test.startTest();
        TriggerHandlerExecution.getInstance().getHandler(Account.class).execute();
        Test.stopTest();

        System.assertEquals(false, AutomationBypass.isBypassed('Account'), 'Account should not be bypassed by default');
        System.assertNotEquals(
            null,
            AutomationBypass.getActiveConfig('Account'),
            'The active configuration should have been read and cached'
        );
    }

    private static void seedMockConfig(String bypassedUser, String bypassedProfile) {
        AutomationBypass.clearCache();
        AutomationBypass.setActiveConfig(
            'Account',
            new List<Trigger_Factory__mdt>{
                new Trigger_Factory__mdt(
                    DeveloperName = 'Mock_Handler',
                    Class_Name__c = 'TriggerFactoryHandlerMock',
                    Object_API_Name__c = 'Account',
                    Bypassed_User__c = bypassedUser,
                    Bypassed_Profile__c = bypassedProfile,
                    Execution_Order__c = 1
                )
            }
        );
        TriggerFactoryHandlerMock.reset();
    }

    private static void runOperation(TriggerOperation operation) {
        TriggerHandlerExecution.getInstance().getHandler(Account.class).execute(operation);
    }

    @IsTest
    static void testExecuteDispatchesEveryTriggerOperation() {
        Map<TriggerOperation, String> operations = new Map<TriggerOperation, String>{
            TriggerOperation.BEFORE_INSERT => 'before insert',
            TriggerOperation.BEFORE_UPDATE => 'before update',
            TriggerOperation.BEFORE_DELETE => 'before delete',
            TriggerOperation.AFTER_INSERT => 'after insert',
            TriggerOperation.AFTER_UPDATE => 'after update',
            TriggerOperation.AFTER_DELETE => 'after delete',
            TriggerOperation.AFTER_UNDELETE => 'after undelete'
        };

        Test.startTest();
        for (TriggerOperation operation : operations.keySet()) {
            seedMockConfig(null, null);
            runOperation(operation);
            System.assertEquals(
                operation,
                TriggerFactoryHandlerMock.lastOperation,
                'The handler should be dispatched for ' + operations.get(operation)
            );
            System.assertEquals(1, TriggerFactoryHandlerMock.instantiations, 'The handler should be instantiated once');
            System.assertEquals(
                'TriggerFactoryHandlerMock',
                TriggerFactoryHandlerMock.lastName,
                'The handler name should be set from the configuration'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testExecuteWithoutOperationTypeDispatchesNothing() {
        seedMockConfig(null, null);

        Test.startTest();
        runOperation(null);
        Test.stopTest();

        System.assertEquals(1, TriggerFactoryHandlerMock.instantiations, 'The handler should still be instantiated');
        System.assertEquals(
            null,
            TriggerFactoryHandlerMock.lastOperation,
            'No event should be dispatched without an operation type'
        );
    }

    @IsTest
    static void testExecuteSkipsHandlerWhenUserIsBypassed() {
        seedMockConfig(UserInfo.getUserName(), null);

        Test.startTest();
        runOperation(TriggerOperation.BEFORE_INSERT);
        Test.stopTest();

        System.assertEquals(0, TriggerFactoryHandlerMock.instantiations, 'A bypassed user should not run the handler');
    }

    @IsTest
    static void testExecuteRunsHandlerWhenAnotherUserIsBypassed() {
        seedMockConfig('someone.else@example.com', 'No Such Profile');

        Test.startTest();
        runOperation(TriggerOperation.AFTER_INSERT);
        Test.stopTest();

        System.assertEquals(1, TriggerFactoryHandlerMock.instantiations, 'A non bypassed user should run the handler');
    }

    @IsTest
    static void testExecuteLogsErrorForUnknownClass() {
        AutomationBypass.clearCache();
        AutomationBypass.setActiveConfig(
            'Account',
            new List<Trigger_Factory__mdt>{
                new Trigger_Factory__mdt(
                    DeveloperName = 'Missing_Handler',
                    Class_Name__c = 'ThisClassDoesNotExist',
                    Object_API_Name__c = 'Account',
                    Execution_Order__c = 1
                )
            }
        );
        TriggerFactoryHandlerMock.reset();

        Test.startTest();
        runOperation(TriggerOperation.BEFORE_INSERT);
        Test.stopTest();

        System.assertEquals(0, TriggerFactoryHandlerMock.instantiations, 'An unresolvable class should be skipped');
    }

    @IsTest
    static void testRecursionDepthIsReleasedAfterNormalExecution() {
        seedMockConfig(null, null);
        TriggerHandlerExecution.resetRecursionDepth();

        Test.startTest();
        runOperation(TriggerOperation.BEFORE_INSERT);
        runOperation(TriggerOperation.BEFORE_INSERT);
        Test.stopTest();

        System.assertEquals(2, TriggerFactoryHandlerMock.instantiations, 'Sequential runs should not be blocked');
        for (Integer depth : TriggerHandlerExecution.RECURSION_DEPTH.values()) {
            System.assertEquals(0, depth, 'The depth counter should be released after each run');
        }
    }

    @IsTest
    static void testRecursionBeyondMaxDepthThrows() {
        seedMockConfig(null, null);
        TriggerHandlerExecution.resetRecursionDepth();
        TriggerHandlerExecution.MAX_RECURSION_DEPTH = 3;
        TriggerFactoryHandlerMock.recurseOnBeforeInsert = true;

        String message;
        Test.startTest();
        try {
            runOperation(TriggerOperation.BEFORE_INSERT);
            System.assert(false, 'A TriggerRecursionException was expected');
        } catch (TriggerHandlerExecution.TriggerRecursionException e) {
            message = e.getMessage();
        } finally {
            TriggerFactoryHandlerMock.recurseOnBeforeInsert = false;
            TriggerHandlerExecution.MAX_RECURSION_DEPTH = 5;
        }
        Test.stopTest();

        System.assert(
            message.contains('Maximum recursion depth of 3'),
            'The exception should report the configured maximum, got: ' + message
        );
        System.assert(
            message.contains('TriggerFactoryHandlerMock'),
            'The exception should name the offending handler, got: ' + message
        );
        System.assertEquals(
            3,
            TriggerFactoryHandlerMock.instantiations,
            'The handler should run exactly MAX_RECURSION_DEPTH times'
        );
    }

    @IsTest
    static void testResetRecursionDepthClearsCounters() {
        seedMockConfig(null, null);
        runOperation(TriggerOperation.AFTER_INSERT);
        System.assert(!TriggerHandlerExecution.RECURSION_DEPTH.isEmpty(), 'A counter should have been created');

        Test.startTest();
        TriggerHandlerExecution.resetRecursionDepth();
        Test.stopTest();

        System.assert(TriggerHandlerExecution.RECURSION_DEPTH.isEmpty(), 'The counters should be cleared');
    }
}