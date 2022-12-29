/*******************************************************************************************************************************
* 
* @ Name            :   DEL_KnowledgeManagementController
* @ Purpose         :   Controller class for del_KnowledgeArticlesComponent
* @ Author          :   Rakesh Nayak
* @ Test Class Name :   DEL_KnowledgeManagementControllerTest
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
        @AuraEnabled public String strErrorMessage;

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
        @AuraEnabled public Map<String, String> map_CategoriesByUniqueName = new Map<String, String>();
        //Map all Knowledge Configuration for Articles with Knowledge Artile Id
        @AuraEnabled public Map<String, DEL_KnowledgeConfiguration__c> map_KnowledgeArticleConfigByKnowledgeArticleId = new Map<String, DEL_KnowledgeConfiguration__c>();
        //Current Logged-In User information
        @AuraEnabled public User objUserInformation = new user();

        public KnowledgeWrapper() {
            this.blnIsSuccess = true;
            this.strErrorMessage = '';
        }
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
        @AuraEnabled public Boolean blnIsSuccess;
        @AuraEnabled public String strErrorMessage;

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
        //Map of Knowledge Configuration by Knowledge Article Id
        @AuraEnabled public Map<String, DEL_KnowledgeConfiguration__c> map_KnowledgeConfigurationByKnowledgeArticleId = new Map<String, DEL_KnowledgeConfiguration__c>();

        public TableofContentsWrapper() {
            this.blnIsSuccess = true;
            this.strErrorMessage = '';
        }
    }

    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method save all the selected categories
    * @ params       :  'map_categoryByParent'       - Map of each category and its immediate parent
    *                :  'list_SubcategoriesSelected' - List of slected subcategories from the component
    *                :  'strPageName'                - Name of the page
    * @ return       :  'list_AllArrangedArticles'   - List of All Sorted Articles
    **/
    @AuraEnabled
    public static KnowledgeWrapper saveCategories(
        Map<String, String> map_CategoryByParent, 
        List<Object> list_SubcategoriesSelected, 
        String strPageName, 
        Map<String, List<Knowledge__kav>> map_knowledgeArticlesByCategory
    ) {
        map_KnowledgeConfigurationsByName = new Map<String, DEL_KnowledgeConfiguration__c>();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsforUpsert = new List<DEL_KnowledgeConfiguration__c>();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsforUpdate = new List<DEL_KnowledgeConfiguration__c>();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsforInsert = new List<DEL_KnowledgeConfiguration__c>();
        //Final list of subcategories to be removed from the configs
        List<DEL_KnowledgeConfiguration__c> list_ConfigurationsToDelete = new List<DEL_KnowledgeConfiguration__c>();
        //List of subcategories to be removed from the configs
        List<DEL_KnowledgeConfiguration__c> list_ConfigurationsForDeletion = new List<DEL_KnowledgeConfiguration__c>();
        //Set of existing and newly added  article configuration keys (Article Configuration Name + Knowledge Article  Id)
        Set<String> set_KnowledgeConfigurationKeys = new Set<String>();
        //List of article configs to be deleted
        List<DEL_KnowledgeConfiguration__c> list_ArticleconfigurationsToDelete = new List<DEL_KnowledgeConfiguration__c>();
        //List of  errors from all the DML operations
        List<String> list_ConsolidatedDMLErrors =new List<String>();
        Map<String, DEL_KnowledgeConfiguration__c> map_KnowledgeConfigurationByKnowledgeArticleId = new Map<String, DEL_KnowledgeConfiguration__c>();
        KnowledgeWrapper objKnowledgeWrapper = new KnowledgeWrapper();

        try {
            for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : [SELECT 
                                                                            Id,
                                                                            Name,
                                                                            ParentCategory__c,
                                                                            Type__c, 
                                                                            KnowledgeArticleId__c, 
                                                                            SortOrder__c
                                                                            FROM 
                                                                            DEL_KnowledgeConfiguration__c
                                                                            WHERE PageName__c = :strPageName 
                                                                            OR Type__c = 'Knowledge Article'
                                                                            ]
            ) {
                if (objKnowledgeConfiguration.Type__c == 'Knowledge Article') {
                    map_KnowledgeConfigurationByKnowledgeArticleId.put(objKnowledgeConfiguration.Name + objKnowledgeConfiguration.KnowledgeArticleId__c, objKnowledgeConfiguration);
                } else {
                    map_KnowledgeConfigurationsByName.put(objKnowledgeConfiguration.Name, objKnowledgeConfiguration);
                }
            }
            
            for (Object strsubCategory : list_SubcategoriesSelected) {
                String strJson = JSON.serialize(strsubCategory);
                CategoryWrapper objWrapper = (CategoryWrapper)JSON.deserialize(strjson, CategoryWrapper.class);
                DEL_KnowledgeConfiguration__c objKnowledgeConfiguration = new DEL_KnowledgeConfiguration__c();
                if (map_KnowledgeConfigurationsByName.containsKey(objWrapper.name)) {
                    objKnowledgeConfiguration = map_KnowledgeConfigurationsByName.get(objWrapper.name);
                    objKnowledgeConfiguration.SortOrder__c = Integer.valueOf(objWrapper.SortOrder);
                    objKnowledgeConfiguration.PageName__c = strPageName;
                    objKnowledgeConfiguration.Type__c = 'Data Category';
                    list_KnowledgeConfigurationsforUpdate.add(objKnowledgeConfiguration);
                } else {
                    objKnowledgeConfiguration.Name = objWrapper.name;
                    objKnowledgeConfiguration.SortOrder__c = Integer.valueOf(objWrapper.SortOrder);
                    objKnowledgeConfiguration.PageName__c = strPageName;
                    objKnowledgeConfiguration.Type__c = 'Data Category';
                    list_KnowledgeConfigurationsforInsert.add(objKnowledgeConfiguration);
                }
            }

            list_KnowledgeConfigurationsforUpsert.addAll(list_KnowledgeConfigurationsforInsert);
            list_KnowledgeConfigurationsforUpsert.addAll(list_KnowledgeConfigurationsforUpdate);
            for (String strCategory : map_KnowledgeConfigurationsByName.keySet()) {
                if(list_KnowledgeConfigurationsforUpdate.contains(map_KnowledgeConfigurationsByName.get(strCategory))) {
                    continue;
                } else {
                    list_ConfigurationsForDeletion.add(map_KnowledgeConfigurationsByName.get(strcategory));
                }
            }

            if (!map_knowledgeArticlesByCategory.isEmpty()) {
                List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurations = new List<DEL_KnowledgeConfiguration__c>();
                for (String strCategory : map_knowledgeArticlesByCategory.keySet()) {
                    for (Integer intIndex = 0; intIndex < map_knowledgeArticlesByCategory.get(strCategory).size(); intIndex++) {
                        if (map_KnowledgeConfigurationByKnowledgeArticleId.containsKey(strCategory + map_knowledgeArticlesByCategory.get(strCategory)[intIndex].KnowledgeArticleId)) {
                            map_KnowledgeConfigurationByKnowledgeArticleId.get(strCategory + map_knowledgeArticlesByCategory.get(strCategory)[intIndex].KnowledgeArticleId).SortOrder__c = intIndex + 1;
                            set_KnowledgeConfigurationKeys.add(strCategory + map_knowledgeArticlesByCategory.get(strCategory)[intIndex].KnowledgeArticleId);
                        } else {
                            DEL_KnowledgeConfiguration__c objKnowledgeConfiguration = new DEL_KnowledgeConfiguration__c(
                                KnowledgeArticleId__c = map_knowledgeArticlesByCategory.get(strCategory)[intIndex].KnowledgeArticleId,
                                Type__c = 'Knowledge Article',
                                SortOrder__c = intIndex + 1,
                                Name = strCategory
                            );
                            set_KnowledgeConfigurationKeys.add(strCategory + objKnowledgeConfiguration.KnowledgeArticleId__c);
                            map_KnowledgeConfigurationByKnowledgeArticleId.put(strCategory + objKnowledgeConfiguration.KnowledgeArticleId__c, objKnowledgeConfiguration);
                        }
                    }
                }
            }

            if (strPageName == 'Admin_Setup') {
                for (String strKnowledgeConfigurationKey : map_KnowledgeConfigurationByKnowledgeArticleId.keySet()) {
                    if (!set_KnowledgeConfigurationKeys.contains(strKnowledgeConfigurationKey)) {
                        list_ArticleconfigurationsToDelete.add(map_KnowledgeConfigurationByKnowledgeArticleId.get(strKnowledgeConfigurationKey));
                    }
                }
            }

            List<Database.UpsertResult> list_UpsertResults = new List<Database.UpsertResult>();
            if (!list_KnowledgeConfigurationsforUpsert.isEmpty()) {
                list_UpsertResults.addAll(Database.upsert(list_KnowledgeConfigurationsforUpsert, false));
            }

            if (!map_KnowledgeConfigurationByKnowledgeArticleId.values().isEmpty() && strPageName == 'Admin_Setup') {
                list_UpsertResults.AddAll(Database.upsert(map_KnowledgeConfigurationByKnowledgeArticleId.values(), false));
            }
            
            if (!list_UpsertResults.isEmpty()) {
                list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_UpsertResults, 'Upsert'));
            }

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
            if (!list_ArticleconfigurationsToDelete.isEmpty() && strPageName == 'Admin_Setup') {
                list_ConfigurationsToDelete.addAll(list_ArticleconfigurationsToDelete);
            }
            List<Database.DeleteResult> list_DeleteResults = Database.delete(list_ConfigurationsToDelete, true);
            list_ConsolidatedDMLErrors.addAll(DEL_Utils.processDMLErrors(list_DeleteResults, 'Delete'));
            
            if (!list_ConsolidatedDMLErrors.isEmpty()) {
                DEL_Utils.logDMLException(
                    'DEL_KnowledgeManagementController',
                    'saveCategories',
                    list_ConsolidatedDMLErrors
                );
            }

        } catch (Exception objException) {
            DEL_Utils.logException(
                'DEL_KnowledgeManagementController',
                'saveCategories',
                objException,
                true
            );
            objKnowledgeWrapper.blnIsSuccess = false;
            objKnowledgeWrapper.strErrorMessage = objException.getMessage();
        }
        return objKnowledgeWrapper;
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
                                                                                Type__c, 
                                                                                KnowledgeArticleId__c, 
                                                                                SortOrder__c
                                                                                FROM 
                                                                                DEL_KnowledgeConfiguration__c
                                                                                WHERE PageName__c = 'Admin_Setup'
                                                                                OR PageName__c = :strPageName 
                                                                                OR Type__c = 'Knowledge Article'
                                                                                ORDER BY SortOrder__c ASC
                                                                                ]
                ) {
                    if(objKnowledgeConfiguration.Type__c == 'Knowledge Article') {
                        objWrapper.map_KnowledgeConfigurationByKnowledgeArticleId.put(objKnowledgeConfiguration.Name + objKnowledgeConfiguration.KnowledgeArticleId__c, objKnowledgeConfiguration);
                    } else {
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
                
            } catch(Exception objException) {
                DEL_Utils.logException(
                    'DEL_KnowledgeManagementController',
                    'getCategorySelectionsByPage',
                    objException,
                    true
                );
                objWrapper.blnIsSuccess = false;
                objWrapper.strErrorMessage = objException.getMessage();
            }
            return objWrapper;
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
                                                                                SortOrder__c, 
                                                                                KnowledgeArticleId__c,
                                                                                Type__c
                                                                                FROM DEL_KnowledgeConfiguration__c
                                                                                WHERE PageName__c = 'Admin_Setup'
                                                                                OR Type__c= 'Knowledge Article'
                                                                                ORDER BY SortOrder__c ASC]
                ) {
                    if (!String.isNotBlank(objKnowledgeConfiguration.Type__c) ||
                        objKnowledgeConfiguration.Type__c != 'Knowledge Article'
                    ) {
                        map_KnowledgeConfigurationsByName.put(objKnowledgeConfiguration.Name, objKnowledgeConfiguration);
                        objWrapper.list_DefaultSortedCategories.add(objKnowledgeConfiguration.Name);
                    } else if (String.isNotBlank(objKnowledgeConfiguration.KnowledgeArticleId__c)) {
                        objWrapper.map_KnowledgeArticleConfigByKnowledgeArticleId.put(objKnowledgeConfiguration.Name + objKnowledgeConfiguration.KnowledgeArticleId__c, objKnowledgeConfiguration);
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
                objWrapper.blnIsSuccess = false;
                objWrapper.strErrorMessage = objException.getMessage();
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
    public static Map<String, List<Knowledge__kav>> getAllKnowledgeArticles() { 
        List<Knowledge__DataCategorySelection> list_KnowledgeArticlesWithCategory = new List<Knowledge__DataCategorySelection>();
        //Map of List of Category Names by KnowledgeVersion Id
        Map<Id, List<String>> map_CategoryNamesByKnowledgeVersionId = new Map<Id, List<String>>();
        Map<String, List<Knowledge__kav>> map_KnowledgeArticlesByCategoryName = new Map<String, List<Knowledge__kav>>();
        Map<Id, Id> map_KnowledgeRecordIdByKnowledgeArticleId = new Map<Id, Id>();

        list_KnowledgeArticlesWithCategory = [SELECT 
                                              Id, 
                                              ParentId, 
                                              DataCategoryGroupName, 
                                              DataCategoryName 
                                              FROM Knowledge__DataCategorySelection];
        for (Knowledge__DataCategorySelection objKnowledgeCategory : list_KnowledgeArticlesWithCategory) {
            if (map_CategoryNamesByKnowledgeVersionId.containsKey(objKnowledgeCategory.ParentId)) {
                map_CategoryNamesByKnowledgeVersionId.get(objKnowledgeCategory.ParentId).add(objKnowledgeCategory.DataCategoryName);
            } else {
                map_CategoryNamesByKnowledgeVersionId.put(
                    objKnowledgeCategory.ParentId, 
                    new List<String> { objKnowledgeCategory.DataCategoryName }
                );
            }
        }

        List<Knowledge__kav> list_KnowledgeArticles = [SELECT Id, 
                                                       KnowledgeArticleId,
                                                       Title, 
                                                       PublishStatus, 
                                                       VersionNumber 
                                                       FROM Knowledge__kav
                                                       WHERE Id IN :map_CategoryNamesByKnowledgeVersionId.keySet()
                                                       AND PublishStatus = 'Online'
                                                       ];
        for (Knowledge__kav objKnowledgeArticle : list_KnowledgeArticles) {
            map_KnowledgeRecordIdByKnowledgeArticleId.put(objKnowledgeArticle.KnowledgeArticleId, objKnowledgeArticle.Id);
        }

        List<Knowledge__kav> list_KnowledgeArticlesNew = [SELECT 
                                                          Id, 
                                                          KnowledgeArticleId,
                                                          Title, 
                                                          PublishStatus, 
                                                          VersionNumber, 
                                                          Language, 
                                                          IsMasterLanguage
                                                          FROM Knowledge__kav
                                                          WHERE KnowledgeArticleId IN :map_KnowledgeRecordIdByKnowledgeArticleId.keySet()
                                                          AND PublishStatus = 'Online'
                                                          ];

        for (Knowledge__kav objKnowledgeArticle : list_KnowledgeArticlesNew) {
            if (map_CategoryNamesByKnowledgeVersionId.containsKey(map_KnowledgeRecordIdByKnowledgeArticleId.get(objKnowledgeArticle.KnowledgeArticleId))) {
                for (String strCategoryName : map_CategoryNamesByKnowledgeVersionId.get(map_KnowledgeRecordIdByKnowledgeArticleId.get(objKnowledgeArticle.KnowledgeArticleId))) {
                    if (!map_KnowledgeArticlesByCategoryName.containsKey(strCategoryName)) {
                        map_KnowledgeArticlesByCategoryName.put(strCategoryName, new List<Knowledge__kav>{ objKnowledgeArticle });
                    } else {
                        map_KnowledgeArticlesByCategoryName.get(strCategoryName).add(objKnowledgeArticle);
                    }
                }
            }
        }
        return map_KnowledgeArticlesByCategoryName;
    }

    /**
     * @ author        : G Nanda Kishore Reddy 
     * @ description   : This apex method is used differentiate previous knowledge article and next knowledge article by Sort Order
     *                   and returns Sorted Knowledge Articles.
     * @params         : 'recordId' - Id of the Knowledge Articles.
     *                 : 'strCategoryName' - This parameter stores Category Unique Name.
     * @ return        : 'articles'  - Map of 'Next' or 'Previous' or 'Both' knowledge article corresponding to the current knowledge articles.
     **/
    @AuraEnabled(cacheable = true)
    public static Map<String, Knowledge__kav> getNextAndPreviousArticles (Id recordId, String strCategoryName) {
        Id idNextKnowledgeArticleId, idPreviousKnowledgeArticleId;
        Id idKnowledgeArticleId, idMasterArticleId;
        Id idUserId = UserInfo.getUserId();
        User objLoggedInUser = getCurrentUserDetails(idUserId);
        List<Knowledge__DataCategorySelection> list_DataCategorySelection = new List<Knowledge__DataCategorySelection>();
        Map<Id, DEL_KnowledgeConfiguration__c> map_KnowledgeArticleConfigurationByKnowledgeArticleId = 
            new Map<Id, DEL_KnowledgeConfiguration__c>();
        Map<Id, List<Knowledge__kav>> map_KnowledgeArticlesByKnowledgeArticleId = new Map<Id, List<Knowledge__kav>>();
        Map<String, Knowledge__kav> map_articlesByNextPrevious = new Map<String, Knowledge__kav>();
        
        Map<Id, Knowledge__kav> map_knowledgeArticleByArticleId = new Map<Id, Knowledge__kav>([SELECT 
                                                                                               Id, 
                                                                                               Title, 
                                                                                               KnowledgeArticleId, 
                                                                                               PublishStatus, 
                                                                                               VersionNumber, 
                                                                                               Language,
                                                                                               IsMasterLanguage
                                                                                               FROM Knowledge__kav 
                                                                                               WHERE PublishStatus = 'Online'
                                                                                               ]);
        
        if (map_knowledgeArticleByArticleId.containsKey(recordId)) {
            idKnowledgeArticleId = map_knowledgeArticleByArticleId.get(recordId).KnowledgeArticleId;
        }
        for (Knowledge__kav objKnowledgeArticle : map_knowledgeArticleByArticleId.values()) {
            if (!map_KnowledgeArticlesByKnowledgeArticleId.containsKey(objKnowledgeArticle.KnowledgeArticleId)) {
                map_KnowledgeArticlesByKnowledgeArticleId.put(objKnowledgeArticle.KnowledgeArticleId, new List<Knowledge__kav>{ objKnowledgeArticle });
            } else {
                map_KnowledgeArticlesByKnowledgeArticleId.get(objKnowledgeArticle.KnowledgeArticleId).add(objKnowledgeArticle);
            }
            if (objKnowledgeArticle.KnowledgeArticleId == idKnowledgeArticleId && objKnowledgeArticle.IsMasterLanguage) {
                idMasterArticleId = objKnowledgeArticle.Id;
            }
        }

        if (String.isNotBlank(idMasterArticleId)) {
            list_DataCategorySelection = [SELECT 
                                          Id, 
                                          DataCategoryGroupName, 
                                          DataCategoryName 
                                          FROM Knowledge__DataCategorySelection 
                                          WHERE ParentId = :idMasterArticleId
                                          ORDER BY CreatedDate DESC];
        }

        Set<String> set_ValidCategoryNames = new Set<String>();
        Boolean blnFlag = true;
        Knowledge__DataCategorySelection objLatestDataCategorySelection = new Knowledge__DataCategorySelection();
        if (!list_DataCategorySelection.isEmpty()) {
            for (Knowledge__DataCategorySelection objDataCategorySelection: list_DataCategorySelection) {
                set_ValidCategoryNames.add(objDataCategorySelection.DataCategoryGroupName);
                set_ValidCategoryNames.add(objDataCategorySelection.DataCategoryName);
                if (blnFlag) {
                    objLatestDataCategorySelection = objDataCategorySelection;
                    blnFlag = false;
                }
            }
        }

        if (String.isBlank(strCategoryName) || (String.isNotBlank(strCategoryName) && !set_ValidCategoryNames.contains(strCategoryName))) {
            strCategoryName = objLatestDataCategorySelection.DataCategoryName;
        }
        
        List<DEL_KnowledgeConfiguration__c> list_knowledgeArticleConfiguration = [SELECT 
                                                                                  Id,
                                                                                  Name, 
                                                                                  KnowledgeArticleId__c, 
                                                                                  SortOrder__c, 
                                                                                  Type__c 
                                                                                  FROM DEL_KnowledgeConfiguration__c
                                                                                  WHERE Type__c = 'Knowledge Article'
                                                                                  AND Name = :strCategoryName];
        
        for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration: list_knowledgeArticleConfiguration) {
            map_KnowledgeArticleConfigurationByKnowledgeArticleId.put(objKnowledgeConfiguration.KnowledgeArticleId__c, objKnowledgeConfiguration);
        }

        if (String.isNotBlank(strCategoryName) && String.isNotBlank(idKnowledgeArticleId)) {
            for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration: list_knowledgeArticleConfiguration) {
                if (strCategoryName == objKnowledgeConfiguration.Name && 
                    String.isNotBlank(String.valueOf(objKnowledgeConfiguration.SortOrder__c)) && 
                    String.isNotBlank(String.valueOf(map_KnowledgeArticleConfigurationByKnowledgeArticleId.get(idKnowledgeArticleId).SortOrder__c)) &&
                    objKnowledgeConfiguration.SortOrder__c == map_KnowledgeArticleConfigurationByKnowledgeArticleId.get(idKnowledgeArticleId).SortOrder__c-1
                ) {
                    idPreviousKnowledgeArticleId = objKnowledgeConfiguration.KnowledgeArticleId__c;
                }
                if (strCategoryName == objKnowledgeConfiguration.Name && 
                String.isNotBlank(String.valueOf(objKnowledgeConfiguration.SortOrder__c)) && 
                String.isNotBlank(String.valueOf(map_KnowledgeArticleConfigurationByKnowledgeArticleId.get(idKnowledgeArticleId).SortOrder__c)) &&
                objKnowledgeConfiguration.SortOrder__c == map_KnowledgeArticleConfigurationByKnowledgeArticleId.get(idKnowledgeArticleId).SortOrder__c+1
                ) {
                    idNextKnowledgeArticleId = objKnowledgeConfiguration.KnowledgeArticleId__c;
                }
            }

            if (String.isNotBlank(idNextKnowledgeArticleId) && 
                map_KnowledgeArticlesByKnowledgeArticleId.containsKey(idNextKnowledgeArticleId)
            ) {
                List<Knowledge__kav> list_KnowledgeArticles = map_KnowledgeArticlesByKnowledgeArticleId.get(idNextKnowledgeArticleId);
                for (Knowledge__kav objKnowledgeArticle: list_KnowledgeArticles) {
                    if (objKnowledgeArticle.IsMasterLanguage) {
                        map_articlesByNextPrevious.put('next', objKnowledgeArticle);
                    } else if (objKnowledgeArticle.Language == objLoggedInUser.LanguageLocaleKey) {
                        map_articlesByNextPrevious.put('next', objKnowledgeArticle);
                        break;
                    }
                }
            }
            if (String.isNotBlank(idPreviousKnowledgeArticleId) && 
                map_KnowledgeArticlesByKnowledgeArticleId.containsKey(idPreviousKnowledgeArticleId)
            ) {
                List<Knowledge__kav> list_KnowledgeArticles = map_KnowledgeArticlesByKnowledgeArticleId.get(idPreviousKnowledgeArticleId);
                for (Knowledge__kav objKnowledgeArticle: list_KnowledgeArticles) {
                    if (objKnowledgeArticle.IsMasterLanguage) {
                        map_articlesByNextPrevious.put('previous', objKnowledgeArticle);
                    } else if (objKnowledgeArticle.Language == objLoggedInUser.LanguageLocaleKey) {
                        map_articlesByNextPrevious.put('previous', objKnowledgeArticle);
                        break;
                    }
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