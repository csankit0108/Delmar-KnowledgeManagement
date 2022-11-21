/*
 * Copyright (c) 2019, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: MIT
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/MIT
 */

import { LightningElement, api, track } from 'lwc';
import { TreeData } from './treeData';
import { keyCodes, deepCopy } from 'c/utilsPrivate';
import UserPreferencesShowWorkPhoneToExternalUsers from '@salesforce/schema/User.UserPreferencesShowWorkPhoneToExternalUsers';
//CLDEL00026 - "Category Name" (It stores the label for column name in tree)
import CLDEL00026 from "@salesforce/label/c.CLDEL00026";
export default class cTree extends LightningElement {
    @api header;
    @api draggable;
    
    @track strTreeTitle = CLDEL00026;
    @track _currentFocusedItem = null;
    @track _childNodes;
    @track _key;
    @track _focusedChild = null;
    @track _items = [];

    _defaultFocused = { key: '1', parent: '0' };
    _selected = null;
    @track _selectedItem = null;
    hasDetachedListeners = true;

    strOnDropKey;
    strOnDropName;
    strDragStartKey;
    strDragStartName;
    objDragStartItem;
    UpdatedCategoriesList = [];
    list_ItemsTemp = [];
    ToUpdateCategoryParent;

    
    constructor() {
        super();
        this.callbackMap = {};
        this.treedata = null;
        this.template.addEventListener(
            'privateitemkeydown',
            this.handleKeydown.bind(this)
        );

        this.template.addEventListener(
            'privateitemclick',
            this.handleClick.bind(this)
        );

        this.template.addEventListener(
            'privateregisteritem',
            this.handleRegistration.bind(this)
        );

        this.template.addEventListener(
            'privateitemdragstart',
            this.handleDragStart.bind(this)
        );

        this.template.addEventListener(
            'privateitemondrop',
            this.handleOnDrop.bind(this)
        );

        /*this.template.addEventListener(
            'privateitemdragenter',
            this.handleDragEnter.bind(this)
        );

        this.template.addEventListener(
            'privateitemdragleave',
            this.handleDragLeave.bind(this)
        );

        this.template.addEventListener(
            'privateitemdragover',
            this.handleDragOver.bind(this)
        );*/
    }


    handleDragStart(event) {
        console.log('inside handleDragStart in Tree Comp');
        const key = event.detail.key;
        const target = event.detail.target;
        const item = this.treedata.getItem(key);
        // console.log('item::'+JSON.stringify(item));
        // console.log('key::'+key);
        // console.log('target::'+ target);
        // console.log('name:: '+event.detail.name);
        this.strDragStartKey = key;
        this.strDragStartName = event.detail.name;
        this.objDragStartItem = item;
    }

    handleOnDrop(event) {
        console.log('inside handleOnDrop in Tree Comp');
        const key = event.detail.key;
        const target = event.detail.target;
        const item = this.treedata.getItem(key);
        // console.log('key::'+key);
        // console.log('target::'+ target);
        // console.log('name:: '+event.detail.name);
        // console.log('item::'+JSON.stringify(item));
        this.strOnDropKey = key;
        this.strOnDropName = event.detail.name;
        // let tempjson = '[{"label":"Versapay","name":"a0E2v00001wDGMKEA4","expanded":false,"items":[]},{"items":[{"items":[{"items":[{"label":"About DCMS","name":"a0E2v00001wDGMNEA4","expanded":false,"items":[]},{"label":"Bookings","name":"a0E2v00001wDGMOEA4","expanded":false,"items":[]}],"label":"Client","name":"a0E2v00001wDGMMEA4","expanded":false}],"label":"DCMS","name":"a0E2v00001wDGMLEA4","expanded":false}],"label":"Systems","name":"a0E2v00001wDGMJEA4","expanded":false},{"label":"Test New Category","name":"testId","expanded":false,"items":[]}]';
        // this.items = JSON.parse(tempjson);
        // this.normalizeData(this.items);
        // console.log('items in parent tree::'+JSON.stringify(this.items));
        // console.log('_items in parent tree::'+JSON.stringify(this._items));
        
        if (this.strOnDropName == this.strDragStartName ||  
            this.objDragStartItem["parent"] != item["parent"]
        ) {
            event.stopPropagation();
            return;
        }

        
        this.UpdatedCategoriesListByParentName(this.items, this.strDragStartName, this.strOnDropName, null);
        // console.log('newSorted'+JSON.stringify(this.UpdatedCategoriesList));
        // console.log('ParentName'+JSON.stringify(this.ToUpdateCategoryParent));
        this.list_ItemsTemp = this.items;
        this.sortTree(this.list_ItemsTemp);
        //console.log(JSON.stringify(this.list_ItemsTemp));
        this.items = this.list_ItemsTemp;

        const customEvent = new CustomEvent('privateupdatedtree', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: {
                tree : this.items
            }
        });

