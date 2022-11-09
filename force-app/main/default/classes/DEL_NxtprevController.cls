public with sharing class DEL_NxtprevController {
    @AuraEnabled(cacheable = true)
    public static Map<String, Knowledge__kav> DEL_Nxtprev(Id recordId) {
        Knowledge__kav objKnowledgeArticle = new Knowledge__kav();
        objKnowledgeArticle= [SELECT Id,Title,KnowledgeArticleId,PublishStatus,VersionNumber,SortOrder__c FROM Knowledge__kav WHERE PublishStatus='Online' AND Id = :recordId];
       System.debug(objKnowledgeArticle); 
       Knowledge__DataCategorySelection objDataCategory = new Knowledge__DataCategorySelection();
       objDataCategory=[SELECT Id,DataCategoryGroupName,DataCategoryName FROM Knowledge__DataCategorySelection WHERE ParentId= :recordId];
       System.debug(objDataCategory);
       String groupName=objDataCategory.DataCategoryGroupName + '__c';
       String subCategory=objDataCategory.DataCategoryName + '__c';
       String strQuery = 'SELECT Id,Title,KnowledgeArticleId,PublishStatus,VersionNumber,SortOrder__c FROM Knowledge__kav WHERE PublishStatus=\'Online\' WITH DATA CATEGORY '+groupName +' AT '+subCategory +' ORDER BY SortOrder__c';
       List<Knowledge__kav> filteredArticles =Database.query(strQuery);
       System.debug(filteredArticles);   
       //Map string knowledge_kavv for prev(if prev null) and string for next
       Map<String, Knowledge__kav> articles = new Map<String, Knowledge__kav>();
        for (Knowledge__kav objKnowledgeArticleVersion : filteredArticles) {
            if (String.isNotBlank(String.valueOf(objKnowledgeArticleVersion.SortOrder__c)) &&
                String.isNotBlank(String.valueOf(objKnowledgeArticle.SortOrder__c)) ) {
                if (objKnowledgeArticleVersion.SortOrder__c == (objKnowledgeArticle.SortOrder__c-1)) {
                    articles.put('previous', objKnowledgeArticleVersion);
                }
                if (objKnowledgeArticleVersion.SortOrder__c == (objKnowledgeArticle.SortOrder__c+1)) {
                    articles.put('next', objKnowledgeArticleVersion);
                }
            }
        }
       return articles;
    }
}

    
