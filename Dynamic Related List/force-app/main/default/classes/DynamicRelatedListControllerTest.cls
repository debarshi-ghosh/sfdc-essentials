/**
 * @description Test class for DynamicRelatedListController.
 */
@IsTest
private class DynamicRelatedListControllerTest {

    private static final String TEST_USERNAME = 'drl.test@sfdcdevessentials.test.invalid';

    @TestSetup
    static void setupTestData() {
        Profile sysAdminProfile = [
            SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1
        ];
        User testUser = new User(
            FirstName         = 'DRLTest',
            LastName          = 'User',
            Email             = TEST_USERNAME,
            Username          = TEST_USERNAME,
            Alias             = 'drltu',
            TimeZoneSidKey    = 'America/Chicago',
            LocaleSidKey      = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId         = sysAdminProfile.Id,
            IsActive          = true
        );
        insert testUser;

        System.runAs(testUser) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            List<Contact> contacts = new List<Contact>();
            for (Integer i = 0; i < 5; i++) {
                contacts.add(new Contact(
                    FirstName = 'Test',
                    LastName = 'Contact ' + i,
                    AccountId = acc.Id,
                    Email = 'test' + i + '@example.com'
                ));
            }
            insert contacts;

            Case testCase = new Case(Subject = 'Test Case', AccountId = acc.Id);
            insert testCase;
        }
    }

    private static User getTestUser() {
        return [
            SELECT Id FROM User
            WHERE Username = :TEST_USERNAME
            LIMIT 1
        ];
    }

    private static Account getTestAccount() {
        return [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
    }

    @IsTest
    static void testGetRelatedRecordsSuccess() {
        System.runAs(getTestUser()) {
            Account acc = getTestAccount();

            Test.startTest();
            List<SObject> results = DynamicRelatedListController.getRelatedRecords(
                acc.Id, 'Contact', 'AccountId', 'FirstName,LastName,Email,CreatedDate,Account.CreatedById', 'LastName', 'ASC', 10
            );
            Test.stopTest();

            System.assertEquals(5, results.size(), 'Should return 5 contacts');
        }
    }

    @IsTest
    static void testGetRelatedRecordsWithLimit() {
        System.runAs(getTestUser()) {
            Account acc = getTestAccount();

            Test.startTest();
            List<SObject> results = DynamicRelatedListController.getRelatedRecords(
                acc.Id, 'Contact', 'AccountId', 'FirstName,LastName', null, null, 3
            );
            Test.stopTest();

            System.assertEquals(3, results.size(), 'Should return only 3 contacts due to limit');
        }
    }

    @IsTest
    static void testGetRelatedRecordsDescSort() {
        System.runAs(getTestUser()) {
            Account acc = getTestAccount();

            Test.startTest();
            List<SObject> results = DynamicRelatedListController.getRelatedRecords(
                acc.Id, 'Contact', 'AccountId', 'FirstName,LastName', 'LastName', 'DESC', 10
            );
            Test.stopTest();

            System.assertNotEquals(0, results.size(), 'Should return records');
        }
    }

    @IsTest
    static void testGetRelatedRecordsMissingInputs() {
        System.runAs(getTestUser()) {
            Account acc = getTestAccount();

            Test.startTest();
            try {
                DynamicRelatedListController.getRelatedRecords(
                    acc.Id, '', 'AccountId', 'FirstName', null, null, 10
                );
                System.assert(false, 'Should have thrown AuraHandledException');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Missing required configuration') ||
                    e.getMessage().contains('Script-thrown exception'),
                    'Should throw validation error');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetRelatedRecordsInvalidObject() {
        System.runAs(getTestUser()) {
            Account acc = getTestAccount();

            Test.startTest();
            try {
                DynamicRelatedListController.getRelatedRecords(
                    acc.Id, 'InvalidObject__x', 'AccountId', 'Name', null, null, 10
                );
                System.assert(false, 'Should have thrown AuraHandledException');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Invalid object') ||
                    e.getMessage().contains('Script-thrown exception'),
                    'Should throw invalid object error');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetRelatedRecordsInvalidField() {
        System.runAs(getTestUser()) {
            Account acc = getTestAccount();

            Test.startTest();
            try {
                DynamicRelatedListController.getRelatedRecords(
                    acc.Id, 'Contact', 'AccountId', 'Id FROM Contact WHERE Id != null--', null, null, 10
                );
                System.assert(false, 'Should have thrown AuraHandledException');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Invalid field') ||
                    e.getMessage().contains('Script-thrown exception'),
                    'Injected field path should be rejected');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetRelatedRecordsInvalidSortField() {
        System.runAs(getTestUser()) {
            Account acc = getTestAccount();

            Test.startTest();
            try {
                DynamicRelatedListController.getRelatedRecords(
                    acc.Id, 'Contact', 'AccountId', 'FirstName', 'NotAField__c', 'ASC', 10
                );
                System.assert(false, 'Should have thrown AuraHandledException');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Invalid field') ||
                    e.getMessage().contains('Script-thrown exception'),
                    'Unknown sort field should be rejected');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetRelatedRecordsInvalidRelationshipField() {
        System.runAs(getTestUser()) {
            Account acc = getTestAccount();

            Test.startTest();
            try {
                DynamicRelatedListController.getRelatedRecords(
                    acc.Id, 'Contact', 'NotALookup__c', 'FirstName', null, null, 10
                );
                System.assert(false, 'Should have thrown AuraHandledException');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('Invalid relationship field') ||
                    e.getMessage().contains('Script-thrown exception'),
                    'Unknown relationship field should be rejected');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetColumnMetadataSuccess() {
        System.runAs(getTestUser()) {
            Test.startTest();
            List<DynamicRelatedListController.ColumnInfo> columns =
                DynamicRelatedListController.getColumnMetadata('Contact', 'FirstName,LastName,Email,CreatedDate,DoNotCall,MailingLatitude');
            Test.stopTest();

            System.assertEquals(6, columns.size(), 'Should return 6 column infos');
            System.assertNotEquals(null, columns[0].label, 'Column label should not be null');
            System.assertNotEquals(null, columns[0].fieldName, 'Column fieldName should not be null');
        }
    }

    @IsTest
    static void testGetColumnMetadataInvalidObject() {
        System.runAs(getTestUser()) {
            Test.startTest();
            List<DynamicRelatedListController.ColumnInfo> columns =
                DynamicRelatedListController.getColumnMetadata('InvalidObject__x', 'Name');
            Test.stopTest();

            System.assertEquals(0, columns.size(), 'Should return empty for invalid object');
        }
    }

    @IsTest
    static void testGetColumnMetadataCurrencyField() {
        System.runAs(getTestUser()) {
            Test.startTest();
            List<DynamicRelatedListController.ColumnInfo> columns =
                DynamicRelatedListController.getColumnMetadata('Opportunity', 'Amount');
            Test.stopTest();

            System.assertEquals(1, columns.size(), 'Should return 1 column');
            System.assertEquals('currency', columns[0].type, 'Amount should be currency type');
        }
    }

    @IsTest
    static void testGetCurrencyInfo() {
        System.runAs(getTestUser()) {
            Test.startTest();
            DynamicRelatedListController.CurrencyInfo info =
                DynamicRelatedListController.getCurrencyInfo();
            Test.stopTest();

            System.assertEquals(
                UserInfo.isMultiCurrencyOrganization(),
                info.isMultiCurrency,
                'Multi-currency flag should match the org setting'
            );
            System.assertEquals(
                UserInfo.getDefaultCurrency(),
                info.userCurrency,
                'User currency should match the running user default currency'
            );
            System.assertNotEquals(null, info.conversionRates, 'Conversion rate map should be initialized');
            if (info.isMultiCurrency) {
                System.assert(
                    info.conversionRates.containsKey(info.userCurrency),
                    'Conversion rates should include the user currency'
                );
            }
        }
    }

    @IsTest
    static void testGetColumnMetadataDateField() {
        System.runAs(getTestUser()) {
            Test.startTest();
            List<DynamicRelatedListController.ColumnInfo> columns =
                DynamicRelatedListController.getColumnMetadata('Contact', 'Account.CreatedById,Birthdate');
            Test.stopTest();

            System.assertEquals(2, columns.size(), 'Should return 1 column');
            System.assertEquals('date', columns[1].type, 'Birthdate should be date type');
        }
    }

    @IsTest
    static void testGetColumnMetadataPhoneField() {
        System.runAs(getTestUser()) {
            Test.startTest();
            List<DynamicRelatedListController.ColumnInfo> columns =
                DynamicRelatedListController.getColumnMetadata('Contact', 'Phone');
            Test.stopTest();

            System.assertEquals(1, columns.size(), 'Should return 1 column');
            System.assertEquals('phone', columns[0].type, 'Phone should be phone type');
        }
    }

    @IsTest
    static void testGetColumnMetadataEmailField() {
        System.runAs(getTestUser()) {
            Test.startTest();
            List<DynamicRelatedListController.ColumnInfo> columns =
                DynamicRelatedListController.getColumnMetadata('Contact', 'Email');
            Test.stopTest();

            System.assertEquals(1, columns.size(), 'Should return 1 column');
            System.assertEquals('email', columns[0].type, 'Email should be email type');
        }
    }

    @IsTest
    static void testGetParentRecordInfoAccount() {
        System.runAs(getTestUser()) {
            Account acc = getTestAccount();

            Test.startTest();
            DynamicRelatedListController.ParentRecordInfo info =
                DynamicRelatedListController.getParentRecordInfo(acc.Id);
            Test.stopTest();

            System.assertEquals('Test Account', info.name, 'Should return account name');
            System.assertNotEquals(null, info.objectLabel, 'Object label should not be null');
        }
    }

    @IsTest
    static void testGetParentRecordInfoNull() {
        System.runAs(getTestUser()) {
            Test.startTest();
            DynamicRelatedListController.ParentRecordInfo info =
                DynamicRelatedListController.getParentRecordInfo(null);
            Test.stopTest();

            System.assertEquals(null, info.name, 'Name should be null for null input');
            System.assertEquals(null, info.objectLabel, 'Object label should be null for null input');
        }
    }

    @IsTest
    static void testGetParentRecordInfoCase() {
        System.runAs(getTestUser()) {
            Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];

            Test.startTest();
            DynamicRelatedListController.ParentRecordInfo info =
                DynamicRelatedListController.getParentRecordInfo(testCase.Id);
            Test.stopTest();

            System.assertNotEquals(null, info.name, 'Case number should not be null');
            System.assertNotEquals(null, info.objectLabel, 'Object label should not be null');
        }
    }
}