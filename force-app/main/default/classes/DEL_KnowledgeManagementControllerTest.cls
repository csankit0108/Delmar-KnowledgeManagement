/***************************************************************************************************************************
* 
* @ Name            :   DEL_KnowledgeManagementControllerTest
* @ Purpose         :   Test class for DEL_KnowledgeManagementController
* @ Author          :   Rakesh Nayak
*
*   Date            |  Developer Name               |  Version      |  Changes
* ==========================================================================================================================
*   18-11-2022      |  rakesh.nayak@absyz.com       |  1.0          |  Initial Version
*   21-11-2022      |  vinaykant.kurre@absyz.com    |  1.1          |  Added Test Methods for Knowledge Articles Methods
*   21-11-2022      |  nandakishore.reddy@absyz.com |  1.2          |  Added Test Methods for Knowledge Articles Navigation.
*
***************************************************************************************************************************/
@isTest
public class DEL_KnowledgeManagementControllerTest {
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  This method is used to setup data for testing apex class 'DEL_KnowledgeManagementController'
    **/
    @TestSetup
    static void createData(){
        DEL_KnowledgeConfiguration__c objKnowledgeConfiguration = new DEL_TestUtility.KnowledgeConfigurationBuilder()
            .setCategoryName('DCMS')
            .setSortOrder(1)
            .setPageName('Admin_Setup')
            .createKnowledgeConfiguration();
        insert objKnowledgeConfiguration;

        DEL_KnowledgeConfiguration__c objKnowledgeConfiguration2 = new DEL_TestUtility.KnowledgeConfigurationBuilder()
            .setCategoryName('Client')
            .setSortOrder(1)
            .setPageName('Admin_Setup')
            .setParentCategory(objKnowledgeConfiguration.Id)
            .createKnowledgeConfiguration();
        insert objKnowledgeConfiguration2;

        DEL_KnowledgeConfiguration__c objKnowledgeConfiguration3 = new DEL_TestUtility.KnowledgeConfigurationBuilder()
            .setCategoryName('Getting_Started')
            .setSortOrder(1)
            .setPageName('Admin_Setup')
            .setParentCategory(objKnowledgeConfiguration2.Id)
            .createKnowledgeConfiguration();
        insert objKnowledgeConfiguration3;

        DEL_KnowledgeConfiguration__c objKnowledgeConfiguration4 = new DEL_TestUtility.KnowledgeConfigurationBuilder()
            .setCategoryName('About_DCMS')
            .setSortOrder(1)
            .setPageName('Admin_Setup')
            .setParentCategory(objKnowledgeConfiguration3.Id)
            .createKnowledgeConfiguration();
        insert objKnowledgeConfiguration4;

        List<Knowledge__kav> list_NewKnowledgeArticles = new List<Knowledge__kav>();
        List<Knowledge__DataCategorySelection> list_KnowledgeDataCategorySelection = new List<Knowledge__DataCategorySelection>();

		Knowledge__kav objKnowledgekav1 = new DEL_TestUtility.KnowledgeKavBuilder()
            .setTitle('Know about delmar details')
            .setUrlName('Know-about-delmar-details')
            .setSortOrder(1)
            .createKnowledgeKav();
        list_NewKnowledgeArticles.add(objKnowledgekav1);
        Knowledge__kav objKnowledgekav2 = new DEL_TestUtility.KnowledgeKavBuilder()
            .setTitle('Role Heirarchy Level')
            .setUrlName('Role-Heirarchy-Level')
            .setSortOrder(2)
            .createKnowledgeKav();
        list_NewKnowledgeArticles.add(objKnowledgekav2);
        Knowledge__kav objKnowledgekav3 = new DEL_TestUtility.KnowledgeKavBuilder()
            .setTitle('All Community Profiles')
            .setUrlName('All-Community-Profiles')
            .setSortOrder(3)
            .createKnowledgeKav();
        list_NewKnowledgeArticles.add(objKnowledgekav3);

		insert list_NewKnowledgeArticles;

        for (Knowledge__kav objKnowledgeArticle: [SELECT KnowledgeArticleId FROM Knowledge__kav]) {
			Knowledge__DataCategorySelection objKnowledgeDataCategorySelection= new DEL_TestUtility.KnowledgeCategorySelectionBuilder()
                .setParentId(objKnowledgeArticle.Id)
                .setDataCategoryGroupName('Systems')
                .setDataCategoryName('About_DCMS')
                .createKnowledgeDataCategorySelection();
                list_KnowledgeDataCategorySelection.add(objKnowledgeDataCategorySelection);

        	KbManagement.PublishingService.publishArticle(objKnowledgeArticle.KnowledgeArticleId,true);
        }
		insert list_KnowledgeDataCategorySelection;

    }

