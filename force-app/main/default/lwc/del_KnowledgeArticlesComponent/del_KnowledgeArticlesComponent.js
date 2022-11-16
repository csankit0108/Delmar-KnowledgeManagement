import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import { NavigationMixin } from 'lightning/navigation';
import getCategoryData from "@salesforce/apex/DEL_KnowledgeManagementController.getDescribeDataCategoryGroupStructureResults";
import saveSelectedCategories from "@salesforce/apex/DEL_KnowledgeManagementController.saveCategories";
import setknowledgeArticlesOrder from '@salesforce/apex/DEL_KnowledgeManagementController.setknowledgeArticlesOrder';

export default class Del_KnowledgeArticlesComponent extends NavigationMixin(LightningElement) {
    @api strPageName;
    selectedCategories = [];
    selectedSubCategories = [];
    @track list_Categories = [];
    @track list_Subcategories = [];
    map_CategoryByParent = [];
    map_CategoriesByTopLevelCategories = [];
    list_DefaultSortedSubcategories = [];
    map_subCategoriesByParentCategory = [];
    list_parentCategories = [];
    list_categoryData;
    @track gridColumns = [{
        type: 'text',
        fieldName: 'name',
        label: 'Category Name'
    }];
    @track gridData = [];
    blnShowTreeGrid = false;
    @track list_SelectedCategories = [];
    dragStartCategoryName;
    dropCategoryName;
    map_NameToIndexMapping = [];
    list_SelectedCategoryNames = [];
    list_FinalSortedCategories = [];
    blnIsToggle = false;
    @track strKnowledgeArticleTableTitle;
    blnDraggable = true;

    @track map_knowledgeArticlesByCategory;
    @track list_KnowledgeArticles;
    map_UniqueNameCategoriesByLabelName;
    dragStart;
    @track disableSaveButton = true;
    @track visibleSaveButton;
    @track selectedTreeNode;
    map_ChildCategoriesByParent = [];
    @track blnIsResetDisabled = true;
    list_selectedConfigurationNames = [];

    constructor() {
        super();

        /*this.template.addEventListener(
            'privateitemdragstart',
            this.handleDragStart2.bind(this)
        );

        this.template.addEventListener(
            'privateitemondrop',
            this.handleOnDrop.bind(this)
        );*/

        this.template.addEventListener(
            'privateitemclick',
            this.handleCategorySelect.bind(this)
        );
        
        this.template.addEventListener(
            'privateupdatedtree',
            this.handleUpdatedTree.bind(this)
        );
            
    }

    handleUpdatedTree (event) {
        this.list_SelectedCategories = event.detail.tree;
        console.log('updatedTree=>'+JSON.stringify(this.list_SelectedCategories));
        this.disableSaveButton = false;
        this.blnIsResetDisabled = false;
    }

    /*handleDragStart2(event) {
        console.log('inside handleDragStart in root cmp');
        const key = event.detail.key;
        const target = event.detail.target;
        console.log('key::'+key);
        console.log('name:: '+event.detail.name);
        this.dragStartCategoryName = event.detail.name;
    }

    handleOnDrop(event) {
        console.log('inside handleOnDrop in root cmp');
        this.blnShowGrid = false;
        const key = event.detail.key;
        const target = event.detail.target;
        console.log('key::'+key);
        console.log('name:: '+event.detail.name);
        this.dropCategoryName = event.detail.name;
        let map_NameIndexMapping = this.list_SelectedCategories.reduce( (objMapNameToIndex, objCategoryName, index) => {
                objMapNameToIndex[objCategoryName.name] = index;
                return objMapNameToIndex;
            }, {} );
        console.log('list_SelectedCategories before drop::'+JSON.stringify(this.list_SelectedCategories));
        Array.prototype.move = function (from, to) {
            this.splice(to, 0, this.splice(from, 1)[0]);
        };
        this.list_SelectedCategories.move(map_NameIndexMapping[this.dragStartCategoryName], map_NameIndexMapping[this.dropCategoryName]);
        this.blnShowGrid = true;
        this.template.querySelector('c-tree').normalizeData(this.list_SelectedCategories);
        console.log('list_SelectedCategories after drop::'+JSON.stringify(this.list_SelectedCategories));
        //console.log('item::'+JSON.stringify(item));
    }*/


