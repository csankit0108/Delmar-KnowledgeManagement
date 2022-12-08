import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import { NavigationMixin } from 'lightning/navigation';
import getCategoryData from "@salesforce/apex/DEL_KnowledgeManagementController.getDescribeDataCategoryGroupStructureResults";
import saveSelectedCategories from "@salesforce/apex/DEL_KnowledgeManagementController.saveCategories";
import setknowledgeArticlesOrder from '@salesforce/apex/DEL_KnowledgeManagementController.setknowledgeArticlesOrder';

//CLDEL00001 - "Error" (It stores the default title for error toast message.)
import CLDEL00001 from "@salesforce/label/c.CLDEL00001";
//CLDEL00007 - "Success" (It stores the title for success toast message.)
import CLDEL00007 from "@salesforce/label/c.CLDEL00007";
//CLDEL00019 - "Available Categories" (It stores the title for the available categories tree grid)
import CLDEL00019 from "@salesforce/label/c.CLDEL00019";
//CLDEL00020 - "Selected Categories(Drag/drop to reorder" (It stores the title for the selected categories tree)
import CLDEL00020 from "@salesforce/label/c.CLDEL00020";
//CLDEL00021 - "Expand All" (This is a label value for 'Expand All' button)
import CLDEL00021 from "@salesforce/label/c.CLDEL00021";
//CLDEL00022 - "Collapse All" (This is a label value for 'Collapse All' button)
import CLDEL00022 from "@salesforce/label/c.CLDEL00022";
//CLDEL00023 - "Reset" (This is a label value for 'Reset' button)
import CLDEL00023 from "@salesforce/label/c.CLDEL00023";
//CLDEL00024 - "Save" (This is a label value for 'Save' button)
import CLDEL00024 from "@salesforce/label/c.CLDEL00024";
//CLDEL00025 - "Sort Articles for Category:" (It stores the title for the available knowledge articles for a category)
import CLDEL00025 from "@salesforce/label/c.CLDEL00025";
//CLDEL00026 - "Category Name" (It stores the label for column name in tree)
import CLDEL00026 from "@salesforce/label/c.CLDEL00026";
//CLDEL00034 - "Article Title" (It stores the column name for knowledge articles table in admin component)
import CLDEL00034 from "@salesforce/label/c.CLDEL00034";
//CLDEL00035 - "Saved All Categories and Articles" (It stores the success message of saving Categories and Knowledge Articles Sort Order)
import CLDEL00035 from "@salesforce/label/c.CLDEL00035";

export default class Del_knowledgeArticlesComponent extends NavigationMixin(LightningElement) {
    
    strAvailableCategoriesTreeTitle = CLDEL00019;
    strSelectedCategoriesTreeTitle = CLDEL00020;
    strExpandAllButtonLabel = CLDEL00021;
    strCollapseAllButtonLabel = CLDEL00022;
    strResetButtonLabel = CLDEL00023;
    strSaveButtonLabel = CLDEL00024;
    strKnowledgeArticleColumnName = CLDEL00034;

    blnCollapse = false;
    blnShowTreeGrid = false;
    blnIsToggle = false;
    blnDraggable = true;
    blnIsTreeLoaded = false;
    blnSelectedExpandCollapseTree = true;
    blnSelectedExpandCollapseTreeGrid = false;

    @track wiredCategoryData;
    dragStart;
    map_knowledgeArticlesByCategory;
    map_UniqueNameCategoriesByLabelName;
    strUserLanguage;

    map_CategoryByParent = [];
    map_NameToIndexMapping = [];
    list_FinalSortedCategories = [];
    list_GroupCategoryNames = [];
    list_selectedConfigurationNames = [];
    map_ChildCategoriesByParent = [];

