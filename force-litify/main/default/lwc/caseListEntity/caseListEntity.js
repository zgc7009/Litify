import { LightningElement, api } from 'lwc';

/**
 * Container component that loads the Users with share records
 * for the specific case
 */
export default class CaseListEntity extends LightningElement {
    @api entity;

    @api
    removeEntity() {
        const confirmationRequest = new CustomEvent("drop", {
            detail: this.entityId
        });

        this.dispatchEvent(confirmationRequest);
    }
}