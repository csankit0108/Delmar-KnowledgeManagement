import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from '@salesforce/apex';
import getCategorySelectionsByPage from '@salesforce/apex/DEL_KnowledgeManagementController.getCategorySelectionsByPage';
import saveCategories from '@salesforce/apex/DEL_KnowledgeManagementController.saveCategories';

//CLDEL00001 - "Error" (It stores the default title for error toast message.)
import CLDEL00001 from "@salesforce/label/c.CLDEL00001";
//CLDEL00007 - "Success" (It stores the title for success toast message.)
import CLDEL00007 from "@salesforce/label/c.CLDEL00007";
//CLDEL00021 - "Expand All" (This is a label value for 'Expand All' button)
import CLDEL00021 from "@salesforce/label/c.CLDEL00021";
//CLDEL00022 - "Collapse All" (This is a label value for 'Collapse All' button)
import CLDEL00022 from "@salesforce/label/c.CLDEL00022";
//CLDEL00024 - "Save" (This is a label value for 'Save' button)
import CLDEL00024 from "@salesforce/label/c.CLDEL00024";
//CLDEL00026 - "Category Name" (It stores the label for column name in tree)
import CLDEL00026 from "@salesforce/label/c.CLDEL00026";
//CLDEL00029 - "Table of Contents" (It stores the title for Selected Categories for the Customer Category Component)
import CLDEL00029 from "@salesforce/label/c.CLDEL00029";
//CLDEL00030 - "Selected Categories(It stores the title for Edit Categories Section for Customer Category Component)
import CLDEL00030 from "@salesforce/label/c.CLDEL00030";
//CLDEL00031 - "Edit Categories" (It stores the label for 'Edit Categories' button in Customer Category Component.)
import CLDEL00031 from "@salesforce/label/c.CLDEL00031";
//CLDEL00032 - "Cancel" (It stores the label for 'Cancel' button in Customer Category Component.)
import CLDEL00032 from "@salesforce/label/c.CLDEL00032";
//CLDEL00033 - "Successfully Saved Categories for" (It stores the Success Message for Successfully Saving of Selected Categories.)
import CLDEL00033 from "@salesforce/label/c.CLDEL00033";


export default class Del_DataCategoryTree extends NavigationMixin(LightningElement) {
    @api strPageName;
    @api blnShowExpandCollpaseButton;
    @api blnDefaultExpandCollapse;
    @api intTableHeight;
    @api strFontWeight;
    @api strFontStyle;
    @api strFontColor;
    @api blnSetUnderline;
    
    strExpandButtonLabel = CLDEL00021;
    strCollapseButtonLabel = CLDEL00022;
    strSavebuttonLabel = CLDEL00024;
    strTitleForCustomerComponent = CLDEL00029;
    strTitleForSelectedCategories = CLDEL00030;
    strEditCategoriesButtonLabel = CLDEL00031;
    strCancelButtonLabel = CLDEL00032;

    blnEditForExpand;
    blnEditForCollapse;
    blnShowGrid = false;
    blnIsEditMode = false;
    blnDraggable = false;
    blnIsToggle = false;
    blnCollapse = false;
    blnLoading = false;
    blnSaveDisabled = true;
    blnEditVisible = false;
    blnIsTreeLoaded = false;
    blnSelectedExpandCollapseTree = true;
    blnSelectedExpandCollapseTreeGrid = false;
    wiredCategoryData;
    blnIsPortalEnabled;
    map_NameToIndexMapping;
    map_ArticlesByCategoryName = [];
    map_CategoryByParent = [];
    map_LabelNameByUniqueNameCategories;
    list_GroupCategoryNames = [];
    @track items = [];
    @track list_Categories;
    @track list_KnowledgeArticles;
    @track list_AvailableCategories = [];
    @track list_SelectedCategories = [];
    @track list_SelectedCategoryNames = [];
    @track list_SelectedCategoryNamesOld = [];
    @track list_SelectedCategoryNamesBackup = [];
    @track gridData = [];
    @track gridColumns = [{
        type: 'text',
        fieldName: 'label',
        label: CLDEL00026
    }];
    
    renderedCallback() {
        this.blnIsTreeLoaded = true;
    }
    
