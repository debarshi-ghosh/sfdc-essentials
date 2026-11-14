import { LightningElement, api } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';

/**
 * @description Self-contained SLDS modal that creates, edits or deletes a record using
 *              the UI API. Deliberately avoids NavigationMixin record actions and
 *              platformShowToastEvent so it behaves identically in Lightning Experience,
 *              Aura-based Experience Cloud sites and LWR sites.
 *
 *              Fires 'success' (detail: { recordId, mode }) and 'close'.
 */
export default class RecordActionModal extends LightningElement {
    /** 'create' | 'edit' | 'delete' */
    @api mode;
    @api objectApiName;
    @api recordId;
    @api objectLabel = 'Record';

    /** Field API names rendered on the create/edit form. */
    @api fieldNames = [];

    /** Values force-applied on submit, e.g. the parent lookup when creating. */
    @api defaultFieldValues = {};

    isSaving = false;
    errorMessage;

    get isDelete() {
        return this.mode === 'delete';
    }

    get isForm() {
        return this.mode === 'create' || this.mode === 'edit';
    }

    get formRecordId() {
        return this.mode === 'edit' ? this.recordId : null;
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get title() {
        if (this.mode === 'create') {
            return 'New ' + this.objectLabel;
        }
        if (this.mode === 'edit') {
            return 'Edit ' + this.objectLabel;
        }
        return 'Delete ' + this.objectLabel;
    }

    handleSubmit(event) {
        event.preventDefault();
        this.errorMessage = undefined;
        this.isSaving = true;
        // Default values win so the parent relationship cannot be overridden from the form.
        const fields = Object.assign({}, event.detail.fields, this.defaultFieldValues);
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        this.isSaving = false;
        this.dispatchEvent(
            new CustomEvent('success', {
                detail: { recordId: event.detail.id, mode: this.mode }
            })
        );
    }

    handleError(event) {
        this.isSaving = false;
        this.errorMessage = this.extractError(event.detail);
    }

    handleDelete() {
        this.errorMessage = undefined;
        this.isSaving = true;
        deleteRecord(this.recordId)
            .then(() => {
                this.dispatchEvent(
                    new CustomEvent('success', {
                        detail: { recordId: this.recordId, mode: this.mode }
                    })
                );
            })
            .catch((error) => {
                this.errorMessage = this.extractError(error);
            })
            .finally(() => {
                this.isSaving = false;
            });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    extractError(error) {
        if (!error) {
            return 'An unexpected error occurred.';
        }
        if (error.body) {
            if (Array.isArray(error.body)) {
                return error.body.map((e) => e.message).join(', ');
            }
            if (error.body.output && error.body.output.errors && error.body.output.errors.length) {
                return error.body.output.errors.map((e) => e.message).join(', ');
            }
            if (error.body.message) {
                return error.body.message;
            }
        }
        if (error.detail) {
            return error.detail;
        }
        if (error.message) {
            return error.message;
        }
        return 'An unexpected error occurred.';
    }
}
