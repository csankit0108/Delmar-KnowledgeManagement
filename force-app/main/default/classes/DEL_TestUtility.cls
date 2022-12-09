/*********************************************************************************************************************
* 
* @ Name            :  DEL_TestUtility
* @ Purpose         :  This is utility class which can be used to create test data for test classes
* @ Author          :  Ankit C
*
*   Date            |  Developer Name         |  Version      |  Changes
* =====================================================================================================================
*   26-07-2022      |  ankit.c@absyz.com      |  1.0          |  Initial Version
*
***********************************************************************************************************************/
@isTest
public class DEL_TestUtility {
    /**
    * @ Name     :  AccountBuilder
    * @ Purpose  :  To create Account record
    * @ Author   :  Ankit C
    **/
    public class AccountBuilder {
        private String strName;
        
        public AccountBuilder() {
            this.strName = '';
        }
        
        public AccountBuilder setName(String strValue) {
            this.strName = strValue;
            return this;
        }
        
        public Account createAccount() {
            Account objAccount = new Account();
            objAccount.Name = this.strName;
            objAccount.Website = 'https://www.delmarcargo.com/en';
            
            return objAccount;
        }
    }
    
    /**
    * @ Name     :  ContactBuilder
    * @ Purpose  :  To create Contact record
    * @ Author   :  Ankit C
    **/
    public class ContactBuilder {
        private String strFirstName;
        private String strLastName;
        private Id idAccountId;
        private String strPreferredLangauge;
        
        public ContactBuilder() {
            this.strFirstName = '';
            this.strLastName = '';
            this.strPreferredLangauge = '';
        }
        
        public ContactBuilder setFirstName(String strValue) {
            this.strFirstName = strValue;
            return this;
        }
        
        public ContactBuilder setLastName(String strValue) {
            this.strLastName = strValue;
            return this;
        }
        
        public ContactBuilder setAccountId(Id idValue) {
            this.idAccountId = idValue;
            return this;
        }

        public ContactBuilder setPreferredLanguage(String strValue) {
            this.strPreferredLangauge = strValue;
            return this;
        }
        
        public Contact createContact() {
            Contact objContact = new Contact();
            objContact.FirstName = this.strFirstName;
            objContact.LastName = this.strLastName;
            objContact.AccountId = this.idAccountId;
            objContact.Preferred_Language__c = this.strPreferredLangauge;
            
            return objContact;
        }
    }
    
    /**
    * @ Name     :  UserBuilder
    * @ Purpose  :  To create User record
    * @ Author   :  Ankit C
    **/
    public class UserBuilder {
        private String strFirstName;
        private String strLastName;
        private Id idContactId;
        private Id idProfileId;
        private String strEmail;
        private String strUsername;
        private String strAlias;
        private Boolean blnEnableCaseComments;
        
        public UserBuilder() {
            this.strFirstName = '';
            this.strLastName = '';
            this.strEmail = '';
            this.strUsername = '';
            this.strAlias = '';
            this.blnEnableCaseComments = true;
        }
        
        public UserBuilder setFirstName(String strValue) {
            this.strFirstName = strValue;
            return this;
        }
        
        public UserBuilder setLastName(String strValue) {
            this.strLastName = strValue;
            return this;
        }
        
        public UserBuilder setEmail(String strValue) {
            this.strEmail = strValue;
            return this;
        }
        
        public UserBuilder setUsername(String strValue) {
            this.strUsername = strValue;
            return this;
        }
        
        public UserBuilder setAlias(String strValue) {
            this.strAlias = strValue;
            return this;
        }
        
        public UserBuilder setContactId(Id idValue) {
            this.idContactId = idValue;
            return this;
        }
        