        this.dispatchEvent(customEvent);
    }
    
    
    sortTree (listItems) {
        if (!this.ToUpdateCategoryParent) {
            this.items = this.UpdatedCategoriesList;
            return;
        } else {
            listItems.forEach(item => {
                if (item.name === this.ToUpdateCategoryParent) {
                    item["items"] = this.UpdatedCategoriesList;
                } else {
                    this.sortTree(item["items"]);
                }
            });
        }
    }

    UpdatedCategoriesListByParentName (items, categoryNameDragged, categoryNameDropped , ParentCategoryName) {
        const categoryNameList = items.map(item => item.name);
        if (categoryNameList.includes(categoryNameDragged) && categoryNameList.includes(categoryNameDropped)) {
            let categoryIndexDragged = items.findIndex(category => category.name === categoryNameDragged);
            let categoryIndexDropped = items.findIndex(category => category.name === categoryNameDropped);
            //console.log(categoryIndexDragged+'=>'+categoryIndexDropped);
            Array.prototype.move = function (from, to) {
                this.splice(to, 0, this.splice(from, 1)[0]);
            };
            items.move(categoryIndexDragged, categoryIndexDropped);
            this.UpdatedCategoriesList = items;
            this.ToUpdateCategoryParent = ParentCategoryName;
            return;
        } else {
            items.forEach(Category => {
                this.UpdatedCategoriesListByParentName(Category["items"], categoryNameDragged, categoryNameDropped, Category.name);
            });
        }
    }

    @api get items() {
        return this._items || [];
    }

    set items(value) {
        this.normalizeData(value);
    }

    @api get selectedItem() {
        return this._selected;
    }

    set selectedItem(value) {
        this._selected = value;
        this.syncSelected();
    }

    get children() {
        return this._childNodes;
    }

    get rootElement() {
        return this._key;
    }

    get focusedChild() {
        return this._focusedChild;
    }

    syncSelected() {
        if (this.treedata && this._childNodes.length > 0) {
            this._selectedItem = this.treedata.syncSelectedToData(
                this.selectedItem
            );

            this.syncCurrentFocused();

            if (this._selectedItem === null) {
                this.setFocusToItem(this._currentFocusedItem, false, false);
            }
        }
    }

    @api
    normalizeData(items) {
        console.log('inside normalizeData');
        console.log('items in normalizeData:: ' + this.items);
        if (items) {
            this.treedata = new TreeData();

            this._items = items.map((item) => {
                return this.treedata.cloneItems(item);
            });

            const treeRoot = this.treedata.parse(this.items, this.selectedItem);
            this._childNodes = treeRoot ? treeRoot.children : [];
            this._selectedItem = treeRoot.selectedItem;
            this._key = this._childNodes.length > 0 ? treeRoot.key : null;
            if (this._key) {
                this.syncCurrentFocused();
            }
        }
    }

    syncCurrentFocused() {
        if (this._selectedItem) {
            this._currentFocusedItem = this._selectedItem;
        } else {
            this._currentFocusedItem = this._defaultFocused;
        }

        this.updateCurrentFocusedChild();
    }

    updateCurrentFocusedChild() {
        if (this._key === this._currentFocusedItem.parent) {
            this._focusedChild = this.treedata.getChildNum(
                this._currentFocusedItem.key
            );
        } else {
            this._focusedChild = this._currentFocusedItem.key;
            this.treedata.updateCurrentFocusedChild(
                this._currentFocusedItem.key
            );
        }
    }

    handleTreeFocusIn(event) {
        const relatedTarget = event.relatedTarget;
        if (
            this._currentFocusedItem &&
            relatedTarget &&
            relatedTarget.tagName !== 'C-TREE-ITEM'
        ) {
            this.setFocusToItem(this._currentFocusedItem, false);
        }
    }

    renderedCallback() {
        if (this._selectedItem) {
            this.setFocusToItem(this._currentFocusedItem, false);
        }
        if (this.hasDetachedListeners) {
            const container = this.template.querySelector(
                '.slds-tree_container'
            );

            container.addEventListener(
                'focus',
                this.handleTreeFocusIn.bind(this)
            );

            this.hasDetachedListeners = false;
        }
    }

    disconnectedCallback() {
        this.hasDetachedListeners = true;
    }


    handleClick(event) {
        console.log('inside handle click in parent');
        const key = event.detail.key;
        const target = event.detail.target;
        const item = this.treedata.getItem(key);
        console.log('key::'+key);
        console.log('target::'+ target);
        console.log('item::'+JSON.stringify(item));
        if (item) {
            if (target === 'chevron') {
                if (item.treeNode.nodeRef.expanded) {
                    this.collapseBranch(item.treeNode);
                } else {
                    this.expandBranch(item.treeNode);
                }
            } else {
                this._selectedItem = item;
                this.dispatchSelectEvent(item.treeNode);
                this.setFocusToItem(item);
            }
        }
        console.log(JSON.stringify(this._selectedItem));
    }

    expandBranch(node) {
        if (!node.isLeaf && !node.isDisabled) {
            node.nodeRef.expanded = true;
            if (
                this._selectedItem &&
                this._selectedItem.key.startsWith(node.key)
            ) {
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {
                    this.setFocusToItem(this._selectedItem);
                }, 0);
            }

            this.dispatchEvent(
                new CustomEvent('change', {
                    detail: {
                        items: deepCopy(this._items)
                    }
                })
            );
        }
    }

    collapseBranch(node) {
        if (!node.isLeaf && !node.isDisabled) {
            node.nodeRef.expanded = false;
            this.treedata.updateVisibleTreeItemsOnCollapse(node.key);

            this.dispatchEvent(
                new CustomEvent('change', {
                    detail: { items: deepCopy(this._items) }
                })
            );
        }
    }

    dispatchSelectEvent(node) {
        if (!node.isDisabled) {
            const customEvent = new CustomEvent('select', {
                bubbles: true,
                composed: true,
                cancelable: true,
                detail: { name: node.name }
            });

            this.dispatchEvent(customEvent);
        }
    }

    handleKeydown(event) {
        event.preventDefault();
        event.stopPropagation();
        const item = this.treedata.getItem(event.detail.key);
        switch (event.detail.keyCode) {
            case keyCodes.up:
                this.setFocusToPrevItem();
                break;
            case keyCodes.down:
                this.setFocusToNextItem();
                break;
            case keyCodes.home:
                this.setFocusToFirstItem();
                break;
            case keyCodes.end:
                this.setFocusToLastItem();
                break;
            case keyCodes.right:
                this.expandBranch(item.treeNode);
                break;
            case keyCodes.left:
                if (item.treeNode.nodeRef.expanded && !item.treeNode.isLeaf) {
                    this.collapseBranch(item.treeNode);
                } else {
                    this.handleParentCollapse(event.detail.key);
                }
                break;

            default:
                break;
        }
    }

    setFocusToItem(item, shouldFocus = true, shouldSelect = true) {
        const currentFocused = this.treedata.getItemAtIndex(
            this.treedata.currentFocusedItemIndex
        );

        if (
            currentFocused &&
            currentFocused.key !== item.key &&
            this.callbackMap[currentFocused.parent]
        ) {
            this.callbackMap[currentFocused.key].unfocusCallback();
        }
        if (item) {
            this._currentFocusedItem = this.treedata.updateCurrentFocusedItemIndex(
                item.index
            );

            if (this.callbackMap[item.parent]) {
                this.callbackMap[item.parent].focusCallback(
                    item.key,
                    shouldFocus,
                    shouldSelect
                );
            }
        }
    }

    setFocusToNextItem() {
        const nextNode = this.treedata.findNextNodeToFocus();
        if (nextNode && nextNode.index !== -1) {
            this.setFocusToItem(nextNode);
        }
    }

    setFocusToPrevItem() {
        const prevNode = this.treedata.findPrevNodeToFocus();
        if (prevNode && prevNode.index !== -1) {
            this.setFocusToItem(prevNode);
        }
    }

    setFocusToFirstItem() {
        const node = this.treedata.findFirstNodeToFocus();
        if (node && node.index !== -1) {
            this.setFocusToItem(node);
        }
    }

    setFocusToLastItem() {
        const lastNode = this.treedata.findLastNodeToFocus();
        if (lastNode && lastNode.index !== -1) {
            this.setFocusToItem(lastNode);
        }
    }

    handleFocusFirst(event) {
        event.stopPropagation();
        this.setFocusToFirstItem();
    }

    handleFocusLast(event) {
        event.stopPropagation();
        this.setFocusToLastItem();
    }

    handleFocusNext(event) {
        event.stopPropagation();
        this.setFocusToNextItem();
    }

    handleFocusPrev(event) {
        event.stopPropagation();
        this.setFocusToPrevItem();
    }

    handleChildBranchCollapse(event) {
        event.stopPropagation();
        this.treedata.updateVisibleTreeItemsOnCollapse(event.detail.key);
    }

    handleParentCollapse(key) {
        const item = this.treedata.getItem(key);
        if (item && item.level > 1) {
            const parent = this.treedata.getItem(item.parent);
            this.collapseBranch(parent.treeNode);
            this.setFocusToItem(parent);
        }
    }

    handleRegistration(event) {
        const itemKey = event.detail.key;
        this.callbackMap[itemKey] = {
            focusCallback: event.detail.focusCallback,
            unfocusCallback: event.detail.unfocusCallback
        };

        this.treedata.addVisible(itemKey);
        event.stopPropagation();
    }

    get hasChildren() {
        return this._items && this._items.length > 0;
    }
}