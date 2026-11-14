/**
 * @description Generic dispatcher for community quick actions.
 *              Routes action names to their handler classes using the
 *              Community_Action_Handler__mdt registry, so new actions can be
 *              added by configuration without touching this class.
 *
 *              To register a new action:
 *              1. Create a class implementing ICommunityAction
 *              2. Add a Community_Action_Handler__mdt record with the action
 *                 API name and the handler class name
 */
public with sharing class CommunityActionDispatcher {

    /**
     * @description Cached registry of action name -> handler class name.
     *              Tests can assign this directly to bypass custom metadata.
     */
    @TestVisible
    private static Map<String, String> actionHandlerMap;

    /**
     * @description Builds (and caches) the handler registry from custom metadata.
     * @return Map of configured action names to handler class names.
     */
    private static Map<String, String> getActionHandlerMap() {
        if (actionHandlerMap == null) {
            actionHandlerMap = new Map<String, String>();
            for (Community_Action_Handler__mdt config : Community_Action_Handler__mdt.getAll().values()) {
                if (config.Is_Active__c
                    && String.isNotBlank(config.Action_Name__c)
                    && String.isNotBlank(config.Handler_Class__c)) {
                    actionHandlerMap.put(config.Action_Name__c, config.Handler_Class__c);
                }
            }
        }
        return actionHandlerMap;
    }

    /**
     * @description Execute a community action by routing to the appropriate handler.
     * @param actionName The full action API name (e.g., 'My_Object__c.View_Invoice').
     * @param recordId The record Id to execute the action on.
     * @return CommunityActionResult with instructions for the UI.
     */
    @AuraEnabled
    public static CommunityActionResult executeAction(String actionName, Id recordId) {
        if (String.isBlank(actionName) || recordId == null) {
            return CommunityActionResult.toast('Error', 'Invalid action or record.', 'error');
        }

        String handlerClassName = resolveHandler(actionName);
        if (String.isBlank(handlerClassName)) {
            return CommunityActionResult.toast('Error', 'No handler registered for action: ' + actionName, 'error');
        }

        try {
            Type handlerType = Type.forName(handlerClassName);
            if (handlerType == null) {
                return CommunityActionResult.toast('Error', 'Handler class not found: ' + handlerClassName, 'error');
            }

            ICommunityAction handler = (ICommunityAction) handlerType.newInstance();
            return handler.execute(recordId);
        } catch (Exception e) {
            return CommunityActionResult.toast('Error', e.getMessage(), 'error');
        }
    }

    /**
     * @description Resolves the handler class name for a given action name.
     *              An exact configured match wins; otherwise the first configured
     *              name contained in the incoming action name is used.
     * @param actionName The action name to look up.
     * @return The handler class name, or null if not found.
     */
    private static String resolveHandler(String actionName) {
        Map<String, String> registry = getActionHandlerMap();
        if (registry.containsKey(actionName)) {
            return registry.get(actionName);
        }
        for (String key : registry.keySet()) {
            if (actionName.contains(key)) {
                return registry.get(key);
            }
        }
        return null;
    }
}