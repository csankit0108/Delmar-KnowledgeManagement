/*******************************************************************************************************
* 
* @ Name            :   DEL_UtilsTest
* @ Purpose         :   Test class for the DEL_Utils class.
* @ Author          :   Ankit C
*
*   Date            |  Developer Name               |  Version      |  Changes
* ======================================================================================================
*  26-07-2022       |  ankit.c@absyz.com            |  1.0          |  Initial version
*******************************************************************************************************/
@IsTest
private class DEL_UtilsTest {
    /**
    * @ author       :  Ankit C
    * @ description  :  Test method for logException() method in DEL_Utils class
    **/
    @IsTest
    private static void testLogException() {
        Account objAccount = new Account();
        DEL_ExceptionLog__c objExceptionLog = new DEL_ExceptionLog__c();
        Test.startTest();
        try {
            // This DML will fail as Name is required.
            insert objAccount;
        } catch (Exception objException) {
            objExceptionLog = DEL_Utils.logException(
                'DEL_UtilsTest',
                'testLogException',
                objException,
                true
            );
        }
        Test.stopTest();
        
        // Assert if an DEL_ExceptionLog__c record was created of DML Type
        System.assert(objExceptionLog.Id != null);
        System.assertEquals('System.DmlException', objExceptionLog.ExceptionType__c, 'Record was not created.');
    }
    
    /**
    * @ author       :  Ankit C
    * @ description  :  Test method for logDMLException() and processDMLErrors() method in DEL_Utils class
    **/
    @IsTest
    private static void testLogDMLException() {
        List<Account> list_Accounts = new List<Account>();
        list_Accounts.add(new Account());
        DEL_ExceptionLog__c objExceptionLog = new DEL_ExceptionLog__c();
        Test.startTest();
        List<Database.SaveResult> list_SaveResults = Database.insert(list_Accounts, false);
        List<String> list_Errors = DEL_Utils.processDMLErrors(list_SaveResults, 'Insert');
        DEL_Utils.logDMLException(
            'DEL_UtilsTest',
            'testLogDMLException',
            list_Errors
        );
        Test.stopTest();
        
        List<DEL_ExceptionLog__c> list_ExceptionLogs = [SELECT
                                                        Id, 
                                                        MethodName__c
                                                        FROM DEL_ExceptionLog__c
                                                        WHERE MethodName__c = 'testLogDMLException'];
        System.assert(!list_ExceptionLogs.isEmpty());
    }
    
    /**
    * @ author       :  Rakesh Nayak
    * @ description  :  Test method for HandleHtmlBody()  method in DEL_Utils class
    **/
    @IsTest
    private static void testHandleHtmlBody() {
        String strHtmlBody = '<div>this is HtmlBody<br><div><i>Okay</i></div><br><b>Update please</b></div><br><div class="gmail_quote"><body>Test</body>';
        Test.startTest();
        String strLatestReply = DEL_Utils.handleHtmlBody(strHtmlBody);
        Test.stopTest();

        System.assertEquals('<div>this is HtmlBody<br><div><i>Okay</i></div><br><b>Update please</b></div>', strLatestReply);
    }

}