        public UserBuilder setProfileId(Id idValue) {
            this.idProfileId = idValue;
            return this;
        }


        
        public User createUser() {
            User objUser = new User();
            objUser.FirstName = this.strFirstName;
            objUser.LastName = this.strLastName;
            objUser.Email = this.strEmail;
            objUser.Username = this.strUsername;
            objUser.Alias = this.strAlias;
            objUser.ContactId = this.idContactId;
            objUser.ProfileId = this.idProfileId;
            objUser.TimeZoneSidKey = 'America/Los_Angeles';
            objUser.LocaleSidKey = 'en_US';
            objUser.EmailEncodingKey = 'ISO-8859-1';
            objUser.LanguageLocaleKey = 'en_US';
            objUser.DEL_EnableCaseComments__c = this.blnEnableCaseComments;
            
            return objUser;
        }
    }
    
    /**
    * @ Name     :  CaseBuilder
    * @ Purpose  :  To create Case record
    * @ Author   :  Ankit C
    **/
    public class CaseBuilder {
        private String strSubject;
        private String strDescription;
        private Id idContactId;
        private Id idAccountId;
        private Id idOwnerId;
        private String strOrigin;
        private String strType;
        private String strStatus;
        private String strPriority;
        private String strSuppliedEmail;
        private String strLanguage;
        
        public CaseBuilder() {
            this.strSubject = '';
            this.strDescription = '';
            this.strOrigin = '';
            this.strType = '';
            this.strStatus = '';
            this.strPriority = '';
            this.strSuppliedEmail = '';
            this.strLanguage = '';
            this.idOwnerId = UserInfo.getUserId();
        }
        
        public CaseBuilder setSubject(String strValue) {
            this.strSubject = strValue;
            return this;
        }
        
        public CaseBuilder setDescription(String strValue) {
            this.strDescription = strValue;
            return this;
        }
        
        public CaseBuilder setOrigin(String strValue) {
            this.strOrigin = strValue;
            return this;
        }
        
        public CaseBuilder setType(String strValue) {
            this.strType = strValue;
            return this;
        }
        
        public CaseBuilder setPriority(String strValue) {
            this.strPriority = strValue;
            return this;
        }
        
        public CaseBuilder setStatus(String strValue) {
            this.strStatus = strValue;
            return this;
        }
        
        public CaseBuilder setContactId(Id idValue) {
            this.idContactId = idValue;
            return this;
        }
        
        public CaseBuilder setAccountId(Id idValue) {
            this.idAccountId = idValue;
            return this;
        }

        public CaseBuilder setOwnerId(Id idValue) {
            this.idOwnerId = idValue;
            return this;
        }
        
        public CaseBuilder setSuppliedEmail(String strValue) {
            this.strSuppliedEmail = strValue;
            return this;
        }

        public CaseBuilder setLanguage(String strValue) {
            this.strLanguage = strValue;
            return this;
        }
        
        public Case createCase() {
            Case objCase = new Case();
            objCase.Subject = this.strSubject;
            objCase.Description =  this.strDescription;
            objCase.Origin = this.strOrigin;
            objCase.Type = this.strType;
            objCase.Priority = this.strPriority;
            objCase.AccountId = this.idAccountId;
            objCase.ContactId = this.idContactId;
            objCase.SuppliedEmail = this.strSuppliedEmail;
            objCase.Language__c = this.strLanguage;
            ObjCase.OwnerId = this.idOwnerId;
            
            return objCase;
        }
    }
    
    /**
    * @ Name     :  CaseCommentBuilder
    * @ Purpose  :  To create DEL_CaseComment__c record
    * @ Author   :  Ankit C
    **/
    public class CaseCommentBuilder {
        private String strBody;
        private String idCaseId;
        private String strEmailMessageId;
        private Boolean blnHasAttachment;
        private Boolean blnVisibleToCustomer;
        
        public CaseCommentBuilder() {
            this.strBody = '';
            this.strEmailMessageId = '';
            this.blnHasAttachment = false;
            this.blnVisibleToCustomer = false;
        }
        
        public CaseCommentBuilder setBody(String strValue) {
            this.strBody = strValue;
            return this;
        }
        
