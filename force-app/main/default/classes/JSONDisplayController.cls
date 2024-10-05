public class JSONDisplayController {
    public String jsonOutput { get; set; }
    public Invoice__c invoice { get; set; } 
    public List<Invoice_Line_Item__c> lineItems { get; set; } 

    public JSONDisplayController() {

        jsonOutput = ApexPages.currentPage().getParameters().get('jsonOutput');
        
        invoice = new Invoice__c();
        lineItems = new List<Invoice_Line_Item__c>();
    }

public PageReference createInvoice() {
    // Deserialize the data
    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonOutput);
    
    // Creating the Invoice record
    invoice.Invoice_Date__c = Date.valueOf((String) data.get('Date'));
    invoice.Due_Date__c = Date.valueOf((String) data.get('DueDate'));
    invoice.Account__c = (String) ((Map<String, Object>) data.get('Contact')).get('AccountNumber');
    invoice.Invoice_Reference__c = (String) data.get('Reference');

    try {
        insert invoice;
    } catch (DmlException e) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to create invoice: ' + e.getMessage()));
        return null; 
    }
   //creating invoice line item records
    List<Object> lineItemsData = (List<Object>) data.get('LineItems');

    
    if (lineItemsData != null && !lineItemsData.isEmpty()) {
        for (Object lineItemObj : lineItemsData) {
            Map<String, Object> lineItemData = (Map<String, Object>) lineItemObj; 
            
            Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c();
            lineItem.Invoice__c = invoice.Id; 
            lineItem.Line_Description__c = (String) lineItemData.get('Description');
            lineItem.Quantity__c = Decimal.valueOf((String) lineItemData.get('Quantity')); 
            lineItem.Unit_Price__c = Decimal.valueOf((String) lineItemData.get('UnitAmount')); 

            lineItems.add(lineItem);
        }
    } else {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No line items found.'));
        return null; 
    }


    try {
        insert lineItems;
    } catch (DmlException e) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to create line items: ' + e.getMessage()));
        return null; 
    }

    // Redirecting to the newly created Invoice record
    PageReference invoicePage = new PageReference('/' + invoice.Id);
    invoicePage.setRedirect(true);
    return invoicePage;
}

}