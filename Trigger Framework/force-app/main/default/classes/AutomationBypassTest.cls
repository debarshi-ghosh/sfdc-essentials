/**
 * @description Tests for AutomationBypass, the shared trigger and flow bypass evaluator.
 */
@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class AutomationBypassTest {
    private static Trigger_Factory__mdt buildConfig(String bypassedUser, String bypassedProfile) {
        return new Trigger_Factory__mdt(
            DeveloperName = 'Test_Config',
            Class_Name__c = 'SomeHandler',
            Object_API_Name__c = 'Account',
            Bypassed_User__c = bypassedUser,
            Bypassed_Profile__c = bypassedProfile,
            Execution_Order__c = 1
        );
    }

    @IsTest
    static void testNoConfigMeansNoBypass() {
        AutomationBypass.clearCache();
        Test.startTest();
        Boolean result = AutomationBypass.isBypassed('ObjectWithNoConfiguration__c');
        Test.stopTest();
        System.assertEquals(false, result, 'An object without configuration must never be bypassed');
    }

    @IsTest
    static void testBlankAndNullInputsAreNotBypassed() {
        AutomationBypass.clearCache();
        System.assertEquals(false, AutomationBypass.isBypassed((String) null), 'Null object name must not bypass');
        System.assertEquals(false, AutomationBypass.isBypassed('   '), 'Blank object name must not bypass');
        System.assertEquals(false, AutomationBypass.isBypassed((SObjectType) null), 'Null type must not bypass');
        System.assertEquals(false, AutomationBypass.isBypassed((SObject) null), 'Null record must not bypass');
        System.assertEquals(false, AutomationBypass.isBypassed((Trigger_Factory__mdt) null), 'Null config must not bypass');
    }

    @IsTest
    static void testSetBypassIsSharedAcrossCallers() {
        AutomationBypass.clearCache();
        AutomationBypass.setBypass('Account', true);
        System.assertEquals(true, AutomationBypass.isBypassed('Account'), 'The cached decision must be reused');
        System.assertEquals(true, AutomationBypass.isBypassed('ACCOUNT'), 'The cache key must be case insensitive');
        System.assertEquals(
            true,
            AutomationBypass.isBypassed(Account.SObjectType),
            'The SObjectType overload must resolve to the same cache entry'
        );
        System.assertEquals(
            true,
            AutomationBypass.isBypassed(new Account()),
            'The record overload must resolve to the same cache entry'
        );
    }

    @IsTest
    static void testSetBypassIgnoresInvalidArguments() {
        AutomationBypass.clearCache();
        AutomationBypass.setBypass(null, true);
        AutomationBypass.setBypass('Account', null);
        System.assertEquals(0, AutomationBypass.BYPASS_CACHE.size(), 'Invalid arguments must not populate the cache');
    }

    @IsTest
    static void testClearCacheResetsDecision() {
        AutomationBypass.clearCache();
        AutomationBypass.setBypass('Account', true);
        AutomationBypass.clearCache();
        System.assertEquals(false, AutomationBypass.isBypassed('Account'), 'Clearing the cache must re-evaluate');
    }

    @IsTest
    static void testGlobalBypassWinsOverEverything() {
        AutomationBypass.clearCache();
        TriggerHandlerExecution.BYPASS = true;
        try {
            System.assertEquals(true, AutomationBypass.isBypassed('Account'), 'The global switch must bypass any object');
            System.assertEquals(
                true,
                AutomationBypass.isBypassed(buildConfig(null, null)),
                'The global switch must bypass any configuration row'
            );
            System.assertEquals(0, AutomationBypass.BYPASS_CACHE.size(), 'The global switch must not pollute the cache');
        } finally {
            TriggerHandlerExecution.BYPASS = false;
        }
    }

    @IsTest
    static void testConfigMatchesRunningUserName() {
        AutomationBypass.clearCache();
        Trigger_Factory__mdt config = buildConfig(UserInfo.getUserName(), null);
        System.assertEquals(true, AutomationBypass.isBypassed(config), 'The running user name must match');
    }

    @IsTest
    static void testConfigMatchesRunningUserNameCaseInsensitivelyInAList() {
        AutomationBypass.clearCache();
        String csv = 'someone@example.com , ' + UserInfo.getUserName().toUpperCase() + ' ,other@example.com';
        System.assertEquals(
            true,
            AutomationBypass.isBypassed(buildConfig(csv, null)),
            'A comma separated, differently cased and padded value must still match'
        );
    }

    @IsTest
    static void testConfigMatchesRunningProfileName() {
        AutomationBypass.clearCache();
        Profile runningProfile = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
        Test.startTest();
        Boolean result = AutomationBypass.isBypassed(buildConfig(null, 'Nobody, ' + runningProfile.Name));
        Test.stopTest();
        System.assertEquals(true, result, 'The running user profile name must match');
    }

    @IsTest
    static void testConfigDoesNotMatchOtherUserOrProfile() {
        AutomationBypass.clearCache();
        Test.startTest();
        Boolean result = AutomationBypass.isBypassed(buildConfig('nobody@example.com', 'No Such Profile'));
        Test.stopTest();
        System.assertEquals(false, result, 'A configuration for other users must not bypass the running user');
    }

    @IsTest
    static void testConfigWithoutBypassValuesDoesNotBypass() {
        AutomationBypass.clearCache();
        Test.startTest();
        Boolean result = AutomationBypass.isBypassed(buildConfig(null, null));
        Test.stopTest();
        System.assertEquals(false, result, 'A configuration without bypass values must not bypass');
    }

    @IsTest
    static void testGetActiveConfigIsCached() {
        AutomationBypass.clearCache();
        Test.startTest();
        List<Trigger_Factory__mdt> first = AutomationBypass.getActiveConfig('Account');
        Integer queriesAfterFirstRead = Limits.getQueries();
        List<Trigger_Factory__mdt> second = AutomationBypass.getActiveConfig('account');
        Test.stopTest();
        System.assertEquals(queriesAfterFirstRead, Limits.getQueries(), 'The configuration must be queried only once');
        System.assertEquals(first, second, 'The same cached configuration must be returned');
        System.assertEquals(
            0,
            AutomationBypass.getActiveConfig(null).size(),
            'A blank object name must return an empty configuration'
        );
    }

    @IsTest
    static void testInvocableWithRecord() {
        AutomationBypass.clearCache();
        AutomationBypass.setBypass('Account', true);
        AutomationBypass.Request request = new AutomationBypass.Request();
        request.record = new Account(Name = 'Test');

        Test.startTest();
        List<AutomationBypass.Result> results = AutomationBypass.checkBypass(
            new List<AutomationBypass.Request>{ request }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One result per request is expected');
        System.assertEquals(true, results[0].isBypassed, 'The object must be derived from the record');
    }

    @IsTest
    static void testInvocableWithObjectApiName() {
        AutomationBypass.clearCache();
        AutomationBypass.setBypass('Contact', true);
        AutomationBypass.Request request = new AutomationBypass.Request();
        request.objectApiName = 'Contact';

        Test.startTest();
        List<AutomationBypass.Result> results = AutomationBypass.checkBypass(
            new List<AutomationBypass.Request>{ request }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].isBypassed, 'The object API name fallback must be honoured');
    }

    @IsTest
    static void testInvocableIsBulkSafe() {
        AutomationBypass.clearCache();
        List<AutomationBypass.Request> requests = new List<AutomationBypass.Request>();
        for (Integer i = 0; i < 200; i++) {
            AutomationBypass.Request request = new AutomationBypass.Request();
            request.record = new Account(Name = 'Test ' + i);
            requests.add(request);
        }

        Test.startTest();
        List<AutomationBypass.Result> results = AutomationBypass.checkBypass(requests);
        Integer queriesUsed = Limits.getQueries();
        Test.stopTest();

        System.assertEquals(200, results.size(), 'Every request must produce a result');
        System.assert(queriesUsed <= 1, 'At most one configuration query must be issued for 200 requests');
    }

    @IsTest
    static void testInvocableResolvesEachDistinctObjectOnce() {
        AutomationBypass.clearCache();
        AutomationBypass.setBypass('Account', true);
        AutomationBypass.setBypass('Contact', false);

        List<AutomationBypass.Request> requests = new List<AutomationBypass.Request>();
        for (Integer i = 0; i < 100; i++) {
            AutomationBypass.Request accountRequest = new AutomationBypass.Request();
            accountRequest.record = new Account(Name = 'Test ' + i);
            requests.add(accountRequest);

            AutomationBypass.Request contactRequest = new AutomationBypass.Request();
            contactRequest.record = new Contact(LastName = 'Test ' + i);
            requests.add(contactRequest);
        }
        AutomationBypass.Request blankRequest = new AutomationBypass.Request();
        requests.add(blankRequest);

        Test.startTest();
        List<AutomationBypass.Result> results = AutomationBypass.checkBypass(requests);
        Integer queriesUsed = Limits.getQueries();
        Test.stopTest();

        System.assertEquals(201, results.size(), 'Every request must produce a result');
        System.assertEquals(0, queriesUsed, 'Cached decisions must not trigger any query');
        System.assertEquals(true, results[0].isBypassed, 'The first Account request must be bypassed');
        System.assertEquals(false, results[1].isBypassed, 'The first Contact request must not be bypassed');
        System.assertEquals(false, results[200].isBypassed, 'A request without record or name must not be bypassed');
    }
}
