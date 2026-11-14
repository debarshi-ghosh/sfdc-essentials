/**
 * @description Test class for CommunityActionDispatcher, CommunityActionResult
 *              and the ICommunityAction extension point.
 */
@IsTest
private class CommunityActionDispatcherTest {

    private static final String TEST_ACTION_KEY = 'Test_Action';
    private static final String FAILING_ACTION_KEY = 'Failing_Action';

    /**
     * @description Sample handler used to verify dispatcher routing.
     */
    public class MockAction implements ICommunityAction {
        /**
         * @description Returns a successful OPEN_URL result for the given record.
         * @param recordId The record the action was invoked on.
         * @return CommunityActionResult describing what the UI should do.
         */
        public CommunityActionResult execute(Id recordId) {
            return CommunityActionResult.openUrl('https://example.com/' + recordId);
        }
    }

    /**
     * @description Sample handler that throws, to verify dispatcher error handling.
     */
    public class ThrowingAction implements ICommunityAction {
        /**
         * @description Always throws to exercise the dispatcher catch block.
         * @param recordId The record the action was invoked on.
         * @return CommunityActionResult never returned.
         */
        public CommunityActionResult execute(Id recordId) {
            throw new CalloutException('Handler blew up for ' + recordId);
        }
    }

    @TestSetup
    static void setupTestData() {
        insert new Account(Name = 'Dispatcher Test Account');
    }

    private static Account getTestAccount() {
        return [SELECT Id FROM Account WHERE Name = 'Dispatcher Test Account' LIMIT 1];
    }

    // ─── CommunityActionResult ─────────────────────────────────────────────────

    @IsTest
    static void testResultOpenUrl() {
        Test.startTest();
        CommunityActionResult result = CommunityActionResult.openUrl('https://example.com');
        Test.stopTest();

        System.assertEquals('OPEN_URL', result.resultType, 'Should be OPEN_URL type');
        System.assertEquals(true, result.success, 'Should be success');
        System.assertEquals('https://example.com', result.url, 'URL should match');
    }

    @IsTest
    static void testResultToastError() {
        Test.startTest();
        CommunityActionResult result = CommunityActionResult.toast('Error', 'Something failed', 'error');
        Test.stopTest();

        System.assertEquals('TOAST', result.resultType, 'Should be TOAST type');
        System.assertEquals(false, result.success, 'Error toast should have success=false');
        System.assertEquals('Error', result.title, 'Title should match');
        System.assertEquals('Something failed', result.message, 'Message should match');
        System.assertEquals('error', result.variant, 'Variant should be error');
    }

    @IsTest
    static void testResultToastSuccess() {
        Test.startTest();
        CommunityActionResult result = CommunityActionResult.toast('Done', 'Completed', 'success');
        Test.stopTest();

        System.assertEquals('TOAST', result.resultType, 'Should be TOAST type');
        System.assertEquals(true, result.success, 'Success toast should have success=true');
        System.assertEquals('success', result.variant, 'Variant should be success');
    }

    @IsTest
    static void testResultNavigate() {
        Account acc = getTestAccount();

        Test.startTest();
        CommunityActionResult result = CommunityActionResult.navigate(acc.Id);
        Test.stopTest();

        System.assertEquals('NAVIGATE', result.resultType, 'Should be NAVIGATE type');
        System.assertEquals(true, result.success, 'Should be success');
        System.assertEquals(acc.Id, result.recordId, 'Record Id should match');
    }

    // ─── CommunityActionDispatcher ─────────────────────────────────────────────

    @IsTest
    static void testExecuteActionBlankActionName() {
        Account acc = getTestAccount();

        Test.startTest();
        CommunityActionResult result = CommunityActionDispatcher.executeAction('', acc.Id);
        Test.stopTest();

        System.assertEquals('TOAST', result.resultType, 'Should return toast for blank action');
        System.assertEquals(false, result.success, 'Should be error');
        System.assert(result.message.contains('Invalid action'), 'Should mention invalid action');
    }

    @IsTest
    static void testExecuteActionNullRecordId() {
        Test.startTest();
        CommunityActionResult result = CommunityActionDispatcher.executeAction(TEST_ACTION_KEY, null);
        Test.stopTest();

        System.assertEquals('TOAST', result.resultType, 'Should return toast for null record');
        System.assertEquals(false, result.success, 'Should be error');
    }

