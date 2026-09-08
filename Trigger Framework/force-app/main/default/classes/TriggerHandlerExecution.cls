/**
 * @description TriggerHandlerExecution class.
 */
@SuppressWarnings('PMD.ApexDangerousMethods,PMD.AvoidDebugStatements,PMD.DebugsShouldUseLoggingLevel,PMD.FieldNamingConventions')
public with sharing class TriggerHandlerExecution {
    public static Boolean BYPASS = false;

    /**
     * @description Maximum number of times the same handler may be re-entered for the same SObject
     * and trigger operation within one transaction. Raise or lower it at runtime when a legitimate
     * cascade needs more depth.
     */
    public static Integer MAX_RECURSION_DEPTH = 5;

    /**
     * Transaction scoped re-entrancy counters, keyed by object + operation + handler class.
     */
    @TestVisible
    private static final Map<String, Integer> RECURSION_DEPTH = new Map<String, Integer>();

    private static TriggerHandlerExecution instance;
    private final Map<Type, HandlerExecutor> handlerPool;
    private TriggerHandlerExecution() {
        this.handlerPool = new Map<Type, HandlerExecutor>();
    }

    /**
     * @description Clears the recursion counters. Intended for tests and for long running
     * transactions that deliberately restart a cascade.
     */
    public static void resetRecursionDepth() {
        RECURSION_DEPTH.clear();
    }

    /**
     * @description Raised when a handler re-enters itself more than MAX_RECURSION_DEPTH times for
     * the same SObject and trigger operation.
     */
    public class TriggerRecursionException extends Exception {
    }
    
    /**
     * @description Get Instance.
     * @return TriggerHandlerExecution value.
     */
    public static TriggerHandlerExecution getInstance() {
        if (TriggerHandlerExecution.instance == null) {
            TriggerHandlerExecution.instance = new TriggerHandlerExecution();
        }
        return TriggerHandlerExecution.instance;
    }
    
    /**
     * @description Get Handler.
     * @param typeName The type Name.
     * @return HandlerExecutor value.
     */
    public HandlerExecutor getHandler(Type typeName) {
        HandlerExecutor executor = this.handlerPool.get(typeName);
        if (executor == null) {
            executor = new HandlerExecutor(typeName);
            this.handlerPool.put(typeName, executor);
        }
        return executor;
    }
    
    /**
     * @description HandlerExecutor class.
     */
    public class HandlerExecutor {
        private Type typeName;
        private HandlerExecutor(Type typeName) {
            this.typeName = typeName;
        }
        
        /**
         * @description Execute.
         */
        public void execute() {
            this.execute(Trigger.operationType);
        }

        @TestVisible
        private void execute(TriggerOperation operationType) {
            String objectApiName = this.typeName.toString();
            System.debug(LoggingLevel.INFO, 'Trigger Bypassed:: ' + BYPASS);
            if (AutomationBypass.isBypassed(objectApiName)) {
                System.debug(LoggingLevel.INFO, 'All automation bypassed for : ' + objectApiName);
                return;
            }
            MetadataHandler metadataHandler = new MetadataHandler(this.typeName);
            List<Trigger_Factory__mdt> handlersToExecute = metadataHandler.getMeta();
            for (Trigger_Factory__mdt handlerMeta : handlersToExecute) {
                if (!AutomationBypass.isBypassed(handlerMeta)) {
                    this.executeHandler(handlerMeta, operationType);
                }
            }
        }
        
        private void executeHandler(Trigger_Factory__mdt handlerMeta, TriggerOperation operationType) {
            Integer cpu = Limits.getCpuTime();
            System.debug('initialize time : ' + (Limits.getCpuTime() - cpu));
            Type handlerType = Type.forName(handlerMeta.NamespacePrefix, handlerMeta.Class_Name__c);
            if (handlerType == null) {
                this.logNoApplicableClassError(handlerMeta);
                return;
            }
            String depthKey = this.typeName + '|' + operationType + '|' + handlerMeta.Class_Name__c;
            this.enterHandler(depthKey, handlerMeta);
            try {
                TriggerFactoryHandler handler = (TriggerFactoryHandler) handlerType.newInstance();
                handler.setName(handlerMeta.Class_Name__c);
                System.debug('Executing : ' + handler.getName() + ' for : ' + this.typeName);
                handler.setSobjectType(this.typeName);
                this.callAppropriateContext(handler, operationType);
            } finally {
                this.exitHandler(depthKey);
            }
        }

        private void enterHandler(String depthKey, Trigger_Factory__mdt handlerMeta) {
            Integer depth = RECURSION_DEPTH.containsKey(depthKey) ? RECURSION_DEPTH.get(depthKey) : 0;
            if (depth >= MAX_RECURSION_DEPTH) {
                throw new TriggerRecursionException(
                    'Maximum recursion depth of ' +
                        MAX_RECURSION_DEPTH +
                        ' exceeded for handler "' +
                        handlerMeta.Class_Name__c +
                        '" on ' +
                        this.typeName +
                        '. Check for a handler that re-triggers itself, or raise ' +
                        'TriggerHandlerExecution.MAX_RECURSION_DEPTH.'
                );
            }
            RECURSION_DEPTH.put(depthKey, depth + 1);
        }

        private void exitHandler(String depthKey) {
            Integer depth = RECURSION_DEPTH.get(depthKey);
            if (depth != null && depth > 0) {
                RECURSION_DEPTH.put(depthKey, depth - 1);
            }
        }
        
        private void callAppropriateContext(TriggerFactoryHandler handler, TriggerOperation operationType) {
            TriggerFactoryHandler.TriggerContext context = new TriggerFactoryHandler.TriggerContext();
            
            switch on operationType {
                when BEFORE_INSERT {
                    handler.beforeInsert(context);
                }
                when BEFORE_UPDATE {
                    handler.beforeUpdate(context);
                }
                when BEFORE_DELETE {
                    handler.beforeDelete(context);
                }
                when AFTER_INSERT {
                    handler.afterInsert(context);
                }
                when AFTER_UPDATE {
                    handler.afterUpdate(context);
                }
                when AFTER_DELETE {
                    handler.afterDelete(context);
                }
                when AFTER_UNDELETE {
                    handler.afterUnDelete(context);
                }
                when else {
                    System.debug(LoggingLevel.INFO, 'No trigger operation type available, nothing to dispatch.');
                }
            }
        }
        
        private void logNoApplicableClassError(Trigger_Factory__mdt handlerMeta) {
            System.debug('\n\nHandlerExecutionPool: creating handler "'
                    + (String.isEmpty(handlerMeta.NamespacePrefix) ? '' : handlerMeta.NamespacePrefix) + handlerMeta.Class_Name__c
                    + '" encountered an error:\nNo applicable class was found. Probably the class was removed or renamed.\n');
        }
    }
    
    private class MetadataHandler {
        private List<Trigger_Factory__mdt> handlersMeta;
        /**
         * @description Metadata Handler.
         * @param typeName The type Name.
         */
        public MetadataHandler(Type typeName) {
            this.handlersMeta = this.readHandlersMetadata(typeName);
        }
        /**
         * @description Get Meta.
         * @return List<Trigger_Factory__mdt> value.
         */
        public List<Trigger_Factory__mdt> getMeta() {
            return this.handlersMeta;
        }
        private List<Trigger_Factory__mdt> readHandlersMetadata(Type typeName) {
            return AutomationBypass.getActiveConfig(typeName.toString());
        }
    }
}