/**
 * @description TriggerFactoryHandler class.
 */
@SuppressWarnings('PMD.EmptyStatementBlock')
public abstract with sharing class TriggerFactoryHandler {
    protected Type typeName;
    private String name;

    /**
     * @description VRM Trigger Factory Handler.
     */
    public TriggerFactoryHandler() {
    }

    protected virtual void onBeforeInsert(TriggerContext context) {
    }

    protected virtual void onBeforeUpdate(TriggerContext context) {
    }

    protected virtual void onBeforeDelete(TriggerContext context) {
    }

    protected virtual void onAfterInsert(TriggerContext context) {
    }

    protected virtual void onAfterUpdate(TriggerContext context) {
    }

    protected virtual void onAfterDelete(TriggerContext context) {
    }

    protected virtual void onAfterUnDelete(TriggerContext context) {
    }

    /**
     * @description Before Insert.
     * @param context The context.
     */
    public void beforeInsert(TriggerContext context) {
        this.logBeforeEventHandling(context);
        this.onBeforeInsert(context);
        this.logAfterEventHandling(context);
    }

    /**
     * @description Before Update.
     * @param context The context.
     */
    public void beforeUpdate(TriggerContext context) {
        this.logBeforeEventHandling(context);
        this.onBeforeUpdate(context);
        this.logAfterEventHandling(context);
    }

    /**
     * @description Before Delete.
     * @param context The context.
     */
    public void beforeDelete(TriggerContext context) {
        this.logBeforeEventHandling(context);
        this.onBeforeDelete(context);
        this.logAfterEventHandling(context);
    }

    /**
     * @description After Insert.
     * @param context The context.
     */
    public void afterInsert(TriggerContext context) {
        this.logBeforeEventHandling(context);
        this.onAfterInsert(context);
        this.logAfterEventHandling(context);
    }

    /**
     * @description After Update.
     * @param context The context.
     */
    public void afterUpdate(TriggerContext context) {
        this.logBeforeEventHandling(context);
        this.onAfterUpdate(context);
        this.logAfterEventHandling(context);
    }

    /**
     * @description After Delete.
     * @param context The context.
     */
    public void afterDelete(TriggerContext context) {
        this.logBeforeEventHandling(context);
        this.onAfterDelete(context);
        this.logAfterEventHandling(context);
    }

    /**
     * @description After Un Delete.
     * @param context The context.
     */
    public void afterUnDelete(TriggerContext context) {
        this.logBeforeEventHandling(context);
        this.onAfterUnDelete(context);
        this.logAfterEventHandling(context);
    }

    /**
     * @description Set Sobject Type.
     * @param typeName The type Name.
     */
    public void setSobjectType(Type typeName) {
        this.typeName = typeName;
        this.sobjectTypeSetupCallback(typeName);
    }
    
    /**
     * @description Set Name.
     * @param name The name.
     */
    public void setName(String name) {
        this.name = name;
    }
    
    /**
     * @description Get Name.
     * @return String value.
     */
    public String getName() {
        return this.name;
    }
    
    /**
     * @description Get Type Name.
     * @return Type value.
     */
    public Type getTypeName() {
        return this.typeName;
    }
    
    protected virtual void sobjectTypeSetupCallback(Type typeName) {
    }
    
    protected virtual void logBeforeEventHandling(TriggerContext context) {
    }

    protected virtual void logAfterEventHandling(TriggerContext context) {
    }

    /**
     * @description TriggerContext class.
     */
    public virtual class TriggerContext {
        public List<SObject> newList;
        public Map<Id, SObject> newMap;
        public List<SObject> oldList;
        public Map<Id, SObject> oldMap;
        public Integer size;
        public TriggerOperation operationType;


        /**
         * @description Trigger Context.
         */
        public TriggerContext() {
            this.newList = Trigger.new;
            this.newMap = Trigger.newMap;
            this.oldList = Trigger.old;
            this.oldMap = Trigger.oldMap;
            this.size = Trigger.size;
            this.operationType = Trigger.operationType;
        }
    }
}