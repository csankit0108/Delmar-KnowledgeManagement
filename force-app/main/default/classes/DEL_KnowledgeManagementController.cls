/*******************************************************************************************************************************
* 
* @ Name            :   DEL_KnowledgeManagementController
* @ Purpose         :   Controller class for del_KnowledgeArticlesComponent
* @ Author          :   Rakesh Nayak
*
*   Date            |  Developer Name               |  Version      |  Changes
* ==============================================================================================================================
*   17-11-2022      |  ankit.c@absyz.com            |  1.0          |  Initial Version
*   17-11-2022      |  rakesh.nayak@absyz.com       |  1.1          |  Added category save and configuration deletion functions.
*   21-11-2022      |  vinaykant.kurre@absyz.com    |  1.2          |  Added Knowledge Articles Management functions.
*   21-11-2022      |  nandakishore.reddy@absyz.com |  1.2          |  Added Knowledge Articles Navigation function.

********************************************************************************************************************************/
public with sharing class DEL_KnowledgeManagementController {
    //Map of DEL_KnowledgeConfiguration__c records by Name
    public static Map<String, DEL_KnowledgeConfiguration__c> map_KnowledgeConfigurationsByName;

    //Map of SubCategories by their Unique Name
    public static Map<String, String> map_CategoriesByUniqueName = new Map<String, String>();

    
    /**
    * @ Name     :  KnowledgeWrapper
    * @ Purpose  :  Wrapper class to send response to the lwc.
    * @ Author   :  Ankit CS
    **/
    public class KnowledgeWrapper {
        @AuraEnabled public Boolean blnIsSuccess;
        //Map of List of sub categories by top level categories
        @AuraEnabled public Map<String, List<String>> map_CategoriesByTopLevelCategories = new Map<String, List<String>>();
        //This map defines what is the parent category for a sub category
        @AuraEnabled public Map<String, String> map_CategoryByParent = new Map<String, String>();
        //List of Top level category names
        @AuraEnabled public List<String> list_ParentCategoryNames = new List<String>();
        //List of Group Category Names
        @AuraEnabled public List<String> list_GroupCategoryNames = new List<String>();
        //List of previously sorted category names
        @AuraEnabled public List<String> list_DefaultSortedCategories = new List<String>();
        //List of previously sorted sub category names
        @AuraEnabled public List<String>  list_DefaultSortedSubcategories = new List<String>();
        //This map defines the child categories for a parent category
        @AuraEnabled public Map<String, List<String>> map_ChildCategoriesByParent = new Map<String, List<String>>();
        @AuraEnabled public List<CategoryWrapper> list_AllCategories = new List<CategoryWrapper>();
        //Map all published Knowledge Articles based on Category Unique Name      
        @AuraEnabled public Map<String, List<Knowledge__kav>> map_KnowledgeArticlesByCategoryUniqueName = new Map<String, List<Knowledge__kav>>();
        //Map all Category Unique Name By it's Label Name
        @AuraEnabled public map<String, String> map_CategoriesByUniqueName = new Map<String, String>();
        //Current Logged-In User information
        @AuraEnabled public User objUserInformation = new user();
    }

    /**
    * @ Name     :  CategoryWrapper
    * @ Purpose  :  Wrapper class to deserialize the JSON objects from lwc.
    * @ Author   :  Ankit CS
    **/
    public class CategoryWrapper {
        @AuraEnabled public String SortOrder;
        @AuraEnabled public String name;
        public CategoryWrapper() {
            name = '';
        }
    }
    
    /**
    * @ Name     :  TableofContentsWrapper
    * @ Purpose  :  Wrapper class to send knowledge configurations and knowledge articles to the component.
    * @ Author   :  Ankit CS
    **/
    public class TableofContentsWrapper {
        //This map defines what is the parent category for a sub category
        @AuraEnabled public Map<String, String> map_CategoryByParent = new Map<String, String>();
        @AuraEnabled public Map<String, List<Knowledge__kav>> map_ArticlesByCategoryName = new Map<String, List<Knowledge__kav>>();
        @AuraEnabled public List<DEL_KnowledgeConfiguration__c> list_AvailableCategories = new List<DEL_KnowledgeConfiguration__c>();
        @AuraEnabled public List<DEL_KnowledgeConfiguration__c> list_SelectedCategories = new List<DEL_KnowledgeConfiguration__c>();
        //List of Group Category Names
        @AuraEnabled public List<String> list_GroupCategoryNames = new List<String>();
        //Map all Sub-Category Unique Name By it's Label Name
        @AuraEnabled public map<String, String> map_CategoriesByUniqueName = new Map<String, String>();
        //Current Logged-In User information
        @AuraEnabled public User objUserInformation = new user();
    }

    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method save all the selected categories
    * @ params       :  'map_categoryByParent'       - Map of each category and its immediate parent
    *                :  'list_SubcategoriesSelected' - List of slected subcategories from the component
    *                :  'strPageName'                - Name of the page
    * @ return       :  'list_KnowledgeConfigurationsforUpsert' - List of newly added/updated configurations
    **/
    @AuraEnabled
    public static List<DEL_KnowledgeConfiguration__c> saveCategories(Map<String, String> map_CategoryByParent, List<Object> list_SubcategoriesSelected, String strPageName) {
        map_KnowledgeConfigurationsByName = new Map<String,DEL_KnowledgeConfiguration__c>();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsforUpsert = new List<DEL_KnowledgeConfiguration__c>();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsforUpdate = new List<DEL_KnowledgeConfiguration__c>();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsforInsert = new List<DEL_KnowledgeConfiguration__c>();
        //Final list of subcategories to be removed from the configs
        List<DEL_KnowledgeConfiguration__c> list_ConfigurationsToDelete = new List<DEL_KnowledgeConfiguration__c>();
        //List of subcategories to be removed from the configs
        List<DEL_KnowledgeConfiguration__c> list_ConfigurationsForDeletion = new List<DEL_KnowledgeConfiguration__c>();
        //List of  errors from all the DML operations
        List<String> list_ConsolidatedDMLErrors =new List<String>();

        try {
            for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : [SELECT 
                                                                            Id,
                                                                            Name,
                                                                            ParentCategory__c,
                                                                            SortOrder__c
                                                                            FROM 
                                                                            DEL_KnowledgeConfiguration__c
                                                                            WHERE PageName__c = :strPageName 
                                                                            ]
            ) {
                map_KnowledgeConfigurationsByName.put(objKnowledgeConfiguration.Name, objKnowledgeConfiguration);
            }
            
            for (Object strsubCategory : list_SubcategoriesSelected) {
                String strJson = JSON.serialize(strsubCategory);
                CategoryWrapper objWrapper = (CategoryWrapper)JSON.deserialize(strjson, CategoryWrapper.class);
                DEL_KnowledgeConfiguration__c objKnowledgeConfiguration = new DEL_KnowledgeConfiguration__c();
                if (map_KnowledgeConfigurationsByName.containsKey(objWrapper.name)) {
                    objKnowledgeConfiguration = map_KnowledgeConfigurationsByName.get(objWrapper.name);
                    objKnowledgeConfiguration.SortOrder__c = Integer.valueOf(objWrapper.SortOrder);
                    objKnowledgeConfiguration.PageName__c = strPageName;
                    list_KnowledgeConfigurationsforUpdate.add(objKnowledgeConfiguration);
                } else {
                    objKnowledgeConfiguration.Name = objWrapper.name;
                    objKnowledgeConfiguration.SortOrder__c = Integer.valueOf(objWrapper.SortOrder);
                    objKnowledgeConfiguration.PageName__c = strPageName;
                    list_KnowledgeConfigurationsforInsert.add(objKnowledgeConfiguration);
                }
            }

            list_KnowledgeConfigurationsforUpsert.addAll(list_KnowledgeConfigurationsforInsert);
            list_KnowledgeConfigurationsforUpsert.addAll(list_KnowledgeConfigurationsforUpdate);
            for (String strCategory : map_KnowledgeConfigurationsByName.keySet())  {
                if(list_KnowledgeConfigurationsforUpdate.contains(map_KnowledgeConfigurationsByName.get(strCategory))) {
                    continue;
                } else {
                    list_ConfigurationsForDeletion.add(map_KnowledgeConfigurationsByName.get(strcategory));
                }
            }

            List<Database.UpsertResult> list_UpsertResults = Database.upsert(list_KnowledgeConfigurationsforUpsert, false);
            list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_UpsertResults, 'Upsert'));

            for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : list_KnowledgeConfigurationsforUpsert) {
                map_KnowledgeConfigurationsByName.put(objKnowledgeConfiguration.Name, objKnowledgeConfiguration);
            }

            for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : list_KnowledgeConfigurationsforUpsert) {
                String strParentCategory = map_CategoryByParent.get(objKnowledgeConfiguration.Name);
                Id idParentCategory = map_KnowledgeConfigurationsByName.get(strParentCategory)?.Id;
                objKnowledgeConfiguration.ParentCategory__c = idParentCategory;
                map_KnowledgeConfigurationsByName.get(objKnowledgeConfiguration.Name).ParentCategory__c  = idParentCategory;
            }

            List<Database.SaveResult> list_UpdateResults = Database.update(list_KnowledgeConfigurationsforUpsert, false);
            list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_UpdateResults, 'Update'));

            //Fetch and delete the categories and their inner subcategories
            fetchChildCategories(list_ConfigurationsForDeletion, map_KnowledgeConfigurationsByName, list_ConfigurationsToDelete);

            List<Database.DeleteResult> list_DeleteResults = Database.delete(list_ConfigurationsToDelete, true);
            list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_DeleteResults, 'Delete'));
            
            if (!list_ConsolidatedDMLErrors.isEmpty()) {
                DEL_Utils.logDMLException(
                    'DEL_KnowledgeManagementController',
                    'saveCategories',
                    list_ConsolidatedDMLErrors
                );
            }

            return list_KnowledgeConfigurationsforUpsert;

        } catch (Exception objException) {
            DEL_Utils.logException(
                'DEL_KnowledgeManagementController',
                'saveCategories',
                objException,
                true
            );
            return list_KnowledgeConfigurationsforUpsert; 
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<DEL_KnowledgeConfiguration__c> getSelectedCategories(String strPageName) {
        List<DEL_KnowledgeConfiguration__c> list_SelectedCategories = [SELECT
                                                                       Id,
                                                                       Name,
                                                                       ParentCategory__c,
                                                                       SortOrder__c,
                                                                       PageName__c
                                                                       FROM 
                                                                       DEL_KnowledgeConfiguration__c
                                                                       WHERE 
                                                                       PageName__c = 'Admin_Setup' OR
                                                                       PageName__c = :strPageName
                                                                       ORDER By SortOrder__c];
        return list_SelectedCategories;
    }
    
    /**
    * @ author       :  Ankit CS
    * @ description  :  This method queries and returns the TableofContentsWrapper Object which mainly consists of
    *                   all the Available and Selected Categories based on the Page Name (strPageName).
    * @ params       :  'strPageName' - Page Name from the Component to search for Knowledge Configurations.
    * @ return       :  'TableofContentsWrapper' - Wrapper Class
    **/
    @AuraEnabled(cacheable = true)
    public static TableofContentsWrapper getCategorySelectionsByPage(String strPageName) {
        List<DescribeDataCategoryGroupResult> describeCategoryResult;
            List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
        	List<DataCategory> list_ParentCategories = new List<DataCategory>();
            TableofContentsWrapper objWrapper = new TableofContentsWrapper();
            Map<String, String> map_CategoryByParent = new Map<String, String>();
            map_KnowledgeConfigurationsByName = new Map<String,DEL_KnowledgeConfiguration__c>();
            Map<String, List<String>> map_ChildCategoriesByParent = new Map<String, List<String>>();
        	Map<String, List<String>> map_ConfigsByPageName = new Map<String, List<String>>();
        	Map<String, DEL_KnowledgeConfiguration__c> map_ConfigsByName = new Map<String, DEL_KnowledgeConfiguration__c>();
            try {
                for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : [SELECT 
                                                                                Id,
                                                                                Name,
                                                                                ParentCategory__c,
                                                                                PageName__c,
                                                                                SortOrder__c
                                                                                FROM 
                                                                                DEL_KnowledgeConfiguration__c
                                                                                WHERE PageName__c = 'Admin_Setup'
                                                                                OR PageName__c = :strPageName
                                                                                ORDER BY SortOrder__c ASC
                                                                                ]
                ) {
                    map_ConfigsByName.put(objKnowledgeConfiguration.Name+objKnowledgeConfiguration.PageName__c, objKnowledgeConfiguration);
                    if (objKnowledgeConfiguration.PageName__c == 'Admin_Setup') {
                        if (!map_ConfigsByPageName.containsKey('Admin_Setup')) {
                            map_ConfigsByPageName.put('Admin_Setup', new List<String> { objKnowledgeConfiguration.Name });
                        } else {
                            map_ConfigsByPageName.get('Admin_Setup').add(objKnowledgeConfiguration.Name);
                        }
                    } else if (
                        String.isNotBlank(objKnowledgeConfiguration.PageName__c) &&
                        String.isNotBlank(strPageName) &&
                        strPageName == objKnowledgeConfiguration.PageName__c
                    ) {
                        if (!map_ConfigsByPageName.containsKey(strPageName)) {
                            map_ConfigsByPageName.put(strPageName, new List<String> { objKnowledgeConfiguration.Name });
                        } else {
                            map_ConfigsByPageName.get(strPageName).add(objKnowledgeConfiguration.Name);
                        }
                    }
                }

                //Making the call to the describeDataCategoryGroups to
                //get the list of category groups associated
                List<String> objType = new List<String>();
                objType.add('KnowledgeArticleVersion');
                describeCategoryResult = Schema.describeDataCategoryGroups(objType);
                
                //Creating a list of pair objects to use as a parameter
                //for the describe call
                List<DataCategoryGroupSobjectTypePair> list_DataCategoryGroupSobjectTypePairs = 
                    new List<DataCategoryGroupSobjectTypePair>();
                
                //Looping throught the first describe result to create
                //the list of list_DataCategoryGroupSobjectTypePairs for the second describe call
                for (DescribeDataCategoryGroupResult singleResult : describeCategoryResult) {
                    DataCategoryGroupSobjectTypePair objDataCategoryGroupSobjectTypePair = new DataCategoryGroupSobjectTypePair();
                    objDataCategoryGroupSobjectTypePair.setSobject(singleResult.getSobject());
                    objDataCategoryGroupSobjectTypePair.setDataCategoryGroupName(singleResult.getName());
                    list_DataCategoryGroupSobjectTypePairs.add(objDataCategoryGroupSobjectTypePair);
                }
                
                //describeDataCategoryGroupStructures()
                describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(list_DataCategoryGroupSobjectTypePairs, false);
                //Getting data from the result
                for (DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult) {
                    //Get name of the associated Sobject
                    singleResult.getSobject();
                    
                    //Get the name of the data category group
                    singleResult.getName();
                    
                    //Get the name of the data category group
                    singleResult.getLabel();
                    
                    //Get the description of the data category group
                    singleResult.getDescription();

                    map_CategoriesByUniqueName.put(singleResult.getName(), singleResult.getLabel());
                    objWrapper.list_GroupCategoryNames.add(singleResult.getName());
                    
                    //Get the top level categories
                    DataCategory [] list_TopLevelCategories = singleResult.getTopCategories();
                    if (!list_TopLevelCategories.isEmpty()) {
                        DataCategory category = list_TopLevelCategories[0];
                        if (category.getName() == 'All') {
                            list_ParentCategories = category.getChildCategories();
                            for (DataCategory topLevelCategory : list_ParentCategories) {
                                
                                if (
                                    map_ConfigsByPageName.containsKey('Admin_Setup') &&
                                    map_ConfigsByPageName.get('Admin_Setup').contains(topLevelCategory.getName())
                                ) {
                                    objWrapper.list_AvailableCategories.add(map_ConfigsByName.get(topLevelCategory.getName()+'Admin_Setup'));
                                }
                                
                                if (
                                    map_ConfigsByPageName.containsKey(strPageName) && 
                                    map_ConfigsByPageName.get(strPageName).contains(topLevelCategory.getName())
                                ) {
                                    objWrapper.list_SelectedCategories.add(map_ConfigsByName.get(topLevelCategory.getName()+strPageName));
                                }
                                
                                map_CategoryByParent.put(topLevelCategory.getName(), singleResult.getName());

                                List<DataCategory> list_Subcategories = new List<DataCategory>();
                                List<String> list_SubcategoryNames = new List<String>();
                                getAllCategories(
                                    new List<DataCategory> { topLevelCategory }, 
                                    map_CategoryByParent,
                                    list_Subcategories,
                                    map_ChildCategoriesByParent
                                );
                                for (DataCategory objSubcategory : list_Subcategories) {
                                    CategoryWrapper objCategoryWrapper = new CategoryWrapper();
                                    objCategoryWrapper.name = objSubcategory.getName();
                                    if (
                                        map_ConfigsByPageName.containsKey('Admin_Setup') &&
                                        map_ConfigsByPageName.get('Admin_Setup').contains(objSubcategory.getName())
                                    ) {
                                        objWrapper.list_AvailableCategories.add(map_ConfigsByName.get(objSubcategory.getName()+'Admin_Setup'));
                                        //objWrapper.list_AvailableCategories.add(map_ConfigsByName.get(topLevelCategory.getLabel()));
                                    }
                                    
                                    if (
                                        map_ConfigsByPageName.containsKey(strPageName) && 
                                        map_ConfigsByPageName.get(strPageName).contains(objSubcategory.getName())
                                    ) {
                                        objWrapper.list_SelectedCategories.add(map_ConfigsByName.get(objSubcategory.getName()+strPageName));
                                        // objWrapper.list_SelectedCategories.add(map_ConfigsByName.get(topLevelCategory.getLabel()));
                                    }
                                    list_SubcategoryNames.add(objSubcategory.getName());
                                }
  
                            }
                        }
                    }
                }
                
                if (objWrapper.list_SelectedCategories.isEmpty()) {
	                 objWrapper.list_SelectedCategories = objWrapper.list_AvailableCategories;
                }

                objWrapper.map_ArticlesByCategoryName = getAllKnowledgeArticles();
                objWrapper.map_CategoryByParent = map_CategoryByParent;
                objWrapper.map_CategoriesByUniqueName = map_CategoriesByUniqueName;
                Id idUserId = UserInfo.getUserId();
                objWrapper.objUserInformation = getCurrentUserDetails(idUserId);
                return objWrapper;
            } catch(Exception objException) {
                DEL_Utils.logException(
                    'DEL_KnowledgeManagementController',
                    'getCategorySelectionsByPage',
                    objException,
                    true
                );
                return objWrapper;
            }
    }

    /**
    * @ author       :  Rakesh Nayak & Ankit CS
    * @ description  :  This method queries all the categories present in the org and segregates them based on hierarchy
    * @ params       :  -
    * @ return       :  'objWrapper' - object of KnowledgeWrapper
    **/
    @AuraEnabled(cacheable = true)
    public static KnowledgeWrapper 
        getDescribeDataCategoryGroupStructureResults() {
            List<DescribeDataCategoryGroupResult> describeCategoryResult;
            List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
            List<DataCategory> list_ParentCategories = new List<DataCategory>();
            KnowledgeWrapper objWrapper = new KnowledgeWrapper();
            Map<String, String> map_CategoryByParent = new Map<String, String>();
            map_KnowledgeConfigurationsByName = new Map<String,DEL_KnowledgeConfiguration__c>();
            Map<String, List<String>> map_ChildCategoriesByParent = new Map<String, List<String>>();
            try {
                for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : [SELECT 
                                                                                Id,
                                                                                Name,
                                                                                ParentCategory__c,
                                                                                PageName__c,
                                                                                SortOrder__c
                                                                                FROM 
                                                                                DEL_KnowledgeConfiguration__c
                                                                                WHERE PageName__c = 'Admin_Setup'
                                                                                ORDER BY SortOrder__c ASC
                                                                                ]
                ) {
                    map_KnowledgeConfigurationsByName.put(objKnowledgeConfiguration.Name, objKnowledgeConfiguration);
                    objWrapper.list_DefaultSortedCategories.add(objKnowledgeConfiguration.Name);
                }

                //Making the call to the describeDataCategoryGroups to
                //get the list of category groups associated
                List<String> objType = new List<String>();
                objType.add('KnowledgeArticleVersion');
                describeCategoryResult = Schema.describeDataCategoryGroups(objType);
                
                //Creating a list of pair objects to use as a parameter
                //for the describe call
                List<DataCategoryGroupSobjectTypePair> list_DataCategoryGroupSobjectTypePairs = 
                    new List<DataCategoryGroupSobjectTypePair>();
                
                //Looping throught the first describe result to create
                //the list of list_DataCategoryGroupSobjectTypePairs for the second describe call
                for (DescribeDataCategoryGroupResult singleResult : describeCategoryResult) {
                    DataCategoryGroupSobjectTypePair objDataCategoryGroupSobjectTypePair = new DataCategoryGroupSobjectTypePair();
                    objDataCategoryGroupSobjectTypePair.setSobject(singleResult.getSobject());
                    objDataCategoryGroupSobjectTypePair.setDataCategoryGroupName(singleResult.getName());
                    list_DataCategoryGroupSobjectTypePairs.add(objDataCategoryGroupSobjectTypePair);
                }
                
                //describeDataCategoryGroupStructures()
                describeCategoryStructureResult = 
                    Schema.describeDataCategoryGroupStructures(list_DataCategoryGroupSobjectTypePairs, false);
                //Getting data from the result
                for (DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult) {
                    //Get name of the associated Sobject
                    singleResult.getSobject();
                    
                    //Get the name of the data category group
                    singleResult.getName();
                    
                    //Get the name of the data category group
                    singleResult.getLabel();
                    
                    //Get the description of the data category group
                    singleResult.getDescription();

                    map_CategoriesByUniqueName.put(singleResult.getName(), singleResult.getLabel());
                    objWrapper.list_GroupCategoryNames.add(singleResult.getName());
                    CategoryWrapper objCategoryWrapperGroup = new CategoryWrapper();
                    objCategoryWrapperGroup.name = singleResult.getName();
                    objWrapper.list_AllCategories.add(objCategoryWrapperGroup);
                    
                    //Get the top level categories
                    DataCategory [] list_TopLevelCategories = singleResult.getTopCategories();
                    if (!list_TopLevelCategories.isEmpty()) {
                        DataCategory category = list_TopLevelCategories[0];
                        if (category.getName() == 'All') {
                            list_ParentCategories = category.getChildCategories();
                            for (DataCategory topLevelCategory : list_ParentCategories) {
                                List<DataCategory> list_Subcategories = new List<DataCategory>();
                                List<String> list_SubcategoryNames = new List<String>();
                                if (map_ChildCategoriesByParent.containsKey(singleResult.getName())) {
                                    map_ChildCategoriesByParent.get(singleResult.getName()).add(topLevelCategory.getName());
                                } else {
                                    map_ChildCategoriesByParent.put(singleResult.getName(),new List<String>{topLevelCategory.getName()});
                                }
                                map_CategoryByParent.put(topLevelCategory.getName(), singleResult.getName());
                                getAllCategories(
                                    new List<DataCategory> { topLevelCategory }, 
                                    map_CategoryByParent,
                                    list_Subcategories,
                                    map_ChildCategoriesByParent
                                );
                                map_CategoriesByUniqueName.put(topLevelCategory.getName(), topLevelCategory.getLabel());
                                for (DataCategory objSubcategory : list_Subcategories) {
                                    CategoryWrapper objCategoryWrapper = new CategoryWrapper();
                                    objCategoryWrapper.name = objSubcategory.getName();
                                    objWrapper.list_AllCategories.add(objCategoryWrapper);
                                    list_SubcategoryNames.add(objSubcategory.getName());
                                }

                                objWrapper.map_CategoriesByTopLevelCategories.put(
                                    topLevelCategory.getName(), 
                                    list_SubcategoryNames
                                );
                            }
                        }
                    }

                    objWrapper.map_ChildCategoriesByParent = map_ChildCategoriesByParent;
                    objWrapper.map_CategoryByParent = map_CategoryByParent;
                }

                objWrapper.list_ParentCategoryNames.addAll(objWrapper.map_CategoriesByTopLevelCategories.keySet());
                for (String strparent : objWrapper.map_CategoriesByTopLevelCategories.keySet()) {
                    CategoryWrapper objCategoryWrapper = new CategoryWrapper();
                    objCategoryWrapper.name = strparent;
                    objWrapper.list_AllCategories.add(objCategoryWrapper);
                }
                objWrapper.map_KnowledgeArticlesByCategoryUniqueName = getAllKnowledgeArticles();
                objWrapper.map_CategoriesByUniqueName = map_CategoriesByUniqueName;
                Id idUserId = UserInfo.getUserId();
                objWrapper.objUserInformation = getCurrentUserDetails(idUserId);

            } catch (Exception objException) {
                DEL_Utils.logException(
                    'DEL_KnowledgeManagementController',
                    'getDescribeDataCategoryGroupStructureResults',
                    objException,
                    true
                );
                return objWrapper;
            }
            return objWrapper;
        }

    /**
    * @ author       :  Rakesh NayaK
    * @ description  :  This method fetches all the inner categories for given categories
    * @ params       :  'categories'                  - List of categories  whose inneer categories are to be fetched
    *                :  'map_ChildCategoriesByParent' - Map of child categories by parent category
    *                :  'allCategories'               - List of all categories present in the org
    *                :  'map_CategoryByParent'        - Map of each inner category by it's immediate parent
    **/
    public static void getAllCategories(
        DataCategory [] categories, 
        Map<String, String> map_CategoryByParent,
        List<DataCategory> allCategories,
        Map<String, List<String>> map_ChildCategoriesByParent
    ) {
        if (categories.isEmpty()) {
            return;
        } else {
            DataCategory [] categoriesClone = categories.clone();
            DataCategory category = categoriesClone[0];
            for (DataCategory subcategory : category.getChildCategories()) {
                if (map_ChildCategoriesByParent.containsKey(category.getName())) {
                    map_ChildCategoriesByParent.get(category.getName()).add(subcategory.getName());
                } else {
                    map_ChildCategoriesByParent.put(category.getName(), new List<String> {subcategory.getName()});
                }
                map_CategoryByParent.put(subcategory.getName(), category.getName());
            }
            map_CategoriesByUniqueName.put(category.getName(), category.getLabel());

            categoriesClone.remove(0);
            categoriesClone.addAll(category.getChildCategories());
            allCategories.addAll(category.getChildCategories());
            getAllCategories(categoriesClone, map_CategoryByParent, allCategories, map_ChildCategoriesByParent);
        }
    }

    /**
    * @ author       :  Rakesh NayaK
    * @ description  :  This method fetches all thee child categories for the categories to be deleted
    * @ params       :  'list_ConfigsForDeletion'           - list of categories removed from the component
    *                :  'map_KnowledgeConfigurationsByName' - map of Knowledge configuration records by category name
    *                :  'list_ConfigurationsToDelete'       - final list of configurations to be deleted
    **/
    public static void fetchChildCategories(
        List<DEL_KnowledgeConfiguration__c> list_ConfigsForDeletion, 
        Map<String, DEL_KnowledgeConfiguration__c> map_KnowledgeConfigurationsByName,
        List<DEL_KnowledgeConfiguration__c> list_ConfigurationsToDelete
        ) {
        if(!list_ConfigsForDeletion.isEmpty()) {
            DEL_KnowledgeConfiguration__c objConfig = list_ConfigsForDeletion[0];
            if (!list_ConfigurationsToDelete.contains(objConfig)) {
                list_ConfigurationsToDelete.add(objConfig);
            }
            for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : map_KnowledgeConfigurationsByName.values()) {
                if(objKnowledgeConfiguration.ParentCategory__c == objConfig.Id) {
                    if (!list_ConfigurationsToDelete.contains(objKnowledgeConfiguration)) {
                        list_ConfigurationsToDelete.add(objKnowledgeConfiguration);
                    }
                    if (!list_ConfigsForDeletion.contains(objKnowledgeConfiguration)) {
                        list_ConfigsForDeletion.add(objKnowledgeConfiguration);
                    }
                }
            }
            list_ConfigsForDeletion.remove(0);
            fetchChildCategories(list_ConfigsForDeletion, map_KnowledgeConfigurationsByName, list_ConfigurationsToDelete);
        } else {
            return;
        }
    }

    /**
    * @ author       :  Vinay kant
    * @ description  :  This method will fetch all the Knowledge Articles under each active categories.
    * @ return       :  'map_KnowledgeArticlesByCategoryName' - Map of all the Knowledge Articles by Category Unique Name.
    **/
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Knowledge__kav>> getAllKnowledgeArticles () { 
        List<Knowledge__DataCategorySelection> list_KnowledgeArticlesWithCategory = new List<Knowledge__DataCategorySelection>();
        Map<Id, String> map_KnowledgeArticleIdByCategoryName = new Map<Id, String>();
        Map<String, List<Knowledge__kav>> map_KnowledgeArticlesByCategoryName = new Map<String, List<Knowledge__kav>>();
        Map<Id, Id> map_KnowledgeRecordIdByKnowledgeArticleId = new Map<Id, Id>();

        list_KnowledgeArticlesWithCategory = [SELECT 
                                              Id, 
                                              ParentId, 
                                              DataCategoryGroupName, 
                                              DataCategoryName 
                                              FROM Knowledge__DataCategorySelection];
        for (Knowledge__DataCategorySelection objKnowledgeCategory : list_KnowledgeArticlesWithCategory) {
            map_KnowledgeArticleIdByCategoryName.put(objKnowledgeCategory.ParentId, objKnowledgeCategory.DataCategoryName);
        }

        List<Knowledge__kav> list_KnowledgeArticles = [SELECT Id, 
                                                       KnowledgeArticleId, 
                                                       SortOrder__c, 
                                                       Title, 
                                                       PublishStatus, 
                                                       VersionNumber 
                                                       FROM Knowledge__kav
                                                       WHERE Id IN :map_KnowledgeArticleIdByCategoryName.keySet()
                                                       AND PublishStatus = 'Online'
                                                       ORDER BY SortOrder__c];
        for (Knowledge__kav objKnowledgeArticle : list_KnowledgeArticles) {
            map_KnowledgeRecordIdByKnowledgeArticleId.put(objKnowledgeArticle.KnowledgeArticleId, objKnowledgeArticle.Id);
        }

        List<Knowledge__kav> list_KnowledgeArticlesNew = [SELECT 
                                                          Id, 
                                                          KnowledgeArticleId, 
                                                          SortOrder__c, 
                                                          Title, 
                                                          PublishStatus, 
                                                          VersionNumber, 
                                                          Language, 
                                                          IsMasterLanguage
                                                          FROM Knowledge__kav
                                                          WHERE KnowledgeArticleId IN :map_KnowledgeRecordIdByKnowledgeArticleId.keySet()
                                                          AND PublishStatus = 'Online'
                                                          ORDER BY SortOrder__c];

        for (Knowledge__kav objKnowledgeArticle : list_KnowledgeArticlesNew) {
            String strCategoryName = map_KnowledgeArticleIdByCategoryName.get(map_KnowledgeRecordIdByKnowledgeArticleId.get(objKnowledgeArticle.KnowledgeArticleId));
            if (!map_KnowledgeArticlesByCategoryName.containsKey(strCategoryName)) {
                map_KnowledgeArticlesByCategoryName.put(strCategoryName, new List<Knowledge__kav>{ objKnowledgeArticle });
            } else {
                map_KnowledgeArticlesByCategoryName.get(strCategoryName).add(objKnowledgeArticle);
            }
        }
        return map_KnowledgeArticlesByCategoryName;
    }

    /**
    * @ author       :  Vinay kant
    * @ description  :  This method set the 'SortOrder__c' field for the Knowledge Articles to store it in sorted order.
    * @ params       :  'list_KnowledgeArticles' - list of Knowledge Articles
    **/
    @AuraEnabled
    public static void setknowledgeArticlesOrder(List<Knowledge__kav> list_KnowledgeArticles) {
        Map<Id, Knowledge__kav> map_KnowledgeArticleByKnowledgeId = new Map<Id, Knowledge__kav>();
        List<Id> list_DraftArticleIds = new List<Id>();
        List<Id> list_KnowledgeArticlesIds = new List<Id>();
        List<Knowledge__kav> list_DraftKnowledgeArticles = new List<Knowledge__kav>();
        
        try {
            if (list_KnowledgeArticles.size() > 0) {
                for (Knowledge__kav objKnowledgeArticle : list_KnowledgeArticles) {
                    map_KnowledgeArticleByKnowledgeId.put(objKnowledgeArticle.KnowledgeArticleId, objKnowledgeArticle);
                }
                List<Knowledge__kav> list_KnowledgeArticlesNew = [SELECT 
                                                                  Id, 
                                                                  KnowledgeArticleId, 
                                                                  SortOrder__c, 
                                                                  Title, 
                                                                  PublishStatus, 
                                                                  VersionNumber, 
                                                                  Language, 
                                                                  IsMasterLanguage
                                                                  FROM Knowledge__kav
                                                                  WHERE KnowledgeArticleId IN :map_KnowledgeArticleByKnowledgeId.keySet()
                                                                  AND PublishStatus = 'Online'];

                for (Knowledge__kav objKnowledgeArticle : list_KnowledgeArticlesNew) {
                    Id idDraftArticle;
                    if (!objKnowledgeArticle.IsMasterLanguage) {
                        idDraftArticle = KbManagement.PublishingService.editPublishedTranslation(objKnowledgeArticle.KnowledgeArticleId, objKnowledgeArticle.Language, false);
                    } else {
                        idDraftArticle = KbManagement.PublishingService.editOnlineArticle(objKnowledgeArticle.KnowledgeArticleId, false);
                    }
                    list_DraftArticleIds.add(idDraftArticle);
                }

                list_DraftKnowledgeArticles = [SELECT 
                                               Id,
                                               KnowledgeArticleId, 
                                               VersionNumber, 
                                               Language,
                                               IsMasterLanguage
                                               FROM Knowledge__kav
                                               WHERE Id IN :list_DraftArticleIds];
                for (Knowledge__kav objDraftKnowledgeArticle : list_DraftKnowledgeArticles) {
                    objDraftKnowledgeArticle.SortOrder__c = map_KnowledgeArticleByKnowledgeId.get(objDraftKnowledgeArticle.KnowledgeArticleId).SortOrder__c;
                }

                if (list_DraftKnowledgeArticles.size() > 0) {
                    update list_DraftKnowledgeArticles;
                }
                
                for (Knowledge__kav objKnowledgeArticle : list_DraftKnowledgeArticles) {
                    if (!objKnowledgeArticle.IsMasterLanguage) {
                        Id idNewUpdatedArticle = objKnowledgeArticle.Id;
                        KbManagement.PublishingService.completeTranslation(idNewUpdatedArticle);
                    } else {
                        Id idNewUpdatedArticle = objKnowledgeArticle.KnowledgeArticleId;
                        KbManagement.PublishingService.publishArticle(idNewUpdatedArticle, false);
                    }
                }
            }
        } catch (Exception objException) {
            DEL_Utils.logException(
                'DEL_KnowledgeManagementController',
                'setknowledgeArticlesOrder',
                objException,
                true
            );
            throw new AuraHandledException(objException.getMessage());
        }
    }

    /**
     * @ author        : G Nanda Kishore Reddy 
     * @ description   : This apex method is used differentiate previous knowledge article and next knowledge article by Sort Order
     *                   and returns Sorted Knowledge Articles.
     * @params         : 'recordId' - Id of the Knowledge Articles.
     * @ return        : 'articles'  - Map of 'Next' or 'Previous' or 'Both' knowledge article corresponding to the current knowledge articles.
     **/
    @AuraEnabled(cacheable = true)
    public static Map<String, Knowledge__kav> DEL_Nxtprev (Id recordId) {
        Knowledge__kav objKnowledgeArticle = [SELECT 
                                              Id, 
                                              Title, 
                                              KnowledgeArticleId, 
                                              PublishStatus, 
                                              VersionNumber, 
                                              SortOrder__c,
                                              Language,
                                              IsMasterLanguage
                                              FROM Knowledge__kav 
                                              WHERE PublishStatus = 'Online' 
                                              AND Id = :recordId];

        Knowledge__kav objKnowledgeArticleMasterLanguage = [SELECT 
                                                            Id, 
                                                            Title, 
                                                            KnowledgeArticleId
                                                            FROM Knowledge__kav 
                                                            WHERE PublishStatus = 'Online' 
                                                            AND KnowledgeArticleId = :objKnowledgeArticle.KnowledgeArticleId
                                                            AND IsMasterLanguage = true 
                                                            LIMIT 1];

        Knowledge__DataCategorySelection objDataCategory = [SELECT 
                                                            Id, 
                                                            DataCategoryGroupName, 
                                                            DataCategoryName 
                                                            FROM Knowledge__DataCategorySelection 
                                                            WHERE ParentId = :objKnowledgeArticleMasterLanguage.Id];

        String groupName = objDataCategory.DataCategoryGroupName + '__c';
        String subCategory = objDataCategory.DataCategoryName + '__c';
        String strQuery = 'SELECT Id, Title, KnowledgeArticleId, PublishStatus, VersionNumber, IsMasterLanguage, Language, SortOrder__c FROM Knowledge__kav WHERE PublishStatus=\'Online\' WITH DATA CATEGORY '+groupName +' AT '+subCategory +' ORDER BY SortOrder__c';
        List<Knowledge__kav> filteredArticles = Database.query(strQuery);

        Map<String, Knowledge__kav> map_articlesByNextPrevious = new Map<String, Knowledge__kav>();
        
        for (Knowledge__kav objKnowledgeArticleFiltered: filteredArticles) {
            if (String.isNotBlank(String.valueOf(objKnowledgeArticleFiltered.SortOrder__c)) &&
                String.isNotBlank(String.valueOf(objKnowledgeArticle.SortOrder__c)) 
            ) {
                if (objKnowledgeArticleFiltered.SortOrder__c == (objKnowledgeArticle.SortOrder__c-1) &&
                    objKnowledgeArticleFiltered.IsMasterLanguage
                ) {
                    map_articlesByNextPrevious.put('previous', objKnowledgeArticleFiltered);
                }
                if (objKnowledgeArticleFiltered.SortOrder__c == (objKnowledgeArticle.SortOrder__c+1) &&
                    objKnowledgeArticleFiltered.IsMasterLanguage
                ) {
                    map_articlesByNextPrevious.put('next', objKnowledgeArticleFiltered);
                }
            }
        }
        for (Knowledge__kav objKnowledgeArticleFiltered: filteredArticles) {
            if (String.isNotBlank(String.valueOf(objKnowledgeArticleFiltered.SortOrder__c)) &&
                String.isNotBlank(String.valueOf(objKnowledgeArticle.SortOrder__c)) 
            ) {
                if (objKnowledgeArticleFiltered.SortOrder__c == (objKnowledgeArticle.SortOrder__c-1) &&
                    objKnowledgeArticleFiltered.Language == objKnowledgeArticle.Language
                ) {
                    map_articlesByNextPrevious.put('previous', objKnowledgeArticleFiltered);
                }
                if (objKnowledgeArticleFiltered.SortOrder__c == (objKnowledgeArticle.SortOrder__c+1) &&
                    objKnowledgeArticleFiltered.Language == objKnowledgeArticle.Language
                ) {
                    map_articlesByNextPrevious.put('next', objKnowledgeArticleFiltered);
                }
            }
        }

        return map_articlesByNextPrevious;
    }

    /**
    * @ author       :  Vinay kant
    * @ description  :  This method will fetch current logged-in user information.
    * @ params       :  'idUserId' - Current logged-in User Id.
    **/
    @AuraEnabled(cacheable=true)
    public static User getCurrentUserDetails(Id idUserId) { 
        return [SELECT 
                Id,
                Name,
                IsPortalEnabled,
                LanguageLocaleKey,
                UserPermissionsKnowledgeUser
                FROM User 
                WHERE Id = :idUserId
                AND IsActive = true];
    }
}