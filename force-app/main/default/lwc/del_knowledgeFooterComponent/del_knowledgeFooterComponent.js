import { LightningElement,api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import DEL_Nxtprev from '@salesforce/apex/DEL_NxtprevController.DEL_Nxtprev';

export default class Del_knowledgeFooterComponent extends NavigationMixin(LightningElement) {
    @track objNextPrevious;
    @track blnNext = false;
    @track blnPrevious = false;
    //@track buttonNextVariant='brand';
    //@track buttonPreviousVariant='neutral';
    @api recordId;

    connectedCallback(){
        DEL_Nxtprev({recordId:this.recordId})
        .then(result => {
            this.objNextPrevious=JSON.parse(JSON.stringify(result));
            console.log(JSON.stringify(this.objNextPrevious));
            if (!this.objNextPrevious.hasOwnProperty('next')) {
                this.blnNext = true;
            }
            if (!this.objNextPrevious.hasOwnProperty('previous')) {
                this.blnPrevious = true;
            }
        })
        .catch(error => {
            console.log(JSON.stringify(error));
        })
    }

    
    handleClick(evt){
        let recordIdToNavigate;
        if (evt.target.name == 'previous') {
            recordIdToNavigate = this.objNextPrevious.hasOwnProperty('previous') ? this.objNextPrevious.previous.Id : null ;
        }
        if (evt.target.name == 'next') {
            recordIdToNavigate = this.objNextPrevious.hasOwnProperty('next') ? this.objNextPrevious.next.Id : null ;
        }
        console.log(recordIdToNavigate);
        if (recordIdToNavigate) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordIdToNavigate,
                    actionName: 'view'
                },
            });
        }

    }
}