    @wire(getCategoryData)
    categoryData(result) {
        this.list_categoryData  = result;
        const {error, data} = result;
        if (data) {
            this.gridData =[];
            this.list_SelectedCategories = [];
            console.log('inside connectedCallback');
            console.log(result);
            console.log('parent categories' + data.list_ParentCategoryNames);
            let list_AllCategories = JSON.parse(JSON.stringify(data.list_AllCategories));
            this.map_CategoryByParent = data.map_CategoryByParent;
            this.list_SelectedCategoryNames = data.list_DefaultSortedCategories;
            this.list_selectedConfigurationNames = data.list_DefaultSortedCategories;
            this.map_UniqueNameCategoriesByLabelName = data.map_SubCategoriesByUniqueName;
            this.map_ChildCategoriesByParent = JSON.parse(JSON.stringify(data.map_ChildCategoriesByParent));
            this.map_knowledgeArticlesByCategory = JSON.parse(JSON.stringify(data.map_KnowledgeArticlesByCategoryUniqueName));
            if (data.hasOwnProperty("objUserInformation")) {
                this.visibleSaveButton = data.objUserInformation.UserPermissionsKnowledgeUser;
            }
            this.createTree(this.list_SelectedCategoryNames);
            this.map_NameToIndexMapping = list_AllCategories.reduce( (objMapNameToIndex, objCategoryName, index) => {
                objMapNameToIndex[objCategoryName.name] = index;
                return objMapNameToIndex;
            }, {} );
            list_AllCategories.forEach(objCategoryName => {
                let root;
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
        //this.list_SelectedCategories.push('Quick Text');
            this.blnShowTreeGrid = true;
            this.list_Categories = [];
            for (let objParentCategory of data.list_ParentCategoryNames) {
                this.list_Categories.push({ label: objParentCategory, value: objParentCategory});
            }

        } else if (error) {
            console.log(error);
        }
    }

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

    handleRowSelection(event) {
        this.disableSaveButton = false;
        console.log('Selected Category' +JSON.stringify(this.list_SelectedCategories));
        console.log('inside handleRowSelection');
        console.log('selected rows::' + JSON.stringify(event.detail.selectedRows));
        if (this.blnIsToggle ) {
            this.blnIsToggle = false;
            return;
        }
        this.blnIsResetDisabled  = false;
        let list_NewlyAddedCategories = event.detail.selectedRows.filter(element1 => !this.list_SelectedCategoryNames.some(element2 => element1.name === element2)).map(element => element.name);
        console.log('newly added categories :: '+JSON.stringify(list_NewlyAddedCategories));
        let list_ChildCategoryNamesTemp = [];
        let list_ChildCategoryNames = [];
        if(list_NewlyAddedCategories.length > 0) {
            console.log('size of new category>0');
            list_ChildCategoryNames = this.fetchChildCategories(list_NewlyAddedCategories, list_ChildCategoryNamesTemp);
            console.log('list od child categories :: '+ list_ChildCategoryNames);
        }

        list_ChildCategoryNames.forEach(strCategory => this.list_SelectedCategoryNames.push(strCategory));
        this.list_SelectedCategories = [];
        let list_SelectedCategoriesTemp = [];
        this.list_SelectedCategoryNames = [];
        try {
            for (let objSelectedCategory of event.detail.selectedRows) {
                if (!this.list_SelectedCategoryNames.includes(objSelectedCategory.name)) {
                    this.list_SelectedCategoryNames.push(objSelectedCategory.name);
                }

                let list_Temp = [];
                let list_ParentCategoryNames = this.getParentCategories(objSelectedCategory.name, list_Temp);
                console.log('category name:: '+objSelectedCategory.name);
                console.log('parent names:: '+JSON.stringify(list_ParentCategoryNames));
                for (let objParentName of list_ParentCategoryNames) {
                    if (!this.list_SelectedCategoryNames.includes(objParentName)) {
                        this.list_SelectedCategoryNames.push(objParentName);
                    }
                }
            }

            console.log('list_SelectedCategoryNames:: '+JSON.stringify(this.list_SelectedCategoryNames));
            if (!this.list_SelectedCategoryNames.includes(this.selectedTreeNode)) {
                this.list_KnowledgeArticles = null;
                this.strKnowledgeArticleTableTitle = null;
                this.selectedTreeNode = null;
            }
            this.list_SelectedCategoryNames.forEach(objSelectedCategoryName => {
                list_SelectedCategoriesTemp.push({ 
                    label :objSelectedCategoryName, 
                    name :objSelectedCategoryName,
                    expanded: true 
                });
            });

            let map_NameIndexMapping = list_SelectedCategoriesTemp.reduce((objMapNameToIndex, objCategoryName, index) => {
                objMapNameToIndex[objCategoryName.name] = index;
                return objMapNameToIndex;
            }, {} );
            console.log('map_NameIndexMapping:: ' + JSON.stringify(map_NameIndexMapping));
            list_SelectedCategoriesTemp.forEach(objSelectedCategory => {
                let root;
                if (!this.map_CategoryByParent[objSelectedCategory.name]) {
                    root = objSelectedCategory;
                    this.list_SelectedCategories.push(root);
                } else {
                    console.log('objSelectedCategory.name:: ' + objSelectedCategory.name + 'parent:: ' + this.map_CategoryByParent[objSelectedCategory.name]);
                    let objParentCategory = list_SelectedCategoriesTemp[map_NameIndexMapping[this.map_CategoryByParent[objSelectedCategory.name]]];
                    if (objParentCategory) {
                        objParentCategory.items = [...(objParentCategory["items"] || []), objSelectedCategory];
                    }
                }
            });
            console.log('this.list_SelectedCategories:: ' + JSON.stringify(this.list_SelectedCategories));
        } catch(error) {
            console.log(error);
        }

        this.template.querySelector('c-tree').normalizeData(this.list_SelectedCategories);
    }

    handleToggle(event) {
        console.log('inside toggle');
        console.log('selected rows::' + JSON.stringify(event.detail.name));
        console.log('selected rows::' + JSON.stringify(event.detail.isExpanded));
        console.log('selected rows::' + JSON.stringify(event.detail.hasChildrenContent));
        console.log('selected rows::' + JSON.stringify(event.detail.row));
        if (!event.detail.isExpanded && event.detail.hasChildrenContent) {
            this.blnIsToggle = true;
        }
    }

    handleCategorySelect(event) {
        this.selectedTreeNode = event.detail.name;
        let strUniqueNameCategory = this.map_UniqueNameCategoriesByLabelName[this.selectedTreeNode];
        if (this.map_knowledgeArticlesByCategory.hasOwnProperty(strUniqueNameCategory)) {
            this.list_KnowledgeArticles = this.map_knowledgeArticlesByCategory[strUniqueNameCategory];
            this.strKnowledgeArticleTableTitle =  "Sort Articles for Category: "+this.selectedTreeNode;
            console.log(this.strKnowledgeArticleTableTitle);
        } else {
            this.list_KnowledgeArticles = null;
            this.strKnowledgeArticleTableTitle = null;
            this.selectedTreeNode = null;
        }
    }

    handleCategorySave() {
        this.list_FinalSortedCategories = [];
        console.log('selected categories :: '+ JSON.stringify(this.list_SelectedCategories));

        this.assignSortOrder(this.list_SelectedCategories);

        console.log('final sorted list :: '+ JSON.stringify(this.list_FinalSortedCategories));

        const promiseSaveArticlesAndCategories = new Promise((resolve, reject) => {
            let allRunSuccessfully = {};

            //Calling this function to save Categories order 
            //Class&MethodName - DEL_KnowledgemanagementController.saveSelectedCategories()
            saveSelectedCategories({
                /*list_SelectedCategories:  list_AllSelectedCategories,*/
                list_SubcategoriesSelected: this.list_FinalSortedCategories,
                map_CategoryByParent: this.map_CategoryByParent,
                strPageName: 'Admin_Setup'
             })
            .then(result => {

                console.log('InsideSaveCat');
                allRunSuccessfully["status"] = true;
                allRunSuccessfully["message"] = "Saved All Categories and Articles";
            })
            .catch(error => {
                console.log('InsideSaveCatErr');
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

            //Calling this function to save Knowledge Articles order 
            //Class&MethodName - DEL_KnowledgemanagementController.setknowledgeArticlesOrder()
            if (this.list_KnowledgeArticles) {
                setknowledgeArticlesOrder({list_KnowledgeArticles : this.list_KnowledgeArticles})
                .then(result => {
                    allRunSuccessfully["status"] = true;
                    allRunSuccessfully["message"] = "Saved All Categories and Articles";
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
            }
        });

        promiseSaveArticlesAndCategories.then(message => {
            this.showToastMessage('Success', message, 'success');
            refreshApex(this.list_categoryData);
        }).catch(message => {
            console.log(JSON.stringify(message));
            this.showToastMessage('Error', message, 'error');
        }).finally(() => {
            this.disableSaveButton = true;
            this.blnIsResetDisabled = true;

        });

    }

    showToastMessage (title, message, variant) {
        const event = new ShowToastEvent({
                        title: title,
                        variant: variant,
                        message: message,
                      });
        this.dispatchEvent(event);
    }

    createTree(list_categoryNames) {
        console.log('default category names :: ' + list_categoryNames);
        let list_SelectedCategoriesTemp  = [];
        list_categoryNames.forEach(objSelectedCategoryName => {
            list_SelectedCategoriesTemp.push({ 
                label :objSelectedCategoryName, 
                name :objSelectedCategoryName,
                expanded: true 
            });
        });

        let map_NameIndexMapping = list_SelectedCategoriesTemp.reduce((objMapNameToIndex, objCategoryName, index) => {
            objMapNameToIndex[objCategoryName.name] = index;
            return objMapNameToIndex;
        }, {} );
        console.log('map_NameIndexMapping:: ' + JSON.stringify(map_NameIndexMapping));
        list_SelectedCategoriesTemp.forEach(objSelectedCategory => {
            let root;
            if (!this.map_CategoryByParent[objSelectedCategory.name]) {
                root = objSelectedCategory;
                this.list_SelectedCategories.push(root);
            } else {
                console.log('objSelectedCategory.name:: ' + objSelectedCategory.name + 'parent:: ' + this.map_CategoryByParent[objSelectedCategory.name]);
                let objParentCategory = list_SelectedCategoriesTemp[map_NameIndexMapping[this.map_CategoryByParent[objSelectedCategory.name]]];
                if (objParentCategory) {
                    objParentCategory.items = [...(objParentCategory["items"] || []), objSelectedCategory];
                }
            }
        });

        this.template.querySelector('c-tree').normalizeData(this.list_SelectedCategories);
    }

    getParentCategories(strSubcategory, list_AllParentNames) {
        console.log('inside recursive function'+strSubcategory);
        if (this.map_CategoryByParent[strSubcategory]) {
                console.log('this is a unique subcategory');
                if (!list_AllParentNames.includes(this.map_CategoryByParent[strSubcategory])) {
                    list_AllParentNames.unshift(this.map_CategoryByParent[strSubcategory]);
                    this.getParentCategories(this.map_CategoryByParent[strSubcategory], list_AllParentNames);
                }
            return list_AllParentNames;
        } else {
            return list_AllParentNames;
        }
    }

    //Knowledge Articles Drag and Drop Functions
    handleClickRow (event) {
        /*event.preventDefault();
        return false;*/
    }

    handleDragStart (event) {
        this.dragStart = event.target.dataset.index;
        event.target.classList.add("dragStartClass");
        console.log("start=>"+this.dragStart);
    }

    handleDragOver (event) {
        event.preventDefault();
        return false;
    }

    handleDrop (event) {
        event.preventDefault();
        const DraggedIndex = this.dragStart;
        const DroppedIndex = event.target.dataset.index;
        if (DraggedIndex === DroppedIndex) {
            this.clearStyling();
            return false;
        }
        console.log("droppedOn=>"+event.target.dataset.index);
        this.disableSaveButton = false;
        Array.prototype.move = function (from, to) {
            this.splice(to, 0, this.splice(from, 1)[0]);
        };
        this.list_KnowledgeArticles.move(DraggedIndex, DroppedIndex);
        this.setSortOrderForKnowledgeArticles();
        this.clearStyling();
    }

    handleDragEnter (event) {
        if (event.target.classList && this.dragStart != event.target.dataset.index) {
            event.target.classList.add('over');
        }
    }

    handleDragLeave (event) {
        if (event.target.classList && this.dragStart != event.target.dataset.index) {
            event.target.classList.remove('over');
        }
    }

    setSortOrderForKnowledgeArticles () {
        let i = 0;
        this.list_KnowledgeArticles.forEach(objKnowledgeArticle => {
            objKnowledgeArticle["SortOrder__c"] = ++i;
        });
    }

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

    handleNavigateKnowledgeArticle (event) {
        if (event.target.dataset.id) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: event.target.dataset.id,
                    actionName: 'view'
                },
            }).then(url => {
                window.open(url, "_blank");
            });
        }
    }

    handleOnReset(event) {
        this.blnIsResetDisabled = true;
        this.disableSaveButton = true;
        this.list_SelectedCategories = [];
        this.list_SelectedCategoryNames = this.list_selectedConfigurationNames;
        this.createTree(this.list_SelectedCategoryNames);
    }

    fetchChildCategories (list_Categories, list_AllChildCategories) {
        let strCategory = list_Categories[0];
        if(this.map_ChildCategoriesByParent[strCategory]) {
            for (let strChildCategory of this.map_ChildCategoriesByParent[strCategory]) {
                if(!list_AllChildCategories.includes(strChildCategory)) {
                    list_AllChildCategories.push(strChildCategory);
                    list_Categories.push(strChildCategory);
                }
            }
            console.log('end of for');
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
}