    @wire(getCategorySelectionsByPage, {strPageName : '$strPageName'})
    wiredCategoryData(result) {
        this.wiredCategoryData  = result;
        const {error, data} = result;
        if (data) {
            this.blnSelectedExpandCollapseTree = this.blnDefaultExpandCollapse;
            this.blnShowGrid = true;
            this.gridData = [];
            this.list_SelectedCategoryNames = [];
            this.list_SelectedCategoryNamesBackup = [];
            this.list_SelectedCategoryNamesOld = [];

            this.list_SelectedCategories = JSON.parse(JSON.stringify(data.list_SelectedCategories));
            this.list_AvailableCategories = JSON.parse(JSON.stringify(data.list_AvailableCategories));
            this.map_CategoryByParent = JSON.parse(JSON.stringify(data.map_CategoryByParent));
            this.map_ArticlesByCategoryName = JSON.parse(JSON.stringify(data.map_ArticlesByCategoryName));
            this.map_LabelNameByUniqueNameCategories = JSON.parse(JSON.stringify(data.map_CategoriesByUniqueName));
            this.list_GroupCategoryNames = JSON.parse(JSON.stringify(data.list_GroupCategoryNames));

            let objUserInformation = JSON.parse(JSON.stringify(data.objUserInformation));
            this.blnIsPortalEnabled = data.objUserInformation.IsPortalEnabled;
            if (objUserInformation && !objUserInformation.IsPortalEnabled && 
                objUserInformation.hasOwnProperty('UserPermissionsKnowledgeUser') &&
                objUserInformation["UserPermissionsKnowledgeUser"]
            ) {
                this.blnEditVisible = true;
            }
            this.filterKnowledgeArticles(objUserInformation.LanguageLocaleKey);
            this.selectedCategoriesFilter(this.list_SelectedCategories);
            this.sortTreeItems(this.list_AvailableCategories);
            this.makeTree(this.list_AvailableCategories, false);
            this.sortTreeItems(this.list_SelectedCategories);
            this.makeTree(this.list_SelectedCategories, true);
            this.changeAttributeNameOfItems(this.items);
            this.list_Categories = this.items;
            
            this.template.querySelector('c-tree').normalizeData(this.list_Categories);
            
            this.blnLoading = false;
        } else if (error) {
            this.showToastMessage(CLDEL00001, error.body.message, 'error');
            this.blnLoading = false;
        }
    }
    
    /**
     * @ author      : Vinay kant
     * @ description : This method will recheck the selected categories and their order based on available categories.
     * @ params      : 'list_SelectedCategories' - List of Knowledge Configuration records selected for the instance.
    **/
    selectedCategoriesFilter(list_SelectedCategories){
        let map_SortingOrderByAdminSetupConfigs = this.list_AvailableCategories.reduce( (objMapNameToIndex, objKnowledgeConfiguration, index) => {
            objMapNameToIndex[objKnowledgeConfiguration.Name] = objKnowledgeConfiguration.SortOrder__c;
            return objMapNameToIndex;
        }, {} );
        list_SelectedCategories.forEach((eachConfig, index) => {
            if (map_SortingOrderByAdminSetupConfigs.hasOwnProperty(eachConfig.Name)) {
                eachConfig.SortOrder__c = map_SortingOrderByAdminSetupConfigs[eachConfig.Name];
            } else {
                list_SelectedCategories.splice(index, 1);
            }
        });
    }