    @track blnIsLoading = false;
    @track blnDisableSaveButton = true;
    @track blnIsResetDisabled = true;
    @track strKnowledgeArticleTableTitle;
    @track list_KnowledgeArticles;
    @track visibleSaveButton;
    @track selectedTreeNode;
    @track list_SelectedCategories = [];
    @track list_Categories = [];
    @track list_SelectedCategoryNames = [];
    @track list_SelectedCategoryNamesBackup = [];
    @track gridColumns = [{
        type: 'text',
        fieldName: 'categoryLabel',
        label: CLDEL00026
    }];
    @track gridData = [];

    constructor() {
        super();
        
        /*this.template.addEventListener(
            'privateitemclick',
            this.handleCategorySelect.bind(this)
        );*/
        
        this.template.addEventListener(
            'privateupdatedtree',
            this.handleUpdatedTree.bind(this)
        );
            
    }

    renderedCallback () {
        this.blnIsTreeLoaded = true;
    }

    /**
    *@ author      : Vinaykant
    *@ description : This method will get the updated tree when there is a change on Tree Nodes Order.
    **/
    handleUpdatedTree (event) {
        this.list_SelectedCategories = event.detail.tree;
        this.blnDisableSaveButton = false;
        this.blnIsResetDisabled = false;
    }