        public CaseCommentBuilder setEmailMessageId(String strValue) {
            this.strEmailMessageId = strValue;
            return this;
        }
        
        public CaseCommentBuilder setCaseId(Id idValue) {
            this.idCaseId = idValue;
            return this;
        }

        public CaseCommentBuilder setHasAttachment(Boolean blnValue) {
            this.blnHasAttachment = blnValue;
            return this;
        }

        public CaseCommentBuilder setVisibleToCustomer(Boolean blnValue) {
            this.blnVisibleToCustomer = blnValue;
            return this;
        }
        
        public DEL_CaseComment__c createCaseComment() {
            DEL_CaseComment__c objCaseComment = new DEL_CaseComment__c();
            objCaseComment.Body__c = this.strBody;
            objCaseComment.Case__c = this.idCaseId;
            objCaseComment.EmailMessageId__c = this.strEmailMessageId;
            objCaseComment.HasAttachment__c = this.blnHasAttachment;
            objCaseComment.VisibleToCustomer__c = this.blnVisibleToCustomer;
            
            return objCaseComment;
        }
    }
    
    /**
    * @ Name     :  CaseCollaborationBuilder
    * @ Purpose  :  To create DEL_CaseCollaborator__c record
    * @ Author   :  Dinesh Chandra
    **/
    public class CaseCollaborationBuilder {
        private Id idCaseId;
        private Id idUserId;
        
        public CaseCollaborationBuilder setCaseId(Id idValue) {
            this.idCaseId = idValue;
            return this;
        }
        
        public CaseCollaborationBuilder setUserId(Id idValue) {
            this.idUserId = idValue;
            return this;
        }
        
        public DEL_CaseCollaborator__c createCaseCollaborator() {
            DEL_CaseCollaborator__c objCaseCollaborator = new DEL_CaseCollaborator__c();
            objCaseCollaborator.User__c = this.idUserId;
            objCaseCollaborator.Case__c = this.idCaseId;
            
            return objCaseCollaborator;
        }
    }
    
    /**
    * @ Name     :  EmailMessagetBuilder
    * @ Purpose  :  To create Email Message record
    * @ Author   :  Rakesh Nayak
    **/
    public class EmailMessageBuilder {
        private String strTextBody;
        private String strHtmlBody;
        private Id idParentId;
        private String strFromAddress;
        private String strFromName;
        private String strMessageIdentifier;
        private String strThreadIdentifier;
        private Boolean blnIncoming;
        private String strHeaders;
        private String strToAddress;
        private String strCcAddress;
        
        public EmailMessageBuilder() {
            this.strTextBody = '';
            this.strHtmlBody = '';
            this.strFromAddress = '';
            this.strFromName = '';
            this.strMessageIdentifier = '';
            this.strThreadIdentifier = '';
            this.strHeaders = '';
            this.strToAddress = '';
            this.strCcAddress = '';
        }
        
        public EmailMessageBuilder setTextBody(String strValue) {
            this.strTextBody = strValue;
            return this;
        }
        
        public EmailMessageBuilder setHtmlBody(String strValue) {
            this.strHtmlBody = strValue;
            return this;
        }
        
        public EmailMessageBuilder setMessageIdentifier(String strValue) {
            this.strMessageIdentifier = strValue;
            return this;
        }
        
        public EmailMessageBuilder setThreadIdentifier(String strValue) {
            this.strThreadIdentifier = strValue;
            return this;
        }
        
        public EmailMessageBuilder setFromName(String strValue) {
            this.strFromName = strValue;
            return this;
        }
        
        public EmailMessageBuilder setParentId(Id idValue) {
            this.idParentId = idValue;
            return this;
        }
        
        public EmailMessageBuilder setFromAddress(String strValue) {
            this.strFromAddress = strValue;
            return this;
        }

        public EmailMessageBuilder setToAddress(String strValue) {
            this.strToAddress = strValue;
            return this;
        }

