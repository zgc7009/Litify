import { LightningElement, api } from 'lwc';

import './caseListEntity.css';

/**
 * Container component that loads the Users with share records
 * for the specific case
 */
export default class CaseListEntity extends LightningElement {
    @api entity;

    @api
    removeEntity() {
        const confirmationRequest = new CustomEvent("drop", {
            detail: {
                entity: this.entity.Id
            }
        });

        this.dispatchEvent(confirmationRequest);
    }
}