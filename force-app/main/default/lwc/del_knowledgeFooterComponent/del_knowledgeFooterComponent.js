import { LightningElement,api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import DEL_Nxtprev from '@salesforce/apex/DEL_KnowledgeManagementController.DEL_Nxtprev';

//CLDEL00027 - "Next" (This is a label value for 'Next' button)
import CLDEL00027 from "@salesforce/label/c.CLDEL00027";
//CLDEL00028 - "Previous" (This is a label value for 'Previous' button)
import CLDEL00028 from "@salesforce/label/c.CLDEL00028";
export default class Del_knowledgeFooterComponent extends NavigationMixin(LightningElement) {
    @track objNextPrevious;
    @track blnNext = false;
    @track blnPrevious = false;
    @api recordId;

    strNextButton= CLDEL00027;
    strPreviousButton= CLDEL00028;
    connectedCallback(){
    /**
     * @ author        : G Nanda Kishore Reddy 
     * @ description   : This Method 'DEL_Nxtprev' from Class 'DEL_NxtprevController' is used to retrive the recordId
     *                   and make blnNext,blnPrevious true based on the key value.
     * @ params        : 'recordId' - Id of the Knowledge Articles.
    **/
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

/**
* @ author        : G Nanda Kishore Reddy 
* @ description   : This method is used to navigate knowledge articles based on 'Previous' and 'Next' button. 
**/
 
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