        public EmailMessageBuilder setCcAddress(String strValue) {
            this.strCcAddress = strValue;
            return this;
        }
        
        public EmailMessageBuilder setIncoming(Boolean blnValue) {
            this.blnIncoming = blnValue;
            return this;
        }
        
        public EmailMessageBuilder setHeaders(String strValue) {
            this.strHeaders = strValue;
            return this;
        }
        
        public EmailMessage createEmailMessage() {
            EmailMessage objEmailMessage = new EmailMessage();
            objEmailMessage.TextBody = this.strTextBody;
            objEmailMessage.HtmlBody = this.strHtmlBody;
            objEmailMessage.ThreadIdentifier = this.strThreadIdentifier;
            objEmailMessage.MessageIdentifier = this.strMessageIdentifier;
            objEmailMessage.FromName = this.strFromName;
            objEmailMessage.FromAddress = this.strFromAddress;
            objEmailMessage.ToAddress = this.strToAddress;
            objEmailMessage.ParentId = this.idParentId;
            objEmailMessage.Incoming = this.blnIncoming;
            objEmailMessage.Headers = this.strHeaders;
            objEmailMessage.CcAddress = this.strCcAddress;
            
            return objEmailMessage;
        }
    }
    
    /**
    * @ Name     :  CaseCollaborationConfigurationBuilder
    * @ Purpose  :  To create DEL_CaseCollaborationConfiguration__c record
    * @ Author   :  Ankit C
    **/
    public class CaseCollaborationConfigurationBuilder {
        private String strMergeFields;
        private String strCaseQueryFields;
        private String strSiteName;
        private String strEmailTemplateName;
        private String strOrgWideAddress;
        private Id idSetupOwnerId;
        private String strTemplateNameSpanish;
        private String strTemplateNameFrench;
        private String strFieldSetName;
        
        public CaseCollaborationConfigurationBuilder() {
            this.strMergeFields = '';
            this.strCaseQueryFields = '';
            this.strSiteName = '';
            this.strEmailTemplateName = '';
            this.strOrgWideAddress = '';
            this.strTemplateNameSpanish = '';
            this.strTemplateNameFrench = '';
            this.strFieldSetName = '';
        }
        
        public CaseCollaborationConfigurationBuilder setMergeFields(String strValue) {
            this.strMergeFields = strValue;
            return this;
        }
        
        public CaseCollaborationConfigurationBuilder setCaseQueryFields(String strValue) {
            this.strCaseQueryFields = strValue;
            return this;
        }
        
        public CaseCollaborationConfigurationBuilder setSiteName(String strValue) {
            this.strSiteName = strValue;
            return this;
        }
        
        public CaseCollaborationConfigurationBuilder setEmailTemplateName(String strValue) {
            this.strEmailTemplateName = strValue;
            return this;
        }
        
        public CaseCollaborationConfigurationBuilder setOrgWideAddress(String strValue) {
            this.strOrgWideAddress = strValue;
            return this;
        }
        
        public CaseCollaborationConfigurationBuilder setOwnerId(Id idValue) {
            this.idSetupOwnerId = idValue;
            return this;
        }

        public CaseCollaborationConfigurationBuilder setSpanishTemplateName(String strValue) {
            this.strTemplateNameSpanish = strValue;
            return this;
        }

        public CaseCollaborationConfigurationBuilder setFrenchTemplateName(String strValue) {
            this.strTemplateNameFrench = strValue;
            return this;
        }

        public CaseCollaborationConfigurationBuilder setFieldSetName(String strValue) {
            this.strFieldSetName = strValue;
            return this;
        }
        
