/**
 * @description Controller for the Dynamic Related List component.
 *              Provides dynamic querying of related records based on configurable parameters.
 */
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.AvoidDeeplyNestedIfStmts,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList')
public with sharing class DynamicRelatedListController {

    /**
     * @description Global describe is expensive, so it is resolved once per transaction
     *              and reused by every lookup in this class.
     */
    private static Map<String, Schema.SObjectType> globalDescribeCache;

    /**
     * @description Resolves an SObjectType from the cached global describe.
     * @param objectApiName The object API name to look up.
     * @return The matching SObjectType, or null if the name is blank or unknown.
     */
    private static Schema.SObjectType getObjectType(String objectApiName) {
        if (globalDescribeCache == null) {
            globalDescribeCache = Schema.getGlobalDescribe();
        }
        return String.isBlank(objectApiName) ? null : globalDescribeCache.get(objectApiName);
    }

    /**
     * @description Fetches related records dynamically based on the provided configuration.
     * @param parentRecordId The Id of the parent record.
     * @param childObjectApiName The API name of the child object.
     * @param relationshipFieldApiName The lookup/master-detail field on the child pointing to parent.
     * @param fieldApiNames Comma-separated list of field API names to query.
     * @param sortField The field to sort by.
     * @param sortDirection ASC or DESC.
     * @param recordLimit Maximum records to return.
     * @return List of SObject records.
     */
    @AuraEnabled(cacheable=true)
    public static List<SObject> getRelatedRecords(
        Id parentRecordId,
        String childObjectApiName,
        String relationshipFieldApiName,
        String fieldApiNames,
        String sortField,
        String sortDirection,
        Integer recordLimit
    ) {
        validateInputs(childObjectApiName, relationshipFieldApiName, fieldApiNames);

        Schema.SObjectType objType = getObjectType(childObjectApiName);

        List<String> fields = parseFields(fieldApiNames);
        // Identifiers cannot be bound as SOQL parameters, so describing every field path
        // is the only reliable defence against injection via the component configuration
        // (which, on the full view page, arrives from a URL parameter).
        validateFieldPaths(objType, fields);
        if (String.isNotBlank(sortField)) {
            validateFieldPaths(objType, new List<String>{ sortField });
        }

        if (!fields.contains('Id')) {
            fields.add(0, 'Id');
        }
        if (!fields.contains('Name') && hasField(childObjectApiName, 'Name')) {
            fields.add('Name');
        }

        // Auto-include relationship Name for lookup fields
        if (objType != null) {
            Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
            List<String> lookupNameFields = new List<String>();
            for (String f : fields) {
                if (f.contains('.')) {
                    // Traversal reference field (e.g., Relation__r.Lookup__c): auto-include
                    // the related record's Name so the LWC can display it as link text.
                    // Resolves to: parentPath.RelationshipName.Name
                    ColumnInfo traversalInfo = resolveTraversalField(objType, f);
                    if (traversalInfo != null && traversalInfo.relationshipName != null) {
                        Integer lastDotIdx = f.lastIndexOf('.');
                        String namePath = f.substring(0, lastDotIdx) + '.' + traversalInfo.relationshipName + '.Name';
                        if (!fields.contains(namePath) && !lookupNameFields.contains(namePath)) {
                            lookupNameFields.add(namePath);
                        }
                    }
                } else if (fieldMap.containsKey(f)) {
                    Schema.DescribeFieldResult dfr = fieldMap.get(f).getDescribe();
                    if (dfr.getType() == Schema.DisplayType.REFERENCE && dfr.getRelationshipName() != null) {
                        String relNameField = dfr.getRelationshipName() + '.Name';
                        if (!fields.contains(relNameField)) {
                            lookupNameFields.add(relNameField);
                        }
                    }
                }
            }
            fields.addAll(lookupNameFields);
        }

        // In multi-currency orgs, every currency amount is stored in the owning record's
        // currency. Auto-include the matching CurrencyIsoCode so the LWC can render the
        // value in the record currency and convert it to the running user's currency.
        fields.addAll(collectCurrencyIsoFields(objType, fields));

        // Wrap picklist/multi-picklist fields with toLabel() so the query returns the
        // display label (e.g. 'In Progress') instead of the internal API value ('In_Progress').
        // Works for both direct fields and relationship traversal paths.
        // CurrencyIsoCode is a picklist too, but must stay as the ISO code, not its label.
        List<String> queryFields = new List<String>();
        for (String f : fields) {
            Boolean isIsoCode = f.endsWithIgnoreCase('CurrencyIsoCode');
            queryFields.add((!isIsoCode && isPicklistField(objType, f)) ? 'toLabel(' + f + ')' : f);
        }

        String query = buildQuery(queryFields, childObjectApiName, relationshipFieldApiName, sortField, sortDirection, recordLimit);
        return Database.query(query, AccessLevel.USER_MODE);
    }

    /**
     * @description Retrieves column metadata (label, type) for the given fields.
     * @param childObjectApiName The API name of the child object.
     * @param fieldApiNames Comma-separated list of field API names.
     * @return List of ColumnInfo wrappers with field metadata.
     */
    @AuraEnabled(cacheable=true)
    public static List<ColumnInfo> getColumnMetadata(String childObjectApiName, String fieldApiNames) {
        List<ColumnInfo> columns = new List<ColumnInfo>();
        List<String> fields = parseFields(fieldApiNames);

        Schema.SObjectType objType = getObjectType(childObjectApiName);
        if (objType == null) {
            return columns;
        }
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

        for (String fieldName : fields) {
            if (fieldName.contains('.')) {
                // Relationship traversal field (e.g., Account__r.Name or A__r.B__r.Name).
                // Walk the relationship chain to resolve the final field's label and type.
                ColumnInfo col = resolveTraversalField(objType, fieldName);
                if (col != null) {
                    columns.add(col);
                }
            } else {
                if (fieldMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
                    ColumnInfo col = new ColumnInfo();
                    col.fieldName = fieldName;
                    col.label = dfr.getLabel();
                    col.type = mapFieldType(dfr.getType());
                    if (dfr.getType() == Schema.DisplayType.REFERENCE) {
                        col.relationshipName = dfr.getRelationshipName();
                    }
                    columns.add(col);
                }
            }
        }
        return columns;
    }

    /**
     * @description Resolves a dot-notation traversal path (e.g., Account__r.Name or
     *              A__r.B__r.FieldName) by walking the relationship chain and describing
     *              the final field on the target object.
     * @param startObjType The SObjectType to start traversal from.
     * @param fieldPath    Dot-separated path of relationship names followed by a field name.
     * @return ColumnInfo with label and type taken from the final field, or null if unresolvable.
     */
    private static ColumnInfo resolveTraversalField(Schema.SObjectType startObjType, String fieldPath) {
        List<String> parts = fieldPath.split('\\.');
        Schema.SObjectType currentObjType = startObjType;

        // Walk every relationship segment except the last (which is the field name)
        for (Integer i = 0; i < parts.size() - 1; i++) {
            Schema.SObjectField relField = findFieldByRelationshipName(
                currentObjType.getDescribe().fields.getMap(), parts[i]
            );
            if (relField == null) {
                return null;
            }
            List<Schema.SObjectType> refTo = relField.getDescribe().getReferenceTo();
            if (refTo.isEmpty()) {
                return null;
            }
            currentObjType = refTo[0];
        }

        String finalFieldName = parts[parts.size() - 1];
        Map<String, Schema.SObjectField> finalFieldMap = currentObjType.getDescribe().fields.getMap();
        if (!finalFieldMap.containsKey(finalFieldName)) {
            return null;
        }

        Schema.DescribeFieldResult dfr = finalFieldMap.get(finalFieldName).getDescribe();
        ColumnInfo col = new ColumnInfo();
        col.fieldName = fieldPath;
        col.label = dfr.getLabel();
        col.type = mapFieldType(dfr.getType());
        // For traversal reference fields, expose the relationship name so the LWC can
        // resolve and display the related record's Name instead of the raw Salesforce ID.
        if (dfr.getType() == Schema.DisplayType.REFERENCE) {
            col.relationshipName = dfr.getRelationshipName();
        }
        return col;
    }

    /**
     * @description Finds the SObjectField on an object whose relationship name matches relName.
     *              Field maps are keyed by field API name (e.g., Account__c), not relationship
     *              name (Account__r), so we must iterate to find the correct field.
     * @param fieldMap Map of field API name to SObjectField for the target object.
     * @param relName  The relationship name to search for (e.g., Account__r).
     * @return The matching SObjectField, or null if not found.
     */
    private static Schema.SObjectField findFieldByRelationshipName(
        Map<String, Schema.SObjectField> fieldMap, String relName
    ) {
        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if (dfr.getType() == Schema.DisplayType.REFERENCE
                && relName.equalsIgnoreCase(dfr.getRelationshipName())
            ) {
                return field;
            }
        }
        return null;
    }

    /**
     * @description Returns true when a field (direct or traversal) is a PICKLIST or
     *              MULTIPICKLIST type, so the caller can wrap it with toLabel() in SOQL.
     * @param startObjType The SObjectType to start from.
     * @param fieldPath    Field API name or dot-notation traversal path.
     * @return True if the final resolved field is a picklist type.
     */
    private static Boolean isPicklistField(Schema.SObjectType startObjType, String fieldPath) {
        Schema.DisplayType fieldType = getFieldType(startObjType, fieldPath);
        return fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST;
    }

    /**
     * @description Resolves the DisplayType of a direct field or dot-notation traversal path.
     * @param startObjType The SObjectType to start from.
     * @param fieldPath    Field API name or dot-notation traversal path.
     * @return The DisplayType of the final field, or null if unresolvable.
     */
    private static Schema.DisplayType getFieldType(Schema.SObjectType startObjType, String fieldPath) {
        if (startObjType == null) {
            return null;
        }
        Schema.SObjectType currentObjType = startObjType;
        String finalFieldName = fieldPath;
        if (fieldPath.contains('.')) {
            // Walk the relationship chain to reach the final field's object
            List<String> parts = fieldPath.split('\\.');
            for (Integer i = 0; i < parts.size() - 1; i++) {
                Schema.SObjectField relField = findFieldByRelationshipName(
                    currentObjType.getDescribe().fields.getMap(), parts[i]
                );
                if (relField == null) {
                    return null;
                }
                List<Schema.SObjectType> refTo = relField.getDescribe().getReferenceTo();
                if (refTo.isEmpty()) {
                    return null;
                }
                currentObjType = refTo[0];
            }
            finalFieldName = parts[parts.size() - 1];
        }
        Map<String, Schema.SObjectField> fieldMap = currentObjType.getDescribe().fields.getMap();
        if (!fieldMap.containsKey(finalFieldName)) {
            return null;
        }
        return fieldMap.get(finalFieldName).getDescribe().getType();
    }

    /**
     * @description Builds the list of CurrencyIsoCode paths needed to render currency fields
     *              in the currency of the record that owns them. For a direct currency field
     *              this is 'CurrencyIsoCode'; for a traversal path such as Order__r.Amount__c
     *              it is 'Order__r.CurrencyIsoCode'.
     * @param objType The child SObjectType being queried.
     * @param fields  Fields already selected for the query.
     * @return Additional ISO code paths to add to the query (empty in single-currency orgs).
     */
    private static List<String> collectCurrencyIsoFields(Schema.SObjectType objType, List<String> fields) {
        List<String> isoFields = new List<String>();
        if (objType == null || !UserInfo.isMultiCurrencyOrganization()) {
            return isoFields;
        }
        for (String f : fields) {
            if (getFieldType(objType, f) != Schema.DisplayType.CURRENCY) {
                continue;
            }
            String isoPath = f.contains('.')
                ? f.substring(0, f.lastIndexOf('.')) + '.CurrencyIsoCode'
                : 'CurrencyIsoCode';
            if (!fields.contains(isoPath) && !isoFields.contains(isoPath)) {
                isoFields.add(isoPath);
            }
        }
        return isoFields;
    }

    /**
     * @description Returns the running user's currency plus the org's active conversion rates,
     *              so the client can display amounts in both the record and user currency.
     * @return CurrencyInfo wrapper. In single-currency orgs only the user currency is populated.
     */
    @AuraEnabled(cacheable=true)
    public static CurrencyInfo getCurrencyInfo() {
        CurrencyInfo info = new CurrencyInfo();
        info.userCurrency = UserInfo.getDefaultCurrency();
        info.isMultiCurrency = UserInfo.isMultiCurrencyOrganization();
        info.conversionRates = new Map<String, Decimal>();
        if (!info.isMultiCurrency) {
            return info;
        }
        // CurrencyType only exists in multi-currency orgs, so it must be queried dynamically.
        for (SObject rate : Database.query(
            'SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsActive = true',
            AccessLevel.USER_MODE
        )) {
            info.conversionRates.put(
                String.valueOf(rate.get('IsoCode')),
                (Decimal) rate.get('ConversionRate')
            );
        }
        return info;
    }

    private static void validateInputs(String childObjectApiName, String relationshipFieldApiName, String fieldApiNames) {
        if (String.isBlank(childObjectApiName) || String.isBlank(relationshipFieldApiName) || String.isBlank(fieldApiNames)) {
            throw new AuraHandledException('Missing required configuration. Please configure the component in App Builder.');
        }
        // Validate object exists
        Schema.SObjectType objType = getObjectType(childObjectApiName);
        if (objType == null) {
            throw new AuraHandledException('Invalid object API name: ' + childObjectApiName);
        }
        // The relationship field is concatenated into the WHERE clause, so it must be a
        // real field on the child object.
        if (!objType.getDescribe().fields.getMap().containsKey(relationshipFieldApiName)) {
            throw new AuraHandledException('Invalid relationship field API name: ' + relationshipFieldApiName);
        }
    }

    /**
     * @description Ensures every supplied field path resolves against describe before it is
     *              concatenated into a SOQL string. Unresolvable paths are rejected rather
     *              than passed through, which prevents SOQL injection through configuration.
     * @param objType    The child SObjectType being queried.
     * @param fieldPaths Field API names or dot-notation traversal paths.
     */
    private static void validateFieldPaths(Schema.SObjectType objType, List<String> fieldPaths) {
        for (String fieldPath : fieldPaths) {
            if (String.isBlank(fieldPath) || getFieldType(objType, fieldPath) == null) {
                throw new AuraHandledException('Invalid field API name: ' + fieldPath);
            }
        }
    }

    private static List<String> parseFields(String fieldApiNames) {
        List<String> fields = new List<String>();
        for (String f : fieldApiNames.split(',')) {
            String trimmed = f.trim();
            if (String.isNotBlank(trimmed)) {
                fields.add(trimmed);
            }
        }
        return fields;
    }

    private static Boolean hasField(String objectName, String fieldName) {
        Schema.SObjectType objType = getObjectType(objectName);
        if (objType == null) {
            return false;
        }
        return objType.getDescribe().fields.getMap().containsKey(fieldName);
    }

    private static String buildQuery(
        List<String> fields,
        String childObjectApiName,
        String relationshipFieldApiName,
        String sortField,
        String sortDirection,
        Integer recordLimit
    ) {
        // All identifiers reaching this point have been validated against describe.
        String query = 'SELECT ' + String.join(fields, ', ') +
            ' FROM ' + childObjectApiName +
            ' WHERE ' + relationshipFieldApiName + ' = :parentRecordId';

        if (String.isNotBlank(sortField)) {
            String dir = (sortDirection != null && sortDirection.equalsIgnoreCase('DESC')) ? 'DESC' : 'ASC';
            query += ' ORDER BY ' + sortField + ' ' + dir;
        }

        if (recordLimit != null && recordLimit > 0) {
            query += ' LIMIT ' + recordLimit;
        }
        return query;
    }

    private static String mapFieldType(Schema.DisplayType fieldType) {
        switch on fieldType {
            when CURRENCY {
                return 'currency';
            }
            when DATE {
                return 'date';
            }
            when DATETIME {
                return 'datetime';
            }
            when DOUBLE, LONG, INTEGER {
                return 'number';
            }
            when PERCENT {
                return 'percent';
            }
            when PHONE {
                return 'phone';
            }
            when EMAIL {
                return 'email';
            }
            when URL {
                return 'url';
            }
            when BOOLEAN {
                return 'boolean';
            }
            when REFERENCE {
                return 'reference';
            }
            when else {
                return 'text';
            }
        }
    }

    /**
     * @description Wrapper class for column metadata.
     */
    public class ColumnInfo {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public String relationshipName;
    }

    /**
     * @description Wrapper class carrying the user's currency and the org conversion rates.
     */
    public class CurrencyInfo {
        @AuraEnabled public String userCurrency;
        @AuraEnabled public Boolean isMultiCurrency;
        @AuraEnabled public Map<String, Decimal> conversionRates;
    }

    /**
     * @description Wrapper class for parent record information used in breadcrumbs.
     */
    public class ParentRecordInfo {
        @AuraEnabled public String name;
        @AuraEnabled public String objectLabel;
    }

    /**
     * @description Gets parent record name and object label for breadcrumb display.
     * @param parentRecordId The Id of the parent record.
     * @return ParentRecordInfo wrapper with name and object label.
     */
    @AuraEnabled(cacheable=true)
    public static ParentRecordInfo getParentRecordInfo(Id parentRecordId) {
        ParentRecordInfo info = new ParentRecordInfo();
        if (parentRecordId == null) {
            return info;
        }
        Schema.SObjectType objType = parentRecordId.getSObjectType();
        info.objectLabel = objType.getDescribe().getLabelPlural();

        String objectApiName = objType.getDescribe().getName();
        String nameField = 'Name';
        if (objectApiName == 'Case') {
            nameField = 'CaseNumber';
        }

        String query = 'SELECT ' + nameField + ' FROM ' + objectApiName +
            ' WHERE Id = :parentRecordId LIMIT 1';
        List<SObject> records = Database.query(query, AccessLevel.USER_MODE);
        if (!records.isEmpty()) {
            info.name = String.valueOf(records[0].get(nameField));
        }
        return info;
    }
}