    /**
    *@ author      : Ankit C & Rakesh Nayak
    *@ description : This method queries all the data categories from the active category groups 
    *                and existing configuration records
    **/
    @wire(getCategoryData)
    categoryData(result) {
        this.wiredCategoryData  = result;
        const {error, data} = result;
        if (data) {
            this.gridData = [];
            this.list_SelectedCategories = [];
            this.list_KnowledgeArticles = null;
            this.strKnowledgeArticleTableTitle = null;
            this.blnSelectedExpandCollapseTree = true;
            this.blnSelectedExpandCollapseTreeGrid = false;

            let list_AllCategories = JSON.parse(JSON.stringify(data.list_AllCategories));
            this.map_CategoryByParent = data.map_CategoryByParent;
            this.list_SelectedCategoryNames = data.list_DefaultSortedCategories;
            this.list_SelectedCategoryNamesBackup = data.list_DefaultSortedCategories;
            this.list_selectedConfigurationNames = data.list_DefaultSortedCategories;
            this.map_UniqueNameCategoriesByLabelName = data.map_CategoriesByUniqueName;
            this.map_ChildCategoriesByParent = JSON.parse(JSON.stringify(data.map_ChildCategoriesByParent));
            this.map_knowledgeArticlesByCategory = JSON.parse(JSON.stringify(data.map_KnowledgeArticlesByCategoryUniqueName));
            this.list_GroupCategoryNames = JSON.parse(JSON.stringify(data.list_GroupCategoryNames));

            if (data.hasOwnProperty("objUserInformation")) {
                this.visibleSaveButton = data.objUserInformation.UserPermissionsKnowledgeUser;
                this.filterKnowledgeArticles(data.objUserInformation.LanguageLocaleKey);
                this.strUserLanguage = data.objUserInformation.LanguageLocaleKey;
            }

            this.createTree(this.list_SelectedCategoryNames);

            this.map_NameToIndexMapping = list_AllCategories.reduce( (objMapNameToIndex, objCategoryName, index) => {
                objCategoryName.categoryLabel = this.map_UniqueNameCategoriesByLabelName[objCategoryName.name];
                objMapNameToIndex[objCategoryName.name] = index;
                return objMapNameToIndex;
            }, {} );

            list_AllCategories.forEach(objCategoryName => {
                let root = {};
                if (!this.map_CategoryByParent[objCategoryName.name]) {
                    root = objCategoryName;
                    this.gridData.push(root);
                } else {
                    let parentCategory = list_AllCategories[this.map_NameToIndexMapping[this.map_CategoryByParent[objCategoryName.name]]];
                    if (parentCategory) {
                        parentCategory._children = [...(parentCategory["_children"] || []), objCategoryName];
                    }
                }
            });
            this.blnShowTreeGrid = true;
            this.list_Categories = [];
            for (let objParentCategory of data.list_ParentCategoryNames) {
                this.list_Categories.push({ label: objParentCategory, value: objParentCategory});
            }

            this.blnIsLoading = false;
        } else if (error) {
            this.showToastMessage(CLDEL00001, error.body.message , 'error');
            this.blnIsLoading = false;
        }
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will sort the Object based on 'SortOrder__c' attribute.
     * @ params      : 'list_KnowledgeArticles' - List of Knowledge Articles records.
    **/
    sortObjectItems(list_KnowledgeArticles) {
        return list_KnowledgeArticles.sort((objFirst, objSecond) => {
                if (objFirst.hasOwnProperty('SortOrder__c') && objFirst.hasOwnProperty('SortOrder__c')) {
                    var intFirstObjSortOrder = objFirst.SortOrder__c;
                    var intSecondObjSortOrder = objSecond.SortOrder__c;
                    if(intFirstObjSortOrder < intSecondObjSortOrder) return -1;
                    if(intFirstObjSortOrder > intSecondObjSortOrder) return 1;
                    return 0;
                }
            });
    }

    /**
     * @ author      : Vinay kant
     * @ description : This method will filter knowledge article records based on logged-in user preference language.
     * @ params      : 'strUserLanguageCode' - Current logged-in user preference language code.
    **/
    filterKnowledgeArticles (strUserLanguageCode) {
        Object.keys(this.map_knowledgeArticlesByCategory).forEach(eachCategory => {
            let listKnowledgeArticlesCategory = this.map_knowledgeArticlesByCategory[eachCategory];
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
            this.map_knowledgeArticlesByCategory[eachCategory] = this.sortObjectItems(listKnowledgeArticlesTemp);
        });
    }

    /**
    *@ author      : Ankit C
    *@ description : This method is used to assign the sort orders for selected categories.
    **/
    assignSortOrder(data) {
        for (let i=0; i<data.length; i++) {
            let temp = data[i]
            temp.sortorder = i + 1;
            let temp2 = {};
            temp2.name = data[i].name;
            temp2.sortorder = i + 1;
            this.list_FinalSortedCategories.push(temp2);
            if(data[i].items && data[i].items.length > 0) {
                this.assignSortOrder(data[i].items);
            }
        }
    }

    /**
    *@ author      : Ankit C & Rakesh Nayak
    *@ description : This method is used to handle the operations on selection of category from available categories.
    **/
    handleRowSelection(event) {
        if (this.blnIsToggle ) {
            this.blnIsToggle = false;
            return;
        }

        if (this.blnCollapse) {
            this.list_SelectedCategoryNamesBackup = this.list_SelectedCategoryNames;
            this.blnCollapse = false;
        } else {
            this.blnDisableSaveButton = false;
            this.blnIsResetDisabled  = false;
            let list_NewlyAddedCategories = event.detail.selectedRows.filter(element1 => !this.list_SelectedCategoryNames.some(element2 => element1.name === element2)).map(element => element.name);
            let list_ChildCategoryNamesTemp = [];
            let list_ChildCategoryNames = [];
            if(list_NewlyAddedCategories.length > 0) {
                list_ChildCategoryNames = this.fetchChildCategories(list_NewlyAddedCategories, list_ChildCategoryNamesTemp);
            }

            this.list_SelectedCategories = [];
            let list_SelectedCategoriesTemp = [];
            this.list_SelectedCategoryNames = [];
            list_ChildCategoryNames.forEach(strCategory => this.list_SelectedCategoryNames.push(strCategory));
            try {
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

                if (!this.list_SelectedCategoryNames.includes(this.selectedTreeNode)) {
                    this.list_KnowledgeArticles = null;
                    this.strKnowledgeArticleTableTitle = null;
                    this.selectedTreeNode = null;
                }

                this.list_SelectedCategoryNames.forEach(objSelectedCategoryName => {
                    list_SelectedCategoriesTemp.push({ 
                        label : this.map_UniqueNameCategoriesByLabelName[objSelectedCategoryName], 
                        name : objSelectedCategoryName,
                        expanded: true 
                    });
                });
                this.list_SelectedCategoryNamesBackup = this.list_SelectedCategoryNames;

                let map_NameIndexMapping = list_SelectedCategoriesTemp.reduce((objMapNameToIndex, objCategoryName, index) => {
                    objMapNameToIndex[objCategoryName.name] = index;
                    return objMapNameToIndex;
                }, {} );

                list_SelectedCategoriesTemp.forEach(objSelectedCategory => {
                    let root = {};
                    if (this.list_GroupCategoryNames.includes(this.map_CategoryByParent[objSelectedCategory.name])) {
                        root = objSelectedCategory;
                        this.list_SelectedCategories.push(root);
                    } else {
                        let objParentCategory = list_SelectedCategoriesTemp[map_NameIndexMapping[this.map_CategoryByParent[objSelectedCategory.name]]];
                        if (objParentCategory) {
                            objParentCategory.items = [...(objParentCategory["items"] || []), objSelectedCategory];
                        }
                    }
                });
            } catch(error) {
                this.showToastMessage(CLDEL00001, error, 'error');
            }

            if(this.blnIsTreeLoaded) {
                this.template.querySelector('c-tree').normalizeData(this.list_SelectedCategories);
            }
        }
    }

    /**
    *@ author      : Ankit C
    *@ description : This method is used to handle the expand/collapse of category in available categories tree
    **/
    handleToggle(event) {
        if (!event.detail.isExpanded && event.detail.hasChildrenContent) {
            this.blnIsToggle = true;
        }
    }

    /**
    *@ author      : Vinaykant
    *@ description : This method will call the list of knowledge Articles if the Category is selected
    **/
    handleCategorySelect(event) {
        this.list_KnowledgeArticles = [];
        this.selectedTreeNode = event.detail.name;
        if (this.map_knowledgeArticlesByCategory.hasOwnProperty(this.selectedTreeNode)) {
            this.list_KnowledgeArticles = this.map_knowledgeArticlesByCategory[this.selectedTreeNode];
            this.setSortOrderForKnowledgeArticles();
            this.strKnowledgeArticleTableTitle = CLDEL00025 + " " + this.map_UniqueNameCategoriesByLabelName[this.selectedTreeNode];
        } else {
            this.list_KnowledgeArticles = null;
            this.strKnowledgeArticleTableTitle = null;
            this.selectedTreeNode = null;
        }
    }

    /**
    *@ author      : Rakesh Nayak
    *@ description : This method is used to create/update knowlwdge configuration records and update knowledge 
    *                article records on click of save button
    **/
    handleCategorySave() {
        this.blnIsLoading = true;
        this.list_FinalSortedCategories = [];
        this.assignSortOrder(this.list_SelectedCategories);
        if (this.list_KnowledgeArticles) {
            this.setSortOrderForKnowledgeArticles();
        }

        const promiseSaveArticlesAndCategories = new Promise((resolve, reject) => {
            let allRunSuccessfully = {};

            //Calling this function to save Categories order 
            //Class&MethodName - DEL_KnowledgemanagementController.saveCategories()
            saveSelectedCategories({
                list_SubcategoriesSelected: this.list_FinalSortedCategories,
                map_CategoryByParent: this.map_CategoryByParent,
                strPageName: 'Admin_Setup'
             })
            .then(result => {
                allRunSuccessfully["status"] = true;
                allRunSuccessfully["message"] = CLDEL00035;
            })
            .catch(error => {
                allRunSuccessfully["status"] = false;
                allRunSuccessfully["message"] = error.body.message;
            })
            .finally(() => {
                //Calling this function to save Knowledge Articles order 
                //Class&MethodName - DEL_KnowledgemanagementController.setknowledgeArticlesOrder()
                if (this.list_KnowledgeArticles) {
                    setknowledgeArticlesOrder({list_KnowledgeArticles : this.list_KnowledgeArticles})
                    .then(result => {
                        allRunSuccessfully["status"] = true;
                        allRunSuccessfully["message"] = CLDEL00035;
                    })
                    .catch(error => {
                        allRunSuccessfully["status"] = false;
                        allRunSuccessfully["message"] = error.body.message;
                    })
                    .finally(() => {
                        if (allRunSuccessfully["status"]) {
                            resolve(allRunSuccessfully["message"]);
                        } else {
                            reject(allRunSuccessfully["message"]);
                        }
                    });
                } else {
                    if (allRunSuccessfully["status"]) {
                        resolve(allRunSuccessfully["message"]);
                    } else {
                        reject(allRunSuccessfully["message"]);
                    }
                }
            });
        });

        /**
        *@ author      : Vinaykant
        *@ description : This will provide the message/status upon 'DEL_KnowledgemanagementController.setknowledgeArticlesOrder()'
                        and 'DEL_KnowledgemanagementController.saveCategories()' apex class methods execution. 
        **/
        promiseSaveArticlesAndCategories.then(message => {
            this.showToastMessage(CLDEL00007, message, 'success');
        }).catch(message => {
            this.showToastMessage(CLDEL00001, message, 'error');
        }).finally(() => {
            this.blnDisableSaveButton = true;
            this.blnIsResetDisabled = true;
            refreshApex(this.wiredCategoryData);
        });
        
    }

    /**
    *@ author      : Ankit C
    *@ description : This method is used to display the ShowToast event based on the values of
     *                   'strTitle','strMessage' and 'strVariant'
    **/
    showToastMessage (strTitle, strMessage, strVariant) {
        const event = new ShowToastEvent({
                        title: strTitle,
                        variant: strVariant,
                        message: strMessage,
                      });
        this.dispatchEvent(event);
    }

    /**
    *@ author      : Rakesh Nayak
    *@ description : This method is used to create  the tree structure based on the array elements
    *                of 'list_CategoryNames'
    **/
    createTree(list_CategoryNames) {
        let list_SelectedCategoriesTemp  = [];
        list_CategoryNames.forEach(objSelectedCategoryName => {
            list_SelectedCategoriesTemp.push({ 
                label : this.map_UniqueNameCategoriesByLabelName[objSelectedCategoryName], 
                name : objSelectedCategoryName,
                expanded: true 
            });
        });
        
        let map_NameIndexMapping = list_SelectedCategoriesTemp.reduce((objMapNameToIndex, objCategoryName, index) => {
            objMapNameToIndex[objCategoryName.name] = index;
            return objMapNameToIndex;
        }, {} );

        list_SelectedCategoriesTemp.forEach(objSelectedCategory => {
            let root = {};
            if (this.list_GroupCategoryNames.includes(this.map_CategoryByParent[objSelectedCategory.name])) {
                root = objSelectedCategory;
                this.list_SelectedCategories.push(root);
            } else {
                let objParentCategory = list_SelectedCategoriesTemp[map_NameIndexMapping[this.map_CategoryByParent[objSelectedCategory.name]]];
                if (objParentCategory) {
                    objParentCategory.items = [...(objParentCategory["items"] || []), objSelectedCategory];
                }
            }
        });
        
        if(this.blnIsTreeLoaded) {
            this.template.querySelector('c-tree').normalizeData(this.list_SelectedCategories);
        }
    }

    /**
    *@ author      : Rakesh Nayak
    *@ description : This method is used to get all the child categories for the selected categories.
    *                
    **/
    fetchChildCategories (list_Categories, list_AllChildCategories) {
        let strCategory = list_Categories[0];
        if(this.map_ChildCategoriesByParent[strCategory]) {
            for (let strChildCategory of this.map_ChildCategoriesByParent[strCategory]) {
                if(!list_AllChildCategories.includes(strChildCategory)) {
                    list_AllChildCategories.push(strChildCategory);
                    list_Categories.push(strChildCategory);
                }
            }
            list_Categories.shift();
            this.fetchChildCategories(list_Categories, list_AllChildCategories);
            return list_AllChildCategories;
        }
        else if(list_Categories.length > 0) {
            list_Categories.shift();
            this.fetchChildCategories(list_Categories, list_AllChildCategories);
            return list_AllChildCategories;
        } else {
            return list_AllChildCategories;
        }
    }

    /**
    *@ author      : Rakesh Nayak
    *@ description : This method is used to get parent categories for the strSubcategory and will return all the parents
    *                for 'strSubcategory'
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
    *@ author      : G Nanda Kishore Reddy
    *@ description : This method is used to handle the Expand/Collapse button. 
    **/
    handleClickExpandCollapse (event) {
        if (event.target.name == 'treegrid') {
            const treeGrid =  this.template.querySelector('lightning-tree-grid');
            this.blnSelectedExpandCollapseTreeGrid = !this.blnSelectedExpandCollapseTreeGrid;
            if (this.blnSelectedExpandCollapseTreeGrid) {
                this.blnCollapse = true;
                treeGrid.expandAll();
                this.list_SelectedCategoryNames = this.list_SelectedCategoryNamesBackup;
                this.blnCollapse = false;
            } else {
                this.blnCollapse = true;
                treeGrid.collapseAll();
                this.list_SelectedCategoryNames = this.list_SelectedCategoryNamesBackup;
            }
        }
        if (event.target.name == 'tree') {
            this.blnSelectedExpandCollapseTree = !this.blnSelectedExpandCollapseTree;
            this.changeExpandCollapse(this.list_SelectedCategories, this.blnSelectedExpandCollapseTree);
            this.template.querySelector('c-tree').normalizeData(this.list_SelectedCategories);
        }
    }

    /**
    *@ author      : G Nanda Kishore Reddy
    *@ description : This recursive method is set expanded attribute value of the tree as True/false. 
    *@ params      : 'treeData' - List of Nested Json object.
                     'blnExpandCollapse' - Boolean value of Expand/Collapse button.  
    **/
    changeExpandCollapse (treeData, blnExpandCollapse) {
        treeData.forEach(objTreeNode => {
            if (!objTreeNode.hasOwnProperty("Title")) {
                objTreeNode.expanded = blnExpandCollapse;
            }
            if (objTreeNode.items) {
                this.changeExpandCollapse(objTreeNode.items, blnExpandCollapse);
            }
        });
    }

    /**
    *@ author      : Vinay kant
    *@ description : This method will navigate to Knowledge Article upon click.
    **/
    handleNavigateKnowledgeArticle (event) {
        let idToNavigateArticle = event.target.dataset.id;
        let filteredArticle = [...this.list_KnowledgeArticles].filter(objArticle => (objArticle.KnowledgeArticleId == event.target.dataset.id) && (objArticle.Language != this.strUserLanguage));
        if (filteredArticle.length == 1) {
            idToNavigateArticle = filteredArticle[0]["Id"];
        }
        
        if (idToNavigateArticle) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: idToNavigateArticle,
                    actionName: 'view'
                },
            }).then(url => {
                window.open(url, "_blank");
            });
        }
    }

    /**
    *@ author      : Rakesh Nayak
    *@ description : This method is used to handle the operations on click of Reset button
    **/
    handleOnReset(event) {
        this.blnIsResetDisabled = true;
        this.blnDisableSaveButton = true;
        this.list_KnowledgeArticles = null;
        this.strKnowledgeArticleTableTitle = null;
        this.list_SelectedCategories = [];
        this.list_SelectedCategoryNames = this.list_selectedConfigurationNames;
        this.list_SelectedCategoryNamesBackup = this.list_selectedConfigurationNames;
        this.createTree(this.list_SelectedCategoryNames);
    }


    //Knowledge Articles Drag and Drop Functions
    handleClickRow (event) {
        event.preventDefault();
        return false;
    }

    /**
    *@ author      : Vinay kant
    *@ description : This method will handle the Drag Start event of drag/drop Functionality.
    **/
    handleDragStart (event) {
        this.dragStart = event.target.dataset.index;
        event.target.classList.add("dragStartClass");
    }
    
    /**
    *@ author      : Vinay kant
    *@ description : This method will handle the Drag End event of drag/drop Functionality.
    **/
    handleDragEnd (event) {
        event.preventDefault();
        this.clearStyling();
        return;
    }

    /**
    *@ author      : Vinay kant
    *@ description : This method will handle the Drag Over event of drag/drop Functionality.
    **/
    handleDragOver (event) {
        event.preventDefault();
        return false;
    }

    /**
    *@ author      : Vinay kant
    *@ description : This method will handle the Drag Drop event of drag/drop Functionality.
    **/
    handleDrop (event) {
        event.preventDefault();
        const DraggedIndex = this.dragStart;
        const DroppedIndex = event.target.dataset.index;
        if (DraggedIndex === DroppedIndex) {
            this.clearStyling();
            return false;
        }
        this.blnDisableSaveButton = false;
        this.blnIsResetDisabled = false;
        Array.prototype.move = function (from, to) {
            this.splice(to, 0, this.splice(from, 1)[0]);
        };
        this.list_KnowledgeArticles.move(DraggedIndex, DroppedIndex);
        this.setSortOrderForKnowledgeArticles();
        this.clearStyling();
    }

    /**
    *@ author      : Vinay kant
    *@ description : This method will handle the Drag Enter event of drag/drop Functionality.
    **/
    handleDragEnter (event) {
        if (event.target.classList && this.dragStart != event.target.dataset.index) {
            event.target.classList.add('over');
        }
    }

    /**
    *@ author      : Vinay kant
    *@ description : This method will handle the Drag Leave event of drag/drop Functionality.
    **/
    handleDragLeave (event) {
        if (event.target.classList && this.dragStart != event.target.dataset.index) {
            event.target.classList.remove('over');
        }
    }

    /**
    *@ author      : Vinay kant
    *@ description : This Method will Set 'SortOrder__c' Field based on the sorting of Knowledge Articles.
    **/
    setSortOrderForKnowledgeArticles () {
        let i = 0;
        this.list_KnowledgeArticles.forEach(objKnowledgeArticle => {
            objKnowledgeArticle["SortOrder__c"] = ++i;
        });
    }

    /**
    *@ author      : Vinay kant
    *@ description : This will remove all 'over' and 'dragStartClass' CSS Styles from mentioned HTML elements.
    **/
    clearStyling () {
        let allRowElements = [...this.template.querySelectorAll('tr')];
        let allDataElements = [...this.template.querySelectorAll('td')];
        let allDataDivElements = [...this.template.querySelectorAll('td > div')];
        let allDataAnchorElements = [...this.template.querySelectorAll('td > div > a')];
        allRowElements.forEach( rowElement => {
            rowElement.classList.remove("dragStartClass");
            rowElement.classList.remove("over");
        });
        allDataElements.forEach( dataElement => {
            dataElement.classList.remove("dragStartClass");
            dataElement.classList.remove("over");
        });
        allDataDivElements.forEach( dataDivElement => {
            dataDivElement.classList.remove("dragStartClass");
            dataDivElement.classList.remove("over");
        });
        allDataAnchorElements.forEach( dataDivElement => {
            dataDivElement.classList.remove("dragStartClass");
            dataDivElement.classList.remove("over");
        });
    }

}
