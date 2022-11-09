public with sharing class DEL_KnowledgeManagementController {
    //Map of DEL_KnowledgeConfiguration__c records by Name
    public static Map<String, DEL_KnowledgeConfiguration__c> map_KnowledgeConfigurationsByName;

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
    }

    public class CategoryWrapper {
        public String SortOrder;
        public String name;
        public CategoryWrapper() {
            name = '';
        }
    }

    @AuraEnabled
    public static List<DEL_KnowledgeConfiguration__c> saveCategories(List<String> list_SelectedCategories, Map<String, String> map_CategoryByParent, List<Object> list_SubcategoriesSelected, String strPageName) {
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

        for (String strcategory : list_SelectedCategories) {
            DEL_KnowledgeConfiguration__c objKnowledgeConfiguration =new DEL_KnowledgeConfiguration__c();
            if(map_KnowledgeConfigurationsByName.containsKey(strCategory)) {
                objKnowledgeConfiguration = map_KnowledgeConfigurationsByName.get(strCategory);
                objKnowledgeConfiguration.SortOrder__c = list_SelectedCategories.IndexOf(strCategory) + 1;
                objKnowledgeConfiguration.PageName__c = strPageName;
                list_KnowledgeConfigurationsforUpdate.add(objKnowledgeConfiguration);
            } else {
                objKnowledgeConfiguration.Name = strCategory;
                objKnowledgeConfiguration.SortOrder__c = list_SelectedCategories.IndexOf(strCategory) + 1;
                objKnowledgeConfiguration.PageName__c = strPageName;
                list_KnowledgeConfigurationsforInsert.add(objKnowledgeConfiguration);
            }
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
            Id idParentCategory = map_CategoryIdByName.get(strParentCategory);
            objKnowledgeConfiguration.ParentCategory__c = idParentCategory;
            map_KnowledgeConfigurationsByName.get(objKnowledgeConfiguration.Name).ParentCategory__c  = idParentCategory;
        }

        update list_KnowledgeConfigurationsforUpsert;

        for (DEL_KnowledgeConfiguration__c objconfig : map_KnowledgeConfigurationsByName.values()) {
            System.debug('map valuess :: ' + objConfig);
        }
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
    public static KnowledgeWrapper 
        getDescribeDataCategoryGroupStructureResults(){
            List<DescribeDataCategoryGroupResult> describeCategoryResult;
            List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
            List<DataCategory> list_ParentCategories = new List<DataCategory>();
            KnowledgeWrapper objWrapper = new KnowledgeWrapper();
            Map<String, String> map_CategoryByParent = new Map<String, String>();
            map_KnowledgeConfigurationsByName = new Map<String,DEL_KnowledgeConfiguration__c>();
            Map<String, DEL_KnowledgeConfiguration__c> map_SelectedSubcategoriesByName = new Map<String, DEL_KnowledgeConfiguration__c>();
            List<String> list_SortedSubcategories = new List<String>();
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
                    if(String.isBlank(objKnowledgeConfiguration.ParentCategory__c)) {
                        objWrapper.list_DefaultSortedCategories.add(objKnowledgeConfiguration.Name);
                    } else {
                        map_SelectedSubcategoriesByName.put(objKnowledgeConfiguration.Name, objKnowledgeConfiguration);
                    }
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
                                    map_SelectedSubcategoriesByName,
                                    list_SortedSubcategories,
                                    map_ChildCategoriesByParent
                                );
                                for (DataCategory objSubcategory : list_Subcategories) {
                                    list_SubcategoryNames.add(objSubcategory.getLabel());
                                }

                                objWrapper.map_CategoriesByTopLevelCategories.put(
                                    topLevelCategory.getLabel(), 
                                    list_SubcategoryNames
                                );                         
                            }
                        }
                    }

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
                    
                    objWrapper.list_DefaultSortedSubcategories = list_SortedSubcategories;
                    List<DataCategory> childCategoryList = new List<DataCategory>();
                }
                objWrapper.list_ParentCategoryNames.addAll(objWrapper.map_CategoriesByTopLevelCategories.keySet());
            } catch (Exception e) {
            }
            return objWrapper;
        }

    public static void getAllCategories(
        DataCategory [] categories, 
        Map<String, String> map_CategoryByParent,
        List<DataCategory> allCategories,
        Map<String,DEL_KnowledgeConfiguration__c> map_SelectedSubcategoriesByName,
        List<String> list_SortedSubcategories,
        Map<String, List<String>> map_ChildCategoriesByParent
    ) {
        List<DEL_KnowledgeConfiguration__c> list_SubcategoriesTemp = new List<DEL_KnowledgeConfiguration__c>();
        if (categories.isEmpty()) {
            return;
        } else {
            DataCategory [] categoriesClone = categories.clone();
            DataCategory category = categoriesClone[0];
            for (DataCategory subcategory : category.getChildCategories()) {
                if (map_SelectedSubcategoriesByName.containsKey(subcategory.getLabel())) {
                    list_SubcategoriesTemp.add(map_SelectedSubcategoriesByName.get(subcategory.getLabel()));
                }
                if (map_ChildCategoriesByParent.containsKey(category.getLabel())) {
                    map_ChildCategoriesByParent.get(category.getLabel()).add(subcategory.getLabel());
                } else {
                    map_ChildCategoriesByParent.put(category.getLabel(), new List<String>{ subcategory.getLabel() });
                }
                map_CategoryByParent.put(subcategory.getLabel(), category.getLabel());
            }

            list_SortedSubcategories.addAll(sortCategories(list_SubcategoriesTemp));
            //DataCategory[] allCategories = new DataCategory[]{category};
            //DataCategory[] allCategories = new DataCategory[]{};
            categoriesClone.remove(0);
            system.debug('inner category:: ' + category.getLabel());
            system.debug('child category:: ' + category.getChildCategories());
            categoriesClone.addAll(category.getChildCategories());
            allCategories.addAll(category.getChildCategories());
            getAllCategories(categoriesClone, map_CategoryByParent, allCategories, map_SelectedSubcategoriesByName, list_SortedSubcategories, map_ChildCategoriesByParent);
            system.debug('allCategories:: '+allCategories);
            //return allCategories;
        }
    }

    public static List<String> sortCategories(List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurationsToSort) {
        List<String> list_SortedCategoryNames = new List<String>();
        for(Integer i = 0; i < list_KnowledgeConfigurationsToSort.size(); i++) {
            for(Integer j = i+1; j < list_KnowledgeConfigurationsToSort.size(); j++) {
                if (list_KnowledgeConfigurationsToSort[i].SortOrder__c > list_KnowledgeConfigurationsToSort[j].SortOrder__c) {
                    DEL_KnowledgeConfiguration__c objKnowledgeConfigurtion = list_KnowledgeConfigurationsToSort[i];
                    list_KnowledgeConfigurationsToSort[i] = list_KnowledgeConfigurationsToSort[j];
                    list_KnowledgeConfigurationsToSort[j] = objKnowledgeConfigurtion;
                }
            }
            list_SortedCategoryNames.add(list_KnowledgeConfigurationsToSort[i].Name);
        }
        return list_SortedCategoryNames;
    }

    public static void fetchChildCategories(
        List<DEL_KnowledgeConfiguration__c> list_ConfigsForDeletion, 
        Map<String, DEL_KnowledgeConfiguration__c> map_KnowledgeConfigurationsByName,
        List<DEL_KnowledgeConfiguration__c> list_ConfigurationsToDelete
        ) {
            System.debug('first list for deletion :: '+list_ConfigsForDeletion);
            System.debug('list for deletion :: '+ list_ConfigurationsToDelete);
        if(!list_ConfigsForDeletion.isEmpty()) {
            DEL_KnowledgeConfiguration__c objConfig = list_ConfigsForDeletion[0];
            System.debug('objConfig :: '+objConfig);
            if (!list_ConfigurationsToDelete.contains(objConfig)) {
                list_ConfigurationsToDelete.add(objConfig);
            }
            for (DEL_KnowledgeConfiguration__c objKnowledgeConfiguration : map_KnowledgeConfigurationsByName.values()) {
                System.debug('inside for loop');
                if(objKnowledgeConfiguration.ParentCategory__c == objConfig.Id) {
                    System.debug('parent category id :: ' + objKnowledgeConfiguration.ParentCategory__c);
                    System.debug('objconfig id :: ' + objConfig.Id);
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
}