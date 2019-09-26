// hello.test.js
import { createElement } from 'lwc';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

import CaseList from 'c/caseList';

import getCases from '@salesforce/apex/CaseListController.getCases';
const getCasesAdapter = registerApexTestWireAdapter(getCases);

import { CurrentPageReference } from 'lightning/navigation';
const pageRefAdapter = registerLdsTestWireAdapter(CurrentPageReference);

const mockCases = require('./data/getCasesAdapter.json');

describe('c-case-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('should initialize', () => {
        const element = initializeElement();

        const wrapper = element.shadowRoot.querySelector('.wrapper');
        expect(wrapper).toBeTruthy();

        const content = wrapper.querySelector('.content');
        expect(content).toBeFalsy();
    });
    
    describe('get cases', () => {
        it('should get cases', () => {
            const element = initializeElement();

            expect(mockCases).toBeDefined();
            getCasesAdapter.emit(mockCases);

            // Resolve a promise to wait for a rerender of the new content.
            return Promise.resolve().then(() => {
                const wrapper = element.shadowRoot.querySelector('.wrapper');
                expect(wrapper).toBeTruthy();

                const content = wrapper.querySelector('.content');
                expect(content).toBeTruthy();
            });
        });
    });

    function initializeElement() {
        const element = createElement('c-case-list', {
            is: CaseList
        });
        document.body.appendChild(element);

        return element;
    }
});