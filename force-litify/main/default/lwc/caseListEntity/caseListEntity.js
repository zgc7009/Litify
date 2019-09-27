import { LightningElement, api } from 'lwc';

/**
 * Container component that manages individual Users with share records for the specific case
 */
export default class CaseListEntity extends LightningElement {
    @api entity;
    @api icon;

    connectedCallback() {
        this.icon = this.entity.isIndividual ? 'standard:individual' : 'standard:groups';
    }

    // Triggered when a requets is made to remove an entity
    @api
    removeEntity() {
        // Build the request details
        const confirmationRequest = new CustomEvent("drop", {
            detail: {
                entity: this.entity.sId
            }
        });

        // Pass the event up to the caseListItem component
        this.dispatchEvent(confirmationRequest);
    }
}