    @isTest private static void testCategoryAddition() {
        Test.startTest();
        DEL_KnowledgeManagementController.KnowledgeWrapper objWrapper = DEL_KnowledgeManagementController.getDescribeDataCategoryGroupStructureResults();
        List<DEL_KnowledgeManagementController.CategoryWrapper> list_CategoryWrapper = new List<DEL_KnowledgeManagementController.CategoryWrapper>();
        for (String strCategory : objWrapper.list_DefaultSortedCategories ) {
            DEL_KnowledgeManagementController.CategoryWrapper objCategoryWrapper = new DEL_KnowledgeManagementController.CategoryWrapper();
            objCategoryWrapper.name = strCategory;
            objCategoryWrapper.SortOrder = '1';
            list_CategoryWrapper.add(objCategoryWrapper);
        }

        DEL_KnowledgeManagementController.CategoryWrapper objNewCategoryWrapper = new DEL_KnowledgeManagementController.CategoryWrapper();
        objNewCategoryWrapper.name = 'Bookings';
        objNewCategoryWrapper.SortOrder = '2';
        list_CategoryWrapper.add(objNewCategoryWrapper);
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurations = DEL_KnowledgeManagementController.saveCategories(objWrapper.map_CategoryByParent, list_CategoryWrapper, 'Admin_Setup');
        Test.stopTest();
        System.assertEquals(5, list_KnowledgeConfigurations.size(), 'Category not added!');
    }

    @isTest private static void testCategoryDeletion() {
        Test.startTest();
        DEL_KnowledgeManagementController.KnowledgeWrapper objWrapper = DEL_KnowledgeManagementController.getDescribeDataCategoryGroupStructureResults();
        List<DEL_KnowledgeManagementController.CategoryWrapper> list_CategoryWrapper = new List<DEL_KnowledgeManagementController.CategoryWrapper>();
        for (String strCategory : objWrapper.list_DefaultSortedCategories ) {
            if (strCategory == 'Getting_Started') {
                continue;
            } else {
                DEL_KnowledgeManagementController.CategoryWrapper objCategoryWrapper = new DEL_KnowledgeManagementController.CategoryWrapper();
                objCategoryWrapper.name = strCategory;
                objCategoryWrapper.SortOrder = '1';
                list_CategoryWrapper.add(objCategoryWrapper);
            }
        }

        DEL_KnowledgeManagementController.CategoryWrapper objNewCategoryWrapper = new DEL_KnowledgeManagementController.CategoryWrapper();
        List<DEL_KnowledgeConfiguration__c> list_KnowledgeConfigurations = DEL_KnowledgeManagementController.saveCategories(objWrapper.map_CategoryByParent, list_CategoryWrapper, 'Admin_Setup');
        Test.stopTest();
        List<DEL_KnowledgeConfiguration__c> list_AvailableKnowledgeConfigurations = [SELECT Id FROM DEL_KnowledgeConfiguration__c];
        System.assertEquals(2, list_AvailableKnowledgeConfigurations.size(), 'Categories are not removed!');
    }

    @isTest private static void testKnowledgeArticlesMethods() {
        Knowledge__kav objKnowledgekav = [SELECT 
										  Id, 
										  Title, 
										  KnowledgeArticleId,
										  PublishStatus, 
										  VersionNumber, 
										  SortOrder__c 
										  FROM Knowledge__kav 
										  WHERE PublishStatus='Online' 
										  LIMIT 1];
		
        Test.startTest();
        Map<String, Knowledge__kav> map_NextPreviousKnowledgeArticle = DEL_KnowledgeManagementController.DEL_Nxtprev(objKnowledgekav.Id);
        Set<String> list_String = map_NextPreviousKnowledgeArticle.keySet();
        Map<String, List<Knowledge__kav>> map_AllKnowledgeArticlesByCategory = DEL_KnowledgeManagementController.getAllKnowledgeArticles();
        List<Knowledge__kav> list_KnowledgeArticles = map_AllKnowledgeArticlesByCategory.get('About_DCMS');
        DEL_KnowledgeManagementController.setknowledgeArticlesOrder(list_KnowledgeArticles);
        Test.stopTest();
        
        System.assert(!list_String.isEmpty(), 'ERROR: Atleast one either next or previous Knowledge article should be fetched');
        System.assert(!list_KnowledgeArticles.isEmpty(), 'ERROR: Atleast one Knowledge Article record should be fetched.');

	}

    @isTest private static void testTableOfContentsMethods() {
        
		DEL_KnowledgeManagementController.TableofContentsWrapper objTableofContentsWrapper = new DEL_KnowledgeManagementController.TableofContentsWrapper();
        Test.startTest();
        objTableofContentsWrapper = DEL_KnowledgeManagementController.getCategorySelectionsByPage('Systems Articles');
        Test.stopTest();

	}
}