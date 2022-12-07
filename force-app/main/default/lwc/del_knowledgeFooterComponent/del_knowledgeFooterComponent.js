import { LightningElement,api,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import DEL_Nxtprev from '@salesforce/apex/DEL_KnowledgeManagementController.DEL_Nxtprev';
import getCurrentUserDetails from '@salesforce/apex/DEL_KnowledgeManagementController.getCurrentUserDetails';
import idUserId from '@salesforce/user/Id';

//CLDEL00001 - "Error" (It stores the default title for error toast message)
import CLDEL00001 from "@salesforce/label/c.CLDEL00001";
//CLDEL00027 - "Next" (This is a label value for 'Next' button)
import CLDEL00027 from "@salesforce/label/c.CLDEL00027";
//CLDEL00028 - "Previous" (This is a label value for 'Previous' button)
import CLDEL00028 from "@salesforce/label/c.CLDEL00028";

export default class Del_knowledgeFooterComponent extends NavigationMixin(LightningElement) {
    @api recordId;

    isUserPortalEnabled;
    @track strLabelPreviousToDisplay = CLDEL00028;
    @track strLabelNextToDisplay = CLDEL00027;
    @track objNextPrevious;
    @track blnNext = false;
    @track blnPrevious = false;


    connectedCallback () {
        /**
         * @ author        : G Nanda Kishore Reddy 
         * @ description   : This Method 'getCurrentUserDetails' fetches current logged-in user.
         * @ params        : 'idUserId' - Id of the Current-Logged In User.
        **/
        getCurrentUserDetails({ idUserId : idUserId })
        .then(result => {
            this.isUserPortalEnabled = result.IsPortalEnabled;
        })
        .catch(error => {
            this.showToastMessage(CLDEL00001, error.body.message, 'error');
        })

        /**
         * @ author        : G Nanda Kishore Reddy 
         * @ description   : This Method 'DEL_Nxtprev' from Class 'DEL_NxtprevController' is used to retrive the recordId
         *                   and make blnNext,blnPrevious true based on the key value.
         * @ params        : 'recordId' - Id of the Knowledge Articles.
        **/
        DEL_Nxtprev({ recordId : this.recordId })
        .then(result => {
            this.objNextPrevious = JSON.parse(JSON.stringify(result));
            if (!this.objNextPrevious.hasOwnProperty('next')) {
                this.blnNext = true;
            }
            if (!this.objNextPrevious.hasOwnProperty('previous')) {
                this.blnPrevious = true;
            }
            this.strLabelPreviousToDisplay = this.objNextPrevious.hasOwnProperty('previous') ? this.objNextPrevious.previous.Title : CLDEL00028;
            this.strLabelNextToDisplay = this.objNextPrevious.hasOwnProperty('next') ? this.objNextPrevious.next.Title : CLDEL00027;
        })
        .catch(error => {
            this.showToastMessage(CLDEL00001, error.body.message, 'error');
        })
    }

    /**
    * @ author        : G Nanda Kishore Reddy 
    * @ description   : This method will handle 'Previous' button event.
    **/
    handlePreviousClick (evt) {
        let recordIdToNavigate;
        if (this.isUserPortalEnabled) {
            recordIdToNavigate = this.objNextPrevious.hasOwnProperty('previous') ? this.objNextPrevious.previous.KnowledgeArticleId : null;
        } else {
            recordIdToNavigate = this.objNextPrevious.hasOwnProperty('previous') ? this.objNextPrevious.previous.Id : null;
        }
        this.navigateToArticleRecord(recordIdToNavigate);
    }

    /**
    * @ author        : G Nanda Kishore Reddy 
    * @ description   : This method will handle 'Next' button event. 
    **/
    handleNextClick (evt) {
        let recordIdToNavigate;
        if (this.isUserPortalEnabled) {
            recordIdToNavigate = this.objNextPrevious.hasOwnProperty('next') ? this.objNextPrevious.next.KnowledgeArticleId : null;
        } else {
            recordIdToNavigate = this.objNextPrevious.hasOwnProperty('next') ? this.objNextPrevious.next.Id : null;
        }
        this.navigateToArticleRecord(recordIdToNavigate);
    }

    /**
    * @ author        : G Nanda Kishore Reddy 
    * @ description   : This method is used to navigate knowledge articles based on 'Previous' and 'Next' button.
    * @ params        : 'recordIdToNavigate' - Record Id to navigate to Article Record.
    **/
    navigateToArticleRecord (recordIdToNavigate) { 
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

    /**
     * @ author      : Vinay kant
     * @ description : This method is used for showing Toast Message.
     * @ params      : 'title' - Title of Toast Message.
     *               : 'message' - Message to Toast Message.
     *               : 'variant' - Type of Toast Message.
    **/
     showToastMessage (title, message, variant) {
        const event = new ShowToastEvent({
                        title: title,
                        variant: variant,
                        message: message,
                      });
        this.dispatchEvent(event);
    }
}