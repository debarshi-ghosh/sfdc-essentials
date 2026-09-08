/**
 * @description Centralised, transaction scoped automation bypass evaluator shared by Apex
 * triggers and record triggered Flows.
 *
 * Whichever automation runs first within the transaction evaluates the Trigger_Factory__mdt
 * configuration once and caches the outcome in a static map. Every later caller in the same
 * transaction reuses that cached value, so a user or profile that is bypassed for an object is
 * bypassed consistently across triggers and flows. In practice the before insert or before update
 * trigger populates the cache first and the after save flows reuse it, but the order does not
 * matter because the first caller wins either way.
 *
 * The bypass is keyed on the SObject API name only, so no flow name or object name is ever
 * hardcoded - Flows pass their $Record and the object is derived at runtime.
 *
 * Flow wiring: add the "Is Automation Bypassed" Apex action as the first element of the record
 * triggered flow, pass $Record, then add a Decision that ends the flow when isBypassed is true.
 *
 * Limitation: before save (Fast Field Updates) record triggered flows do not support Action or
 * Subflow elements, so they cannot call this class. Convert such a flow to after save, or move
 * its logic into a trigger handler, where the bypass applies automatically.
 */
@SuppressWarnings('PMD.AvoidDebugStatements,PMD.DebugsShouldUseLoggingLevel,PMD.FieldNamingConventions,PMD.CognitiveComplexity')
public with sharing class AutomationBypass {
    private static final String AUTOMATED_PROCESS_USER_TYPE = 'AutomatedProcess';
    private static final String VALUE_SEPARATOR = ',';

    /**
     * Transaction scoped decision cache, keyed by upper cased SObject API name.
     * This is the shared state between triggers and flows - first writer wins.
     */
    @TestVisible
    private static final Map<String, Boolean> BYPASS_CACHE = new Map<String, Boolean>();

    /**
     * Transaction scoped configuration cache, keyed by upper cased SObject API name, so the
     * Trigger_Factory__mdt records are queried at most once per object per transaction.
     */
    private static final Map<String, List<Trigger_Factory__mdt>> CONFIG_CACHE = new Map<String, List<Trigger_Factory__mdt>>();

    private static String currentProfileName;
    private static Boolean profileResolved = false;

    /**
     * @description Determines whether all automation (triggers and record triggered flows) is
     * bypassed for the given SObject for the running user.
     * @param objectApiName The SObject API name, for example 'Account'.
     * @return Boolean true when the automation must be skipped.
     */
    public static Boolean isBypassed(String objectApiName) {
        if (TriggerHandlerExecution.BYPASS) {
            return true;
        }
        if (String.isBlank(objectApiName) || isAutomatedProcess()) {
            return false;
        }
        String cacheKey = objectApiName.trim().toUpperCase();
        if (!BYPASS_CACHE.containsKey(cacheKey)) {
            BYPASS_CACHE.put(cacheKey, evaluateObject(objectApiName));
        }
        return BYPASS_CACHE.get(cacheKey);
    }

    /**
     * @description Determines whether all automation is bypassed for the given SObject type.
     * Uses String.valueOf rather than a describe call so it stays cheap when called per record.
     * @param sobjectType The SObject type.
     * @return Boolean true when the automation must be skipped.
     */
    public static Boolean isBypassed(SObjectType sobjectType) {
        return sobjectType == null ? false : isBypassed(String.valueOf(sobjectType));
    }

    /**
     * @description Determines whether all automation is bypassed for the SObject the supplied
     * record belongs to.
     * @param record Any record of the SObject being evaluated.
     * @return Boolean true when the automation must be skipped.
     */
    public static Boolean isBypassed(SObject record) {
        return record == null ? false : isBypassed(record.getSObjectType());
    }

    /**
     * @description Evaluates a single Trigger_Factory__mdt configuration row against the running
     * user. A row is bypassed when the running user name or the running user profile name is
     * listed in the bypass fields. Both fields accept a comma separated list of values.
     * @param config The configuration row.
     * @return Boolean true when the handler configured by this row must be skipped.
     */
    public static Boolean isBypassed(Trigger_Factory__mdt config) {
        if (TriggerHandlerExecution.BYPASS) {
            return true;
        }
        if (config == null || isAutomatedProcess()) {
            return false;
        }
        return matches(config.Bypassed_User__c, UserInfo.getUserName()) ||
            matches(config.Bypassed_Profile__c, getCurrentProfileName());
    }

    /**
     * @description Programmatically forces or clears the bypass decision for an SObject for the
     * remainder of the transaction. Useful for data loads, migrations and test setup.
     * @param objectApiName The SObject API name.
     * @param bypassed The decision to cache.
     */
    public static void setBypass(String objectApiName, Boolean bypassed) {
        if (String.isBlank(objectApiName) || bypassed == null) {
            return;
        }
        BYPASS_CACHE.put(objectApiName.trim().toUpperCase(), bypassed);
    }

    /**
     * @description Clears every cached decision and configuration for the current transaction.
     */
    public static void clearCache() {
        BYPASS_CACHE.clear();
        CONFIG_CACHE.clear();
        currentProfileName = null;
        profileResolved = false;
    }

    /**
     * @description Seeds the configuration cache so unit tests can exercise the framework without
     * relying on Trigger_Factory__mdt records existing in the org.
     * @param objectApiName The SObject API name.
     * @param configs The configuration rows to serve for that object.
     */
    @TestVisible
    private static void setActiveConfig(String objectApiName, List<Trigger_Factory__mdt> configs) {
        CONFIG_CACHE.put(objectApiName.trim().toUpperCase(), configs);
    }

    /**
     * @description Returns the active Trigger_Factory__mdt configuration for an SObject ordered by
     * execution order. Cached per transaction and shared with TriggerHandlerExecution.
     * @param objectApiName The SObject API name.
     * @return List<Trigger_Factory__mdt> the active configuration rows.
     */
    public static List<Trigger_Factory__mdt> getActiveConfig(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return new List<Trigger_Factory__mdt>();
        }
        String cacheKey = objectApiName.trim().toUpperCase();
        if (!CONFIG_CACHE.containsKey(cacheKey)) {
            CONFIG_CACHE.put(cacheKey, readConfig(objectApiName));
        }
        return CONFIG_CACHE.get(cacheKey);
    }

    /**
     * @description Flow entry point. Add this action as the first element of an after save record
     * triggered flow, pass $Record, and end the flow when isBypassed is true. Not available to
     * before save flows, which do not support Apex actions.
     *
     * Bulk safe: the distinct object names are resolved and evaluated once up front, so the
     * per request loop only performs map lookups no matter how many records the flow passes in.
     * @param requests The incoming flow requests.
     * @return List<Result> one result per request, in the same order.
     */
    @InvocableMethod(
        label='Is Automation Bypassed'
        description='Returns true when triggers and flows are bypassed for the object of the record for the running user.'
        category='Automation Framework'
    )
    public static List<Result> checkBypass(List<Request> requests) {
        List<String> resolvedNames = new List<String>();
        Set<String> distinctNames = new Set<String>();
        for (Request request : requests) {
            String objectApiName = request.record == null
                ? request.objectApiName
                : String.valueOf(request.record.getSObjectType());
            resolvedNames.add(objectApiName);
            if (String.isNotBlank(objectApiName)) {
                distinctNames.add(objectApiName);
            }
        }

        Map<String, Boolean> decisions = new Map<String, Boolean>();
        for (String objectApiName : distinctNames) {
            decisions.put(objectApiName, isBypassed(objectApiName));
        }

        List<Result> results = new List<Result>();
        for (String objectApiName : resolvedNames) {
            Result result = new Result();
            result.isBypassed = decisions.containsKey(objectApiName) ? decisions.get(objectApiName) : false;
            results.add(result);
        }
        return results;
    }

    private static Boolean evaluateObject(String objectApiName) {
        List<Trigger_Factory__mdt> configs = getActiveConfig(objectApiName);
        if (configs.isEmpty()) {
            return false;
        }
        for (Trigger_Factory__mdt config : configs) {
            if (!isBypassed(config)) {
                return false;
            }
        }
        System.debug(LoggingLevel.INFO, 'Automation bypassed for object : ' + objectApiName);
        return true;
    }

    private static List<Trigger_Factory__mdt> readConfig(String objectApiName) {
        QueryBuilder queryBuilder = new QueryBuilder(Trigger_Factory__mdt.class)
            .addField('DeveloperName')
            .addField('NamespacePrefix')
            .addField('Class_Name__c')
            .addField('Object_API_Name__c')
            .addField('Bypassed_Profile__c')
            .addField('Bypassed_User__c')
            .addField('Execution_Order__c');
        QueryBuilder.ComplexCondition condition = new QueryBuilder.ComplexCondition();
        condition.andCondition(new QueryBuilder.CompareCondition('Object_API_Name__c').eq(objectApiName));
        condition.andCondition(new QueryBuilder.CompareCondition('Is_Active__c').eq(true));
        return queryBuilder
            .addOrderAsc('Execution_Order__c')
            .addConditions()
            .add(condition)
            .endConditions()
            .toList();
    }

    private static Boolean matches(String configuredValues, String currentValue) {
        if (String.isBlank(configuredValues) || String.isBlank(currentValue)) {
            return false;
        }
        for (String configuredValue : configuredValues.split(VALUE_SEPARATOR)) {
            if (currentValue.equalsIgnoreCase(configuredValue.trim())) {
                return true;
            }
        }
        return false;
    }

    private static Boolean isAutomatedProcess() {
        return AUTOMATED_PROCESS_USER_TYPE.equals(UserInfo.getUserType());
    }

    private static String getCurrentProfileName() {
        if (!profileResolved) {
            profileResolved = true;
            Profile currentProfile = (Profile) new QueryBuilder(Profile.class)
                .addField('Id')
                .addField('Name')
                .addConditions()
                .add(new QueryBuilder.CompareCondition('Id').eq(UserInfo.getProfileId()))
                .endConditions()
                .toSObject();
            currentProfileName = currentProfile == null ? null : currentProfile.Name;
        }
        return currentProfileName;
    }

    /**
     * @description Flow input wrapper. Provide either the record or the object API name.
     */
    public class Request {
        @InvocableVariable(label='Record' description='Typically $Record. The object API name is derived from it.')
        public SObject record;

        @InvocableVariable(label='Object API Name' description='Used only when Record is not supplied.')
        public String objectApiName;
    }

    /**
     * @description Flow output wrapper.
     */
    public class Result {
        @InvocableVariable(label='Is Bypassed' description='True when automation must be skipped for the running user.')
        public Boolean isBypassed;
    }
}
