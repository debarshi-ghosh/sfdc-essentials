@IsTest
private class AccountCreationServiceTest {
    @IsTest
    static void createsOnlyValidAccounts() {
        List<String> names = new List<String>{'Acme', '  Northwind  ', '', null};

        Test.startTest();
        List<Account> created = AccountCreationService.createAccounts(names);
        Test.stopTest();

        System.assertEquals(2, created.size());
        System.assertEquals('Acme', created[0].Name);
        System.assertEquals('Northwind', created[1].Name);
        System.assertNotEquals(null, created[0].Id);
        System.assertEquals(2, [SELECT COUNT() FROM Account WHERE Name IN ('Acme', 'Northwind')]);
    }

    @IsTest
    static void handlesNullInput() {
        List<Account> created = AccountCreationService.createAccounts(null);
        System.assertEquals(0, created.size());
    }
}
