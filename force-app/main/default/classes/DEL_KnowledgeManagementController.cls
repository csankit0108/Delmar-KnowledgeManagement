public with sharing class DEL_KnowledgeManagementController {
    //Map of DEL_KnowledgeConfiguration__c records by Name
    public static Map<String, DEL_KnowledgeConfiguration__c> map_KnowledgeConfigurationsByName;

    //Map of SubCategories by their Unique Name
    public static Map<String, String> map_SubCategoriesByUniqueName = new Map<String, String>();

    

    public class KnowledgeWrapper {
        @AuraEnabled public Boolean blnIsSuccess;
        //Map of List of sub categories by top level categories
        @AuraEnabled public Map<String, List<String>> map_CategoriesByTopLevelCategories = new Map<String, List<String>>();
        //This map defines what is the parent category for a sub category
        @AuraEnabled public Map<String, String> map_CategoryByParent = new Map<String, String>();
        //List of Top level category names
        @AuraEnabled public List<String> list_ParentCategoryNames = new List<String>();
        //List of previously sorted category names
        @AuraEnabled public List<String> list_DefaultSortedCategories = new List<String>();
        //List of previously sorted sub category names
        @AuraEnabled public List<String>  list_DefaultSortedSubcategories = new List<String>();
        //This map defines the child categories for a parent category
        @AuraEnabled public Map<String, List<String>> map_ChildCategoriesByParent = new Map<String, List<String>>();
        @AuraEnabled public List<CategoryWrapper> list_AllCategories = new List<CategoryWrapper>();
        //Map all published Knowledge Articles based on Category Unique Name      
        @AuraEnabled public Map<String, List<Knowledge__kav>> map_KnowledgeArticlesByCategoryUniqueName = new Map<String, List<Knowledge__kav>>();
        //Map all Sub-Category Unique Name By it's Label Name
        @AuraEnabled public map<String, String> map_SubCategoriesByUniqueName = new Map<String, String>();
        //Current Logged-In User information
        @AuraEnabled public User objUserInformation = new user();
    }

    public class CategoryWrapper {
        @AuraEnabled public String SortOrder;
        @AuraEnabled public String name;
        public CategoryWrapper() {
            name = '';
        }
    }
    
    public class TableofContentsWrapper {
        //This map defines what is the parent category for a sub category
        @AuraEnabled public Map<String, String> map_CategoryByParent = new Map<String, String>();
        @AuraEnabled public Map<String, List<Knowledge__kav>> map_ArticlesByCategoryName = new Map<String, List<Knowledge__kav>>();
        @AuraEnabled public List<DEL_KnowledgeConfiguration__c> list_AvailableCategories = new List<DEL_KnowledgeConfiguration__c>();
        @AuraEnabled public List<DEL_KnowledgeConfiguration__c> list_SelectedCategories = new List<DEL_KnowledgeConfiguration__c>();
        //Map all Sub-Category Unique Name By it's Label Name
        @AuraEnabled public map<String, String> map_SubCategoriesByUniqueName = new Map<String, String>();
    }

    @AuraEnabled
    public static List<DEL_KnowledgeConfiguration__c> saveCategories(Map<String, String> map_CategoryByParent, List<Object> list_SubcategoriesSelected, String strPageName) {
        System.debug('list_SubcategoriesSelected :: '+list_SubcategoriesSelected);
        System.debug('map_CategoryByParent :: '+map_CategoryByParent);
        map_KnowledgeConfigurationsByName = new Map<String,DEL_KnowledgeConfiguration__c>();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsforUpsert = new List<DEL_KnowledgeConfiguration__c>();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsforUpdate = new List<DEL_KnowledgeConfiguration__c>();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsforInsert = new List<DEL_KnowledgeConfiguration__c>();
        //Final list of subcategories to be removed from the configs
        List<DEL_KnowledgeConfiguration__c> list_ConfigurationsToDelete = new List<DEL_KnowledgeConfiguration__c>();
        //List of subcategories to be removed from the configs
        List<DEL_KnowledgeConfiguration__c> list_ConfigurationsForDeletion = new List<DEL_KnowledgeConfiguration__c>();


        Map<String, Id> map_CategoryIdByName = new Map<String, Id>();
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
            if(map_KnowledgeConfigurationsByName.containsKey(objWrapper.name)) {
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
        System.debug('List to be inserted :: '+list_KnowledgeConfigurationsforInsert);
        System.debug('List to be updated :: '+list_KnowledgeConfigurationsforUpdate);
        list_KnowledgeConfigurationsforUpsert.addAll(list_KnowledgeConfigurationsforInsert);
        list_KnowledgeConfigurationsforUpsert.addAll(list_KnowledgeConfigurationsforUpdate);
        for(String strCategory : map_KnowledgeConfigurationsByName.keySet())  {
            if(list_KnowledgeConfigurationsforUpdate.contains(map_KnowledgeConfigurationsByName.get(strCategory))) {
                continue;
            } else {
                list_ConfigurationsForDeletion.add(map_KnowledgeConfigurationsByName.get(strcategory));
            }
        }
        upsert list_KnowledgeConfigurationsforUpsert;

        for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : list_KnowledgeConfigurationsforUpsert) {
            map_KnowledgeConfigurationsByName.put(objKnowledgeConfiguration.Name, objKnowledgeConfiguration);
        }
        for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : list_KnowledgeConfigurationsforUpsert) {
            map_CategoryIdByName.put(objKnowledgeConfiguration.Name, objKnowledgeConfiguration.Id);
        }
        System.debug('map of category ids :: '+map_CategoryIdByName);

        for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : list_KnowledgeConfigurationsforUpsert) {
            String strParentCategory = map_CategoryByParent.get(objKnowledgeConfiguration.Name);
            Id idParentCategory = map_KnowledgeConfigurationsByName.get(strParentCategory)?.Id;
            objKnowledgeConfiguration.ParentCategory__c = idParentCategory;
            map_KnowledgeConfigurationsByName.get(objKnowledgeConfiguration.Name).ParentCategory__c  = idParentCategory;
            System.debug('parent id::'+map_KnowledgeConfigurationsByName.get(objKnowledgeConfiguration.Name).ParentCategory__c);
        }

        update list_KnowledgeConfigurationsforUpsert;


        fetchChildCategories(list_ConfigurationsForDeletion, map_KnowledgeConfigurationsByName, list_ConfigurationsToDelete);
        for(DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : list_ConfigurationsToDelete) {
            System.debug('elements to delete :: '+ objKnowledgeConfiguration);
        }
        delete list_ConfigurationsToDelete;
        return list_KnowledgeConfigurationsforUpsert;
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
    
    @AuraEnabled(cacheable = true)
    public static TableofContentsWrapper getCategorySelectionsByPage(String strPageName){
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
                    map_ConfigsByName.put(objKnowledgeConfiguration.Name, objKnowledgeConfiguration);
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
                
                system.debug('map_ConfigsByPageName:: ' +map_ConfigsByPageName);
                system.debug('map_ConfigsByName:: ' +map_ConfigsByName);

                //Making the call to the describeDataCategoryGroups to
                //get the list of category groups associated
                List<String> objType = new List<String>();
                objType.add('KnowledgeArticleVersion');
                describeCategoryResult = Schema.describeDataCategoryGroups(objType);
                
                //Creating a list of pair objects to use as a parameter
                //for the describe call
                List<DataCategoryGroupSobjectTypePair> pairs = 
                    new List<DataCategoryGroupSobjectTypePair>();
                
                //Looping throught the first describe result to create
                //the list of pairs for the second describe call
                for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult) {
                    DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
                    p.setSobject(singleResult.getSobject());
                    p.setDataCategoryGroupName(singleResult.getName());
                    pairs.add(p);
                }
                
                //describeDataCategoryGroupStructures()
                describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
                //Getting data from the result
                for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult) {
                    //Get name of the associated Sobject
                    singleResult.getSobject();
                    
                    //Get the name of the data category group
                    singleResult.getName();
                    
                    //Get the name of the data category group
                    singleResult.getLabel();
                    
                    //Get the description of the data category group
                    singleResult.getDescription();
                    
                    //Get the top level categories
                    DataCategory [] toplevelCategories = singleResult.getTopCategories();
                    if (!toplevelCategories.isEmpty()) {
                        DataCategory category = toplevelCategories[0];
                        if (category.getName() == 'All') {
                            list_ParentCategories = category.getChildCategories();
                            for (DataCategory topLevelCategory : list_ParentCategories) {
                                if (
                                    map_ConfigsByPageName.containsKey('Admin_Setup') &&
                                    map_ConfigsByPageName.get('Admin_Setup').contains(topLevelCategory.getLabel())
                                ) {
                                    system.debug('inside parent category addition for admin:: ' + map_ConfigsByName.get(topLevelCategory.getLabel()));
                                    objWrapper.list_AvailableCategories.add(map_ConfigsByName.get(topLevelCategory.getLabel()));
                                }
                                
                                if (
                                    map_ConfigsByPageName.containsKey(strPageName) && 
                                    map_ConfigsByPageName.get(strPageName).contains(topLevelCategory.getLabel())
                                ) {
                                    system.debug('inside parent category addition for page:: ' + map_ConfigsByName.get(topLevelCategory.getLabel()));
                                    objWrapper.list_SelectedCategories.add(map_ConfigsByName.get(topLevelCategory.getLabel()));
                                }
                                
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
                                    objCategoryWrapper.name = objSubcategory.getLabel();
                                    if (
                                        map_ConfigsByPageName.containsKey('Admin_Setup') &&
                                        map_ConfigsByPageName.get('Admin_Setup').contains(objSubcategory.getLabel())
                                    ) {
                                        objWrapper.list_AvailableCategories.add(map_ConfigsByName.get(objSubcategory.getLabel()));
                                        // objWrapper.list_AvailableCategories.add(map_ConfigsByName.get(topLevelCategory.getLabel()));
                                    }
                                    
                                    if (
                                        map_ConfigsByPageName.containsKey(strPageName) && 
                                        map_ConfigsByPageName.get(strPageName).contains(objSubcategory.getLabel())
                                    ) {
                                        objWrapper.list_SelectedCategories.add(map_ConfigsByName.get(objSubcategory.getLabel()));
                                        // objWrapper.list_SelectedCategories.add(map_ConfigsByName.get(topLevelCategory.getLabel()));
                                    }
                                    list_SubcategoryNames.add(objSubcategory.getLabel());
                                }
  
                            }
                        }
                    }
                }
                
                if (objWrapper.list_SelectedCategories.isEmpty()) {
	                 objWrapper.list_SelectedCategories = objWrapper.list_AvailableCategories;
                }
                system.debug('Available Categories:: ' + objWrapper.list_AvailableCategories);
                system.debug('Selected Categories:: ' + objWrapper.list_SelectedCategories);
                objWrapper.map_ArticlesByCategoryName = getAllKnowledgeArticles();
                objWrapper.map_CategoryByParent = map_CategoryByParent;
                objWrapper.map_SubCategoriesByUniqueName = map_SubCategoriesByUniqueName;
                return objWrapper;
            } catch(Exception objException) {
                return objWrapper;
            }
    }

    @AuraEnabled(cacheable = true)
    public static KnowledgeWrapper 
        getDescribeDataCategoryGroupStructureResults(){
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
                List<DataCategoryGroupSobjectTypePair> pairs = 
                    new List<DataCategoryGroupSobjectTypePair>();
                
                //Looping throught the first describe result to create
                //the list of pairs for the second describe call
                for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult) {
                    DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
                    p.setSobject(singleResult.getSobject());
                    p.setDataCategoryGroupName(singleResult.getName());
                    pairs.add(p);
                }
                
                //describeDataCategoryGroupStructures()
                describeCategoryStructureResult = 
                    Schema.describeDataCategoryGroupStructures(pairs, false);
                
                //Getting data from the result
                for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult) {
                    //Get name of the associated Sobject
                    singleResult.getSobject();
                    
                    //Get the name of the data category group
                    singleResult.getName();
                    
                    //Get the name of the data category group
                    singleResult.getLabel();
                    
                    //Get the description of the data category group
                    singleResult.getDescription();
                    
                    //Get the top level categories
                    DataCategory [] toplevelCategories = singleResult.getTopCategories();
                    system.debug('toplevelCategories size:: ' + toplevelCategories.size());
                    if (!toplevelCategories.isEmpty()) {
                        DataCategory category = toplevelCategories[0];
                        if (category.getName() == 'All') {
                            list_ParentCategories = category.getChildCategories();
                            for (DataCategory topLevelCategory : list_ParentCategories) {
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
                                    objCategoryWrapper.name = objSubcategory.getLabel();
                                    objWrapper.list_AllCategories.add(objCategoryWrapper);
                                    list_SubcategoryNames.add(objSubcategory.getLabel());
                                }

                                objWrapper.map_CategoriesByTopLevelCategories.put(
                                    topLevelCategory.getLabel(), 
                                    list_SubcategoryNames
                                );                         
                            }
                        }
                    }

                    objWrapper.map_ChildCategoriesByParent = map_ChildCategoriesByParent;
                    System.debug('map of parent and child categories :: ' + map_ChildCategoriesByParent);
                    objWrapper.map_CategoryByParent = map_CategoryByParent;
                    system.debug('sorted subcategories :: ' + objWrapper.list_DefaultSortedSubcategories);
                    system.debug('map_CategoriesByTopLevelCategories:: ' + objWrapper.map_CategoriesByTopLevelCategories);
                    system.debug('map_CategoriesByTopLevelCategories keyset:: ' + objWrapper.map_CategoriesByTopLevelCategories.keySet());
                    system.debug('map_CategoriesByTopLevelCategories values:: ' + objWrapper.map_CategoriesByTopLevelCategories.values().size());
                    for (String strparent : objWrapper.map_CategoriesByTopLevelCategories.keySet()) {
                        system.debug('strparent ' + strparent);
                        for (String d :  objWrapper.map_CategoriesByTopLevelCategories.get(strparent)) {
                            system.debug('values inside map:: ' + d);
                        }
                    }
                    
                    List<DataCategory> childCategoryList = new List<DataCategory>();
                }
                objWrapper.list_ParentCategoryNames.addAll(objWrapper.map_CategoriesByTopLevelCategories.keySet());
                for (String strparent : objWrapper.map_CategoriesByTopLevelCategories.keySet()) {
                    CategoryWrapper objCategoryWrapper = new CategoryWrapper();
                    objCategoryWrapper.name = strparent;
                    objWrapper.list_AllCategories.add(objCategoryWrapper);
                }
                objWrapper.map_KnowledgeArticlesByCategoryUniqueName = getAllKnowledgeArticles();
                objWrapper.map_SubCategoriesByUniqueName = map_SubCategoriesByUniqueName;
                Id idUserId = UserInfo.getUserId();
                objWrapper.objUserInformation = [SELECT 
                                                 Id,
                                                 Name,
                                                 UserPermissionsKnowledgeUser
                                                 FROM User 
                                                 WHERE Id = :idUserId
                                                 AND IsActive = true];

            } catch (Exception e) {
            }
            return objWrapper;
        }

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
                if (map_ChildCategoriesByParent.containsKey(category.getLabel())) {
                    map_ChildCategoriesByParent.get(category.getLabel()).add(subcategory.getLabel());
                } else {
                    map_ChildCategoriesByParent.put(category.getLabel(), new List<String> {subcategory.getLabel()});
                }
                map_CategoryByParent.put(subcategory.getLabel(), category.getLabel());
            }
            map_SubCategoriesByUniqueName.put(category.getLabel(), category.getName());

            categoriesClone.remove(0);
            system.debug('inner category:: ' + category.getLabel());
            system.debug('child category:: ' + category.getChildCategories());
            categoriesClone.addAll(category.getChildCategories());
            allCategories.addAll(category.getChildCategories());
            getAllCategories(categoriesClone, map_CategoryByParent, allCategories, map_ChildCategoriesByParent);
            system.debug('allCategories:: '+allCategories);
            //return allCategories;
        }
    }

    public static void fetchChildCategories(
        List<DEL_KnowledgeConfiguration__c> list_ConfigsForDeletion, 
        Map<String, DEL_KnowledgeConfiguration__c> map_KnowledgeConfigurationsByName,
        List<DEL_KnowledgeConfiguration__c> list_ConfigurationsToDelete
        ) {
        if(!list_ConfigsForDeletion.isEmpty()) {
            DEL_KnowledgeConfiguration__c objConfig = list_ConfigsForDeletion[0];
            System.debug('objConfig :: '+objConfig);
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

    @AuraEnabled(cacheable=true)
    public static Map<String, List<Knowledge__kav>> getAllKnowledgeArticles () { 
        List<Knowledge__DataCategorySelection> list_KnowledgeArticlesWithCategory = new List<Knowledge__DataCategorySelection>();
        Map<Id, String> map_KnowledgeArticleIdByCategoryName = new Map<Id, String>();
        Map<String, List<Knowledge__kav>> map_KnowledgeArticlesByCategoryName = new Map<String, List<Knowledge__kav>>();

        list_KnowledgeArticlesWithCategory = [SELECT Id, 
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
            List<Knowledge__kav> list_KnowledgeArticlesTemp = new List<Knowledge__kav>();
            if (map_KnowledgeArticleIdByCategoryName.containsKey(objKnowledgeArticle.Id)) {
                String CategoryName = map_KnowledgeArticleIdByCategoryName.get(objKnowledgeArticle.Id);
                if (!map_KnowledgeArticlesByCategoryName.containsKey(CategoryName)) {
                    list_KnowledgeArticlesTemp.add(objKnowledgeArticle);
                } else {
                    list_KnowledgeArticlesTemp = map_KnowledgeArticlesByCategoryName.get(CategoryName);
                    list_KnowledgeArticlesTemp.add(objKnowledgeArticle);
                }
                map_KnowledgeArticlesByCategoryName.put(CategoryName, list_KnowledgeArticlesTemp);
            }
        }
        return map_KnowledgeArticlesByCategoryName;
    }

    @AuraEnabled
    public static void setknowledgeArticlesOrder(List<Knowledge__kav> list_KnowledgeArticles) {
        Map<Id, Knowledge__kav> map_KnowledgeArticleByKnowledgeId = new Map<Id, Knowledge__kav>();
        List<Id> list_DraftArticleIds = new List<Id>();
        List<Id> list_KnowledgeArticlesIds = new List<Id>();
        List<Knowledge__kav> list_DraftKnowledgeArticles = new List<Knowledge__kav>();

        try {
            if (list_KnowledgeArticles.size() > 0) {
                for (Knowledge__kav objKnowledgeArticle : list_KnowledgeArticles) {
                    System.debug('AtStart=>'+objKnowledgeArticle.VersionNumber);
                    map_KnowledgeArticleByKnowledgeId.put(objKnowledgeArticle.KnowledgeArticleId, objKnowledgeArticle);
                    Id idDraftArticle = KbManagement.PublishingService.editOnlineArticle(objKnowledgeArticle.KnowledgeArticleId, false);
                    list_DraftArticleIds.add(idDraftArticle);
                }
                list_DraftKnowledgeArticles = [SELECT 
                                               Id,
                                               KnowledgeArticleId, 
                                               VersionNumber
                                               FROM Knowledge__kav
                                               WHERE Id IN :list_DraftArticleIds];
                for (Knowledge__kav objDraftKnowledgeArticle : list_DraftKnowledgeArticles) {
                    objDraftKnowledgeArticle.SortOrder__c = map_KnowledgeArticleByKnowledgeId.get(objDraftKnowledgeArticle.KnowledgeArticleId).SortOrder__c;
                }

                if (list_DraftKnowledgeArticles.size() > 0) {
                    update list_DraftKnowledgeArticles;
                }
                
                for (Knowledge__kav objKnowledgeArticle : list_DraftKnowledgeArticles) {
                    Id idNewUpdatedArticle = objKnowledgeArticle.KnowledgeArticleId;
                    KbManagement.PublishingService.publishArticle(idNewUpdatedArticle, false);
                }
            }
        } catch (Exception e) { 
            throw new AuraHandledException(e.getMessage());
        }
    }
}