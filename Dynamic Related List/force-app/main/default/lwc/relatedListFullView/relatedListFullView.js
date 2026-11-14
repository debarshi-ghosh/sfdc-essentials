import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import LOCALE from '@salesforce/i18n/locale';
import { publish, MessageContext } from 'lightning/messageService';
import { refreshApex } from '@salesforce/apex';
import DYNAMIC_QUICK_ACTION from '@salesforce/messageChannel/DynamicQuickAction__c';
import getRelatedRecords from '@salesforce/apex/DynamicRelatedListController.getRelatedRecords';
import getColumnMetadata from '@salesforce/apex/DynamicRelatedListController.getColumnMetadata';
import getParentRecordInfo from '@salesforce/apex/DynamicRelatedListController.getParentRecordInfo';
import getCurrencyInfo from '@salesforce/apex/DynamicRelatedListController.getCurrencyInfo';

export default class RelatedListFullView extends NavigationMixin(LightningElement) {
    parentRecordId;
    childObjectApiName;
    relationshipFieldApiName;
    fieldApiNames;
    cardTitle = 'Related Records';
    iconName = 'standard:related_list';
    rowActionsConfig;
    parentObjectApiName;
    hideRecordLink = false;
    showNewButton = false;

    parentName;
    parentObjectLabel;
    records = [];
    columns = [];
    rawRecordData;
    currencyInfo;
    currencyFields = [];
    isLoading = true;
    errorMessage;
    sortedBy;
    sortedDirection = 'ASC';
    modalMode;
    modalRecordId;

    @wire(MessageContext)
    messageContext;
    currentPage = 1;
    pageSize = 25;
    pageSizeOptions = [
        { label: '25', value: '25' },
        { label: '50', value: '50' },
        { label: '100', value: '100' },
        { label: '200', value: '200' },
        { label: '1000', value: '1000' }
    ];