        public DEL_CaseCollaborationConfiguration__c createConfiguration() {
            DEL_CaseCollaborationConfiguration__c objCaseCollaborationConfiguration = new DEL_CaseCollaborationConfiguration__c(
                MergeFields__c = this.strMergeFields,
                CaseQueryFields__c = this.strCaseQueryFields,
                SiteName__c = this.strSiteName,
                CaseCommentEmailTemplateEnglish__c = this.strEmailTemplateName,
                SetupOwnerId = this.idSetupOwnerId,
                OrgWideAddress__c = this.strOrgWideAddress,
                CaseCommentsEmailTemplateFrench__c = this.strTemplateNameFrench,
                CaseCommentsEmailTemplateSpanish__c = this.strTemplateNameSpanish,
                CCAddressSwitch__c = true,
                VisibleToCustomerSwitch__c = true,
                CollaboratorsFieldSet__c = this.strFieldSetName
            );
            
            return objCaseCollaborationConfiguration;
        }
    }
    
    /**
    * @ Name     :  EmailTemplateBuilder
    * @ Purpose  :  To create EmailTemplate record
    * @ Author   :  Ankit C
    **/
    public class EmailTemplateBuilder {
        private String strName;
        private String strDeveloperName;
        private String strHtmlValue;
        private Id idFolderId;
        private String strTemplateType;
        private String strSubject;
        
        public EmailTemplateBuilder() {
            this.strName = '';
            this.strDeveloperName = '';
            this.strHtmlValue = '';
            this.strTemplateType = '';
            this.strSubject = '';
        }
        
        public EmailTemplateBuilder setName(String strValue) {
            this.strName = strValue;
            return this;
        }
        
        public EmailTemplateBuilder setDeveloperName(String strValue) {
            this.strDeveloperName = strValue;
            return this;
        }
        
        public EmailTemplateBuilder setHtmlValue(String strValue) {
            this.strHtmlValue = strValue;
            return this;
        }
        
        public EmailTemplateBuilder setFolderId(Id idValue) {
            this.idFolderId = idValue;
            return this;
        }
        
        public EmailTemplateBuilder setTemlateType(String strValue) {
            this.strTemplateType = strValue;
            return this;
        }
        
        public EmailTemplateBuilder setSubject(String strValue) {
            this.strSubject = strValue;
            return this;
        }
        
        public EmailTemplate createEmailTemplate() {
            EmailTemplate objEmailTemplate = new EmailTemplate(
                Name = this.strName,
                DeveloperName = this.strDeveloperName,
                HtmlValue = this.strHtmlValue,
                FolderId = this.idFolderId,
                TemplateType = this.strTemplateType,
                Subject = this.strSubject
            );
            
            return objEmailTemplate;
        }
    }

    /**
    * @ Name     :  ContentVersionBuilder
    * @ Purpose  :  To create ContentVersion record
    * @ Author   :  Rakesh Nayak
    **/
    public class ContentVersionBuilder {
        private String strTitle;
        private String strPathOnClient;
        private Blob blobVersionData;
        private  Boolean blnIsMajorVersion;
        
        public ContentVersionBuilder() {
            this.strTitle= '';
            this.strPathOnClient = '';
        }
        
        public ContentVersionBuilder setTitle(String strValue) {
            this.strTitle = strValue;
            return this;
        }
        
        public ContentVersionBuilder setPathOnClient(String strValue) {
            this.strPathOnClient = strValue;
            return this;
        }
        
        public ContentVersionBuilder setVersionData(String strValue) {
            this.blobVersionData = EncodingUtil.base64Decode(strValue);
            return this;
        }
        
        public ContentVersionBuilder setIsMajorVersion(Boolean blnValue) {
            this.blnIsMajorVersion = blnValue;
            return this;
        }
        
        public ContentVersion createContentVersion() {
            ContentVersion objContentVersion = new ContentVersion();
            objContentVersion.Title = this.strTitle;
            objContentVersion.PathOnClient = this.strPathOnclient;
            objContentVersion.VersionData = this.blobVersionData;
            objContentVersion.IsMajorVersion =this.blnIsMajorVersion;
            
            return objContentVersion;
        }
    }