    /**
     * @ author      : Vinay kant & Ankit C
     * @ description : This method will form a tree structure consisting of list of nested JSON Objects.
     * @ params      : 'list_KnowledgeConfigsRecords' - List of Knowledge Configuration records.
     *               : 'blnIsTree' - Boolean Value to distinguish Available and Selected Categories based on Instance Name.
    **/
    makeTree (list_KnowledgeConfigsRecords, blnIsTree) {
        this.list_GroupCategoryNames.forEach((groupCategoryName, index) =>{
            list_KnowledgeConfigsRecords.push({
                Name : groupCategoryName,
                SortOrder__c : index + 1
            })
        });

        const nameMappingConfigs = list_KnowledgeConfigsRecords.reduce( (objMapNameToIndex, objKnowledgeConfiguration, index) => {
            objMapNameToIndex[objKnowledgeConfiguration.Name] = index;
            return objMapNameToIndex;
        }, {} );

        list_KnowledgeConfigsRecords.forEach(objKnowledgeConfiguration => {
            let root = objKnowledgeConfiguration;
            if (blnIsTree) {
                this.list_SelectedCategoryNames.push(objKnowledgeConfiguration.Name);
                this.list_SelectedCategoryNamesOld.push(objKnowledgeConfiguration.Name);
                this.list_SelectedCategoryNamesBackup = this.list_SelectedCategoryNames;
                
                if (this.list_GroupCategoryNames.includes(this.map_CategoryByParent[objKnowledgeConfiguration.Name])) {
                    if (this.map_ArticlesByCategoryName[objKnowledgeConfiguration.Name]) {
                        for (let objArticle of this.map_ArticlesByCategoryName[objKnowledgeConfiguration.Name]) {
                            root.items = [...(root["items"] || []), objArticle];
                        }
                    }
                    this.items.push(root);
                } else {
                    let parentCategory = list_KnowledgeConfigsRecords[nameMappingConfigs[this.map_CategoryByParent[objKnowledgeConfiguration.Name]]];
                    if (parentCategory) {
                        parentCategory.items = [...(parentCategory["items"] || []), objKnowledgeConfiguration];
                    }
                    let child = list_KnowledgeConfigsRecords[nameMappingConfigs[objKnowledgeConfiguration.Name]];
                    if (this.map_ArticlesByCategoryName[objKnowledgeConfiguration.Name]) {
                        for (let objArticle of this.map_ArticlesByCategoryName[objKnowledgeConfiguration.Name]) {
                            child.items = [...(child["items"] || []), objArticle];
                        }
                    }
                }
            } else {
                if (!this.map_CategoryByParent[objKnowledgeConfiguration.Name]) {
                    root.name = objKnowledgeConfiguration.Name;
                    root.label = this.map_LabelNameByUniqueNameCategories[objKnowledgeConfiguration.Name];
                    this.gridData.push(root);
                } else {
                    objKnowledgeConfiguration.name = objKnowledgeConfiguration.Name;
                    objKnowledgeConfiguration.label = this.map_LabelNameByUniqueNameCategories[objKnowledgeConfiguration.Name];
                    let parentCategory = list_KnowledgeConfigsRecords[nameMappingConfigs[this.map_CategoryByParent[objKnowledgeConfiguration.Name]]];
                    
                    if (parentCategory) {
                        parentCategory._children = [...(parentCategory["_children"] || []), objKnowledgeConfiguration];
                    }
                }
            }
        });
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will change/remove attribute of formed nested JSON Tree.
     * @ params      : 'list_nestedTreeNodes' - List of nested JSON Object (Tree Structure)
    **/
    changeAttributeNameOfItems (list_nestedTreeNodes) {
        list_nestedTreeNodes.forEach(objCategory => { 
            if (objCategory.hasOwnProperty("Title")) {
                objCategory["label"] = objCategory.Title;
                objCategory["name"] = this.blnIsPortalEnabled ? objCategory.KnowledgeArticleId : objCategory.Id;
                objCategory["expanded"] = false;
                objCategory["type"] = 'url';

                if (objCategory.hasOwnProperty("Title")) {
                    delete objCategory["Title"];
                }
                if (objCategory.hasOwnProperty("PublishStatus")) {
                    delete objCategory["PublishStatus"];
                }
                if (objCategory.hasOwnProperty("VersionNumber")) {
                    delete objCategory["VersionNumber"];
                }
                if (objCategory.hasOwnProperty("KnowledgeArticleId")) {
                    delete objCategory["KnowledgeArticleId"];
                }

            } else {
                objCategory["label"] = this.map_LabelNameByUniqueNameCategories[objCategory.Name];
                objCategory["name"] = objCategory.Name;
                objCategory["expanded"] = this.blnDefaultExpandCollapse;

                if (objCategory.hasOwnProperty("Id")) {
                    delete objCategory["Id"];
                }
                if (objCategory.hasOwnProperty("Name")) {
                    delete objCategory["Name"];
                }
                if (objCategory.hasOwnProperty("SortOrder__c")) {
                    delete objCategory["SortOrder__c"];
                }
                if (objCategory.hasOwnProperty("ParentCategory__c")) {
                    delete objCategory["ParentCategory__c"];
                }
            }

            if (objCategory.hasOwnProperty("items")) {
                this.changeAttributeNameOfItems(objCategory["items"]);
            } else {
                objCategory["items"] = [];
            }
        });
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will sort the tree nodes based on SortOrder__c attribute.
     * @ params      : 'list_nestedTreeNodes' - List of nested JSON Object (Tree Structure)
    **/
    sortTreeItems(list_nestedTreeNodes) {
        return list_nestedTreeNodes.sort((objFirst, objSecond) => {
            var intFirstObjSortOrder = objFirst.SortOrder__c;
            var intSecondObjSortOrder = objSecond.SortOrder__c;
            if (objFirst.hasOwnProperty("items")) {
                this.sortTreeItems(objFirst.items);
            }
            if (objSecond.hasOwnProperty("items")) {
                this.sortTreeItems(objSecond.items);
            }
            if(intFirstObjSortOrder < intSecondObjSortOrder) return -1;
            if(intFirstObjSortOrder > intSecondObjSortOrder) return 1;
            return 0;
        });
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will filter knowledge article records based on logged-in user preference language.
     * @ params      : 'strUserLanguageCode' - Current logged-in user preference language code.
    **/
    filterKnowledgeArticles (strUserLanguageCode) {
        Object.keys(this.map_ArticlesByCategoryName).forEach(eachCategory => {
            let listKnowledgeArticlesCategory = this.map_ArticlesByCategoryName[eachCategory];
            let listKnowledgeArticlesTemp = [];
            let map_ArticlesByKnowledgeArticleId = {};
            for (let article of listKnowledgeArticlesCategory) {
                let listArticle = []; 
                if (!map_ArticlesByKnowledgeArticleId.hasOwnProperty(article.KnowledgeArticleId)) {
                    listArticle.push(article);
                    map_ArticlesByKnowledgeArticleId[article.KnowledgeArticleId] = listArticle;
                } else {
                    listArticle = map_ArticlesByKnowledgeArticleId[article.KnowledgeArticleId];
                    listArticle.push(article);
                }
                map_ArticlesByKnowledgeArticleId[article.KnowledgeArticleId] = listArticle;
            }
            Object.keys(map_ArticlesByKnowledgeArticleId).forEach(idKnowledgeArticleId => {
                let list_Articles = map_ArticlesByKnowledgeArticleId[idKnowledgeArticleId];
                let filtered_Articles = [...list_Articles].filter(article => article.Language === strUserLanguageCode);
                if (filtered_Articles.length < 1) {
                    filtered_Articles = [...list_Articles].filter(article => article.IsMasterLanguage === true);
                }
                listKnowledgeArticlesTemp.push(...filtered_Articles);
            });
            this.map_ArticlesByCategoryName[eachCategory] = this.sortTreeItems(listKnowledgeArticlesTemp);
        });
    }

    /**
     * @ author      : Ankit C
     * @ description : 
    **/
    handleToggle(event) {
        if (!event.detail.isExpanded && event.detail.hasChildrenContent) {
            this.blnIsToggle = true;
        }
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will handle the row selection event of Tree-Grid Lightning Component after Edit Categories.
    **/
    handleRowSelection (event) {
        if (this.blnIsToggle) {
            this.blnIsToggle = false;
            return;
        }

        if (this.blnCollapse) {
            this.list_SelectedCategoryNamesBackup = this.list_SelectedCategoryNames;
            this.blnCollapse = false;
        } else {
            let list_ChildCategoriesNames = [];
            let list_NewlyAddedCategories = event.detail.selectedRows.filter(element1 => !this.list_SelectedCategoryNames.some(element2 => element1.name === element2)).map(element => element.name);
            let gridDataTemp = this.gridData;
            if (list_NewlyAddedCategories) {
                list_ChildCategoriesNames = this.fetchChildCategories(gridDataTemp, list_NewlyAddedCategories);
            }

            this.list_SelectedCategoryNames = [];
            this.list_SelectedCategoryNames.push(...list_ChildCategoriesNames);
            for (let objSelectedCategory of event.detail.selectedRows) {
                if (!this.list_SelectedCategoryNames.includes(objSelectedCategory.name)) {
                    this.list_SelectedCategoryNames.push(objSelectedCategory.name);
                }

                let list_Temp = [];
                let list_ParentCategoryNames = this.getParentCategories(objSelectedCategory.name, list_Temp);
                for (let objParentName of list_ParentCategoryNames) {
                    if (!this.list_SelectedCategoryNames.includes(objParentName)) {
                        this.list_SelectedCategoryNames.push(objParentName);
                    }
                }
            }
            this.list_SelectedCategoryNames = [...new Set(this.list_SelectedCategoryNames)];
            this.list_SelectedCategoryNamesBackup = this.list_SelectedCategoryNames;
        }

        //Two Lists Comparing Method Defination - 'compareLists'
        //Return true if both lists consists of same elements
        const compareLists = (listOne, listTwo) => listOne.length === listTwo.length && listOne.every((element) => listTwo.includes(element));
        
        if (!compareLists(this.list_SelectedCategoryNames, this.list_SelectedCategoryNamesOld)) {
            this.blnSaveDisabled = false;
        } else {
            this.blnSaveDisabled = true;
        }
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will get all parent names for selected category Lightning Tree Grid Component.
     * @ params      : 'strSubcategory' - Newly selected category name from 'handleRowSelection()' method.
     *               : 'list_AllParentNames' - List of Parent names to be stored on every recursion
     * @ return      : 'list_AllParentNames' - List of all Parent names of 'strSubcategory'
    **/
    getParentCategories(strSubcategory, list_AllParentNames) {
        if (this.map_CategoryByParent[strSubcategory]) {
                if (!list_AllParentNames.includes(this.map_CategoryByParent[strSubcategory])) {
                    list_AllParentNames.unshift(this.map_CategoryByParent[strSubcategory]);
                    this.getParentCategories(this.map_CategoryByParent[strSubcategory], list_AllParentNames);
                }
            return list_AllParentNames;
        } else {
            return list_AllParentNames;
        }
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will get all parent names for selected category Lightning Tree-Grid Component.
     * @ params      : 'list_nestedTreeNodes' - Passing 'gridData' which is list nested JSON Object for Lightning Tree-Grid Component.
     *               : 'list_NewlyAddedCategories' - List of all child Categories if parent is Selected to be stored in every recursion.
     * @ return      : 'list_NewlyAddedCategories' - List of all child Categories if parent is Selected.
    **/
    fetchChildCategories (list_nestedTreeNodes, list_NewlyAddedCategories) {
        list_nestedTreeNodes.forEach(objTreeNode => {
            if (!list_NewlyAddedCategories.includes(objTreeNode.name)) {
                if (objTreeNode._children) {
                    this.fetchChildCategories(objTreeNode._children, list_NewlyAddedCategories);
                }
            } else {
                if (objTreeNode._children) {
                    let childCategoriesNames = [...objTreeNode._children].map(element => element.name);
                    list_NewlyAddedCategories.push(...childCategoriesNames);
                    this.fetchChildCategories(objTreeNode._children, list_NewlyAddedCategories);
                }
            }
        });
        return list_NewlyAddedCategories;
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will handle Expand All/Collapse All Button Event to expand/collapse tree structure.
    **/
     handleClickExpandCollapse (event) {
        if (event.target.name == 'treegrid') {
            const treeGrid =  this.template.querySelector('lightning-tree-grid');
            this.blnSelectedExpandCollapseTreeGrid = !this.blnSelectedExpandCollapseTreeGrid;
            if (this.blnSelectedExpandCollapseTreeGrid) {
                this.blnCollapse = true;
                treeGrid.expandAll();
                if (!this.blnEditForExpand) {
                    this.list_SelectedCategoryNames = this.list_SelectedCategoryNamesBackup;
                }
                this.blnEditForExpand = !this.blnEditForExpand;
                this.blnCollapse = false;
            } else {
                this.blnCollapse = true;
                treeGrid.collapseAll();
                if (!this.blnEditForCollapse) {
                    this.list_SelectedCategoryNames = this.list_SelectedCategoryNamesBackup;
                }
                this.blnEditForCollapse = !this.blnEditForCollapse;
            }
        }

        if (event.target.name == 'tree') {
            this.blnSelectedExpandCollapseTree = !this.blnSelectedExpandCollapseTree;
            this.changeExpandCollapse(this.items, this.blnSelectedExpandCollapseTree);
            this.list_Categories = this.items;
            this.template.querySelector('c-tree').normalizeData(this.items);
        }
    }

    /**
     * @ author      : Vinay kant
     * @ description : This recursive method will change the expanded value true/false.
     * @ params      : 'list_nestedTreeNodes' - List of nested JSON Object (Tree Structure)
    **/
    changeExpandCollapse (list_nestedTreeNodes, blnExpandCollapse) {
        list_nestedTreeNodes.forEach(objTreeNode => {
            if (!objTreeNode.hasOwnProperty("Title")) {
                objTreeNode.expanded = blnExpandCollapse;
            }
            if (objTreeNode.items) {
                this.changeExpandCollapse(objTreeNode.items, blnExpandCollapse);
            }
        });
    }

    /**
     * @ author      : Vinay kant & Ankit C
     * @ description : This method will handle tree node select event.
    **/
    handleOnSelect(event) {
        let list_Articles = [];
        Object.keys(this.map_ArticlesByCategoryName).forEach(objCategory => {
            list_Articles.push(...this.map_ArticlesByCategoryName[objCategory]);
        });
        let list_ArticlesIds = list_Articles.map(objArticle => objArticle.name);
        if (list_ArticlesIds.includes(event.detail.name)){
            this[NavigationMixin.GenerateUrl]({
                type: "standard__recordPage",
                attributes: {
                    recordId: event.detail.name,
                    actionName: "view"
                }
            }).then((url) => {
                window.open(url);
            });
        }
    }

    /**
     * @ author      : Vinay kant & Ankit C
     * @ description : This method will handle Edit Categories Button Events.
    **/
    handleEditCategories(event) {
        this.blnIsEditMode = true;
        this.list_SelectedCategoryNames = this.list_SelectedCategoryNamesOld;
        this.blnEditForExpand = true;
        this.blnEditForCollapse = true;
    }

    /**
     * @ author      : Vinay kant & Ankit C
     * @ description : This method will handle Cancel/Reset Button Events.
    **/
    handleOnCancel(event) {
        this.blnIsEditMode = false;
        this.list_SelectedCategoryNames = this.list_SelectedCategoryNamesOld;
        if (this.blnSelectedExpandCollapseTreeGrid) {
            this.blnSelectedExpandCollapseTreeGrid = !this.blnSelectedExpandCollapseTreeGrid;
        }
        this.blnEditForExpand = false;
        this.blnEditForCollapse = false;
        this.blnSaveDisabled = true;
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will save the selected Categories for the current Instance Name from Lightning Tree-Grid Component.
    **/
    handleOnSave(event) {
        let gridDataClone = this.gridData;
        let listFinalCategories = [];
        listFinalCategories = this.allSelectedCategories(gridDataClone, listFinalCategories);
        this.blnLoading = true;

        /**
         * @ author      : Vinay kant
         * @ description : This apex method will save all selected categories for the current Instance name given in the component.
         *                 - 'DEL_KnowledgemanagementController.saveCategories()'
         * @ params      : 'list_SubcategoriesSelected' - List of categories Selected in the Tree-Grid Component
         *               : 'map_CategoryByParent' - Map of all Categories by thier corresponding Parent Category.
         *               : 'strPageName' - Instance Name given while embedding the component on the Salesforce.
        **/
        saveCategories({
            list_SubcategoriesSelected: listFinalCategories,
            map_CategoryByParent: this.map_CategoryByParent,
            strPageName: this.strPageName
        })
        .then(result => {
            this.showToastMessage(CLDEL00007, CLDEL00033+' '+this.strPageName, 'success');
            this.blnIsEditMode = false;

            this.blnSelectedExpandCollapseTree = !this.blnSelectedExpandCollapseTree;
            if (this.blnSelectedExpandCollapseTreeGrid) {
                this.blnSelectedExpandCollapseTreeGrid = !this.blnSelectedExpandCollapseTreeGrid;
            }

            refreshApex(this.wiredCategoryData);
        })
        .catch(error => {
            this.showToastMessage(CLDEL00001, error.body.message, 'error');
        });
        
        this.blnSaveDisabled = true;
    }

    /**
     * @ author      : Vinay kant
     * @ description : This recursive method will save all selected categories with 'name' and 'sortorder' attribute.
     * @ params      : 'list_nestedTreeNodes' - List of nested JSON objects (Tree Structure)
     *               : 'listFinalCategories' - List of nested JSON Object (Tree Structure) with 'name' and 'sortorder' attribute in every recursion.
     * @ return      : 'listFinalCategories' - List of nested JSON objects (Tree Structure) with 'name' and 'sortorder' attribute;
    **/
    allSelectedCategories(list_nestedTreeNodes, listFinalCategories) {
        list_nestedTreeNodes.forEach(objTreeNode => {
            if (this.list_SelectedCategoryNames.includes(objTreeNode.name)) {
                listFinalCategories.push({name : objTreeNode.name, sortorder : objTreeNode.SortOrder__c});
            }
            if (objTreeNode._children) {
                this.allSelectedCategories(objTreeNode._children, listFinalCategories);
            }
        });
        return listFinalCategories;
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
