import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getCategoryData from "@salesforce/apex/DEL_KnowledgeManagementController.getDescribeDataCategoryGroupStructureResults";
import saveSelectedCategories from "@salesforce/apex/DEL_KnowledgeManagementController.saveCategories";

export default class Del_KnowledgeArticlesComponent extends LightningElement {
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

    constructor() {
        super();

        this.template.addEventListener(
            'privateitemdragstart',
            this.handleDragStart2.bind(this)
        );

        this.template.addEventListener(
            'privateitemondrop',
            this.handleOnDrop.bind(this)
        );
    }

    handleDragStart2(event) {
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
    }


    @wire(getCategoryData)
    categoryData(result) {
        const {error, data} = result;
        this.list_categoryData  = result;
        if (data) {
            console.log('inside connectedCallback');
            console.log(result);
            console.log('parent categories' + data.list_ParentCategoryNames);
            let list_AllCategories = JSON.parse(JSON.stringify(data.list_AllCategories));
            this.map_CategoryByParent = data.map_CategoryByParent;
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
        console.log(this.list_Categories);
        this.selectedCategories = data.list_DefaultSortedCategories;
        this.list_DefaultSortedSubcategories = data.list_DefaultSortedSubcategories
        this.map_CategoriesByTopLevelCategories = data.map_CategoriesByTopLevelCategories;
        this.handleDefaultSubcategories(this.selectedCategories);
        let dummydata = JSON.parse('[{"label":"Systems","name":"Systems","expanded":true,"items":[{"label":"DCMS","name":"DCMS","expanded":true,"items":[{"label":"Client","name":"Client","expanded":true,"items":[{"label":"About DCMS","name":"About DCMS","expanded":true,"items":[],"sortorder":1},{"label":"Bookings","name":"Bookings","expanded":true,"items":[],"sortorder":2}],"sortorder":1}],"sortorder":1}],"sortorder":1},{"label":"Versapay","name":"Versapay","expanded":true,"items":[],"sortorder":2}]');
        this.assignSortOrder(dummydata);
        console.log('list_FinalSortedCategories:: ' + JSON.stringify(this.list_FinalSortedCategories));
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

    /*connectedCallback() {
        getCategoryData({})
            .then(result => {
                console.log('inside connectedCallback');
                console.log(result);
                console.log('parent categories' + result.list_ParentCategoryNames);
                for (let objParentCategory of result.list_ParentCategoryNames) {
                    this.list_Categories.push({ label: objParentCategory, value: objParentCategory})
                }
                console.log(this.list_Categories);
                this.selectedCategories = result.list_DefaultSortedCategories;
                this.list_DefaultSortedSubcategories = result.list_DefaultSortedSubcategories
                this.map_CategoryByParent = result.map_CategoryByParent;
                this.map_CategoriesByTopLevelCategories = result.map_CategoriesByTopLevelCategories;
                this.handleDefaultSubcategories(this.selectedCategories);
            })
            .catch(error => {
                console.log(error);
            });
    }*/

    // handleCategoryChange(e) {
    //     this.selectedCategories = e.detail.value;

    //     this.list_Subcategories = [];
    //     for (let objSelectedCategory of this.selectedCategories) {
    //         for (let objSubCategory of this.map_CategoriesByTopLevelCategories[objSelectedCategory]) {
    //             this.list_Subcategories.push({ label: objSubCategory, value: objSubCategory });
    //         }
    //         console.log('this.list_Subcategories:: ' + JSON.stringify(this.list_Subcategories));
    //     }
    //     console.log(this.selectedCategories);
    // }

    // handleSubCategoryChange(e) {
    //     console.log('inside subcategorychange');
    //     this.selectedSubCategories = [];
    //     this.map_subCategoriesByParentCategory = [];
    //     this.list_parentCategories = [];
    //     console.log('Selected cat :: '+e.target.value);
    //     console.log('Map=>'+JSON.stringify(this.map_CategoryByParent));
    //     for(let strSubcategory of e.target.value) {
    //         this.getParentCategories(strSubcategory);
    //         /*this.list_Subcategories.forEach(element => {
    //             if (element["value"] == this.map_CategoryByParent[strSubcategory]) {
    //                 this.selectedSubCategories.push(this.map_CategoryByParent[strSubcategory]);
    //             }
    //         });*/
    //     }
    //     console.log('list of parents :: ' + this.list_parentCategories);
    //     this.selectedSubCategories.push(...this.list_parentCategories);
    //     e.detail.value.forEach(element => {
    //         if (!this.selectedSubCategories.includes(element)) {
    //             this.selectedSubCategories.push(element);
    //         }
    //     });
    //     for (let subcategory of this.selectedSubCategories) {
    //         var strParentCategory = this.map_CategoryByParent[subcategory];
    //         console.log('strParentCategory :: ' + strParentCategory);
    //         if  (this.map_subCategoriesByParentCategory.hasOwnProperty(strParentCategory)) {
    //             console.log('map has a parent :: sub  :: '+subcategory);
    //             this.map_subCategoriesByParentCategory[strParentCategory].push(subcategory);
    //             console.log('inserted value :: '+this.map_subCategoriesByParentCategory[strParentCategory]);
    //         } else {
    //             console.log('map doesnt have a parent :: sub  :: '+subcategory );
    //             this.map_subCategoriesByParentCategory[strParentCategory] = [subcategory];
    //             console.log('inserted value :: '+this.map_subCategoriesByParentCategory[strParentCategory]);

    //         }
    //     }
    //     for(let key of Object.keys(this.map_subCategoriesByParentCategory)) {
    //         console.log('map value ::'+this.map_subCategoriesByParentCategory[key]);
    //     }
    // }

    handleRowSelection(event) {
        console.log('Selected Category' +JSON.stringify(this.list_SelectedCategories));
        console.log('inside handleRowSelection');
        console.log('selected rows::' + JSON.stringify(event.detail.selectedRows));
        if (this.blnIsToggle ) {
            this.blnIsToggle = false;
            return;
        }

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
        /*for (let objSelectedCategory of event.detail.selectedRows) {
            let list_categories = this.list_SelectedCategories.map(objCategory => objCategory.name);
            if (!list_categories.includes(objSelectedCategory.name)) {
                this.list_parentCategories = [];
                this.getParentCategories(objSelectedCategory.name);
                for (let strParent of this.list_parentCategories) {
                    if (!list_categories.includes(strParent)) {
                        this.list_SelectedCategories.push({ label :strParent, name : strParent });
                    }
                }
                this.list_SelectedCategories.push({ label :objSelectedCategory.name, name :objSelectedCategory.name });
            }
        }*/

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
        console.log('selected category:: ' + event.detail.name);
    }

    handleCategorySave() {
        let list_AllSelectedCategories = [];
        for (let objCategory of this.selectedCategories) {
            list_AllSelectedCategories.push(objCategory);
        }
        console.log('selected categories :: '+list_AllSelectedCategories);

        let list_SubcategoriesSelected = [];

        for(let key of Object.keys(this.map_subCategoriesByParentCategory)) {
            for (let i = 1; i  <= this.map_subCategoriesByParentCategory[key].length; i++) {
                let objSubcategory = {
                    Name  : this.map_subCategoriesByParentCategory[key][i-1],
                    SortOrder : i
                };

                list_SubcategoriesSelected.push(objSubcategory);
            }
        }
        console.log('list to pass :: '+ JSON.stringify(list_SubcategoriesSelected));
        /*for (let objSubCategory of this.selectedSubCategories) {
            list_AllSelectedCategories.push(objSubCategory);
        }*/
        saveSelectedCategories({
            list_SelectedCategories:  list_AllSelectedCategories,
            list_SubcategoriesSelected: list_SubcategoriesSelected,
            map_CategoryByParent: this.map_CategoryByParent,
            strPageName: 'Admin_Setup'
         })
            .then(result => {
                //console.log(result);
                //for (var category of result) {
                //    this.selectedCategories.push(category);
                //}
                refreshApex(this.list_categoryData);
                const event = new ShowToastEvent({
                    title: 'Success!',
                    variant: 'success',
                    message: 'Categories save successfully',
                });
                this.dispatchEvent(event);
            })
            .catch(error => {
                console.log(error);
            });
    }

    handleDefaultSubcategories(list_defaultselectedCategories){
        console.log('inside handle subcategory');
        this.selectedCategories = list_defaultselectedCategories;
        this.list_Subcategories = [];
        for (let objSelectedCategory of this.selectedCategories) {
            for (let objSubCategory of this.map_CategoriesByTopLevelCategories[objSelectedCategory]) {
                this.list_Subcategories.push({ label: objSubCategory, value: objSubCategory });
            }
            console.log('this.list_Subcategories:: ' + this.list_Subcategories);
        }
        console.log('subcategory list :: ' + this.list_DefaultSortedSubcategories);
        this.selectedSubCategories = this.list_DefaultSortedSubcategories;

        console.log(this.selectedCategories);
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
}