    /**
    * @ Name     :  ContentDocumentLinkBuilder
    * @ Purpose  :  To create ContentDocumentLink record
    * @ Author   :  Rakesh Nayak
    **/
    public class ContentDocumentLinkBuilder {
        private Id idContentDocumentId;
        private String strVisibility;
        private String strShareType;
        private Id idLinkedEntityId;
        
        public ContentDocumentLinkBuilder() {
            this.strVisibility = '';
            this.strShareType = '';
        }
        
        public ContentDocumentLinkBuilder setContentDocumentId(Id idValue) {
            this.idContentDocumentId = idValue;
            return this;
        }
        
        public ContentDocumentLinkBuilder setLinkedEntityId(Id idValue) {
            this.idLinkedEntityId = idValue;
            return this;
        }
        
        public ContentDocumentLinkBuilder setShareType(String strValue) {
            this.strShareType = strValue;
            return this;
        }
        
        public ContentDocumentLinkBuilder setVisibility(String strValue) {
            this.strVisibility = strValue;
            return this;
        }
        
        public ContentDocumentLink createContentDocumentLink() {
            ContentDocumentLink objContentDocumentLink = new ContentDocumentLink();
            objContentDocumentLink.ContentDocumentId = this.idContentDocumentId;
            objContentDocumentLink.LinkedEntityId = this.idLinkedEntityId;
            objContentDocumentLink.ShareType = this.strShareType;
            objContentDocumentLink.Visibility = this.strVisibility;
            
            return objContentDocumentLink;
        }
    }

    /**
    * @ Name     :  FeedItemBuilder
    * @ Purpose  :  To create FeedItem record
    * @ Author   :  Rakesh Nayak
    **/
    public class FeedItemBuilder {
        private Id idParentId;
        private String strType;
        private String strBody;

        public FeedItemBuilder() {
            this.strType = '';
            this.strBody = '';
        }
        
        public FeedItemBuilder setParentId(Id idValue) {
            this.idParentId = idValue;
            return this;
        }
        
        public FeedItemBuilder setType(String strValue) {
            this.strType = strValue;
            return this;
        }

        public FeedItemBuilder setBody(String strValue) {
            this.strBody = strValue;
            return this;
        }
        
        public FeedItem createFeedItem() {
            FeedItem objFeedItem = new FeedItem();
            objFeedItem.ParentId = this.idParentId;
            objFeedItem.Type = this.strType;
            objFeedItem.Body = this.strBody;
            
            return objFeedItem;
        }
    }

    /**
    * @ Name     :  FeedItemDeleteEventBuilder
    * @ Purpose  :  To create DEL_FeedItemDeleteEvent__e record
    * @ Author   :  Rakesh Nayak
    **/
    public class FeedItemDeleteEventBuilder {
        private Id idCaseId;
        private Boolean blnIncomingEmail;
        
        public FeedItemDeleteEventBuilder setCaseId(Id idValue) {
            this.idCaseId = idValue;
            return this;
        }
        
        public FeedItemDeleteEventBuilder setIncomingEmail(Boolean blnValue) {
            this.blnIncomingEmail = blnValue;
            return this;
        }
        
        public DEL_FeedItemDeleteEvent__e createFeedItemDeleteEvent() {
            DEL_FeedItemDeleteEvent__e objFeedItemDeleteEvent = new DEL_FeedItemDeleteEvent__e();
            objFeedItemDeleteEvent.CaseId__c = this.idCaseId;
            objFeedItemDeleteEvent.IncomingEmail__c = this.blnIncomingemail;
            
            return objFeedItemDeleteEvent;
        }
    }

    /**
    * @ Name     :  KnowledgeConfigurationBuilder
    * @ Purpose  :  To create DEL_KnowledgeConfiguration__c record
    * @ Author   :  Rakesh Nayak
    **/
    public class KnowledgeConfigurationBuilder {
        private Id idParentCategoryId;
        private String strCategoryName;
        private Integer intSortOrder;
        private String strPageName;

