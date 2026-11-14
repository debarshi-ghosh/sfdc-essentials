/**
 * @description Interface for community action handlers.
 *              Implement this interface to add a new quick action that can be
 *              invoked from Experience Cloud via the generic dispatcher.
 *
 *              Steps to add a new action:
 *              1. Create a class implementing ICommunityAction
 *              2. Register it with a Community_Action_Handler__mdt record
 */
public interface ICommunityAction {
    /**
     * @description Execute the action for the given record.
     * @param recordId The Id of the record to act upon.
     * @return CommunityActionResult describing what the UI should do.
     */
    CommunityActionResult execute(Id recordId);
}