    @wire(CurrentPageReference)
    setPageReference(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.c__d) {
            try {
                const config = JSON.parse(atob(pageRef.state.c__d));
                this.parentRecordId = config.p;
                this.childObjectApiName = config.c;
                this.relationshipFieldApiName = config.r;
                this.fieldApiNames = config.f;
                this.cardTitle = config.t;
                this.iconName = config.i || 'standard:related_list';
                this.rowActionsConfig = config.a;
                this.parentObjectApiName = config.o;
                this.hideRecordLink = config.h || false;
                this.showNewButton = config.n || false;
            } catch (e) {
                this.errorMessage = 'Failed to load configuration.';
                this.isLoading = false;
            }
        }
    }

    @wire(getParentRecordInfo, { parentRecordId: '$parentRecordId' })
    wiredParent({ data, error }) {
        if (data) {
            this.parentName = data.name;
            this.parentObjectLabel = data.objectLabel;
        } else if (error) {
            this.parentName = '';
            this.parentObjectLabel = '';
        }
    }

    get subtitle() {
        const count = this.records ? this.records.length : 0;
        return count + ' item' + (count !== 1 ? 's' : '') + ' \u2022 Updated a few seconds ago';
    }

    get paginatedRecords() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.records.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.records.length / this.pageSize) || 1;
    }

    get isFirstPage() {
        return this.currentPage <= 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    get pageInfo() {
        const total = this.records.length;
        if (total === 0) {
            return '0 items';
        }
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, total);
        return start + '-' + end + ' of ' + total + ' | Page ' + this.currentPage + ' of ' + this.totalPages;
    }

    get pageSizeValue() {
        return String(this.pageSize);
    }

    get hasRecords() {
        return this.records && this.records.length > 0;
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get showBreadcrumb() {
        return !!this.parentRecordId;
    }

    get showModal() {
        return !!this.modalMode;
    }

    /**
     * Direct (non-traversal) configured fields are the ones that can be edited.
     * The parent lookup is excluded because it is injected on submit instead.
     */
    get modalFieldNames() {
        const names = (this.fieldApiNames || '')
            .split(',')
            .map((f) => f.trim())
            .filter(
                (f) =>
                    f &&
                    !f.includes('.') &&
                    f !== 'Id' &&
                    f !== this.relationshipFieldApiName
            );
        return names.length ? names : ['Name'];
    }

    get modalDefaultFieldValues() {
        if (this.modalMode !== 'create' || !this.relationshipFieldApiName) {
            return {};
        }
        const defaults = {};
        defaults[this.relationshipFieldApiName] = this.parentRecordId;
        return defaults;
    }

    get parsedRowActions() {
        if (!this.rowActionsConfig) {
            return [];
        }
        try {
            return JSON.parse(this.rowActionsConfig);
        } catch (e) {
            return [];
        }
    }

    @wire(getColumnMetadata, {
        childObjectApiName: '$childObjectApiName',
        fieldApiNames: '$fieldApiNames'
    })
    wiredColumns({ error, data }) {
        if (data) {
            this.columns = this.buildColumns(data);
            this.processRecordsIfReady();
        } else if (error) {
            this.errorMessage = this.extractError(error);
        }
    }

    wiredRecordsResult;

    @wire(getCurrencyInfo)
    wiredCurrencyInfo({ error, data }) {
        if (data) {
            this.currencyInfo = data;
            this.processRecordsIfReady();
        } else if (error) {
            this.currencyInfo = undefined;
        }
    }

    @wire(getRelatedRecords, {
        parentRecordId: '$parentRecordId',
        childObjectApiName: '$childObjectApiName',
        relationshipFieldApiName: '$relationshipFieldApiName',
        fieldApiNames: '$fieldApiNames',
        sortField: null,
        sortDirection: 'ASC',
        recordLimit: 2000
    })
    wiredRecords(result) {
        this.wiredRecordsResult = result;
        const { error, data } = result;
        this.isLoading = false;
        if (data) {
            this.rawRecordData = data;
            this.processRecordsIfReady();
            this.errorMessage = undefined;
        } else if (error) {
            this.errorMessage = this.extractError(error);
            this.records = [];
        }
    }

    processRecordsIfReady() {
        if (this.rawRecordData && this.columns) {
            this.records = this.flattenRecords(this.rawRecordData);
        }
    }

    buildColumns(columnData) {
        this.currencyFields = [];
        let cols = columnData.map((col, index) => {
            if (index === 0 && this.hideRecordLink) {
                return null;
            }
            let column = {
                label: col.label,
                fieldName: col.fieldName.replace(/\./g, '_'),
                type: col.type,
                sortable: true,
                cellAttributes: { alignment: 'left' }
            };
            if (index === 0) {
                column.type = 'url';
                column.fieldName = '_recordUrl';
                column.typeAttributes = {
                    label: { fieldName: col.fieldName.replace(/\./g, '_') },
                    target: '_self'
                };
            } else if (col.type === 'reference' && col.relationshipName) {
                if (col.fieldName.includes('.')) {
                    // Traversal reference field (e.g., Shipment__r.Location__c):
                    // Apex auto-included parentPath.RelName.Name, so compute that flat key
                    // and use it as the link label so the Name shows instead of the raw ID.
                    const flatKey = column.fieldName; // dots already replaced with underscores
                    const parentFlatPath = col.fieldName
                        .substring(0, col.fieldName.lastIndexOf('.'))
                        .replace(/\./g, '_');
                    column.type = 'url';
                    column.fieldName = '_' + flatKey + '_url';
                    column.typeAttributes = {
                        label: { fieldName: parentFlatPath + '_' + col.relationshipName + '_Name' },
                        target: '_self'
                    };
                } else {
                    // Direct lookup field: display related record Name as hyperlink
                    column.type = 'url';
                    column.fieldName = '_' + col.fieldName + '_url';
                    column.typeAttributes = {
                        label: { fieldName: col.relationshipName + '_Name' },
                        target: '_self'
                    };
                }
            } else if (col.type === 'reference') {
                // Traversal reference field with unresolved relationship name (fallback: show ID as link)
                const flatKey = column.fieldName;
                column.type = 'url';
                column.fieldName = '_' + flatKey + '_url';
                column.typeAttributes = {
                    label: { fieldName: flatKey },
                    target: '_self'
                };
            } else if (col.type === 'currency') {
                // Amounts are stored in the owning record's currency. The datatable currency
                // type always formats with the user/org currency, so render a precomputed
                // string instead: record currency value, plus the user currency equivalent
                // when the two differ.
                const currencyField = this.registerCurrencyField(col);
                column.type = 'text';
                column.fieldName = currencyField.displayKey;
                column.cellAttributes = { alignment: 'left' };
            } else if (col.type === 'date') {
                column.typeAttributes = {
                    year: 'numeric',
                    month: 'short',
                    day: '2-digit',
                    timeZone: 'UTC'
                };
            }
            return column;
        }).filter(col => col !== null);

        const actions = this.parsedRowActions;
        if (actions.length > 0) {
            cols.push({
                type: 'action',
                typeAttributes: { rowActions: actions }
            });
        }

        return cols;
    }

    flattenRecords(data) {
        const deepFlatten = (obj, prefix, result) => {
            Object.keys(obj).forEach((key) => {
                if (key === 'attributes') return;
                const value = obj[key];
                const flatKey = prefix ? prefix + '_' + key : key;
                if (value !== null && typeof value === 'object') {
                    deepFlatten(value, flatKey, result);
                } else {
                    result[flatKey] = value;
                }
            });
        };

        return data.map((record) => {
            let flat = {};
            deepFlatten(record, '', flat);
            // Context-aware URL for the record link (works in CRM and Experience Cloud)
            flat._recordUrl = this.buildRecordUrl(record.Id);
            // Context-aware URLs for lookup/reference fields
            if (this.columns) {
                this.columns.forEach((col) => {
                    if (col.fieldName && col.fieldName.startsWith('_') && col.fieldName.endsWith('_url')) {
                        const originalField = col.fieldName.slice(1, -4);
                        if (flat[originalField]) {
                            flat[col.fieldName] = this.buildRecordUrl(flat[originalField]);
                        }
                    }
                });
            }
            this.applyCurrencyDisplay(flat);
            return flat;
        });
    }

    buildRecordUrl(recordId) {
        const { pathname } = window.location;
        // In Experience Cloud, records resolve via the site's /detail/ route
        // (e.g., /s/detail/<recordId>). The leading /<recordId> form only works in CRM.
        if (pathname.startsWith('/s')) {
            const marker = '/s/';
            const idx = pathname.indexOf(marker);
            const basePath = idx !== -1 ? pathname.substring(0, idx + marker.length) : '/s/';
            return basePath + 'detail/' + recordId;
        }
        return '/' + recordId;
    }

    handleSort(event) {
        const fieldName = event.detail.fieldName;
        const direction = event.detail.sortDirection;
        this.sortedBy = fieldName;
        this.sortedDirection = direction;

        // Determine the data field to sort on
        let sortKey = fieldName;
        const col = this.columns.find((c) => c.fieldName === fieldName);
        if (col && col.type === 'url' && col.typeAttributes && col.typeAttributes.label) {
            sortKey = col.typeAttributes.label.fieldName;
        }
        // Currency columns display a formatted string: sort on the converted numeric value
        // so rows in different currencies are compared on a common basis.
        const currencyField = this.currencyFields.find((c) => c.displayKey === fieldName);
        if (currencyField) {
            sortKey = currencyField.convertedKey;
        }

        const isReverse = direction === 'desc' ? -1 : 1;
        this.records = [...this.records].sort((a, b) => {
            const valA = a[sortKey] != null ? a[sortKey] : '';
            const valB = b[sortKey] != null ? b[sortKey] : '';
            if (typeof valA === 'string') {
                return isReverse * valA.localeCompare(valB);
            }
            return isReverse * (valA - valB);
        });
        this.currentPage = 1;
    }

    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
        }
    }

    handleFirstPage() {
        this.currentPage = 1;
    }

    handleLastPage() {
        this.currentPage = this.totalPages;
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.currentPage = 1;
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredRecordsResult)
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'view_record') {
            this.navigateToRecord(row.Id);
        } else if (action.name === 'edit_record') {
            this.openModal('edit', row.Id);
        } else if (action.name === 'delete_record') {
            this.openModal('delete', row.Id);
        } else if (action.type === 'quick_action') {
            this.invokeQuickAction(action.name, row.Id);
        }
    }

    handleNewRecord() {
        this.openModal('create', null);
    }

    openModal(mode, recordId) {
        this.modalMode = mode;
        this.modalRecordId = recordId;
    }

    handleModalClose() {
        this.modalMode = undefined;
        this.modalRecordId = undefined;
    }

    handleModalSuccess() {
        this.handleModalClose();
        this.handleRefresh();
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    invokeQuickAction(actionApiName, rowRecordId) {
        const isCommunity = window.location.pathname.startsWith('/s');

        if (isCommunity) {
            publish(this.messageContext, DYNAMIC_QUICK_ACTION, {
                actionName: actionApiName,
                recordId: rowRecordId
            });
            return;
        }

        const backgroundContext = encodeURIComponent(window.location.pathname);
        const url =
            '/lightning/action/quick/' +
            actionApiName +
            '?objectApiName&context=RECORD_DETAIL&recordId=' +
            rowRecordId +
            '&backgroundContext=' +
            backgroundContext;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        });
    }

    navigateToParent() {
        if (this.parentRecordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.parentRecordId,
                    actionName: 'view'
                }
            });
        }
    }

    navigateToObjectHome() {
        if (this.parentObjectApiName) {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.parentObjectApiName,
                    actionName: 'home'
                }
            });
        }
    }

    /**
     * Registers a currency column and returns the flat record keys used to render it.
     * Apex auto-selects the CurrencyIsoCode of the record that owns the amount
     * (the child record itself, or the related record for a traversal path).
     */
    registerCurrencyField(col) {
        const valueKey = col.fieldName.replace(/\./g, '_');
        const isoKey = col.fieldName.includes('.')
            ? col.fieldName.substring(0, col.fieldName.lastIndexOf('.')).replace(/\./g, '_') +
              '_CurrencyIsoCode'
            : 'CurrencyIsoCode';
        const currencyField = {
            valueKey,
            isoKey,
            displayKey: '_' + valueKey + '_display',
            convertedKey: '_' + valueKey + '_converted'
        };
        this.currencyFields.push(currencyField);
        return currencyField;
    }

    applyCurrencyDisplay(flat) {
        this.currencyFields.forEach((cf) => {
            const amount = flat[cf.valueKey];
            if (amount === null || amount === undefined || amount === '') {
                flat[cf.displayKey] = '';
                flat[cf.convertedKey] = null;
                return;
            }
            const recordIso = flat[cf.isoKey] || this.userCurrency;
            flat[cf.displayKey] = this.buildCurrencyDisplay(amount, recordIso);
            const converted = this.convertAmount(amount, recordIso);
            flat[cf.convertedKey] = converted === null ? amount : converted;
        });
    }

    get userCurrency() {
        return this.currencyInfo ? this.currencyInfo.userCurrency : undefined;
    }

    /**
     * Returns the amount in the record's own currency, followed by the equivalent in the
     * running user's currency when the two differ (e.g. "EUR 1,000.00 (USD 1,080.00)").
     */
    buildCurrencyDisplay(amount, recordIso) {
        const userIso = this.userCurrency || recordIso;
        const base = this.formatAmount(amount, recordIso || userIso);
        if (!this.currencyInfo || !this.currencyInfo.isMultiCurrency || !recordIso || recordIso === userIso) {
            return base;
        }
        const converted = this.convertAmount(amount, recordIso);
        if (converted === null) {
            return base;
        }
        return base + ' (' + this.formatAmount(converted, userIso) + ')';
    }

    /**
     * Converts an amount from the record currency to the user currency using the org
     * conversion rates (both rates are expressed against the corporate currency).
     */
    convertAmount(amount, recordIso) {
        const info = this.currencyInfo;
        if (!info || !info.isMultiCurrency || !info.conversionRates) {
            return amount;
        }
        if (!recordIso || recordIso === info.userCurrency) {
            return amount;
        }
        const fromRate = info.conversionRates[recordIso];
        const toRate = info.conversionRates[info.userCurrency];
        if (!fromRate || !toRate) {
            return null;
        }
        return (amount / fromRate) * toRate;
    }

    formatAmount(amount, isoCode) {
        const value = Number(amount);
        // Intl only accepts well-formed ISO 4217 codes; fall back to a plain format otherwise.
        if (!isoCode || !/^[A-Za-z]{3}$/.test(isoCode)) {
            return (isoCode ? isoCode + ' ' : '') + value.toFixed(2);
        }
        return new Intl.NumberFormat(LOCALE, {
            style: 'currency',
            currency: isoCode,
            currencyDisplay: 'code'
        }).format(value);
    }

    extractError(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return 'An unexpected error occurred.';
    }
}