        public KnowledgeConfigurationBuilder() {
            this.strCategoryName = '';
            this.strPageName  = '';
        }
        
        public KnowledgeConfigurationBuilder setParentCategory(Id idValue) {
            this.idParentCategoryId = idValue;
            return this;
        }
        
        public KnowledgeConfigurationBuilder setCategoryName(String strCategoryName) {
            this.strCategoryName = strCategoryName;
            return this;
        }

        public KnowledgeConfigurationBuilder setSortOrder(Integer intSortOrder) {
            this.intSortOrder = intSortOrder;
            return this;
        }

        public KnowledgeConfigurationBuilder setPageName(String strPageName) {
            this.strPageName = strPageName;
            return this;
        }
        
        public DEL_KnowledgeConfiguration__c createKnowledgeConfiguration() {
            DEL_KnowledgeConfiguration__c objKnowledgeConfiguration = new DEL_KnowledgeConfiguration__c();
            objKnowledgeConfiguration.Name = this.strCategoryName;
            objKnowledgeConfiguration.ParentCategory__c = this.idParentCategoryId;
            objKnowledgeConfiguration.SortOrder__c = this.intSortOrder;
            objKnowledgeConfiguration.PageName__c = this.strPageName;

            return objKnowledgeConfiguration;
        }
    }

    /**
    * @ Name     :  KnowledgeKavBuilder
    * @ Purpose  :  To create Knowledge__kav record
    * @ Author   :  G Nanda Kishore Reddy
    **/
    public class KnowledgeKavBuilder {
        private String strTitle;
        private String strurlName;
        private Double douSortOrder;

        public KnowledgeKavBuilder() {
            this.strTitle='';
            this.strUrlName='';
        }
        public KnowledgeKavBuilder setTitle(String strValue){
            this.strTitle=strValue;
            return this;
        }
        public KnowledgeKavBuilder setUrlName( String strValue){
            this.strUrlName=strValue;
            return this;
        }
      
        public KnowledgeKavBuilder setSortOrder( Double douValue){
            this.douSortOrder=douValue;
            return this;
        }
        public Knowledge__kav createKnowledgeKav(){
            Knowledge__kav objKnowledgekav= new Knowledge__kav();
            objKnowledgekav.Title=this.strTitle;
            objKnowledgekav.UrlName=this.strUrlName;
            objKnowledgekav.SortOrder__c=this.douSortOrder;
            return objKnowledgekav;
        }

    }

    /**
    * @ Name     :  KnowledgeCategorySelectionBuilder
    * @ Purpose  :  To create Knowledge__DataCategorySelection record
    * @ Author   :  G Nanda Kishore Reddy
    **/
    public class KnowledgeCategorySelectionBuilder {
        private Id idParentId;
        private String strDataCategoryGroupName;
        private String strDataCategoryName;

        public KnowledgeCategorySelectionBuilder() {
            this.strDataCategoryGroupName = '';
            this.strDataCategoryName = '';
        }

        public KnowledgeCategorySelectionBuilder setParentId(Id idValue){
            this.idParentId=idValue;
            return this;
        }
        public KnowledgeCategorySelectionBuilder setDataCategoryGroupName(String strValue){
            this.strDataCategoryGroupName=strValue;
            return this;
        }
        public KnowledgeCategorySelectionBuilder setDataCategoryName(String strValue){
            this.strDataCategoryName=strValue;
            return this;
        }
        public Knowledge__DataCategorySelection createKnowledgeDataCategorySelection(){
            Knowledge__DataCategorySelection objKnowledgeDataCategorySelection= new Knowledge__DataCategorySelection();
            objKnowledgeDataCategorySelection.ParentId=this.idParentId;
            objKnowledgeDataCategorySelection.DataCategoryGroupName=this.strDataCategoryGroupName;
            objKnowledgeDataCategorySelection.DataCategoryName=this.strDataCategoryName;
            return objKnowledgeDataCategorySelection;
        }
        
    }
}