    @IsTest
    static void testExecuteActionNoHandlerRegistered() {
        Account acc = getTestAccount();
        CommunityActionDispatcher.actionHandlerMap = new Map<String, String>();

        Test.startTest();
        CommunityActionResult result = CommunityActionDispatcher.executeAction(
            'Unregistered_Action_Name', acc.Id
        );
        Test.stopTest();

        System.assertEquals('TOAST', result.resultType, 'Should return toast for unregistered action');
        System.assertEquals(false, result.success, 'Should be error');
        System.assert(result.message.contains('No handler registered'), 'Should mention no handler');
    }

    @IsTest
    static void testRegistryLoadsFromCustomMetadata() {
        Account acc = getTestAccount();

        Test.startTest();
        CommunityActionResult result = CommunityActionDispatcher.executeAction(
            'Action_With_No_Metadata_Record', acc.Id
        );
        Test.stopTest();

        System.assertEquals('TOAST', result.resultType, 'Should fall back to a toast');
        System.assertEquals(false, result.success, 'Should be error when nothing is configured');
    }

    @IsTest
    static void testExecuteActionHandlerClassNotFound() {
        Account acc = getTestAccount();
        CommunityActionDispatcher.actionHandlerMap = new Map<String, String>{
            TEST_ACTION_KEY => 'ThisClassDoesNotExist_12345'
        };

        Test.startTest();
        CommunityActionResult result = CommunityActionDispatcher.executeAction(
            'My_Object__c.' + TEST_ACTION_KEY, acc.Id
        );
        Test.stopTest();

        System.assertEquals('TOAST', result.resultType, 'Should return toast when class is missing');
        System.assertEquals(false, result.success, 'Should be error');
        System.assert(result.message.contains('Handler class not found'), 'Should mention missing class');
    }

    @IsTest
    static void testExecuteActionRoutesToHandler() {
        Account acc = getTestAccount();
        CommunityActionDispatcher.actionHandlerMap = new Map<String, String>{
            TEST_ACTION_KEY => 'CommunityActionDispatcherTest.MockAction'
        };

        Test.startTest();
        CommunityActionResult result = CommunityActionDispatcher.executeAction(
            'My_Object__c.' + TEST_ACTION_KEY, acc.Id
        );
        Test.stopTest();

        System.assertEquals('OPEN_URL', result.resultType, 'Should return the handler result');
        System.assertEquals(true, result.success, 'Should be success');
        System.assert(result.url.contains(acc.Id), 'URL should contain the record Id');
    }

    @IsTest
    static void testExecuteActionExactMatchWins() {
        Account acc = getTestAccount();
        CommunityActionDispatcher.actionHandlerMap = new Map<String, String>{
            'My_Object__c.' + TEST_ACTION_KEY => 'CommunityActionDispatcherTest.MockAction',
            TEST_ACTION_KEY => 'CommunityActionDispatcherTest.ThrowingAction'
        };

        Test.startTest();
        CommunityActionResult result = CommunityActionDispatcher.executeAction(
            'My_Object__c.' + TEST_ACTION_KEY, acc.Id
        );
        Test.stopTest();

        System.assertEquals('OPEN_URL', result.resultType, 'Exact configured match should win');
        System.assertEquals(true, result.success, 'Should be success');
    }

    @IsTest
    static void testExecuteActionHandlerThrows() {
        Account acc = getTestAccount();
        CommunityActionDispatcher.actionHandlerMap = new Map<String, String>{
            FAILING_ACTION_KEY => 'CommunityActionDispatcherTest.ThrowingAction'
        };

        Test.startTest();
        CommunityActionResult result = CommunityActionDispatcher.executeAction(
            'My_Object__c.' + FAILING_ACTION_KEY, acc.Id
        );
        Test.stopTest();

        System.assertEquals('TOAST', result.resultType, 'Should return TOAST when handler throws');
        System.assertEquals(false, result.success, 'Should be error');
        System.assertNotEquals(null, result.message, 'Error message should be present');
    }
}
