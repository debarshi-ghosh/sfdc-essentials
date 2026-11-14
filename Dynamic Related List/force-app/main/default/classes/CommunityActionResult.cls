/**
 * @description Generic result wrapper returned by community action handlers.
 *              The UI component uses the resultType to decide what to do:
 *              - OPEN_URL: Opens a URL in a new tab
 *              - TOAST: Shows a toast notification
 *              - NAVIGATE: Navigates to a record or page
 */
public class CommunityActionResult {

    @AuraEnabled public String resultType;
    @AuraEnabled public Boolean success;
    @AuraEnabled public String url;
    @AuraEnabled public String message;
    @AuraEnabled public String variant;
    @AuraEnabled public String title;
    @AuraEnabled public String recordId;

    /**
     * @description Create a result that instructs the UI to open a URL.
     * @param targetUrl The URL to open in a new tab.
     * @return CommunityActionResult configured for URL opening.
     */
    public static CommunityActionResult openUrl(String targetUrl) {
        CommunityActionResult result = new CommunityActionResult();
        result.resultType = 'OPEN_URL';
        result.success = true;
        result.url = targetUrl;
        return result;
    }

    /**
     * @description Create a result that instructs the UI to show a toast.
     * @param toastTitle Title of the toast.
     * @param toastMessage Message body of the toast.
     * @param toastVariant Variant: success, error, warning, info.
     * @return CommunityActionResult configured for toast display.
     */
    public static CommunityActionResult toast(String toastTitle, String toastMessage, String toastVariant) {
        CommunityActionResult result = new CommunityActionResult();
        result.resultType = 'TOAST';
        result.success = toastVariant != 'error';
        result.title = toastTitle;
        result.message = toastMessage;
        result.variant = toastVariant;
        return result;
    }

    /**
     * @description Create a result that instructs the UI to navigate to a record.
     * @param targetRecordId The record Id to navigate to.
     * @return CommunityActionResult configured for navigation.
     */
    public static CommunityActionResult navigate(Id targetRecordId) {
        CommunityActionResult result = new CommunityActionResult();
        result.resultType = 'NAVIGATE';
        result.success = true;
        result.recordId = targetRecordId;
        return result;
    }
}