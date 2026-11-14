import { LightningElement, wire } from 'lwc';
import { subscribe, MessageContext } from 'lightning/messageService';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DYNAMIC_QUICK_ACTION from '@salesforce/messageChannel/DynamicQuickAction__c';
import executeAction from '@salesforce/apex/CommunityActionDispatcher.executeAction';

/**
 * @description Generic subscriber component for handling quick actions in Experience Cloud.
 *              Place this component on any community page where quick actions need
 *              to be processed. It listens to DynamicQuickAction messages, calls the
 *              generic Apex dispatcher, and processes the result (open URL / show toast / navigate).
 *
 *              No action-specific logic lives here. To add a new action:
 *              1. Create a class implementing ICommunityAction
 *              2. Register it with a Community_Action_Handler__mdt record
 */
export default class CommunityActionHandler extends NavigationMixin(LightningElement) {
    subscription = null;

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToChannel();
    }

    subscribeToChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                DYNAMIC_QUICK_ACTION,
                (message) => this.handleMessage(message)
            );
        }
    }

    async handleMessage(message) {
        const { actionName, recordId } = message;
        if (!actionName || !recordId) {
            return;
        }

        try {
            const result = await executeAction({ actionName, recordId });
            this.processResult(result);
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message || 'Action failed.', 'error');
        }
    }

    processResult(result) {
        if (!result) {
            this.showToast('Error', 'No response from action handler.', 'error');
            return;
        }

        switch (result.resultType) {
            case 'OPEN_URL':
                this.handleOpenUrl(result.url);
                break;
            case 'TOAST':
                this.showToast(result.title || '', result.message || '', result.variant || 'info');
                break;
            case 'NAVIGATE':
                this.handleNavigate(result.recordId);
                break;
            default:
                this.showToast('Error', 'Unknown result type: ' + result.resultType, 'error');
        }
    }

    handleOpenUrl(url) {
        if (!url) {
            this.showToast('Error', 'No URL provided.', 'error');
            return;
        }
        // Security (Checkmarx: Unsafe Use Of Target blank): sever the opener link so the
        // opened page cannot navigate this tab (reverse tabnabbing). The 'noopener'
        // window feature is not used here because it forces a null return value, which
        // would break the popup-blocked detection below.
        const newWindow = window.open(url, '_blank');
        if (newWindow) {
            newWindow.opener = null;
        } else {
            this.showToast('Info', 'Please allow popups for this site.', 'info');
        }
    }

    handleNavigate(recordId) {
        if (!recordId) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}