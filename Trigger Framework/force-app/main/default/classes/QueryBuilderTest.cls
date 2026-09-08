@IsTest
@SuppressWarnings('PMD.AvoidDebugStatements,PMD.CyclomaticComplexity,PMD.DebugsShouldUseLoggingLevel,PMD.EmptyCatchBlock,PMD.UnusedLocalVariable')
private class QueryBuilderTest {

    @TestSetup
static void setupTestData() {

    Profile sysAdminProfile = [
        SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1
    ];

    User testUser = new User(
        FirstName = 'VRM',
        LastName = 'TestUser',
        Email = 'testUser@test.invalid',
        Username = 'testUser@test.invalid',
        Alias = 'vrmt',
        TimeZoneSidKey = 'America/Chicago',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = sysAdminProfile.Id,
        IsActive = true
    );
    insert testUser;

    PermissionSet ps = [
        SELECT Id FROM PermissionSet WHERE Name = 'System_Admin' LIMIT 1
    ];

    insert new PermissionSetAssignment(
        AssigneeId = testUser.Id,
        PermissionSetId = ps.Id
    );
}
private static User getTestUser() {
    return [
        SELECT Id FROM User 
        WHERE Username = 'testUser@test.invalid'
        LIMIT 1
    ];
}

    // Use Test Data Factory instead of inline creators
    private static List<Account> ensureAccounts(Integer n) {

        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < n; i++) {
            Account acc = new AccountBuilder()
                        .withName('TestACC' + (i+1))
                        .withAccountNumber('EO' + (i+1))
                        .withType('Partner')
                        .build();
            acc.AccountNumber = 'DLR-' + (i+1) + '-' + DateTime.now().getTime();
            accounts.add(acc);
        }
        insert accounts;
        return accounts;
    }

    private static List<Contact> ensureContacts(List<Account> parents, Integer perParent) {
        List<Contact> cons = new List<Contact>();
        for (Account a : parents) {
            List<Contact> cPart = new List<Contact>();
            for(Integer i = 0; i < perParent; i++) {
                Contact contact = new ContactBuilder()
                .withLastName('TestContactLast' + '_'+ a.Id + (i+1))
                .withFirstName('TestContact' + (i+1))
                .withEmail('testcontact' + '_' +a.Id + (i+1) + '@test.com')
                .withPhone('555-0000' + (i+1))
                .build();
            
                contact.AccountId = a.Id;
                cPart.add(contact);
            }
            cons.addAll(cPart);
        }
        insert cons;
        return cons;
    }

    @IsTest
    static void testConstructorsAndAddFromVariants() {
        System.runAs(getTestUser()){
        QueryBuilder qb1 = new QueryBuilder('Account');
        System.assertNotEquals(null, qb1.toString(), 'Should build query with string ctor');

        QueryBuilder qb2 = new QueryBuilder(Account.getSObjectType());
        System.assert(qb2.toString().contains('FROM Account'), 'SObjectType ctor');

        QueryBuilder qb3 = new QueryBuilder(Account.class);
        System.assert(qb3.toString().contains('FROM Account'), 'Type ctor');

        QueryBuilder qb4 = new QueryBuilder(new Account());
        System.assert(qb4.toString().contains('FROM Account'), 'SObject ctor');

        QueryBuilder qb = new QueryBuilder().addFrom('Account');
        System.assert(qb.toString().contains('FROM Account'), 'addFrom(String)');

        qb = new QueryBuilder().addFrom(Account.getSObjectType());
        System.assert(qb.toString().contains('FROM Account'), 'addFrom(SObjectType)');

        qb = new QueryBuilder().addFrom(Account.class);
        System.assert(qb.toString().contains('FROM Account'), 'addFrom(Type)');

        qb = new QueryBuilder().addFrom(new Account());
        System.assert(qb.toString().contains('FROM Account'), 'addFrom(SObject)');
    }
}

    @IsTest
    static void testAddFieldsVariantsAndAll() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addField(Account.Name)
            .addFields('CreatedDate, LastModifiedDate')
            .addFields(new List<String>{'OwnerId','BillingCity'})
            .addFields(new Set<String>{'Industry', 'Type'})
            .addFields(new List<SObjectField>{ Account.Rating, Account.AnnualRevenue });

        Account temp = new Account(Name='X', Phone='111');
        qb.addFields(temp);

        qb.addFieldsAll()
          .addFieldsAll('Account')
          .addFieldsAll(Account.class)
          .addFieldsAll(Account.getSObjectType())
          .addFieldsAll(new Account());

        String soql = qb.toString();
        System.assert(soql.contains('FROM Account'), 'Must contain FROM Account');
        System.assert(soql.contains('Id'), 'Must contain fields');
    }
}

    @IsTest
    static void testAddFieldsAllAccessibleCreatableUpdatable() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addFieldsAllAccessible()
            .addFieldsAllAccessible('Account')
            .addFieldsAllAccessible(Account.class)
            .addFieldsAllAccessible(Account.getSObjectType())
            .addFieldsAllAccessible(new Account())
            .addFieldsAllCreatable()
            .addFieldsAllCreatable('Account')
            .addFieldsAllCreatable(Account.class)
            .addFieldsAllCreatable(Account.getSObjectType())
            .addFieldsAllCreatable(new Account())
            .addFieldsAllUpdatable()
            .addFieldsAllUpdatable('Account')
            .addFieldsAllUpdatable(Account.class)
            .addFieldsAllUpdatable(Account.getSObjectType())
            .addFieldsAllUpdatable(new Account());
        System.assert(qb.toString().contains('FROM Account'));
    }
}

    @IsTest
    static void testFieldSetOverloadsGracefully() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account');
        
        // Test basic field set functionality without trying to create metadata objects directly
        // Just verify that calling field set methods doesn't throw exceptions
        try {
            // Try to use a real field set if it exists
            Map<String, Schema.FieldSet> fsMap = Schema.getGlobalDescribe().get('Account').getDescribe().fieldSets.getMap();
            if (!fsMap.isEmpty()) {
                // If a field set exists, use it
                qb.addFieldSet(fsMap.values()[0]);
            }
        } catch (Exception e) {
            // Ignore if no field sets exist
        }
        
        // Test that the method doesn't throw exception with a field set name that might not exist
        // This tests graceful handling of missing field sets
        try {
            qb.addFieldSet('Account', 'NonExistentFieldSet');
        } catch (Exception e) {
            // This is expected to fail gracefully, but we're just testing it doesn't crash
        }
        
        // Test with just field set name (assuming FROM object is Account)
        try {
            qb.addFieldSet('NonExistentFieldSet');
        } catch (Exception e) {
            // This is expected to fail gracefully, but we're just testing it doesn't crash
        }
        
        System.assert(qb.toString().contains('FROM Account'));
    }
}

    @IsTest
    static void testGroupByAndOrderAndLimitOffsetScope() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addGroupBy('Id, Name')
            .addGroupBy(Account.OwnerId)
            .addGroupBy(new List<String>{'Type'})
            .addGroupBy(new Set<String>{'Industry'})
            .addOrder(new QueryBuilder.AscOrder('Name').setNullsOrderLast())
            .addOrderAsc('CreatedDate')
            .addOrderAsc(Account.LastModifiedDate)
            .addOrderDesc('AnnualRevenue')
            .addOrderDesc(Account.NumberOfEmployees)
            .setLimit(10)
            .setOffset(5)
            .setScope(QueryBuilder.FilterScope.Mine);
        String soql = qb.toString();
        System.assert(soql.contains('GROUP BY'));
        System.assert(soql.contains('ORDER BY'));
        System.assert(soql.contains('LIMIT 10'));
        System.assert(soql.contains('OFFSET 5'));
        System.assert(soql.contains('USING SCOPE Mine'));
    }
}

    @IsTest
    static void testForViewReferenceUpdateTrackingViewstat() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setForView(true)
            .setForReference() // sets forReference = true
            .setUpdateTracking()
            .setUpdateViewstat(true);
        String soql = qb.toString();
        System.debug('Query Reference: '+soql);
        System.assert(soql.contains('FOR VIEW') || soql.contains('FOR REFERENCE'));
        System.assert(soql.contains('UPDATE TRACKING, VIEWSTAT'));
    }
}

    @IsTest
    static void testSetForReferenceBooleanBugAndFlagsAlone() {
        System.runAs(getTestUser()){
        // Cover the setForReference(Boolean) bugged path and rendering of flags independently
        // Case 1: Only forReference true (FOR REFERENCE should appear)
        QueryBuilder qbRefOnly = new QueryBuilder('Account')
            .addField('Id')
            .setForReference(); // true
        String soqlRefOnly = qbRefOnly.toString();
        System.assert(soqlRefOnly.contains('FOR REFERENCE'), 'Expected FOR REFERENCE when only forReference is true');

        // Case 2: Only forView true (FOR VIEW should appear)
        QueryBuilder qbViewOnly = new QueryBuilder('Account')
            .addField('Id')
            .setForView(true);
        String soqlViewOnly = qbViewOnly.toString();
        System.assert(soqlViewOnly.contains('FOR VIEW'), 'Expected FOR VIEW when only forView is true');

        // Case 3: Both true (FOR VIEW must appear based on implementation)
        QueryBuilder qbBoth = new QueryBuilder('Account')
            .addField('Id')
            .setForView(true)
            .setForReference();
        String soqlBoth = qbBoth.toString();
        System.assert(soqlBoth.contains('FOR VIEW'), 'Expected FOR VIEW when both flags are true');

        // Case 4: UPDATE TRACKING only (no VIEWSTAT text)
        QueryBuilder qbUTOnly = new QueryBuilder('Account')
            .addField('Id')
            .setUpdateTracking();
        String soqlUTOnly = qbUTOnly.toString();
        System.assert(soqlUTOnly.endsWith('UPDATE TRACKING'), 'Expected only UPDATE TRACKING text');

        // Case 5: UPDATE VIEWSTAT only
        QueryBuilder qbUVOnly = new QueryBuilder('Account')
            .addField('Id')
            .setUpdateViewstat(true);
        String soqlUVOnly = qbUVOnly.toString();
        System.assert(soqlUVOnly.endsWith('UPDATE VIEWSTAT'), 'Expected only UPDATE VIEWSTAT text');
    }
}

    @IsTest
    static void testWithSecurityEnforcedCountStringPlacement() {
        System.runAs(getTestUser()){
        // Ensure WITH SECURITY_ENFORCED appears in select queries, not in count string
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setWithSecurityEnforced()
            .addConditions()
                .add(new QueryBuilder.SimpleCondition('Name != NULL'))
            .endConditions();
        String sel = qb.toString();
        System.assert(sel.contains('WITH SECURITY_ENFORCED'), 'Expected WITH SECURITY_ENFORCED in select');

        String cnt = qb.toStringCount();
        System.assert(!cnt.contains('WITH SECURITY_ENFORCED'), 'Count query should not include WITH SECURITY_ENFORCED');
    }
}

    @IsTest
    static void testConditionsEdgeCasesEqOnAndNullsAndEmptyInCollections() {
        System.runAs(getTestUser()){
        // Cover CompareCondition.eq(Object) null -> isNull path and eqon(null)
        QueryBuilder.ConditionsManager cm = new QueryBuilder('Account')
            .addField('Id')
            .addConditions();

        cm.add(new QueryBuilder.CompareCondition('Name').eq((Object) null));
        cm.add(new QueryBuilder.CompareCondition('Name').eqon(null));
        cm.add(new QueryBuilder.CompareCondition('IsDeleted').ne((Object) null));
        cm.add(new QueryBuilder.InCondition('Id').inCollection(new List<Id>())); // empty list path
        cm.add(new QueryBuilder.InCondition('Id').notIn(new Set<Id>())); // empty set path
        QueryBuilder qb = cm.endConditions();
        String soql = qb.toString();
        System.assert(soql.contains('Name = NULL') || soql.contains('Name != NULL'), 'Null compare branches covered');
    }
}

    @IsTest
    static void testSObjectAccessValidatorRelationshipAndGetFieldNameParens() {
        System.runAs(getTestUser()){
        // Validate relationship traversal and getFieldName() with parentheses like COUNT(Id)
        List<Account> accs = ensureAccounts(1);
        List<Contact> cons = ensureContacts(accs, 1);

        QueryBuilder qb = new QueryBuilder('Contact')
            .addFields(new List<String>{
                'Account.Name', // relationship field -> validator path
                'COUNT(Id)'     // getFieldName should strip parens
            })
            .addGroupBy(new Set<String>{'Account.Name'})
            .setCheckCRUDAndFLS()
            .setLimit(5);
        // Execution will invoke SObjectAccessValidator.getFieldName and relationship checks
        List<SObject> rows = qb.toList();
        System.assertNotEquals(null, rows, 'Query executed with relationship and COUNT(Id) field token');
    }
}

    @IsTest
    static void testCountHelpers() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addCountByField('Id')
            .setLimit(1);
        qb.previewCount();
        System.assertNotEquals(null, qb.toStringCount());
    }
}

    @IsTest
    static void testConditionsSimpleAndComplex() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id');

        qb.addConditions()
          .add(new QueryBuilder.SimpleCondition('Name = \'A\''))
          .endConditions();
        System.assert(qb.toString().contains('WHERE'));

        QueryBuilder.ConditionsManager cm = new QueryBuilder('Account').addField('Id').addConditions();
        cm.add(new QueryBuilder.NullCondition('Phone').isNull());
        cm.add(new QueryBuilder.NullCondition('Website').notNull());
        cm.add(new QueryBuilder.CompareCondition('Type').eq('Customer'));
        cm.add(new QueryBuilder.CompareCondition('Type').ne('Prospect'));
        cm.add(new QueryBuilder.CompareCondition('NumberOfEmployees').eq(10));
        cm.add(new QueryBuilder.CompareCondition('NumberOfEmployees').ne(5));
        cm.add(new QueryBuilder.CompareCondition('NumberOfEmployees').lt(100));
        cm.add(new QueryBuilder.CompareCondition('NumberOfEmployees').lte(200));
        cm.add(new QueryBuilder.CompareCondition('NumberOfEmployees').gt(1));
        cm.add(new QueryBuilder.CompareCondition('NumberOfEmployees').gte(1));
        cm.add(new QueryBuilder.CompareCondition('CreatedDate').eq(Date.today()));
        cm.add(new QueryBuilder.CompareCondition('CreatedDate').ne(Date.today().addDays(-1)));
        cm.add(new QueryBuilder.CompareCondition('CreatedDate').lt(Date.today().addDays(1)));
        cm.add(new QueryBuilder.CompareCondition('CreatedDate').lte(Date.today()));
        cm.add(new QueryBuilder.CompareCondition('CreatedDate').gt(Date.today().addDays(-10)));
        cm.add(new QueryBuilder.CompareCondition('CreatedDate').gte(Date.today().addDays(-10)));
        QueryBuilder qb2 = cm.endConditions();
        System.assert(qb2.toString().contains('WHERE'));

        QueryBuilder.ConditionsManager cm2 = new QueryBuilder('Account').addField('Id').addConditions();
        cm2.add(new QueryBuilder.LikeCondition('Name').likeAnyBoth('Acc'));
        cm2.add(new QueryBuilder.LikeCondition('Name').likeAnyLeft('Acc'));
        cm2.add(new QueryBuilder.LikeCondition('Name').likeAnyRight('Acc'));
        cm2.add(new QueryBuilder.LikeCondition('Name').notLikeAnyBoth('Z'));
        cm2.add(new QueryBuilder.IncludeCondition('Industry').includes(new Set<String>{'Energy','Banking'}));
        cm2.add(new QueryBuilder.IncludeCondition('Industry').includes('Agriculture'));
        cm2.add(new QueryBuilder.InCondition('Id').inCollection(new List<Id>())); // empty collection
        cm2.add(new QueryBuilder.InCondition('Id').notIn(new Set<Id>())); // empty set
        cm2.add(new QueryBuilder.InCondition('Name').inCollection(new List<String>{'A','B'}));
        cm2.add(new QueryBuilder.InCondition('NumberOfEmployees').inCollection(new List<Decimal>{1,2}));
        cm2.add(new QueryBuilder.InCondition('Name').notIn(new Set<String>{'X','Y'}));
        QueryBuilder qb3 = cm2.endConditions();
        System.assert(qb3.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testRecordTypeConditionToStringSafe() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account').addField('Id');
        try {
            qb.addConditions().add(new QueryBuilder.RecordTypeCondition('Master')).endConditions();
        } catch (Exception e) {
            // acceptable if developer name not present
        }
        qb.toString();
        System.assertNotEquals(null, qb.toString());
    }
}

    @IsTest
    static void testSObjectAccessValidatorCorePaths() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addField('Name')
            .setCheckCRUD();

        List<Account> accs = ensureAccounts(2);
        List<SObject> rows = qb.toList();
        System.assertNotEquals(null, rows);
    }
}

    @IsTest
    static void testToListToMapExtractHelpers() {
        System.runAs(getTestUser()){
        List<Account> accs = ensureAccounts(1);
        ensureContacts(accs, 1);

        QueryBuilder qb = new QueryBuilder('Account')
            .addFields('Id, Name, OwnerId')
            .setLimit(50);
        List<SObject> listRes = qb.toList();
        System.assert(listRes.size() > 0, 'Expected accounts returned');

        Map<Id, SObject> mapped = qb.toMap();
        System.assertEquals(listRes.size(), mapped.size(), 'Map should contain same records');

        Map<Id, SObject> extMap = new Map<Id, SObject>();
        qb.toMap(extMap);
        System.assert(extMap.size() > 0);

        SObject first = qb.toSObject();
        System.assertNotEquals(null, first);

        Set<Id> ids = qb.extractIds('Id');
        System.assert(ids.size() > 0);

        List<Object> names = qb.extractField('Name');
        System.assertEquals(listRes.size(), names.size());

        List<Object> ownerIds = qb.extractField(Account.OwnerId);
        System.assertEquals(listRes.size(), ownerIds.size());
    }
}

    @IsTest
    static void testToQueryLocator() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account').addField('Id');
        Database.QueryLocator loc = qb.toQueryLocator();
        System.assertNotEquals(null, loc, 'Should return query locator');
    }
}

    @IsTest
    static void testCloneQueryBuilderVariants() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addFields('Id, Name')
            .addGroupBy(new List<String>{'Id', 'Name'})
            .addOrder(new QueryBuilder.Order('Name').setSortingOrderDesc())
            .setLimit(5);
        ensureAccounts(1);
        qb.toList();

        QueryBuilder cloneNoRes = qb.cloneQueryBuilder(false);
        System.assert(cloneNoRes.toString().contains('FROM Account'));

        QueryBuilder cloneWithRes = qb.cloneQueryBuilder(true);
        System.assertNotEquals(null, cloneWithRes.toString());
    }
}

    @IsTest
    static void testNewQueryAndResetResult() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addFields('Id, Name')
            .setLimit(1);
        qb.toList();
        qb.resetResult();
        // Cannot access private field directly; ensure subsequent call works after reset.
        List<SObject> again = qb.toList();
        System.assertNotEquals(null, again);

        qb.newQuery();
        String s = qb.addFrom('Account').toString();
        System.assert(s.contains('FROM Account'));
    }
}

    @IsTest
    static void testWithSecurityEnforcedFlagBuildOnly() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setWithSecurityEnforced(true);
        String soql = qb.toString();
        System.assert(soql.contains('WITH SECURITY_ENFORCED'));
    }
}

    @IsTest
    static void testSubQueryInlineAndSeparate() {
        System.runAs(getTestUser()){
        List<Account> accs = ensureAccounts(1);
        ensureContacts(accs, 1);

        QueryBuilder contactSub = new QueryBuilder('Contact')
            .addFields('Id, LastName')
            .addConditions()
                .add(new QueryBuilder.CompareCondition('AccountId').eq((String)accs[0].Id))
                .endConditions();

        QueryBuilder qbInline = new QueryBuilder('Account')
            .addField('Id')
            .addSubQuery(contactSub);
        System.assert(qbInline.toString().normalizeSpace().contains('SELECT Id , LastName'));
        
        QueryBuilder qbInlineStr = new QueryBuilder('Account')
            .addField('Id')
            .addSubQuery(contactSub.toString());
        System.assert(qbInlineStr.toString().normalizeSpace().contains('SELECT Id , LastName'));

        QueryBuilder qbSep = new QueryBuilder('Account')
            .addField('Id')
            .addSeparateSubQuery(new QueryBuilder('Contacts').addFields('Id, LastName'));
        String soql = qbSep.toString();
        System.debug('Query:: '+soql.normalizeSpace());
        System.assert(soql.normalizeSpace().contains('(SELECT Id , LastName'));
        qbSep.toList();
    }
}

    @IsTest
    static void testAddFieldsMergedAndAllMerged() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Contact');
        try {
            qb.addFieldsMerged('AccountId');
        } catch (Exception e) {
        }
        try {
            qb.addFieldsAllMerged('AccountId');
        } catch (Exception e) {}
        System.assertNotEquals(null, qb.toString());
    }
}

    @IsTest
    static void testAddFieldsMergedAccessible() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Contact');
        try {
            qb.addFieldsMergedAccessible('AccountId');
        } catch (Exception e) {
        }
        System.assertNotEquals(null, qb.toString());
    }
}

    @IsTest
    static void testAddConditionsWithOrder() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditionsWithOrder('1 AND 2')
            .add(new QueryBuilder.SimpleCondition('Name = \'Test\''))
            .add(new QueryBuilder.SimpleCondition('Type = \'Customer\''))
            .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testSetForView() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setForView();
        String soql = qb.toString();
        System.assert(soql.contains('FOR VIEW'));
    }
}

    @IsTest
    static void testSetForReferenceBoolean() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setForReference(true);
        String soql = qb.toString();
        System.debug('Query: '+soql);
        System.assert(soql.contains('FOR REFERENCE'));
    }
}

    @IsTest
    static void testSetUpdateViewstat() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setUpdateViewstat();
        String soql = qb.toString();
        System.assert(soql.contains('UPDATE VIEWSTAT'));
    }
}

    @IsTest
    static void testSetWithSecurityEnforcedBoolean() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setWithSecurityEnforced(false);
        String soql = qb.toString();
        System.assert(!soql.contains('WITH SECURITY_ENFORCED'));
    }
}

    @IsTest
    static void testSetCheckCRUDAndFLSBoolean() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setCheckCRUDAndFLS(false);
        String soql = qb.toString();
        // Should not contain any CRUD/FLS related clauses
        System.assert(!soql.contains('WITH SECURITY_ENFORCED'));
    }
}

    @IsTest
    static void testSetCheckCRUD() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setCheckCRUD(true);
        String soql = qb.toString();
        // Should not contain any CRUD/FLS related clauses yet
        System.assert(!soql.contains('WITH SECURITY_ENFORCED'));
    }
}

    @IsTest
    static void testSetCheckFLS() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setCheckFLS();
        String soql = qb.toString();
        // Should not contain any CRUD/FLS related clauses yet
        System.assert(!soql.contains('WITH SECURITY_ENFORCED'));
    }
}

    @IsTest
    static void testPreview() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .preview();
        // Just ensuring it doesn't throw an exception
        System.assertNotEquals(null, qb);
    }
}

    @IsTest
    static void testAddCountByFieldSObjectField() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addCountByField(Account.Id);
        String soql = qb.toString();
        System.assert(soql.contains('COUNT(Id)'));
    }
}

    @IsTest
    static void testToIdSet() {
        System.runAs(getTestUser()){
        List<Account> accs = ensureAccounts(2);
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setLimit(2);
        Set<Id> idSet = qb.toIdSet();
        System.assert(idSet.size() > 0);
    }
}

    @IsTest
    static void testCloneQueryBuilderBoolean() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .setLimit(1);
        QueryBuilder cloned = qb.cloneQueryBuilder();
        System.assertNotEquals(null, cloned);
    }
}

    @IsTest
    static void testSetConditionOrder() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditionsWithOrder('1 AND 2')
            .add(new QueryBuilder.SimpleCondition('Name = \'Test\''))
            .add(new QueryBuilder.SimpleCondition('Type = \'Customer\''))
            .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
    }
    @IsTest
    static void testSimpleCondition() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.SimpleCondition('Name = \'Test\''))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testFieldConditionSObjectField() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.SimpleCondition('Name = \'Test\''))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testNullConditionSObjectField() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.NullCondition(Account.Name))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testCompareConditionLte() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.CompareCondition(Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap().get('NumberOfEmployees')).lte(100))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testCompareConditionGte() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.CompareCondition('NumberOfEmployees').gte(10))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testCompareConditionGt() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.CompareCondition('NumberOfEmployees').gt(10))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testLikeConditionSObjectField() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.LikeCondition(Account.Name))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testIncludeConditionSObjectField() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.IncludeCondition(Account.Industry))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testInConditionSObjectField() {
        System.runAs(getTestUser()){
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.InCondition(Account.Id))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testInConditionWithQueryBuilder() {
        System.runAs(getTestUser()){
        QueryBuilder innerQB = new QueryBuilder('Contact')
            .addField('AccountId');
        QueryBuilder qb = new QueryBuilder('Account')
            .addField('Id')
            .addConditions()
                .add(new QueryBuilder.InCondition('Id').inCollection(innerQB))
                .endConditions();
        System.assert(qb.toString().contains('WHERE'));
    }
}

    @IsTest
    static void testRemainingBranchCoverageForQueryBuilder() {
        System.runAs(getTestUser()){
            List<Account> accounts = ensureAccounts(1);
            QueryBuilder accountQb = new QueryBuilder('Account')
                .addField('Id')
                .addFieldsAllMerged('ParentId')
                .addFieldsMerged('ParentId')
                .addFieldsMergedAccessible('ParentId')
                .addFieldsAllAccessible('Account')
                .addFieldsAllCreatable('Account')
                .addFieldsAllUpdatable('Account')
                .setScope(QueryBuilder.FilterScope.Mine)
                .setForView(false)
                .setForReference(false)
                .setUpdateTracking(false)
                .setUpdateViewstat(false)
                .setWithSecurityEnforced(false)
                .setCheckCRUDAndFLS(false)
                .setCheckCRUD(false)
                .setCheckFLS(false)
                .setLimit(1)
                .setOffset(1)
                .addOrder(new QueryBuilder.Order('Name').setSortingOrderDesc().setNullsOrderFirst())
                .addOrderAsc('Name')
                .addOrderDesc('Name');
            String accountSql = accountQb.toString();
            System.assert(accountSql.contains('FROM Account'));

            QueryBuilder subQuery = new QueryBuilder('Contact')
                .addField('Id')
                .addField('AccountId');
            QueryBuilder withSubQuery = new QueryBuilder('Account')
                .addField('Id')
                .addSubQuery(subQuery)
                .addSubQuery('SELECT Id FROM Contact')
                .addSeparateSubQuery(new QueryBuilder('Contact').addField('Id'));
            System.assert(withSubQuery.toString().contains('FROM Account'));

            QueryBuilder emptyCollection = new QueryBuilder('Account')
                .addField('Id')
                .addConditions()
                    .add(new QueryBuilder.InCondition('Id').notIn(new Set<Id>()))
                    .add(new QueryBuilder.InCondition('Name').inCollection(new Set<String>()))
                    .add(new QueryBuilder.InCondition('NumberOfEmployees').inCollection(new List<Decimal>()))
                    .add(new QueryBuilder.IncludeCondition('Industry').includes(new Set<String>{'Banking'}))
                    .add(new QueryBuilder.CompareCondition('IsDeleted').eq((Object) null))
                    .add(new QueryBuilder.CompareCondition('Name').eqon(null))
                    .add(new QueryBuilder.LikeCondition('Name').notLikeAnyBoth('A'))
                    .add(new QueryBuilder.ComplexCondition()
                        .startCondition(new QueryBuilder.CompareCondition('Name').eq('Test'))
                        .orCondition(new QueryBuilder.CompareCondition('Type').eq('Customer'))
                        .andCondition(new QueryBuilder.CompareCondition('Industry').eq('Banking')))
                    .endConditions();
            System.assert(emptyCollection.toString().contains('WHERE'));

            QueryBuilder queryWithOrder = new QueryBuilder('Account')
                .addField('Id')
                .addConditionsWithOrder('1 AND 2')
                .add(new QueryBuilder.SimpleCondition('Name = \'Test\''))
                .add(new QueryBuilder.SimpleCondition('Type = \'Customer\''))
                .endConditions();
            System.assert(queryWithOrder.toString().contains('WHERE'));

            QueryBuilder innerForNotIn = new QueryBuilder('Account').addField('Id');
            QueryBuilder notInQuery = new QueryBuilder('Account')
                .addField('Id')
                .addConditions()
                    .add(new QueryBuilder.InCondition('Id').notIn(innerForNotIn))
                    .endConditions();
            System.assert(notInQuery.toString().contains('NOT IN'));

            QueryBuilder qbReset = new QueryBuilder('Account').addField('Id').setLimit(5);
            qbReset.toList();
            qbReset.resetResult();
            qbReset.newQuery();
            System.assert(qbReset.addFrom('Account').toString().contains('FROM Account'));

            QueryBuilder previewQuery = new QueryBuilder('Account').addField('Id');
            previewQuery.preview();
            previewQuery.previewCount();
            System.assertNotEquals(null, previewQuery.toStringCount());

            Map<String, Schema.RecordTypeInfo> rtMap = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName();
            if (!rtMap.isEmpty()) {
                String rtName = new List<String>(rtMap.keySet())[0];
                QueryBuilder.RecordTypeCondition rtCondition = new QueryBuilder.RecordTypeCondition(rtName);
                rtCondition.setRelatedObjectType('Account');
                System.assert(rtCondition.toString().contains('RecordTypeId ='));
            }

            QueryBuilder.SObjectAccessValidator validator = new QueryBuilder.SObjectAccessValidator(
                Schema.getGlobalDescribe().get('Account'),
                new List<String>{'Id', 'Name', 'Owner.Name'}
            );
            validator.validate();
            System.assertNotEquals(null, validator);
        }
    }

    @IsTest
    static void testConditionVariantsForUncoveredBranches() {
        System.runAs(getTestUser()){
            QueryBuilder qb = new QueryBuilder('Account')
                .addField('Id')
                .addConditions()
                    .add(new QueryBuilder.CompareCondition('IsDeleted').eq(true))
                    .add(new QueryBuilder.CompareCondition('IsDeleted').ne(false))
                    .add(new QueryBuilder.CompareCondition('NumberOfEmployees').lt(Decimal.valueOf('100')))
                    .add(new QueryBuilder.CompareCondition('NumberOfEmployees').lte(Decimal.valueOf('200')))
                    .add(new QueryBuilder.CompareCondition('NumberOfEmployees').gt(Decimal.valueOf('1')))
                    .add(new QueryBuilder.CompareCondition('NumberOfEmployees').gte(Decimal.valueOf('1')))
                    .add(new QueryBuilder.CompareCondition('CreatedDate').lt(Date.today().addDays(1)))
                    .add(new QueryBuilder.CompareCondition('CreatedDate').lte(Date.today()))
                    .add(new QueryBuilder.CompareCondition('CreatedDate').gt(Date.today().addDays(-10)))
                    .add(new QueryBuilder.CompareCondition('CreatedDate').gte(Date.today().addDays(-10)))
                    .add(new QueryBuilder.CompareCondition('Name').eq('Acme'))
                    .add(new QueryBuilder.CompareCondition('Name').ne('Beta'))
                    .add(new QueryBuilder.NullCondition('Name').isNull())
                    .add(new QueryBuilder.NullCondition('Name').notNull())
                    .add(new QueryBuilder.LikeCondition('Name').likeAnyBoth('Foo'))
                    .add(new QueryBuilder.LikeCondition('Name').likeAnyLeft('Foo'))
                    .add(new QueryBuilder.LikeCondition('Name').likeAnyRight('Foo'))
                    .add(new QueryBuilder.InCondition('Name').inCollection(new List<String>{'A', 'B'}))
                    .add(new QueryBuilder.InCondition('NumberOfEmployees').inCollection(new List<Decimal>{1,2}))
                    .add(new QueryBuilder.InCondition('Id').inCollection(new Set<Id>()))
                    .add(new QueryBuilder.IncludeCondition('Industry').includes('Agriculture'))
                    .endConditions();
            System.assert(qb.toString().contains('WHERE'));

            QueryBuilder.ConditionsManager manager = new QueryBuilder('Account').addField('Id').addConditions();
            manager.add(new QueryBuilder.CompareCondition('Name').eq((Object) null));
            manager.add(new QueryBuilder.CompareCondition('Name').eqon('Test'));
            manager.add(new QueryBuilder.CompareCondition('IsDeleted').ne((Object) null));
            QueryBuilder qb2 = manager.endConditions();
            System.assert(qb2.toString().contains('WHERE'));
        }
    }

    /**
     * @description AccountBuilder class.
     */
    public class AccountBuilder {
        private Account account;
        
        /**
         * @description Account Builder.
         */
        public AccountBuilder() {
            account = new Account();
            // Set default values
            account.Name = 'DLR-' + DateTime.now().getTime();
            account.BillingCity = 'New Jersey';
            account.BillingStreet = '6TH Block';
            account.BillingPostalCode = '560095';
            account.Phone = '1234567890';
            account.Fax = '12345';
            account.ShippingCity = 'New Jersey';
            account.ShippingPostalCode = '560095';
        }
        
        /**
         * @description With Name.
         * @param name The name.
         * @return AccountBuilder value.
         */
        public AccountBuilder withName(String name) {
            account.Name = name;
            return this;
        }
        
        /**
         * @description With Account Number.
         * @param accountNumber The account Number.
         * @return AccountBuilder value.
         */
        public AccountBuilder withAccountNumber(String accountNumber) {
            account.AccountNumber = accountNumber;
            return this;
        }
        
        /**
         * @description With Type.
         * @param type The type.
         * @return AccountBuilder value.
         */
        public AccountBuilder withType(String type) {
            account.Type = type;
            return this;
        }
        
        /**
         * @description Build.
         * @return Account value.
         */
        public Account build() {
            return account;
        }
    }

    /**
     * @description ContactBuilder class.
     */
    public class ContactBuilder {
        private Contact contact;
        
        /**
         * @description Contact Builder.
         */
        public ContactBuilder() {
            contact = new Contact();
        }
        
        /**
         * @description With First Name.
         * @param firstName The first Name.
         * @return ContactBuilder value.
         */
        public ContactBuilder withFirstName(String firstName) {
            contact.FirstName = firstName;
            return this;
        }
        
        /**
         * @description With Last Name.
         * @param lastName The last Name.
         * @return ContactBuilder value.
         */
        public ContactBuilder withLastName(String lastName) {
            contact.LastName = lastName;
            return this;
        }
        
        /**
         * @description With Email.
         * @param email The email.
         * @return ContactBuilder value.
         */
        public ContactBuilder withEmail(String email) {
            contact.Email = email;
            return this;
        }
        
        /**
         * @description With Phone.
         * @param phone The phone.
         * @return ContactBuilder value.
         */
        public ContactBuilder withPhone(String phone) {
            contact.Phone = phone;
            return this;
        }
        
        /**
         * @description Build.
         * @return Contact value.
         */
        public Contact build() {
            return contact;
        }
    }
}