import { LightningElement, api, wire } from 'lwc';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

/**
 * Container component that loads the Users with share records
 * for the specific case
 */
export default class ConfirmationModal extends LightningElement {
    @api headerText;
    @api bodyText;
    @api confirmationText;
    @api cancelText;
    
    @wire(CurrentPageReference) pageRef;

    @api
    confirm() {
        fireEvent(this.pageRef, 'confirmRemoval');
    }

    @api
    cancel() {
        fireEvent(this.pageRef, 'cancelRemoval');
    }
}