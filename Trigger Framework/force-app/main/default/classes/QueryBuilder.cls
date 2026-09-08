/**
 * @description QueryBuilder class.
 */
@SuppressWarnings('PMD.AvoidBooleanMethodParameters,PMD.AvoidDebugStatements,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.DebugsShouldUseLoggingLevel,PMD.EagerlyLoadedDescribeSObjectResult,PMD.ExcessivePublicCount,PMD.FieldNamingConventions,PMD.IfElseStmtsMustUseBraces,PMD.IfStmtsMustUseBraces,PMD.NcssCount,PMD.TooManyFields')
public virtual inherited sharing class QueryBuilder {
    public enum FilterScope {
        Delegated,
        Everything,
        Mine,
        MineAndMyGroups,
        My_Territory,
        My_Team_Territory,
        Team
    }

    private String fromSobject;
    private Set<String> fieldTokens;
    private Set<String> groupByFields;
    private List<Order> sortingOrder;
    private FilterScope scope;
    private Integer queryLimit;
    private Integer queryOffset;
    private Integer countResult;
    private Boolean updateTracking;
    private Boolean updateViewstat;
    private Boolean forView;
    private Boolean forReference;
    private Boolean withSecurityEnforced;

    private ConditionsManager conditionsManager;

    private List<SObject> result;
    private Boolean checkCrud;
    private Boolean checkFls;
    private Boolean containsSubquery;
    private List<String> subQueries;
    /**
     * Constructs an empty QueryBuilder instance.
     * Requires a call to addFrom() method for selecting
     * an sobject to build query for.
     *
     * @see QueryBuilder.addFrom
     */
    public QueryBuilder() {
        this.fieldTokens = new Set<String>();
        this.groupByFields = new Set<String>();
        this.sortingOrder = new List<Order>();
        this.subQueries = new List<String>();
        this.conditionsManager = new ConditionsManager(this);
        this.queryLimit = 0;
        this.queryOffset = 0;
        this.countResult = null;
        this.checkCrud = false;
        this.checkFls = false;
        this.containsSubquery = false;
        this.updateTracking = false;
        this.updateViewstat = false;
        this.forView = false;
        this.forReference = false;
        this.withSecurityEnforced = false;
        this.scope = FilterScope.Everything;
    }

    /**
     * Constructs a QueryBuilder instance for
     * given SObject name in a string form.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder('Account');
     * </code>
     * </pre>
     *
     * @param fromSobject
     */
    public QueryBuilder(String fromSobject) {
        this();
        this.fromSobject = fromSobject.trim();
    }

    /**
     * Constructs a QueryBuilder instance for
     * given SObject name in an SObjectType form.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     */
    public QueryBuilder(SObjectType type) {
        this();
        this.fromSobject = type.getDescribe().getName();
    }

    /**
     * Constructs a QueryBuilder instance for
     * given SObject name in an System.Type form.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     */
    public QueryBuilder(Type type) {
        this();
        this.fromSobject = type.getName();
    }

    /**
     * Constructs a QueryBuilder instance for
     * given SObject name in an SObject form.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     */
    public QueryBuilder(SObject sobj) {
        this(sobj.getSObjectType());
    }

    /**
     * Sets the FROM statement in the query.
     * Always overrides the constructor-selected FROM value.
     * <br/>
     * The name of the SObject is accepted as a string.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFrom('Account');
     * </code>
     * </pre>
     *
     * @param fromSobject
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFrom(String fromSobject) {
        this.fromSobject = fromSobject;
        return this;
    }

    /**
     * Sets the FROM statement in the query.
     * Always overrides the constructor-selected FROM value.
     * <br/>
     * The name of the SObject is accepted as an SObjectType.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFrom(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFrom(SObjectType type) {
        return this.addFrom(type.getDescribe().getName());
    }

    /**
     * Sets the FROM statement in the query.
     * Always overrides the constructor-selected FROM value.
     * <br/>
     * The name of the SObject is accepted as a System.Type.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFrom(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFrom(Type type) {
        return this.addFrom(type.getName());
    }

    /**
     * Sets the FROM statement in the query.
     * Always overrides the constructor-selected FROM value.
     * <br/>
     * The name of the SObject is accepted as an SObject.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFrom(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFrom(SObject sobj) {
        return this.addFrom(sobj.getSObjectType());
    }

    /**
     * Constructs a sub-query for given query.
     * The sub-query is build based on a nested QueryBuilder instance.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addSubQuery(new QueryBuilder('Contacts'));
     * </code>
     * </pre>
     *
     * @param queryBuilder
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addSubQuery(QueryBuilder queryBuilder) {
        // 2020-05-03 fixed to remove splitting sub query into field tokens by comma
        // return this.addField('(' + queryBuilder.toString() + ')');
        this.fieldTokens.add('(' + queryBuilder.toString() + ')');
        return this;
    }

    /**
     * @description Add Separate Sub Query.
     * @param queryBuilder The query Builder.
     * @return QueryBuilder value.
     */
    public QueryBuilder addSeparateSubQuery(QueryBuilder queryBuilder) {
        this.containsSubquery = true;
        this.subQueries.add(queryBuilder.toString());
        return this;
    }


    /**
     * Constructs a sub-query for given query.
     * The sub-query is a plain string value.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addSubQuery('SELECT Id FROM Contacts');
     * </code>
     * </pre>
     *
     * @param subQueryString
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addSubQuery(String subQueryString) {
        return this.addField('(' + subQueryString + ')');
    }

    /**
     * Adds a field or number of comma-separated fields
     * into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addField('Id')
     *     .addField('Name, ParentId');
     * </code>
     * </pre>
     *
     * @param fieldName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addField(String fieldName) {
        if (fieldName.contains(',')) {
            return this.addFields(fieldName);
        }
        this.fieldTokens.add(fieldName.trim());
        return this;
    }

    /**
     * @description Adds a field in a form of SObjectField
     * into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addField(Account.Name);
     * </code>
     * </pre>
     *
     * @param field The field.
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addField(SObjectField field) {
        return this.addField(field.getDescribe().getName());
    }

    /**
     * Adds a field or number of populated fields,
     * extracted from sobject instance into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addField(new Account(Name = 'Test'));
     * //results: SELECT Name FROM Account
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFields(SObject sobj) {
        return this.addFields(sobj.getPopulatedFieldsAsMap().keySet());
    }

    /**
     * @description Adds a field or number of comma-separated fields
     * into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFields('Id')
     *     .addFields('Name, ParentId');
     * </code>
     * </pre>
     *
     * @param fieldNames The field Names.
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFields(String fieldNames) {
        return this.addFields(fieldNames.trim().split(','));
    }

    /**
     * Adds a list of fields into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFields(new List<String> {'Name'});
     * </code>
     * </pre>
     *
     * @param fieldNames
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFields(List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.fieldTokens.add(fieldName.trim());
        }
        return this;
    }

    /**
     * Adds a set of fields into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFields(new Set<String> {'Name'});
     * </code>
     * </pre>
     *
     * @param fieldNames
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFields(Set<String> fieldNames) {
        for (String fieldName : fieldNames) {
            this.fieldTokens.add(fieldName.trim());
        }
        return this;
    }

    /**
     * Adds a set of fields into the query selection Set.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFields(new Set<SObjectField> {Account.Name});
     * </code>
     * </pre>
     *
     * @param fields
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFields(List<SObjectField> fields) {
        for (SObjectField field : fields) {
            this.addField(field);
        }
        return this;
    }

    /**
     * Adds all fields of the sobject, specified in FROM statement.
     * The FROM sobject must be specified before calling to this method.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFieldsAll();
     * </code>
     * </pre>
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll() {
        return this.addFieldsAll(this.fromSobject);
    }

    /**
     * Adds all fields of the sobject, specified in param as a string name.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll('Account');
     * </code>
     * </pre>
     *
     * @param sobjectName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll(String sobjectName) {
        Set<String> fieldNames = Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap().keySet();
        this.fieldTokens.addAll(fieldNames);
        return this;
    }

    /**
     * Adds all fields of the sobject, specified in param as System.Type.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll(Type type) {
        return this.addFieldsAll(type.toString());
    }

    /**
     * Adds all fields of the sobject, specified in param as an SObjectType.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll(SObjectType type) {
        return this.addFieldsAll(type.getDescribe().getName());
    }

    /**
     * Adds all fields of the sobject, specified in param as an SObject.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAll(SObject sobj) {
        return this.addFieldsAll(sobj.getSObjectType());
    }

    /**
     * Adds all fields of the related SObject, specified in param as an String.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFieldsMerged('Contact');
     * </code>
     * </pre>
     *
     * @param field
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsMerged(String field) {
        DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe()
                .get(fromSobject)
                .getDescribe()
                .fields
                .getMap()
                .get(field)
                .getDescribe();

        List<SObjectType> referenceTypes = fieldDescribe.getReferenceTo();
        if (referenceTypes == null || referenceTypes.isEmpty()) {
            return this;
        }

        Set<String> referenceObjectFields = referenceTypes[0].getDescribe().fields.getMap().keySet();
        String referenceName = fieldDescribe.getRelationshipName();
        for (String referenceField : referenceObjectFields) {
            this.fieldTokens.add(referenceName + '.' + referenceField);
        }
        return this;
    }

    /**
     * Adds all accessible fields of the related SObject, specified in param as an String.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFieldsMergedAccessible('Contact');
     * </code>
     * </pre>
     *
     * @param field
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsMergedAccessible(String field) {
        DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe()
                .get(fromSobject)
                .getDescribe()
                .fields
                .getMap()
                .get(field)
                .getDescribe();

        List<SObjectType> referenceTypes = fieldDescribe.getReferenceTo();
        if (referenceTypes == null || referenceTypes.isEmpty()) {
            return this;
        }

        Map<String, SObjectField> referenceObjectFields = referenceTypes[0].getDescribe().fields.getMap();
        String referenceName = fieldDescribe.getRelationshipName();
        for (String referenceField : referenceObjectFields.keySet()) {
            if (referenceObjectFields.get(referenceField).getDescribe().isAccessible()) {
                this.fieldTokens.add(referenceName + '.' + referenceField);
            }
        }
        return this;
    }

    /**
     * Adds all accessible fields of the sobject, specified in FROM statement.
     * The FROM sobject must be specified before calling to this method.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllAccessible();
     * </code>
     * </pre>
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllAccessible() {
        return this.addFieldsAllAccessible(this.fromSobject);
    }

    /**
     * Adds all accessible fields of the sobject, specified in param as System.Type.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllAccessible(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllAccessible(Type type) {
        return this.addFieldsAllAccessible(type.toString());
    }

    /**
     * Adds all accessible fields of the sobject, specified in param as an SObjectType.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllAccessible(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllAccessible(SObjectType type) {
        return this.addFieldsAllAccessible(type.getDescribe().getName());
    }

    /**
     * Adds all accessible fields of the sobject, specified in param as an SObject.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllAccessible(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllAccessible(SObject sobj) {
        return this.addFieldsAllAccessible(sobj.getSObjectType());
    }

    /**
    * Adds all accessible fields of the sobject, specified in param as a string name.
    *
    * <br/><br/>
    * <p><b>Example</b></p>
    * <pre>
    * <code>
    * new QueryBuilder()
    *     .addFieldsAllAccessible('Account');
    * </code>
    * </pre>
    *
    * @param sobjectName
    *
    * @return this - current instance of QueryBuilder.class
    */
    public QueryBuilder addFieldsAllAccessible(String sobjectName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        Set<String> accessibleFields = new Set<String>();
        for (Schema.SObjectField field : fieldMap.values()) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isAccessible()) {
                if (fieldDescribe.getName() == 'Name') System.debug(fieldDescribe.getName());
                accessibleFields.add(fieldDescribe.getName());
            }
        }
        fieldTokens.addAll(accessibleFields);
        return this;
    }

    /**
     * Adds all creatable fields of the sobject, specified in FROM statement.
     * The FROM sobject must be specified before calling to this method.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllCreatable();
     * </code>
     * </pre>
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable() {
        return this.addFieldsAllCreatable(this.fromSobject);
    }

    /**
     * Adds all creatable fields of the sobject, specified in param as a string name.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllCreatable('Account');
     * </code>
     * </pre>
     *
     * @param sobjectName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable(String sobjectName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        Set<String> createableFields = new Set<String>();
        for (Schema.SObjectField field : fieldMap.values()) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isCreateable()) {
                createableFields.add(fieldDescribe.getName());
            }
        }
        fieldTokens.addAll(createableFields);
        return this;
    }

    /**
     * Adds all creatable fields of the sobject, specified in param as System.Type.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllCreatable(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable(Type type) {
        return this.addFieldsAllCreatable(type.toString());
    }

    /**
     * Adds all creatable fields of the sobject, specified in param as an SObjectType.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable(SObjectType type) {
        return this.addFieldsAllCreatable(type.getDescribe().getName());
    }

    /**
     * Adds all creatable fields of the sobject, specified in param as an SObject.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAll(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllCreatable(SObject sobj) {
        return this.addFieldsAllCreatable(sobj.getSObjectType());
    }

    /**
     * @description Adds all updatable fields of the sobject, specified in FROM statement.
     * The FROM sobject must be specified before calling to this method.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable();
     * </code>
     * </pre>
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable() {
        return this.addFieldsAllUpdatable(this.fromSobject);
    }

    /**
     * Adds all updatable fields of the sobject, specified in param as string name.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable('Account');
     * </code>
     * </pre>
     *
     * @param sobjectName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable(String sobjectName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(sobjectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        Set<String> updateableFields = new Set<String>{
        };
        for (Schema.SObjectField field : fieldMap.values()) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isUpdateable()) {
                updateableFields.add(fieldDescribe.getName());
            }
        }
        fieldTokens.addAll(updateableFields);
        return this;
    }

    /**
     * Adds all updatable fields of the sobject, specified in param as System.Type.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable(Account.class);
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable(Type type) {
        return this.addFieldsAllUpdatable(type.getName());
    }

    /**
     * Adds all updatable fields of the sobject, specified in param as an SObjectType.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable(Account.getSObjectType());
     * </code>
     * </pre>
     *
     * @param type
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable(SObjectType type) {
        return this.addFieldsAllUpdatable(type.getDescribe().getName());
    }

    /**
     * Adds all updatable fields of the sobject, specified in param as an SObject.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addFieldsAllUpdatable(new Account());
     * </code>
     * </pre>
     *
     * @param sobj
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldsAllUpdatable(SObject sobj) {
        return this.addFieldsAllUpdatable(sobj.getSObjectType());
    }

    /**
     * Adds all fields from a FieldSet for specific object.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFieldSet('Account', 'My_Field_Set');
     * </code>
     * </pre>
     *
     * @param objectName
     * @param fieldSetName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldSet(String objectName, String fieldSetName) {
        Set<String> result = new Set<String>();
        Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectTypeObj = GlobalDescribeMap.get(objectName);
        List<FieldSetMember> fields = sObjectTypeObj.getDescribe().FieldSets.getMap().get(fieldSetName).getFields();
        for (FieldSetMember fieldSetMember : fields) {
            result.add(fieldSetMember.getFieldPath());
        }
        this.fieldTokens.addAll(result);
        return this;
    }

    /**
     * Adds all fields from a specific FieldSet.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * FieldSet myFieldSet = //retrieve a field set
     * new QueryBuilder(Account.class)
     *     .addFieldSet(myFieldSet);
     * </code>
     * </pre>
     *
     * @param fieldSet
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldSet(FieldSet fieldSet) {
        Set<String> fieldNames = new Set<String>();
        for (FieldSetMember fieldSetMember : fieldSet.getFields()) {
            fieldNames.add(fieldSetMember.getFieldPath());
        }
        this.fieldTokens.addAll(fieldNames);
        return this;
    }

    /**
     * Adds all fields from a specific FieldSet by its name.
     * The FROM sobject must be specified before calling to this method.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addFieldSet('My_Field_Set');
     * </code>
     * </pre>
     *
     * @param fieldSetName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addFieldSet(String fieldSetName) {
        return this.addFieldSet(this.fromSobject, fieldSetName);
    }

    /**
     * Returns an instance of ConditionsManage for current QueryBuilder instance.
     * Allows creation of conditions for a query.
     * <p>To finish work with conditions and return to work with QueryBuilder instance
     * it is required to call the endConditions() method of ConditionsManager</p>
     *
     * @return an instance of ConditionsManager.class
     *
     * @see QueryBuilder.ConditionsManager
     */
    public ConditionsManager addConditions() {
        return this.conditionsManager;
    }

    /**
     * Returns an instance of ConditionsManage for current QueryBuilder instance.
     * Allows creation of conditions for a query.
     * <p>As a parameter accepts a string with order of conditions execution and there relations</p>
     * <p>To finish work with conditions and return to work with QueryBuilder instance
     * it is required to call the endConditions() method of ConditionsManager</p>
     * <p>Condition index is 1-based<p>
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder()
     *     .addConditionsWithOrder('1 and (2 or 3) and 4')
     *     .endConditions();
     * </code>
     * </pre>
     *
     * @param conditionOrder
     *
     * @return an instance of ConditionsManager.class
     *
     * @see QueryBuilder.ConditionsManager
     */
    public ConditionsManager addConditionsWithOrder(String conditionOrder) {
        return this.conditionsManager.setConditionOrder(conditionOrder);
    }

    /**
     * Sets a limit for current query. Accepts an integer.
     *
     * @param queryLimit
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setLimit(Integer queryLimit) {
        this.queryLimit = queryLimit;
        return this;
    }

    /**
     * Sets an offset for current query. Accepts an integer.
     *
     * @param queryOffset
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setOffset(Integer queryOffset) {
        this.queryOffset = queryOffset;
        return this;
    }

    /**
     * @description Adds a SORT BY {Order} statement to the query.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrder(
     *          new QueryBuilder.Order(Account.Id)
     *              .setSortingOrderAsc()
     *              .setNullsOrderLast()
     *      );
     * </code>
     * </pre>
     *
     * @param order The order.
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrder(Order order) {
        this.sortingOrder.add(order);
        return this;
    }

    /**
     * Adds a SORT BY {field} ASC statement to the query.
     * Field name is specified as a string.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrderAsc('Account');
     * </code>
     * </pre>
     *
     * @param fieldName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrderAsc(String fieldName) {
        this.sortingOrder.add(new AscOrder(fieldName));
        return this;
    }

    /**
     * Adds a SORT BY {field} ASC statement to the query.
     * Field is specified as an SObjectField.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrderAsc(Account.Name);
     * </code>
     * </pre>
     *
     * @param field
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrderAsc(SObjectField field) {
        this.sortingOrder.add(new AscOrder(field.getDescribe().getName()));
        return this;
    }

    /**
     * Adds a SORT BY {field} DESC statement to the query.
     * Field name is specified as a string.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrderDesc('Account');
     * </code>
     * </pre>
     *
     * @param fieldName
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrderDesc(String fieldName) {
        this.sortingOrder.add(new DescOrder(fieldName));
        return this;
    }

    /**
     * Adds a SORT BY {field} DESC statement to the query.
     * Field is specified as an SObjectField.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .addOrderDesc(Account.Name);
     * </code>
     * </pre>
     *
     * @param field
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addOrderDesc(SObjectField field) {
        this.sortingOrder.add(new DescOrder(field.getDescribe().getName()));
        return this;
    }

    /**
     * Adds a field or number of comma-separated fields to the
     * group by Set of fields.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .groupBy('Name')
     *     .groupBy('Id, ParentId');
     * </code>
     * </pre>
     *
     * @param fields
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addGroupBy(String fields) {
        return this.addGroupBy(fields.trim().split(','));
    }

    /**
     * Adds a field in an SObjectField form to the
     * group by Set of fields.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .groupBy(Account.Name);
     * </code>
     * </pre>
     *
     * @param field
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addGroupBy(SObjectField field) {
        return this.addGroupBy(field.getDescribe().getName());
    }

    /**
     * Adds a list of field to the
     * group by Set of fields.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .groupBy(new List<String> {'Name'});
     * </code>
     * </pre>
     *
     * @param fields
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addGroupBy(List<String> fields) {
        this.groupByFields.addAll(fields);
        return this;
    }

    /**
     * Adds a set of field to the
     * group by Set of fields.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .groupBy(new Set<String> {'Name'});
     * </code>
     * </pre>
     *
     * @param fields
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder addGroupBy(Set<String> fields) {
        this.groupByFields.addAll(fields);
        return this;
    }

    /**
     * Adds the optional USING SCOPE clause of a SOQL query returns
     * records within a specified scope. For example, you can limit
     * the records to return only objects that the user owns
     * or only records in the user’s territory.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setScope(QueryBuilder.FilterScope.Mine);
     * </code>
     * </pre>
     *
     * @param scope
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setScope(QueryBuilder.FilterScope scope) {
        this.scope = scope;
        return this;
    }

    /**
     * Adds FOR VIEW clause in to the query.
     * Allows to update LastViewedDate on retrieved objects.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setForView(true);
     * </code>
     * </pre>
     *
     * @param forView
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setForView(Boolean forView) {
        this.forView = forView;
        return this;
    }

    /**
     * @description Adds FOR VIEW clause in to the query.
     * Allows to update LastViewedDate on retrieved objects.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setForView();
     * </code>
     * </pre>
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setForView() {
        this.forView = true;
        return this;
    }

    /**
     * Adds FOR REFERENCE clause in to the query.
     * Allows to update LastReferencedDate on retrieved objects.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setForReference(true);
     * </code>
     * </pre>
     *
     * @param forReference
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setForReference(Boolean forReference) {
        this.forReference = forReference;
        return this;
    }

    /**
     * @description Adds FOR REFERENCE clause in to the query.
     * Allows to update LastReferencedDate on retrieved objects.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setForView();
     * </code>
     * </pre>
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setForReference() {
        this.forReference = true;
        return this;
    }

    /**
     * @description Sets the UPDATE TRACKING optional clause on a SOQL query.
     * UPDATE TRACKING can be added to a SELECT statement of a
     * SOQL query to report on article searches and views to track
     * the keywords that are used in Salesforce Knowledge article searches
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setUpdateTracking(true);
     * </code>
     * </pre>
     *
     * @param updateTracking The update Tracking.
     * @return QueryBuilder value.
     */
    public QueryBuilder setUpdateTracking(Boolean updateTracking) {
        this.updateTracking = updateTracking;
        return this;
    }

    /**
     * Sets the UPDATE TRACKING optional clause on a SOQL query.
     * UPDATE TRACKING can be added to a SELECT statement of a
     * SOQL query to report on article searches and views to track
     * the keywords that are used in Salesforce Knowledge article searches
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setUpdateTracking();
     * </code>
     * </pre>
     *
     * @return
     */
    public QueryBuilder setUpdateTracking() {
        return this.setUpdateTracking(true);
    }

    /**
     * @description Adds the UPDATE VIEWSTAT optional clause to the SOQL query.
     * Allows get a view count for every article that you have access to online.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setUpdateViewstat(true);
     * </code>
     * </pre>
     *
     * @param updateViewstat The update Viewstat.
     * @return QueryBuilder value.
     */
    public QueryBuilder setUpdateViewstat(Boolean updateViewstat) {
        this.updateViewstat = updateViewstat;
        return this;
    }

    /**
     * Adds the UPDATE VIEWSTAT optional clause to the SOQL query.
     * Allows get a view count for every article that you have access to online.
     *
     * <br/><br/>
     * <p><b>Example</b></p>
     * <pre>
     * <code>
     * new QueryBuilder(Account.class)
     *     .setUpdateViewstat();
     * </code>
     * </pre>
     *
     * @return
     */
    public QueryBuilder setUpdateViewstat() {
        return this.setUpdateViewstat(true);
    }

    /**
     * Enables or disables CRUD and FLS check for current query.
     * Default is disabled.
     * <br/>
     * Enabled CRUD check throws an System.NoAccessException if current user doesn't have access to an SObject.
     * <br/>
     * Enabled FLS check removes a field from result.
     *
     * @param checkCrudAndFls
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckCRUDAndFLS(Boolean checkCrudAndFls) {
        this.setCheckCRUD(checkCrudAndFls);
        return this.setCheckFLS(checkCrudAndFls);
    }

    /**
     * <h1>THIS IS BETA FUNCTIONALITY</h1>
     * Enables CRUD and FLS check for current query.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setWithSecurityEnforced() {
        return this.setWithSecurityEnforced(true);
    }

    /**
     * @description <h1>THIS IS BETA FUNCTIONALITY</h1>
     * Enables CRUD and FLS check for current query.
     *
     * @param withSecurityEnforced The with Security Enforced.
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setWithSecurityEnforced(Boolean withSecurityEnforced) {
        this.withSecurityEnforced = withSecurityEnforced;
        return this;
    }

    /**
     * Enables CRUD and FLS check for current query.
     * <br/>
     * Enabled CRUD check throws an System.NoAccessException if current user doesn't have access to an SObject.
     * <br/>
     * Enabled FLS check removes a field from result.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckCRUDAndFLS() {
        return this.setCheckCRUDAndFLS(true);
    }

    /**
     * Enables or disables CRUD check for current query.
     * <br/>
     * Enabled CRUD check throws an System.NoAccessException if current user doesn't have access to an SObject.
     *
     * @param checkCrud
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckCRUD(Boolean checkCrud) {
        this.checkCrud = checkCrud;
        return this;
    }

    /**
     * Enables CRUD check for current query.
     * <br/>
     * Enabled CRUD check throws an System.NoAccessException if current user doesn't have access to an SObject.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckCRUD() {
        return this.setCheckCRUD(true);
    }

    /**
     * Enables or disables FLS check for current query.
     * Default is disabled.
     * <br/>
     * Enabled FLS check removes a field from result.
     *
     * @param checkFls
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckFLS(Boolean checkFls) {
        this.checkFls = checkFls;
        return this;
    }

    /**
     * Enables FLS check for current query.
     * <br/>
     * Enabled FLS check removes a field from result.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder setCheckFLS() {
        return this.setCheckFLS(true);
    }
    
    /**
     * Builds a current state of query and outputs it to the debug console.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder preview() {
        String logRecord = '\n============RESULTING QUERY============\n\n'
                + this.toString()
                + '\n\n=======================================\n';
        System.debug(logRecord);
        return this;
    }

    /**
     * Builds a current state of query, replacing all the fields with COUNT(Id),
     * exexutes it, and outputs the result to the debug console.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder previewCount() {
        if (this.countResult == null) {
            this.countResult = this.toCount();
        }
        String logRecord = '\n============COUNT RESULT============\n\n'
                + 'Query will return exactly: ' + this.countResult + ' record(s).'
                + '\n\n=======================================\n';
        System.debug(logRecord);
        return this;
    }

    /**
     * @description Add Count By Field.
     * @param fieldName The field Name.
     * @return QueryBuilder value.
     */
    public QueryBuilder addCountByField(String fieldName) {
        this.fieldTokens.add('COUNT(' + fieldName + ')');
        return this;
    }

    /**
     * @description Add Count By Field.
     * @param field The field.
     * @return QueryBuilder value.
     */
    public QueryBuilder addCountByField(SObjectField field) {
        return this.addCountByField(field.getDescribe().getName());
    }

    /**
     * Nullifies and re-creates all of the fields in current QueryBuilder instance.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder newQuery() {
        this.fieldTokens = new Set<String>();
        this.groupByFields = new Set<String>();
        this.sortingOrder = new List<Order>();
        this.conditionsManager = new ConditionsManager(this);
        this.queryLimit = 0;
        this.queryOffset = 0;
        this.countResult = null;
        this.checkCrud = false;
        this.checkFls = false;
        this.updateTracking = false;
        this.updateViewstat = false;
        this.forView = false;
        this.forReference = false;
        this.withSecurityEnforced = false;
        this.scope = FilterScope.Everything;
        return this;
    }

    /**
     * Resets a result for current query.
     * Otherwise, each new call to toList() method returns the same result.
     *
     * @return this - current instance of QueryBuilder.class
     */
    public QueryBuilder resetResult() {
        this.result = null;
        return this;
    }

    /**
     * Builds a query based in current params.
     *
     * @return string representation of query
     */
    public override String toString() {
        this.fieldTokens.remove('');
        this.fieldTokens.remove(null);
        String result = 'SELECT ';
        String fields = '';
        if (this.fieldTokens.isEmpty()) {
            fields = 'Id';
        } else {
            System.debug('Sub Queries: '+this.subQueries);
            if (this.containsSubquery) {
                for (String subQuery : this.subQueries) {
                    this.fieldTokens.add('(' + subQuery + ')');
                }
            }
            fields = String.join(new List<String>(this.fieldTokens), '\n\t, ');
        }
        result += fields + ' \n';
        result += 'FROM ' + this.fromSobject + ' \n';
        if (this.scope != FilterScope.Everything) {
            result += 'USING SCOPE ' + this.scope.name() + ' \n';
        }
        if (this.conditionsManager.hasConditions()) {
            result += 'WHERE ' + this.conditionsManager.builtCondition + ' \n';
        }
        if (this.withSecurityEnforced) {
            result += 'WITH SECURITY_ENFORCED \n';
        }

        if (!this.groupByFields.isEmpty()) {
            result += 'GROUP BY ';
            result += String.join(new List<String>(this.groupByFields), ', ') + ' \n';
        }
        if (!this.sortingOrder.isEmpty()) {
            result += 'ORDER BY ';
            List<String> orders = new List<String>();
            for (Order order : this.sortingOrder) {
                orders.add(order.toString());
            }
            result += String.join(orders, ', ') + ' \n';
        }
        if (this.queryLimit > 0) {
            result += 'LIMIT ' + this.queryLimit + ' \n';
        }
        if (this.queryOffset > 0) {
            result += 'OFFSET ' + this.queryOffset + ' \n';
        }

        if ((this.forView && !this.forReference) || (this.forView && this.forReference)) {
            result += 'FOR VIEW \n';
        }
        if (!this.forView && this.forReference) {
            result += 'FOR REFERENCE \n';
        }

        if (this.updateTracking && this.updateViewstat) {
            result += 'UPDATE TRACKING, VIEWSTAT';
        }
        if (this.updateTracking && !this.updateViewstat) {
            result += 'UPDATE TRACKING';
        }
        if (!this.updateTracking && this.updateViewstat) {
            result += 'UPDATE VIEWSTAT';
        }


        return result.trim();
    }

    /**
     * Builds a query, replacing all the selected fields with COUNT(Id)
     * and returns as a string.
     *
     * @return string representation of query with COUNT(ID) instead of fields
     */
    public String toStringCount() {
        String result = 'SELECT ';
        String countString = 'count() ';
        result += countString;
        result += 'FROM ' + this.fromSobject + ' ';
        if (this.conditionsManager.hasConditions()) {
            result += 'WHERE ' + this.conditionsManager.builtCondition + ' ';
        }
        if (this.scope != FilterScope.Everything) {
            result += 'USING SCOPE ' + this.scope.name() + ' ';
        }
        if (this.queryLimit > 0) {
            result += 'LIMIT ' + this.queryLimit + ' ';
        }
        if (this.queryOffset > 0) {
            result += 'OFFSET ' + this.queryOffset + ' ';
        }
        return result.trim();
    }

    /**
     * Builds a query, replacing all the selected fields with COUNT(Id),
     * executes it and returns a number of records.
     *
     * @return number of records
     */
    public Integer toCount() {
        if (this.countResult == null) {
            this.countResult = Database.countQuery(this.toStringCount());
        }
        return this.countResult;
    }

    /**
     * Executes a query or returns already executed result as a list of SObjects
     *
     * @return list of SObjects
     */
    public List<SObject> toList() {
        if (this.result != null) {
            return this.result;
        }
        SObjectAccessValidator sObjectAccessValidator;
        if (this.checkCrud || this.checkFls) {
            sObjectAccessValidator = new SObjectAccessValidator(
                    Schema.getGlobalDescribe().get(this.fromSobject),
                    this.fieldTokens
            );
            if (this.checkCrud) {
                sObjectAccessValidator.checkObjectLevelAccess();
            }
            if (this.checkFls) {
                sObjectAccessValidator.checkFieldLevelAccess();
            }
        }
        if (this.containsSubquery) {
            for (String subQuery : this.subQueries) {
                this.fieldTokens.add('(' + subQuery + ')');
            }
        }
        System.debug('this.toString' +this.toString());
        List<SObject> result = Database.query(this.toString());
        system.debug('result :' + result);
        this.result = result;

        return this.result;
    }

    /**
     * Executes a query or returns already executed result as a map of SObjects by Id
     *
     * @return map of SObjects by Id
     */
    public Map<Id, SObject> toMap() {
        return new Map<Id, SObject>(this.toList());
    }

    /**
     * Executes a query or returns already executed result and fills the map from params.
     *
     * @param mapToFill
     *
     * @return map of SObjects by Id
     */
    public Map<Id, SObject> toMap(Map<Id, SObject> mapToFill) {
        for (SObject sobj : this.toList()) {
            Id sobjId = (Id) sobj.get('Id');
            mapToFill.put(sobjId, sobj);
        }
        return mapToFill;
    }

    /**
     * Returns the first SObject from the query result.
     *
     * @return first SObject from query
     */
    public SObject toSObject() {
        List<SObject> result = this.toList();
        if (result.isEmpty()) {
            return null;
        }
        return result[0];
    }

    /**
     * Executes a query or returns already executed result as a set of Ids.
     *
     * @return set of Ids
     */
    public Set<Id> toIdSet() {
        return this.toMap().keySet();
    }

    /**
     * Builds a query string and returns a QueryLocator
     *
     * @return Database.QueryLocator built based on query
     */
    public Database.QueryLocator toQueryLocator() {
        return Database.getQueryLocator(this.toString());
    }

    /**
     * Executes a query or returns already executed result as a set of Ids extracted from fields of resulted SObjects.
     *
     * @param fieldName
     *
     * @return set of Ids from query
     */
    public Set<Id> extractIds(String fieldName) {
        Set<Id> result = new Set<Id>();
        for (SObject sobj : this.toList()) {
            String extractedId = (String) sobj.get(fieldName);
            if (String.isEmpty(extractedId)) {
                continue;
            }
            result.add(extractedId);
        }
        return result;
    }

    /**
     * Executes a query or returns already executed result as a list of Objects extracted from fields of resulted SObjects.
     *
     * @param fieldName - String name of a field
     *
     * @return list of Objects
     */
    public List<Object> extractField(String fieldName) {
        List<Object> result = new List<Object>();
        for (SObject sobj : this.toList()) {
            result.add(sobj.get(fieldName));
        }
        return result;
    }

    /**
     * @description Executes a query or returns already executed result as a list of Objects extracted from fields of resulted SObjects.
     *
     * @param field The field.
     * @return list of Objects
     */
    public List<Object> extractField(SObjectField field) {
        List<Object> result = new List<Object>();
        for (SObject sobj : this.toList()) {
            result.add(sobj.get(field));
        }
        return result;
    }

    /**
     * Clones a query builder. Doesn't clone the result list.
     *
     * @return new instance of QueryBuilder, based on current state
     */
    public QueryBuilder cloneQueryBuilder() {
        return this.cloneQueryBuilder(false);
    }

    /**
     * @description Clones a query builder. Can include the list of already queried records.
     *
     * @param includeResult The include Result.
     * @return new instance of QueryBuilder, based on current state
     */
    public QueryBuilder cloneQueryBuilder(Boolean includeResult) {
        QueryBuilder result = new QueryBuilder(this.fromSobject);
        result.addFields(this.fieldTokens);
        result.addGroupBy(this.groupByFields);
        result.conditionsManager = this.conditionsManager.cloneConditionsManager(result);
        result.setLimit(this.queryLimit);
        if (includeResult && this.result != null && !this.result.isEmpty()) {
            result.result = new List<SObject>(this.result);
        }
        result.sortingOrder.addAll(this.sortingOrder);
        return result;
    }

    /**
     * Class, which allows building query conditions.
     */
    public class ConditionsManager {

        private final String BRACKET_L = '{';
        private final String BRACKET_R = '}';

        public List<Condition> conditions;
        private String conditionOrder;
        private final QueryBuilder queryBuilder;

        private String builtCondition;

        /**
         * @description Conditions Manager.
         * @param queryBuilder The query Builder.
         */
        public ConditionsManager(QueryBuilder queryBuilder) {
            this.queryBuilder = queryBuilder;
            this.conditions = new List<Condition>();
        }

        /**
         * @description Clone Conditions Manager.
         * @param queryBuilder The query Builder.
         * @return ConditionsManager value.
         */
        public ConditionsManager cloneConditionsManager(QueryBuilder queryBuilder) {
            ConditionsManager result = new ConditionsManager(queryBuilder);
            result.conditions = new List<Condition>(this.conditions);
            result.conditionOrder = conditionOrder;
            result.builtCondition = builtCondition;
            return result;
        }

        /**
         * @description Add.
         * @param condition The condition.
         * @return ConditionsManager value.
         */
        public ConditionsManager add(Condition condition) {
            if (condition instanceof ObjectTypeDependentCondition) {
                ((ObjectTypeDependentCondition) condition).setRelatedObjectType(this.queryBuilder.fromSobject);
            }
            if (condition.isEmpty()) {
                return this;
            }
            this.conditions.add(condition);
            return this;
        }

        /**
         * @description Preview.
         * @return ConditionsManager value.
         */
        public ConditionsManager preview() {
            System.debug('\nCONDITIONS');
            System.debug(this.toString());
            System.debug('\n');
            return this;
        }

        /**
         * @description Set Condition Order.
         * @param conditionOrder The condition Order.
         * @return ConditionsManager value.
         */
        public ConditionsManager setConditionOrder(String conditionOrder) {
            this.conditionOrder = conditionOrder;
            return this;
        }

        /**
         * @description End Conditions.
         * @return QueryBuilder value.
         */
        public QueryBuilder endConditions() {
            this.builtCondition = this.toString();
            return this.queryBuilder;
        }

        public override String toString() {
            String result = this.conditionOrder;
            if (String.isEmpty(result)) {
                result = '1';
            }
            result = this.bracketConditions(result);
            for (Integer i = 0; i < this.conditions.size(); i++) {
                Condition condition = this.conditions[i];
                if (condition instanceof ObjectTypeDependentCondition) {
                    ((ObjectTypeDependentCondition) condition).setRelatedObjectType(this.queryBuilder.fromSobject);
                }
                String conditionNumber = this.bracket('' + (i + 1));
                if (result.contains(conditionNumber)) {
                    result = result.replace(conditionNumber, condition.toString());
                }
            }
            return result;
        }

        private Boolean hasConditions() {
            return !this.conditions.isEmpty();
        }

        private String bracketConditions(String conditions) {
            this.conditions.size();
            for (Integer i = 1; i <= this.conditions.size(); i++) {
                String conditionNumber = '' + i;
                conditions = conditions.replace(conditionNumber, this.bracket(conditionNumber));
            }
            return conditions;
        }

        private String bracket(String condition) {
            return this.BRACKET_L + condition.trim() + this.BRACKET_R;
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     */
    public abstract class Condition {

        public final String QUOTE = '\'';
        public final String BRACKET_L = '(';
        public final String BRACKET_R = ')';
        protected String formedCondition;

        /**
         * @description Condition.
         */
        public Condition() {
            this.formedCondition = '';
        }

        protected String quote(String field) {
            return this.QUOTE + String.escapeSingleQuotes(field.trim()) + this.QUOTE;
        }

        protected String bracket(String field) {
            return BRACKET_L + field.trim() + BRACKET_R;
        }

        public virtual override String toString() {
            return this.formedCondition;
        }

        /**
         * @description Is Empty.
         * @return Boolean value.
         */
        public virtual Boolean isEmpty() {
            return String.isEmpty(this.toString());
        }
    }

    /**
     * @description SimpleCondition class.
     */
    public class SimpleCondition extends Condition {

        /**
         * @description Simple Condition.
         */
        public SimpleCondition() {
            super();
        }

        /**
         * @description Simple Condition.
         * @param condition The condition.
         */
        public SimpleCondition(String condition) {
            super();
            this.formedCondition = condition;
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is field-dependent.
     */
    public abstract class FieldCondition extends Condition {

        protected String fieldName;

        /**
         * @description Field Condition.
         * @param fieldName The field Name.
         */
        public FieldCondition(String fieldName) {
            super();
            this.fieldName = fieldName;
        }

        /**
         * @description Field Condition.
         * @param fieldName The field Name.
         */
        public FieldCondition(SObjectField fieldName) {
            super();
            this.fieldName = fieldName.getDescribe().getName();
        }

        public override Boolean isEmpty() {
            return String.isEmpty(this.fieldName);
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is field-dependent.
     * The condition compares fields with NULL.
     */
    public class NullCondition extends FieldCondition {

        /**
         * @description Null Condition.
         * @param fieldName The field Name.
         */
        public NullCondition(String fieldName) {
            super(fieldName);
        }

        /**
         * @description Null Condition.
         * @param fieldName The field Name.
         */
        public NullCondition(SObjectField fieldName) {
            super(fieldName);
        }

        //null
        /**
         * @description Is Null.
         * @return Condition value.
         */
        public Condition isNull() {
            this.formedCondition = this.fieldName + ' = NULL';
            return this;
        }

        /**
         * @description Not Null.
         * @return Condition value.
         */
        public Condition notNull() {
            this.formedCondition = this.fieldName + ' != NULL';
            return this;
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is field-dependent.
     * The condition compares fields with String/Boolean/Number/Date Typs.
     */
    public class CompareCondition extends FieldCondition {

        /**
         * @description Compare Condition.
         * @param fieldName The field Name.
         */
        public CompareCondition(String fieldName) {
            super(fieldName);
        }

        /**
         * @description Compare Condition.
         * @param fieldName The field Name.
         */
        public CompareCondition(SObjectField fieldName) {
            super(fieldName);
        }

        /**
         * @description Eq.
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition eq(Object fieldValue) {
            if (fieldValue == null) {
               return new NullCondition(this.fieldName).isNull();
            } else if (fieldValue instanceof String) {
                this.eq((String) fieldValue);
            } else if (fieldValue instanceof Decimal) {
                this.eq((Decimal) fieldValue);
            } else if (fieldValue instanceof Boolean) {
                this.eq((Boolean) fieldValue);
            } else if (fieldValue instanceof Date) {
                this.eq((Date) fieldValue);
            }

            return this;
        }

        /**
         * @description <p><b>Equals</b></p>
         * Check if the field EQUALS the String value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition eq(String fieldValue) {
            this.formedCondition = this.fieldName + ' = ' + this.quote(fieldValue);
            return this;
        }

        /**
         * @description <p><b>Equals</b></p>
         * Check if the field EQUALS OR NULL the String value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition eqon(String fieldValue) {
            if(fieldValue == null){
                return new NullCondition(this.fieldName).isNull();
            }
            this.formedCondition = this.fieldName + ' = ' + this.quote(fieldValue);
            return this;
        }

        /**
         * @description Ne.
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition ne(Object fieldValue) {
            if (fieldValue == null) {
                return new NullCondition(this.fieldName).notNull();
            } else if (fieldValue instanceof String) {
                this.ne((String) fieldValue);
            } else if (fieldValue instanceof Decimal) {
                this.ne((Decimal) fieldValue);
            } else if (fieldValue instanceof Boolean) {
                this.ne((Boolean) fieldValue);
            } else if (fieldValue instanceof Date) {
                this.ne((Date) fieldValue);
            }
            return this;
        }

        /**
         * @description <p><b>Not Equals</b></p>
         * Check if the field NOT EQUALS the String value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition ne(String fieldValue) {
            this.formedCondition = this.fieldName + ' != ' + this.quote(fieldValue);
            return this;
        }

        /**
         * @description <p><b>Equals</b></p>
         * Check if the field EQUALS the Boolean value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition eq(Boolean fieldValue) {
            this.formedCondition = this.fieldName + ' = ' + fieldValue;
            return this;
        }


        /**
         * @description <p><b>Not Equals</b></p>
         * Check if the field NOT EQUALS the Boolean value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition ne(Boolean fieldValue) {
            this.formedCondition = this.fieldName + ' != ' + fieldValue;
            return this;
        }

        /**
         * @description <p><b>Equals</b></p>
         * Check if the field EQUALS the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition eq(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' = ' + fieldValue;
            return this;
        }

        /**
         * @description <p><b>Lower than</b></p>
         * Check if the field LOWER THAN the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition lt(Object fieldValue) {
            if (fieldValue instanceof Decimal) {
                this.lt((Decimal) fieldValue);
            } else if (fieldValue instanceof Date) {
                this.lt((Date) fieldValue);
            }
            return this;
        }
        /**
         * @description <p><b>Lower than</b></p>
         * Check if the field LOWER THAN the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition lt(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' < ' + fieldValue;
            return this;
        }

        /**
         * @description <p><b>Lower than</b></p>
         * Check if the field LOWER THAN the Date value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition lt(Date fieldValue) {
            this.formedCondition = this.fieldName + ' < ' + String.valueOf(fieldValue);
            return this;
        }

        /**
         * @description <p><b>Lower than equals</b></p>
         * Check if the field LOWER THAN or EQUALS the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition lte(Object fieldValue) {
            if (fieldValue instanceof Decimal) {
                this.lte((Decimal) fieldValue);
            } else if (fieldValue instanceof Date) {
                this.lte((Date) fieldValue);
            }
            return this;
        }
        /**
         * @description <p><b>Lower than equals</b></p>
         * Check if the field LOWER THAN or EQUALS the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition lte(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' <= ' + fieldValue;
            return this;
        }

        /**
         * @description <p><b>Grater than equals</b></p>
         * Check if the field GRATER THAN or EQUALS the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition gte(Object fieldValue) {
            if (fieldValue instanceof Decimal) {
                this.gte((Decimal) fieldValue);
            } else if (fieldValue instanceof Date) {
                this.gte((Date) fieldValue);
            }
            return this;
        }
        /**
         * @description <p><b>Grater than equals</b></p>
         * Check if the field GRATER THAN or EQUALS the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition gte(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' >= ' + fieldValue;
            return this;
        }

        /**
         * @description <p><b>Not equals</b></p>
         * Check if the field NOT EQUALS the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition ne(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' != ' + fieldValue;
            return this;
        }


        /**
         * @description <p><b>Equals</b></p>
         * Check if the field EQUALS the Date value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition eq(Date fieldValue) {
            this.formedCondition = this.fieldName + ' = ' + String.valueOf(fieldValue);
            return this;
        }


        /**
         * @description <p><b>Not equals</b></p>
         * Check if the field NOT EQUALS the Date value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition ne(Date fieldValue) {
            this.formedCondition = this.fieldName + ' != ' + String.valueOf(fieldValue);
            return this;
        }

        /**
         * @description <p><b>Grater than</b></p>
         * Check if the field GRATER THAN the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition gt(Object fieldValue) {
            if (fieldValue instanceof Decimal) {
                this.gt((Decimal) fieldValue);
            } else if (fieldValue instanceof Date) {
                this.gt((Date) fieldValue);
            }
            return this;
        }
        /**
         * @description <p><b>Grater than</b></p>
         * Check if the field GRATER THAN the Number value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition gt(Decimal fieldValue) {
            this.formedCondition = this.fieldName + ' > ' + fieldValue;
            return this;
        }
        /**
         * @description <p><b>Grater than</b></p>
         * Check if the field GRATER THAN the Date value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition gt(Date fieldValue) {
            this.formedCondition = this.fieldName + ' > ' + String.valueOf(fieldValue);
            return this;
        }


        /**
         * @description <p><b>Lower than equals</b></p>
         * Check if the field LOWER THAN or EQUALS the Date value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition lte(Date fieldValue) {
            this.formedCondition = this.fieldName + ' <= ' + String.valueOf(fieldValue);
            return this;
        }


        /**
         * @description <p><b>Grater than equals</b></p>
         * Check if the field GRATER THAN or EQUALS the Date value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition gte(Date fieldValue) {
            this.formedCondition = this.fieldName + ' >= ' + String.valueOf(fieldValue);
            return this;
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is field-dependent.
     */
    public class LikeCondition extends FieldCondition {

        /**
         * @description Like Condition.
         * @param fieldName The field Name.
         */
        public LikeCondition(String fieldName) {
            super(fieldName);
        }

        /**
         * @description Like Condition.
         * @param fieldName The field Name.
         */
        public LikeCondition(SObjectField fieldName) {
            super(fieldName);
        }

        /**
         * @description <p><b>Like any</b></p>
         * Check if the field CONTAINS the String value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition likeAnyBoth(String fieldValue) {
            this.formedCondition = this.fieldName + ' LIKE ' + this.quote('%' + fieldValue + '%');
            return this;
        }


        /**
         * @description <p><b>Like end with</b></p>
         * Check if the field END WITH the String value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition likeAnyLeft(String fieldValue) {
            this.formedCondition = this.fieldName + ' LIKE ' + this.quote('%' + fieldValue);
            return this;
        }


        /**
         * @description <p><b>Like start with</b></p>
         * Check if the field START WITH the String value
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition likeAnyRight(String fieldValue) {
            this.formedCondition = this.fieldName + ' LIKE ' + this.quote(fieldValue + '%');
            return this;
        }

        /**
         * @description Not Like Any Both.
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition notLikeAnyBoth(String fieldValue) {
            this.formedCondition = 'NOT ' + this.fieldName + ' LIKE ' + this.quote('%' + fieldValue + '%');
            return this;
        }
    }

    /**
     * @description IncludeCondition class.
     */
    public class IncludeCondition extends FieldCondition {
        /**
         * @description Include Condition.
         * @param fieldName The field Name.
         */
        public IncludeCondition(String fieldName) {
            super(fieldName);
        }

        /**
         * @description Include Condition.
         * @param fieldName The field Name.
         */
        public IncludeCondition(SObjectField fieldName) {
            super(fieldName);
        }

        /**
         * @description Includes.
         * @param fieldValue The field Value.
         * @return Condition value.
         */
        public Condition includes(String fieldValue) {
            this.formedCondition = this.fieldName + ' INCLUDES ' + this.bracket(this.quote(fieldValue));
            return this;
        }

        /**
         * @description Includes.
         * @param fieldValues The field Values.
         * @return Condition value.
         */
        public Condition includes(Set<String> fieldValues) {
            String values = '';
            for (String fieldValue : fieldValues) {
                values += this.quote(fieldValue) + ',';
            }
            this.formedCondition = this.fieldName + ' INCLUDES ' + this.bracket(values.removeEnd(','));
            return this;
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is field-dependent.
     * The condition compares fields with collections.
     */
    public class InCondition extends FieldCondition {

        /**
         * @description In Condition.
         * @param fieldName The field Name.
         */
        public InCondition(String fieldName) {
            super(fieldName);
        }

        /**
         * @description In Condition.
         * @param fieldName The field Name.
         */
        public InCondition(SObjectField fieldName) {
            super(fieldName);
        }

        /**
         * @description In Collection.
         * @param queryBuilder The query Builder.
         * @return Condition value.
         */
        public Condition inCollection(QueryBuilder queryBuilder) {
            this.formedCondition = this.fieldName + ' IN ' + this.bracket(queryBuilder.toString());
            return this;
        }

        //in - set
        /**
         * @description In Collection.
         * @param inList The in List.
         * @return Condition value.
         */
        public Condition inCollection(List<SObject> inList) {
            return this.inCollection(new Map<Id, SObject>(inList));
        }

        /**
         * @description In Collection.
         * @param inKeySet The in Key Set.
         * @return Condition value.
         */
        public Condition inCollection(Map<Id, SObject> inKeySet) {
            return this.inCollection(inKeySet.keySet());
        }

        /**
         * @description In Collection.
         * @param inSet The in Set.
         * @return Condition value.
         */
        public Condition inCollection(Set<String> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inSet);
            return this;
        }

        /**
         * @description In Collection.
         * @param inSet The in Set.
         * @return Condition value.
         */
        public Condition inCollection(Set<Id> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inSet);
            return this;
        }

        /**
         * @description In Collection.
         * @param inSet The in Set.
         * @return Condition value.
         */
        public Condition inCollection(Set<Decimal> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildInNoQuote(inSet);
            return this;
        }

        //set helpers
        private String buildIn(Set<String> inSet) {
            return this.bracket(
                    this.QUOTE
                            + String.join(new List<String> (inSet), this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildIn(Set<Id> inSet) {
            return this.bracket(
                    this.QUOTE
                            + String.join(new List<Id> (inSet), this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildInNoQuote(Set<Decimal> inSet) {
            return this.bracket(String.join(new List<Decimal> (inSet), ', '));
        }


        //in - list
        /**
         * @description In Collection.
         * @param inList The in List.
         * @return Condition value.
         */
        public Condition inCollection(List<Id> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inList);
            return this;
        }

        /**
         * @description In Collection.
         * @param inList The in List.
         * @return Condition value.
         */
        public Condition inCollection(List<String> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inList);
            return this;
        }

        /**
         * @description In Collection.
         * @param inList The in List.
         * @return Condition value.
         */
        public Condition inCollection(List<Decimal> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' IN ' + this.buildInNoQuote(inList);
            return this;
        }

        /**
         * @description In Collection.
         * @param inList The in List.
         * @return Condition value.
         */
        public Condition inCollection(List<PicklistEntry> inList) {
            if (inList.isEmpty()) {
                this.formedCondition = '';
            }
            Set<String> picklistEntryValues = new Set<String>();
            for (PicklistEntry entry : inList) {
                picklistEntryValues.add(entry.value);
            }
            this.inCollection(picklistEntryValues);
            return this;
        }

        //list helpers
        private String buildIn(List<String> inList) {
            return this.bracket(
                    +this.QUOTE
                            + String.join(inList, this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildIn(List<Id> inList) {
            return this.bracket(
                    +this.QUOTE
                            + String.join(inList, this.QUOTE + ', ' + this.QUOTE)
                            + this.QUOTE
            );
        }

        private String buildInNoQuote(List<Decimal> inList) {
            return this.bracket(String.join(inList, ', '));
        }


        //not in
        /**
         * @description Not In.
         * @param inList The in List.
         * @return Condition value.
         */
        public Condition notIn(List<SObject> inList) {
            return this.notIn(new Map<Id, SObject>(inList));
        }

        /**
         * @description Not In.
         * @param inSet The in Set.
         * @return Condition value.
         */
        public Condition notIn(Map<Id, SObject> inSet) {
            return this.notIn(inSet.keySet());
        }

        /**
         * @description Not In.
         * @param inSet The in Set.
         * @return Condition value.
         */
        public Condition notIn(Set<Id> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
                return this;
            }
            this.formedCondition = this.fieldName + ' NOT IN ' + this.buildIn(inSet);
            return this;
        }

        /**
         * @description Not In.
         * @param inSet The in Set.
         * @return Condition value.
         */
        public Condition notIn(Set<String> inSet) {
            if (inSet.isEmpty()) {
                this.formedCondition = '';
            }
            this.formedCondition = this.fieldName + ' NOT IN ' + this.buildIn(inSet);
            return this;
        }

        /**
         * @description Not In.
         * @param queryBuilder The query Builder.
         * @return Condition value.
         */
        public Condition notIn(QueryBuilder queryBuilder) {
            String builtSubQuery = queryBuilder.toString();
            if (String.isEmpty(builtSubQuery)) {
                this.formedCondition = '';
                return this;
            }
            this.formedCondition = this.fieldName + ' NOT IN ' + this.bracket(builtSubQuery);
            return this;
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is field-dependent.
     * The complex condition.
     */
    public class ComplexCondition extends Condition {

        private Condition startCondition;
        private List<String> conditionsOrder;
        private List<Condition> conditions;

        /**
         * @description Complex Condition.
         */
        public ComplexCondition() {
            super();
            this.startCondition = null;
            this.conditions = new List<Condition>();
            this.conditionsOrder = new List<String>();
        }

        /**
         * @description Start Condition.
         * @param condition The condition.
         * @return ComplexCondition value.
         */
        public ComplexCondition startCondition(Condition condition) {
            if (!condition.isEmpty()) {
                this.startCondition = condition;
            }
            return this;
        }

        /**
         * @description Or Condition.
         * @param condition The condition.
         * @return ComplexCondition value.
         */
        public ComplexCondition orCondition(Condition condition) {
            if (this.startCondition == null) {
                return this.startCondition(condition);
            }
            this.conditions.add(condition);
            this.conditionsOrder.add('OR');
            return this;
        }

        /**
         * @description And Condition.
         * @param condition The condition.
         * @return ComplexCondition value.
         */
        public ComplexCondition andCondition(Condition condition) {
            if (this.startCondition == null) {
                return this.startCondition(condition);
            }
            this.conditions.add(condition);
            this.conditionsOrder.add('AND');
            return this;
        }

        /**
         * @description Build.
         * @return ComplexCondition value.
         */
        public ComplexCondition build() {
            if (this.startCondition == null) {
                this.formedCondition = '';
                return this;
            }
            this.formedCondition = this.startCondition.toString() + ' ';
            for (Integer i = 0; i < conditions.size(); i++) {
                String conditionOrder = this.conditionsOrder[i];
                Condition condition = this.conditions[i];
                this.formedCondition += conditionOrder + ' ' + condition.toString() + ' ';
            }
            this.formedCondition = this.bracket(this.formedCondition);
            return this;
        }

        public override Boolean isEmpty() {
            return this.startCondition == null;
        }

        public override String toString() {
            this.build();
            return this.formedCondition;
        }

        /**
         * @description Add Order If Not Empty.
         * @param order The order.
         * @return String value.
         */
        public String addOrderIfNotEmpty(String order) {
            if (this.isEmpty()) {
                return '';
            }
            return ' ' + order;
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is Object-type dependent.
     */
    public abstract class ObjectTypeDependentCondition extends Condition {

        private String objectType;

        /**
         * @description Object Type Dependent Condition.
         */
        public ObjectTypeDependentCondition() {
            super();
        }

        /**
         * @description Set Related Object Type.
         * @param objectType The object Type.
         */
        public void setRelatedObjectType(String objectType) {
            this.objectType = objectType;
        }
    }

    /**
     * Abstract class, which represent a condition, which can be added into ConditionsManager.
     * The condition is Object-type dependent.
     * The condition compares recordTypeId by Record Type DeveloperName.
     */
    public class RecordTypeCondition extends ObjectTypeDependentCondition {

        private String recordTypeName;

        /**
         * @description Record Type Condition.
         * @param recordTypeName The record Type Name.
         */
        public RecordTypeCondition(String recordTypeName) {
            super();
            this.recordTypeName = recordTypeName;
        }

        private Id getRecordTypeId() {
            return Schema.getGlobalDescribe().get(this.objectType).getDescribe().getRecordTypeInfosByDeveloperName().get(this.recordTypeName).getRecordTypeId();
        }

        public override String toString() {
            this.formedCondition = 'RecordTypeId = ' + this.quote(this.getRecordTypeId());
            return this.formedCondition;
        }
    }

    /**
     * Virtual class for creating Order in Query.
     *
     */
    public virtual class Order {

        private final String sortingField;
        private String sortingOrder;
        private String nullsOrder;

        protected Order(String sortingField, String sortingOrder, String nullsOrder) {
            this.sortingField = sortingField;
            this.sortingOrder = sortingOrder;
            this.nullsOrder = nullsOrder;
        }

        protected Order(String sortingField, String sortingOrder) {
            this(sortingField, sortingOrder, '');
        }

        /**
         * @description Order.
         * @param sortingField The sorting Field.
         */
        public Order(String sortingField) {
            this(sortingField, 'ASC', '');
        }

        /**
         * @description Order.
         * @param sortingField The sorting Field.
         */
        public Order(SObjectField sortingField) {
            this(sortingField.getDescribe().getName());
        }

        /**
         * @description Set Sorting Order.
         * @param sortingOrder The sorting Order.
         * @return Order value.
         */
        public Order setSortingOrder(String sortingOrder) {
            this.sortingOrder = sortingOrder;
            return this;
        }

        /**
         * @description Set Sorting Order Asc.
         * @return Order value.
         */
        public Order setSortingOrderAsc() {
            return this.setSortingOrder('ASC');
        }

        /**
         * @description Set Sorting Order Desc.
         * @return Order value.
         */
        public Order setSortingOrderDesc() {
            return this.setSortingOrder('DESC');
        }

        /**
         * @description Set Nulls Order.
         * @param nullsOrder The nulls Order.
         * @return Order value.
         */
        public Order setNullsOrder(String nullsOrder) {
            this.nullsOrder = nullsOrder;
            return this;
        }

        /**
         * @description Set Nulls Order First.
         * @return Order value.
         */
        public Order setNullsOrderFirst() {
            return this.setNullsOrder('FIRST');
        }

        /**
         * @description Set Nulls Order Last.
         * @return Order value.
         */
        public Order setNullsOrderLast() {
            return this.setNullsOrder('LAST');
        }

        public override String toString() {
            return this.sortingField
                    + ' ' + this.sortingOrder
                    + (String.isNotEmpty(this.nullsOrder) ? ' NULLS ' + this.nullsOrder : '');
        }
    }

    /**
     * Class for ordering records Ascending.
     *
     */
    public class AscOrder extends Order {

        /**
         * @description Asc Order.
         * @param sortingField The sorting Field.
         */
        public AscOrder(String sortingField) {
            super(sortingField, 'ASC');
        }
    }

    /**
     * Class for ordering records Descending.
     *
     */
    public class DescOrder extends Order {

        /**
         * @description Desc Order.
         * @param sortingField The sorting Field.
         */
        public DescOrder(String sortingField) {
            super(sortingField, 'DESC');
        }
    }

    /**
     * Class, which performs access validation of SObject/SObject field.
     * Can check CRUD and FLS.
     */
    public class SObjectAccessValidator {
        private String ERROR_NO_ACCESS_ON_OBJECT = 'Insufficient access on {0} Object';
        private String ERROR_NO_ACCESS_ON_FIELD = 'Insufficient access: No such field(s) [{0}] on {1} Object';
        private List<String> fields;
        private DescribeSObjectResult describedSObjectType;
        @TestVisible
        private Map<String, ChildRelationship> childRelationshipsByName {
            get {
                if (this.childRelationshipsByName == null) {
                    this.childRelationshipsByName = new Map<String, ChildRelationship>();
                    for (ChildRelationship childRelationship : this.describedSObjectType.getChildRelationships()) {
                        this.childRelationshipsByName.put(childRelationship.getRelationshipName(), childRelationship);
                    }
                }
                return this.childRelationshipsByName;
            }
            set;
        }

        /**
         * @description S Object Access Validator.
         * @param sObjectName The s Object Name.
         * @param fields The fields.
         */
        public SObjectAccessValidator(String sObjectName, List<String> fields) {
            this.describedSObjectType = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
            this.fields = fields;
        }

        /**
         * @description S Object Access Validator.
         * @param sObjectName The s Object Name.
         * @param fields The fields.
         */
        public SObjectAccessValidator(String sObjectName, Set<String> fields) {
            this.describedSObjectType = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
            List<String> listFields = new List<String>();
            listFields.addAll(fields);
            this.fields = listFields;
        }

        /**
         * @description S Object Access Validator.
         * @param sObjectName The s Object Name.
         * @param fields The fields.
         */
        public SObjectAccessValidator(String sObjectName, List<SObjectField> fields) {
            this.describedSObjectType = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
            this.fields = new List<String>();
            for (SObjectField field : fields) {
                this.fields.add(field.getDescribe().getName());
            }
        }

        /**
         * @description S Object Access Validator.
         * @param sObjectDescribe The s Object Describe.
         * @param fields The fields.
         */
        public SObjectAccessValidator(DescribeSObjectResult sObjectDescribe, List<String> fields) {
            this.describedSObjectType = sObjectDescribe;
            this.fields = fields;
        }

        /**
         * @description S Object Access Validator.
         * @param sObjectDescribe The s Object Describe.
         * @param fields The fields.
         */
        public SObjectAccessValidator(DescribeSObjectResult sObjectDescribe, Set<String> fields) {
            this.describedSObjectType = sObjectDescribe;
            List<String> listFields = new List<String>();
            listFields.addAll(fields);
            this.fields = listFields;
        }

        /**
         * @description S Object Access Validator.
         * @param sObjectDescribe The s Object Describe.
         * @param fields The fields.
         */
        public SObjectAccessValidator(DescribeSObjectResult sObjectDescribe, List<SObjectField> fields) {
            this.describedSObjectType = sObjectDescribe;
            this.fields = new List<String>();
            for (SObjectField field : fields) {
                this.fields.add(field.getDescribe().getName());
            }
        }

        /**
         * @description S Object Access Validator.
         * @param sObjectType The s Object Type.
         * @param fields The fields.
         */
        public SObjectAccessValidator(SObjectType sObjectType, List<String> fields) {
            this(sObjectType.getDescribe(), fields);
        }

        /**
         * @description S Object Access Validator.
         * @param sObjectType The s Object Type.
         * @param fields The fields.
         */
        public SObjectAccessValidator(SObjectType sObjectType, Set<String> fields) {
            this(sObjectType.getDescribe(), new List<String>(fields));
        }

        /**
         * @description S Object Access Validator.
         * @param sObjectType The s Object Type.
         * @param fields The fields.
         */
        public SObjectAccessValidator(SObjectType sObjectType, List<SObjectField> fields) {
            this(sObjectType.getDescribe(), fields);
        }

        /**
         * @description Validate.
         */
        public void validate() {
            this.checkObjectLevelAccess();
            this.checkFieldLevelAccess();
        }

        /**
         * @description Check Object Level Access.
         */
        public void checkObjectLevelAccess() {
            if (!this.describedSObjectType.isAccessible() || !this.describedSObjectType.isQueryable()) {
                System.NoAccessException noAccessException = new System.NoAccessException();
                noAccessException.setMessage(String.format(
                        ERROR_NO_ACCESS_ON_OBJECT,
                        new List<String>{
                                describedSObjectType.getName()
                        }));
                throw noAccessException;
            }
        }

        /**
         * @description Check Field Level Access.
         */
        public void checkFieldLevelAccess() {
            List<String> notAccessibleFields = new List<String>();
            Map<String, SObjectField> allFieldsByName = this.describedSObjectType.fields.getMap();
            for (String field : this.fields) {
                String fieldName = getFieldName(field);
                if (isRelationshipField(fieldName)) {
                    try {
                        validateRelationshipField(fieldName);
                    } catch (Exception ex) {
                        System.debug(ex.getMessage() + ' ' + ex.getLineNumber());
                        notAccessibleFields.add(fieldName);
                    }
                    continue;
                }

                if (allFieldsByName.containsKey(fieldName) && allFieldsByName.get(fieldName).getDescribe().isAccessible()) {
                    continue;
                }

                notAccessibleFields.add(fieldName);
            }

            if (!notAccessibleFields.isEmpty()) {
                NoAccessException noAccessException = new NoAccessException();
                noAccessException.setMessage(String.format(
                        ERROR_NO_ACCESS_ON_FIELD,
                        new List<String>{
                                String.join(notAccessibleFields, ', '),
                                describedSObjectType.getName()
                        }));
                throw noAccessException;
            }
        }

        private void validateRelationshipField(String field) {
            String relationshipFieldName = field.split('\\.')[0];
            String parentFieldNames = field.substring(field.indexOf('.') + 1);
            new SObjectAccessValidator(
                    getSObjectType(relationshipFieldName),
                    new List<String>{
                            parentFieldNames
                    }
            ).validate();
        }

        private SObjectType getSObjectType(String relationshipName) {
            for (Schema.SObjectField field : this.describedSObjectType.fields.getMap().values()) {
                DescribeFieldResult dfResult = field.getDescribe();
                if (dfResult.getRelationshipName() == relationshipName) {
                    return dfResult.getReferenceTo()[0];
                }
            }
            return null;
        }

        private Boolean isRelationshipField(String field) {
            return field.contains('.');
        }

        private String getFieldName(String soqlField) {
            String fieldName = soqlField.trim();
            if (fieldName.contains(' ')) fieldName = fieldName.split(' ')[0];

            if (fieldName.contains('(')) {
                System.debug(fieldName);
                fieldName = fieldName.substring(fieldName.indexOf('(') + 1, fieldName.indexOf(')'));
            }
            return fieldName;
        }
    }

    /**
     * @description Adds all fields of the related SObject, specified in param as an String.
     *
     * Example
     * new QueryBuilder()
     *     .addFieldsAllMerged('Contact');
     * @param field The field.
     * @return QueryBuilder value.
     */
    public QueryBuilder addFieldsAllMerged(String field) {
        DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe()
                .get(fromSobject)
                .getDescribe()
                .fields
                .getMap()
                .get(field)
                .getDescribe();

        List<SObjectType> referenceTypes = fieldDescribe.getReferenceTo();
        if (referenceTypes == null || referenceTypes.isEmpty()) {
            return this;
        }

        Set<String> referenceObjectFields = referenceTypes[0].getDescribe().fields.getMap().keySet();
        String referenceName = fieldDescribe.getRelationshipName();
        for (String referenceField : referenceObjectFields) {
            this.fieldTokens.add(referenceName + '.' + referenceField);
        }
        return this;
    }

    /**
     * Query Builder Exception
     *
     */
    public class QueryBuilderException extends Exception {
    }

    /**
     * Query Builder Exception
     * CRUD / FLS Exception
     *
     */
    public class NoAccessException extends Exception {}
}